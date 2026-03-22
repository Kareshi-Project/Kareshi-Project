package modding;

import polymod.Polymod;
import polymod.Polymod.ModMetadata;
import polymod.backends.OpenFLBackend;
import polymod.backends.PolymodAssets;
import polymod.format.ParseRules;
import openfl.Assets;
import flixel.FlxG;
import haxe.Json;

// ==================== Mod Info ====================

typedef ModInfo =
{
    var id:String;
    var title:String;
    var description:String;
    var author:String;
    var version:String;
    var apiVersion:String;
    var enabled:Bool;
    var path:String;
    @:optional var homepage:String;
    @:optional var icon:String;
    @:optional var dependencies:Array<String>;
}

// ==================== Mod Load Result ====================

typedef ModLoadResult =
{
    var success:Bool;
    var loadedMods:Array<String>;
    var failedMods:Array<String>;
    var errors:Array<String>;
}

// ==================== PolyMod ====================

class PolyMod
{
    // ==================== Constants ====================

    static final MODS_DIR:String        = "mods";
    static final MOD_META_FILE:String   = "_polymod_meta.json";
    static final MOD_ICON_FILE:String   = "_polymod_icon.png";
    static final API_VERSION:String     = "0.0.2";
    static final GAME_ID:String         = "kareshi-project";

    // ==================== State ====================

    static var initialized:Bool              = false;
    static var loadedMods:Array<ModInfo>     = [];
    static var enabledModIDs:Array<String>   = [];
    static var availableMods:Array<ModInfo>  = [];
    static var modScripts:Map<String, scripting.HScript> = new Map();

    // ==================== Callbacks ====================

    public static var onModLoaded:ModInfo -> Void       = null;
    public static var onModUnloaded:String -> Void      = null;
    public static var onModError:String -> String -> Void = null;
    public static var onModsChanged:Void -> Void        = null;

    // ==================== Init ====================

    /**
     * Inicializa o sistema de mods.
     * Deve ser chamado uma vez no boot do jogo.
     */
    public static function init():Void
    {
        if (initialized) return;

        trace('[PolyMod] Initializing mod system — API v$API_VERSION');

        // Cria a pasta de mods se não existir
        #if sys
        if (!sys.FileSystem.exists(MODS_DIR))
            sys.FileSystem.createDirectory(MODS_DIR);
        #end

        scanAvailableMods();
        loadEnabledList();
        initialized = true;

        trace('[PolyMod] Found ${availableMods.length} mod(s). Enabled: ${enabledModIDs.length}');
    }

    // ==================== Scan ====================

    /**
     * Varre a pasta de mods e coleta metadados.
     */
    public static function scanAvailableMods():Void
    {
        availableMods = [];

        #if sys
        if (!sys.FileSystem.exists(MODS_DIR)) return;

        var entries = sys.FileSystem.readDirectory(MODS_DIR);
        for (entry in entries)
        {
            var modPath = '$MODS_DIR/$entry';
            if (!sys.FileSystem.isDirectory(modPath)) continue;

            var metaPath = '$modPath/$MOD_META_FILE';
            if (!sys.FileSystem.exists(metaPath)) continue;

            var info = readModMeta(modPath, metaPath);
            if (info != null)
                availableMods.push(info);
        }

        // Ordena por título
        availableMods.sort(function(a, b) return a.title < b.title ? -1 : 1);
        #end

        trace('[PolyMod] Scanned ${availableMods.length} mod(s).');
    }

    static function readModMeta(modPath:String, metaPath:String):ModInfo
    {
        #if sys
        try
        {
            var raw  = sys.io.File.getContent(metaPath);
            var data = Json.parse(raw);

            // Valida campos obrigatórios
            if (data.id == null || data.title == null || data.author == null)
            {
                trace('[PolyMod] Invalid meta at $metaPath — missing required fields.');
                return null;
            }

            // Verifica compatibilidade de API
            var modAPI:String = data.api_version ?? data.apiVersion ?? "0.0.1";
            if (!isAPICompatible(modAPI))
            {
                trace('[PolyMod] Mod "${data.id}" requires API v$modAPI — current: v$API_VERSION');
            }

            return {
                id:          Std.string(data.id),
                title:       Std.string(data.title),
                description: Std.string(data.description ?? ""),
                author:      Std.string(data.author),
                version:     Std.string(data.version ?? "1.0.0"),
                apiVersion:  modAPI,
                homepage:    data.homepage != null ? Std.string(data.homepage) : null,
                icon:        data.icon     != null ? Std.string(data.icon)     : null,
                dependencies: data.dependencies != null ? cast data.dependencies : [],
                enabled:     false,
                path:        modPath
            };
        }
        catch (e:Dynamic)
        {
            trace('[PolyMod] Error reading meta at $metaPath: $e');
            return null;
        }
        #else
        return null;
        #end
    }

    // ==================== Load ====================

    /**
     * Carrega os mods habilitados via Polymod.
     */
    public static function loadMods(?modIDs:Array<String>):ModLoadResult
    {
        var toLoad = modIDs ?? enabledModIDs;
        var result:ModLoadResult = {
            success:     true,
            loadedMods:  [],
            failedMods:  [],
            errors:      []
        };

        if (toLoad.length == 0)
        {
            trace('[PolyMod] No mods to load.');
            Polymod.init({
                modRoot:       MODS_DIR,
                dirs:          [],
                framework:     OPENFL,
                apiVersionRule: polymod.util.VersionUtil.DEFAULT_VERSION_RULE,
                parseRules:    getParseRules(),
                ignoredFiles:  Polymod.DEFAULT_IGNORED_FILES
            });
            return result;
        }

        // Valida dependências
        var resolved = resolveDependencies(toLoad);
        if (resolved == null)
        {
            result.success = false;
            result.errors.push("Dependency resolution failed.");
            return result;
        }

        // Monta lista de paths
        var dirs:Array<String> = [];
        for (id in resolved)
        {
            var info = getModInfo(id);
            if (info == null)
            {
                result.failedMods.push(id);
                result.errors.push('Mod not found: $id');
                continue;
            }

            #if sys
            if (!sys.FileSystem.exists(info.path))
            {
                result.failedMods.push(id);
                result.errors.push('Path missing: ${info.path}');
                continue;
            }
            #end

            dirs.push(info.path);
            result.loadedMods.push(id);
        }

        // Inicializa o Polymod
        var errors = Polymod.init({
            modRoot:       MODS_DIR,
            dirs:          dirs,
            framework:     OPENFL,
            apiVersionRule: polymod.util.VersionUtil.DEFAULT_VERSION_RULE,
            parseRules:    getParseRules(),
            ignoredFiles:  Polymod.DEFAULT_IGNORED_FILES
        });

        if (errors != null && errors.length > 0)
        {
            for (e in errors)
            {
                var msg = '[${e.modID}] ${e.message}';
                result.errors.push(msg);
                trace('[PolyMod] Error: $msg');
                if (onModError != null) onModError(e.modID, e.message);
            }
            result.success = result.loadedMods.length > 0;
        }

        // Atualiza estado
        loadedMods = [];
        for (id in result.loadedMods)
        {
            var info = getModInfo(id);
            if (info != null)
            {
                info.enabled = true;
                loadedMods.push(info);
                loadModScripts(info);
                if (onModLoaded != null) onModLoaded(info);
            }
        }

        if (onModsChanged != null) onModsChanged();

        trace('[PolyMod] Loaded ${result.loadedMods.length}/${toLoad.length} mod(s).');
        return result;
    }

    /**
     * Descarrega todos os mods ativos.
     */
    public static function unloadAll():Void
    {
        Polymod.clearAssets();

        for (info in loadedMods)
        {
            unloadModScript(info.id);
            if (onModUnloaded != null) onModUnloaded(info.id);
        }

        loadedMods = [];
        if (onModsChanged != null) onModsChanged();

        trace('[PolyMod] All mods unloaded.');
    }

    /**
     * Recarrega todos os mods ativos (útil após mudança na lista).
     */
    public static function reload():ModLoadResult
    {
        unloadAll();
        return loadMods(enabledModIDs);
    }

    // ==================== Enable / Disable ====================

    public static function enableMod(id:String):Bool
    {
        if (enabledModIDs.contains(id)) return true;
        if (getModInfo(id) == null) return false;

        enabledModIDs.push(id);
        saveEnabledList();
        return true;
    }

    public static function disableMod(id:String):Void
    {
        enabledModIDs.remove(id);
        saveEnabledList();
    }

    public static function toggleMod(id:String):Bool
    {
        if (isEnabled(id))
        {
            disableMod(id);
            return false;
        }
        else
        {
            enableMod(id);
            return true;
        }
    }

    public static function isEnabled(id:String):Bool
    {
        return enabledModIDs.contains(id);
    }

    public static function isLoaded(id:String):Bool
    {
        return loadedMods.exists(function(m) return m.id == id);
    }

    // ==================== Mod Order ====================

    public static function moveModUp(id:String):Void
    {
        var i = enabledModIDs.indexOf(id);
        if (i <= 0) return;
        enabledModIDs.splice(i, 1);
        enabledModIDs.insert(i - 1, id);
        saveEnabledList();
    }

    public static function moveModDown(id:String):Void
    {
        var i = enabledModIDs.indexOf(id);
        if (i < 0 || i >= enabledModIDs.length - 1) return;
        enabledModIDs.splice(i, 1);
        enabledModIDs.insert(i + 1, id);
        saveEnabledList();
    }

    public static function setModOrder(ids:Array<String>):Void
    {
        enabledModIDs = ids.copy();
        saveEnabledList();
    }

    // ==================== Dependencies ====================

    static function resolveDependencies(ids:Array<String>):Array<String>
    {
        var resolved:Array<String>  = [];
        var visiting:Array<String>  = [];

        function visit(id:String):Bool
        {
            if (resolved.contains(id)) return true;
            if (visiting.contains(id))
            {
                trace('[PolyMod] Circular dependency detected: $id');
                return false;
            }

            visiting.push(id);
            var info = getModInfo(id);
            if (info == null) { visiting.remove(id); return false; }

            if (info.dependencies != null)
            {
                for (dep in info.dependencies)
                {
                    if (!visit(dep))
                    {
                        trace('[PolyMod] Missing dependency "$dep" for mod "$id"');
                        visiting.remove(id);
                        return false;
                    }
                }
            }

            visiting.remove(id);
            resolved.push(id);
            return true;
        }

        for (id in ids)
            if (!visit(id)) return null;

        return resolved;
    }

    // ==================== Scripts ====================

    static function loadModScripts(info:ModInfo):Void
    {
        #if sys
        var scriptPath = '${info.path}/scripts/mod_init.hscript';
        if (!sys.FileSystem.exists(scriptPath)) return;

        var hs = new scripting.HScript();

        // Injeta info do mod no script
        hs.set("modID",      info.id);
        hs.set("modTitle",   info.title);
        hs.set("modVersion", info.version);
        hs.set("modPath",    info.path);
        hs.set("FlxG",       FlxG);

        hs.onError = function(e) trace('[PolyMod:${info.id}] Script error: $e');

        if (hs.load(scriptPath))
        {
            hs.execute();
            hs.onCreate();
            modScripts.set(info.id, hs);
            trace('[PolyMod] Loaded script for mod: ${info.id}');
        }
        #end
    }

    static function unloadModScript(id:String):Void
    {
        if (modScripts.exists(id))
        {
            modScripts.get(id).onDestroy();
            modScripts.remove(id);
        }
    }

    /**
     * Chama um hook em todos os scripts de mods carregados.
     */
    public static function callHook(hookName:String, ?args:Array<Dynamic>):Void
    {
        for (id => hs in modScripts)
        {
            if (hs.hasFunction(hookName))
            {
                var result = hs.call(hookName, args);
                if (!result.success)
                    trace('[PolyMod:$id] Hook error ($hookName): ${result.error}');
            }
        }
    }

    /**
     * Chama um hook e retorna o primeiro valor não-nulo.
     */
    public static function callHookFirst(hookName:String, ?args:Array<Dynamic>):Dynamic
    {
        for (id => hs in modScripts)
        {
            if (hs.hasFunction(hookName))
            {
                var result = hs.call(hookName, args);
                if (result.success && result.value != null)
                    return result.value;
            }
        }
        return null;
    }

    // ==================== Assets ====================

    /**
     * Retorna um texto de asset com suporte a mods.
     */
    public static function getText(path:String):String
    {
        return Assets.getText(path);
    }

    /**
     * Verifica se um asset existe (original ou de mod).
     */
    public static function exists(path:String):Bool
    {
        return Assets.exists(path);
    }

    /**
     * Retorna o JSON parseado de um asset.
     */
    public static function getJson(path:String):Dynamic
    {
        var raw = getText(path);
        if (raw == null) return null;
        try return Json.parse(raw)
        catch (e:Dynamic) { trace('[PolyMod] JSON parse error: $e'); return null; }
    }

    // ==================== Parse Rules ====================

    static function getParseRules():ParseRules
    {
        var rules = ParseRules.getDefault();
        rules.addType("json",    APPEND);
        rules.addType("txt",     APPEND);
        rules.addType("hscript", REPLACE);
        rules.addType("ogg",     REPLACE);
        rules.addType("png",     REPLACE);
        rules.addType("xml",     REPLACE);
        return rules;
    }

    // ==================== API Version ====================

    static function isAPICompatible(modAPI:String):Bool
    {
        var parts    = API_VERSION.split(".");
        var modParts = modAPI.split(".");
        // Major version deve bater
        return parts[0] == modParts[0];
    }

    // ==================== Persistence ====================

    static final ENABLED_LIST_PATH:String = "mods/.enabled";

    static function saveEnabledList():Void
    {
        #if sys
        try
        {
            var content = enabledModIDs.join("\n");
            sys.io.File.saveContent(ENABLED_LIST_PATH, content);
        }
        catch (e:Dynamic)
        {
            trace('[PolyMod] Failed to save enabled list: $e');
        }
        #end
    }

    static function loadEnabledList():Void
    {
        enabledModIDs = [];

        #if sys
        if (!sys.FileSystem.exists(ENABLED_LIST_PATH)) return;

        try
        {
            var content = sys.io.File.getContent(ENABLED_LIST_PATH);
            for (line in content.split("\n"))
            {
                var id = StringTools.trim(line);
                if (id.length > 0 && getModInfo(id) != null)
                    enabledModIDs.push(id);
            }
        }
        catch (e:Dynamic)
        {
            trace('[PolyMod] Failed to load enabled list: $e');
        }
        #end

        trace('[PolyMod] Enabled mods: ${enabledModIDs.join(", ")}');
    }

    // ==================== Getters ====================

    public static function getAvailableMods():Array<ModInfo>
        return availableMods.copy();

    public static function getLoadedMods():Array<ModInfo>
        return loadedMods.copy();

    public static function getEnabledIDs():Array<String>
        return enabledModIDs.copy();

    public static function getModInfo(id:String):ModInfo
    {
        for (m in availableMods)
            if (m.id == id) return m;
        return null;
    }

    public static function getModCount():Int
        return availableMods.length;

    public static function getLoadedCount():Int
        return loadedMods.length;

    public static function isInitialized():Bool
        return initialized;

    // ==================== Debug ====================

    public static function printStatus():Void
    {
        trace('====== PolyMod Status ======');
        trace('API Version : $API_VERSION');
        trace('Game ID     : $GAME_ID');
        trace('Mods Dir    : $MODS_DIR');
        trace('Available   : ${availableMods.length}');
        trace('Enabled     : ${enabledModIDs.length}');
        trace('Loaded      : ${loadedMods.length}');
        trace('----------------------------');
        for (m in availableMods)
        {
            var status = isLoaded(m.id) ? "✓ LOADED" : (isEnabled(m.id) ? "○ ENABLED" : "✗ DISABLED");
            trace('  [$status]  ${m.id}  v${m.version}  by ${m.author}');
        }
        trace('============================');
    }
}
