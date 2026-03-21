package menus.debug;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import backend.Controls;
import backend.Controls.Action;
import backend.debug.DebugDisplay;
import frontend.JsonHelper;

// ==================== Panel Types ====================

enum EditorPanel
{
    PANEL_INFO;
    PANEL_BACKGROUND;
    PANEL_WAVES;
    PANEL_MIDBOSS;
    PANEL_BOSS;
    PANEL_SCORING;
}

// ==================== StageEditorState ====================

class StageEditorState extends FlxState
{
    // ==================== Layout ====================

    static final SIDEBAR_W:Int   = 200;
    static final HEADER_H:Int    = 48;
    static final FOOTER_H:Int    = 30;
    static final PANEL_X:Float   = SIDEBAR_W + 8;
    static final PANEL_Y:Float   = HEADER_H + 8;
    static final PANEL_W:Float   = 800;
    static final PANEL_H:Float   = FlxG.height - HEADER_H - FOOTER_H - 16;

    // ==================== State ====================

    var controls:Controls;
    var stageData:Dynamic    = null;
    var stagePath:String     = "";
    var isDirty:Bool         = false;
    var currentPanel:EditorPanel = PANEL_INFO;

    // ==================== UI — Header ====================

    var headerBG:FlxSprite;
    var headerTitle:FlxText;
    var headerFile:FlxText;
    var dirtyIndicator:FlxText;
    var breadcrumb:FlxText;

    // ==================== UI — Sidebar ====================

    var sidebarBG:FlxSprite;
    var sidebarItems:Array<FlxSprite>  = [];
    var sidebarLabels:Array<FlxText>   = [];
    var sidebarCursor:FlxSprite;
    var sidebarSelected:Int            = 0;

    static final SIDEBAR_PANELS:Array<String> = [
        "📋  Info",
        "🌌  Background",
        "👾  Waves",
        "⚡  Mid-Boss",
        "💀  Boss",
        "⭐  Scoring"
    ];

    // ==================== UI — Main Panel ====================

    var panelBG:FlxSprite;
    var panelTitle:FlxText;
    var panelDivider:FlxSprite;

    // Field rows
    var fieldRows:Array<FlxSprite> = [];
    var fieldLabels:Array<FlxText> = [];
    var fieldValues:Array<FlxText> = [];
    var fieldKeys:Array<String>    = [];
    var fieldRowSelected:Int       = 0;
    var editingField:Bool          = false;
    var editBuffer:String          = "";
    var editCursor:FlxSprite;
    var editCursorTimer:Float      = 0;

    // ==================== UI — Preview ====================

    var previewBG:FlxSprite;
    var previewTitle:FlxText;
    var previewLines:Array<FlxText> = [];

    // ==================== UI — Footer ====================

    var footerBG:FlxSprite;
    var footerHint:FlxText;
    var footerStatus:FlxText;

    // ==================== UI — Notification ====================

    var notifBG:FlxSprite;
    var notifText:FlxText;
    var notifTimer:Float = 0;

    // ==================== Debug ====================

    #if debug
    var debugDisplay:DebugDisplay;
    #end

    // ==================== Input ====================

    var inputCooldown:Float = 0;
    static final INPUT_COOLDOWN:Float = 0.12;

    // ==================== Create ====================

    override public function create():Void
    {
        super.create();

        controls = Controls.instance;
        FlxG.camera.bgColor = FlxColor.fromRGB(6, 6, 14);

        createBackground();
        createHeader();
        createSidebar();
        createMainPanel();
        createPreviewPanel();
        createFooter();
        createNotification();
        createEditCursor();

        #if debug
        debugDisplay = new DebugDisplay(4, 4);
        add(debugDisplay);
        #end

        // Tenta carregar o stage padrão
        loadStage("data/stages/stage_01.json");

        fadeIn();
    }

    // ==================== Background ====================

    function createBackground():Void
    {
        var bg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(6, 6, 14));
        add(bg);

        // Grid decorativo
        var gc = FlxColor.fromRGBFloat(1, 1, 1, 0.025);
        var gs = 24;
        for (c in 0...Std.int(FlxG.width / gs) + 1)
            add(new FlxSprite(c * gs, 0).makeGraphic(1, FlxG.height, gc));
        for (r in 0...Std.int(FlxG.height / gs) + 1)
            add(new FlxSprite(0, r * gs).makeGraphic(FlxG.width, 1, gc));
    }

    // ==================== Header ====================

    function createHeader():Void
    {
        headerBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, HEADER_H, FlxColor.fromRGB(10, 10, 26));
        add(headerBG);

        add(new FlxSprite(0, HEADER_H - 2).makeGraphic(FlxG.width, 2, FlxColor.fromRGB(40, 40, 120)));

        // Badge
        var badge = new FlxSprite(8, 10).makeGraphic(72, 24, FlxColor.fromRGB(255, 80, 80));
        add(badge);
        var badgeLabel = new FlxText(8, 12, 72, "DEBUG");
        badgeLabel.setFormat(null, 12, FlxColor.WHITE, "center");
        add(badgeLabel);

        headerTitle = new FlxText(90, 8, 300, "Stage Editor");
        headerTitle.setFormat(null, 24, FlxColor.WHITE, "left");
        headerTitle.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(headerTitle);

        breadcrumb = new FlxText(90, 30, 400, "Editor Hub  >  Stage Editor");
        breadcrumb.setFormat(null, 11, FlxColor.fromRGB(100, 100, 160), "left");
        add(breadcrumb);

        headerFile = new FlxText(500, 10, 500, "No file loaded");
        headerFile.setFormat(null, 13, FlxColor.fromRGB(140, 140, 200), "center");
        add(headerFile);

        dirtyIndicator = new FlxText(FlxG.width - 100, 14, 90, "");
        dirtyIndicator.setFormat(null, 13, FlxColor.YELLOW, "right");
        add(dirtyIndicator);
    }

    // ==================== Sidebar ====================

    function createSidebar():Void
    {
        sidebarBG = new FlxSprite(0, HEADER_H).makeGraphic(SIDEBAR_W, FlxG.height - HEADER_H - FOOTER_H, FlxColor.fromRGB(10, 10, 22));
        add(sidebarBG);

        add(new FlxSprite(SIDEBAR_W, HEADER_H).makeGraphic(2, FlxG.height - HEADER_H, FlxColor.fromRGB(30, 30, 80)));

        var secLabel = new FlxText(8, HEADER_H + 8, SIDEBAR_W - 16, "PANELS");
        secLabel.setFormat(null, 10, FlxColor.fromRGB(80, 80, 140), "left");
        add(secLabel);

        add(new FlxSprite(8, HEADER_H + 22).makeGraphic(SIDEBAR_W - 16, 1, FlxColor.fromRGB(30, 30, 70)));

        sidebarCursor = new FlxSprite(0, 0).makeGraphic(SIDEBAR_W, 34, FlxColor.fromRGB(20, 20, 50));
        sidebarCursor.alpha = 0;
        add(sidebarCursor);

        for (i in 0...SIDEBAR_PANELS.length)
        {
            var iy = HEADER_H + 30 + i * 38;

            var row = new FlxSprite(2, iy).makeGraphic(SIDEBAR_W - 4, 34, FlxColor.fromRGB(14, 14, 30));
            row.alpha = 0;
            add(row);
            sidebarItems.push(row);

            var label = new FlxText(12, iy + 8, SIDEBAR_W - 20, SIDEBAR_PANELS[i]);
            label.setFormat(null, 14, FlxColor.fromRGB(180, 180, 220), "left");
            label.alpha = 0;
            add(label);
            sidebarLabels.push(label);
        }

        updateSidebar();
    }

    // ==================== Main Panel ====================

    function createMainPanel():Void
    {
        panelBG = new FlxSprite(PANEL_X, PANEL_Y).makeGraphic(Std.int(PANEL_W), Std.int(PANEL_H), FlxColor.fromRGB(10, 10, 22));
        panelBG.alpha = 0;
        add(panelBG);

        // Bordas
        var bc = FlxColor.fromRGB(30, 30, 80);
        add(new FlxSprite(PANEL_X,              PANEL_Y).makeGraphic(Std.int(PANEL_W), 2, bc));
        add(new FlxSprite(PANEL_X,              PANEL_Y + PANEL_H - 2).makeGraphic(Std.int(PANEL_W), 2, bc));
        add(new FlxSprite(PANEL_X,              PANEL_Y).makeGraphic(2, Std.int(PANEL_H), bc));
        add(new FlxSprite(PANEL_X + PANEL_W - 2, PANEL_Y).makeGraphic(2, Std.int(PANEL_H), bc));

        panelTitle = new FlxText(PANEL_X + 12, PANEL_Y + 10, PANEL_W - 24, "");
        panelTitle.setFormat(null, 18, FlxColor.WHITE, "left");
        panelTitle.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        panelTitle.alpha = 0;
        add(panelTitle);

        panelDivider = new FlxSprite(PANEL_X + 12, PANEL_Y + 36).makeGraphic(Std.int(PANEL_W - 24), 1, FlxColor.fromRGB(30, 30, 70));
        panelDivider.alpha = 0;
        add(panelDivider);
    }

    // ==================== Field Rows ====================

    function buildFieldRows(fields:Array<{key:String, label:String, value:String}>):Void
    {
        // Limpa campos anteriores
        for (r in fieldRows)   r.exists  = false;
        for (l in fieldLabels) l.exists  = false;
        for (v in fieldValues) v.exists  = false;
        fieldRows   = [];
        fieldLabels = [];
        fieldValues = [];
        fieldKeys   = [];
        fieldRowSelected = 0;
        editingField     = false;

        for (i in 0...fields.length)
        {
            var f  = fields[i];
            var fy = PANEL_Y + 48 + i * 38;

            var row = new FlxSprite(PANEL_X + 8, fy).makeGraphic(Std.int(PANEL_W - 16), 32, FlxColor.fromRGB(14, 14, 30));
            add(row);
            fieldRows.push(row);

            var label = new FlxText(PANEL_X + 16, fy + 8, 220, f.label);
            label.setFormat(null, 13, FlxColor.fromRGB(140, 140, 200), "left");
            add(label);
            fieldLabels.push(label);

            var value = new FlxText(PANEL_X + 240, fy + 8, Std.int(PANEL_W - 260), f.value);
            value.setFormat(null, 13, FlxColor.WHITE, "left");
            add(value);
            fieldValues.push(value);

            fieldKeys.push(f.key);
        }

        updateFieldSelection();
    }

    // ==================== Preview Panel ====================

    function createPreviewPanel():Void
    {
        var px:Float = PANEL_X + PANEL_W + 10;
        var pw:Float = FlxG.width - px - 8;
        var py:Float = PANEL_Y;
        var ph:Float = PANEL_H;

        previewBG = new FlxSprite(px, py).makeGraphic(Std.int(pw), Std.int(ph), FlxColor.fromRGB(8, 8, 18));
        previewBG.alpha = 0;
        add(previewBG);

        var bc = FlxColor.fromRGB(25, 25, 70);
        add(new FlxSprite(px, py).makeGraphic(Std.int(pw), 2, bc));
        add(new FlxSprite(px, py + ph - 2).makeGraphic(Std.int(pw), 2, bc));
        add(new FlxSprite(px, py).makeGraphic(2, Std.int(ph), bc));
        add(new FlxSprite(px + pw - 2, py).makeGraphic(2, Std.int(ph), bc));

        previewTitle = new FlxText(px + 8, py + 8, Std.int(pw - 16), "PREVIEW");
        previewTitle.setFormat(null, 11, FlxColor.fromRGB(80, 80, 140), "left");
        previewTitle.alpha = 0;
        add(previewTitle);

        add(new FlxSprite(px + 8, py + 24).makeGraphic(Std.int(pw - 16), 1, FlxColor.fromRGB(20, 20, 50)));

        for (i in 0...16)
        {
            var line = new FlxText(px + 8, py + 30 + i * 22, Std.int(pw - 16), "");
            line.setFormat(null, 12, FlxColor.fromRGB(160, 160, 200), "left");
            line.alpha = 0;
            add(line);
            previewLines.push(line);
        }
    }

    // ==================== Footer ====================

    function createFooter():Void
    {
        var fy = FlxG.height - FOOTER_H;
        footerBG = new FlxSprite(0, fy).makeGraphic(FlxG.width, FOOTER_H, FlxColor.fromRGB(8, 8, 20));
        add(footerBG);

        add(new FlxSprite(0, fy).makeGraphic(FlxG.width, 1, FlxColor.fromRGB(30, 30, 80)));

        footerHint = new FlxText(8, fy + 8, 800,
            "↑↓ Panel   Tab Field   Enter Edit   Esc Cancel/Back   Ctrl+S Save   Ctrl+L Load   Ctrl+N New");
        footerHint.setFormat(null, 11, FlxColor.fromRGBFloat(1, 1, 1, 0.45), "left");
        add(footerHint);

        footerStatus = new FlxText(FlxG.width - 250, fy + 8, 242, "Ready");
        footerStatus.setFormat(null, 11, FlxColor.fromRGB(100, 200, 120), "right");
        add(footerStatus);
    }

    // ==================== Notification ====================

    function createNotification():Void
    {
        notifBG = new FlxSprite(FlxG.width / 2 - 200, 70).makeGraphic(400, 36, FlxColor.fromRGB(20, 60, 20));
        notifBG.alpha = 0;
        add(notifBG);

        notifText = new FlxText(FlxG.width / 2 - 200, 78, 400, "");
        notifText.setFormat(null, 14, FlxColor.fromRGB(100, 255, 120), "center");
        notifText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 1);
        notifText.alpha = 0;
        add(notifText);
    }

    // ==================== Edit Cursor ====================

    function createEditCursor():Void
    {
        editCursor = new FlxSprite(0, 0).makeGraphic(2, 16, FlxColor.WHITE);
        editCursor.alpha = 0;
        add(editCursor);
    }

    // ==================== Fade In ====================

    function fadeIn():Void
    {
        FlxTween.tween(panelBG,      {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.1});
        FlxTween.tween(panelTitle,   {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.15});
        FlxTween.tween(panelDivider, {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.2});
        FlxTween.tween(previewBG,    {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.1});
        FlxTween.tween(previewTitle, {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.2});

        for (line in previewLines)
            FlxTween.tween(line, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.25});

        for (i in 0...sidebarItems.length)
        {
            FlxTween.tween(sidebarItems[i],  {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.1 + i * 0.05});
            FlxTween.tween(sidebarLabels[i], {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.1 + i * 0.05});
        }
        FlxTween.tween(sidebarCursor, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.2});
    }

    // ==================== Load Stage ====================

    function loadStage(path:String):Void
    {
        var data = JsonHelper.load(path);
        if (data == null)
        {
            notify("Failed to load: " + path, FlxColor.fromRGB(255, 80, 80));
            setStatus("Load failed", FlxColor.fromRGB(255, 80, 80));
            return;
        }

        stageData = data;
        stagePath = path;
        isDirty   = false;

        var parts = path.split("/");
        headerFile.text    = parts[parts.length - 1];
        dirtyIndicator.text = "";

        refreshPanel();
        notify("Loaded: " + parts[parts.length - 1], FlxColor.fromRGB(100, 255, 120));
        setStatus("Loaded", FlxColor.fromRGB(100, 255, 120));
    }

    function newStage():Void
    {
        stageData = {
            id:       "new_stage",
            name:     "New Stage",
            subtitle: "",
            difficulty: "easy",
            order:    1
        };
        stagePath  = "";
        isDirty    = true;
        headerFile.text    = "Untitled";
        dirtyIndicator.text = "● UNSAVED";

        refreshPanel();
        notify("New stage created.", FlxColor.fromRGB(100, 200, 255));
        setStatus("New stage", FlxColor.fromRGB(100, 200, 255));
    }

    // ==================== Refresh Panel ====================

    function refreshPanel():Void
    {
        switch (currentPanel)
        {
            case PANEL_INFO:       showInfoPanel();
            case PANEL_BACKGROUND: showBackgroundPanel();
            case PANEL_WAVES:      showWavesPanel();
            case PANEL_MIDBOSS:    showMidBossPanel();
            case PANEL_BOSS:       showBossPanel();
            case PANEL_SCORING:    showScoringPanel();
        }
        refreshPreview();
    }

    // ==================== Info Panel ====================

    function showInfoPanel():Void
    {
        panelTitle.text = "📋  Stage Info";

        if (stageData == null) { buildFieldRows([]); return; }

        buildFieldRows([
            { key: "id",          label: "ID",          value: JsonHelper.getString(stageData, "id",         "???") },
            { key: "name",        label: "Name",        value: JsonHelper.getString(stageData, "name",       "???") },
            { key: "subtitle",    label: "Subtitle",    value: JsonHelper.getString(stageData, "subtitle",   "") },
            { key: "difficulty",  label: "Difficulty",  value: JsonHelper.getString(stageData, "difficulty", "easy") },
            { key: "order",       label: "Order",       value: Std.string(JsonHelper.getInt(stageData, "order", 1)) },
            { key: "bgm",         label: "BGM",         value: JsonHelper.getString(JsonHelper.get(stageData, "music"), "bgm", "") },
            { key: "bossTheme",   label: "Boss Theme",  value: JsonHelper.getString(JsonHelper.get(stageData, "music"), "bossTheme", "") },
            { key: "lore_intro",  label: "Lore Intro",  value: JsonHelper.getString(JsonHelper.get(stageData, "lore"), "intro", "") }
        ]);
    }

    // ==================== Background Panel ====================

    function showBackgroundPanel():Void
    {
        panelTitle.text = "🌌  Background";

        if (stageData == null) { buildFieldRows([]); return; }

        var bg = JsonHelper.get(stageData, "background");
        buildFieldRows([
            { key: "bg_type",      label: "Type",       value: JsonHelper.getString(bg, "type",      "scrolling_stars") },
            { key: "bg_fogColor",  label: "Fog Color",  value: JsonHelper.getString(bg, "fogColor",  "#0A0A1E") },
            { key: "bg_bgColor",   label: "BG Color",   value: JsonHelper.getString(bg, "bgColor",   "#020212") },
            { key: "star_l1_count",label: "Stars L1",   value: "100" },
            { key: "star_l1_speed",label: "Speed L1",   value: "15" },
            { key: "star_l2_count",label: "Stars L2",   value: "60" },
            { key: "star_l2_speed",label: "Speed L2",   value: "35" },
            { key: "star_l3_count",label: "Stars L3",   value: "30" },
            { key: "star_l3_speed",label: "Speed L3",   value: "65" }
        ]);
    }

    // ==================== Waves Panel ====================

    function showWavesPanel():Void
    {
        panelTitle.text = "👾  Enemy Waves";

        if (stageData == null) { buildFieldRows([]); return; }

        var waves = JsonHelper.getArray(stageData, "waves");
        var fields = [];

        for (i in 0...waves.length)
        {
            var w = waves[i];
            var enemies = JsonHelper.getArray(w, "enemies");
            fields.push({ key: 'wave_${i}_id',      label: 'Wave ${i+1} ID',      value: JsonHelper.getString(w, "id", "") });
            fields.push({ key: 'wave_${i}_trigger',  label: 'Wave ${i+1} Trigger', value: Std.string(JsonHelper.getFloat(w, "triggerTime", 0)) + "s" });
            fields.push({ key: 'wave_${i}_enemies',  label: 'Wave ${i+1} Enemies', value: enemies.length + " enemy type(s)" });
        }

        if (fields.length == 0)
            fields.push({ key: "waves_empty", label: "No waves defined", value: "Add waves in the JSON." });

        buildFieldRows(fields);
    }

    // ==================== Mid-Boss Panel ====================

    function showMidBossPanel():Void
    {
        panelTitle.text = "⚡  Mid-Boss";

        if (stageData == null) { buildFieldRows([]); return; }

        var mb = JsonHelper.get(stageData, "midBoss");
        if (mb == null)
        {
            buildFieldRows([{ key: "mb_none", label: "No mid-boss defined", value: "" }]);
            return;
        }

        buildFieldRows([
            { key: "mb_id",          label: "ID",           value: JsonHelper.getString(mb, "id",          "") },
            { key: "mb_name",        label: "Name",         value: JsonHelper.getString(mb, "name",        "") },
            { key: "mb_hp",          label: "HP",           value: Std.string(JsonHelper.getInt(mb, "hp",  300)) },
            { key: "mb_score",       label: "Score",        value: Std.string(JsonHelper.getInt(mb, "score", 5000)) },
            { key: "mb_trigger",     label: "Trigger Time", value: Std.string(JsonHelper.getFloat(mb, "triggerTime", 0)) + "s" },
            { key: "mb_spawnX",      label: "Spawn X",      value: Std.string(JsonHelper.getInt(mb, "spawnX", 0)) },
            { key: "mb_spawnY",      label: "Spawn Y",      value: Std.string(JsonHelper.getInt(mb, "spawnY", -40)) },
            { key: "mb_movePattern", label: "Move Pattern", value: JsonHelper.getString(mb, "movePattern", "") },
            { key: "mb_phases",      label: "Phases",       value: Std.string(JsonHelper.getArray(mb, "phases").length) }
        ]);
    }

    // ==================== Boss Panel ====================

    function showBossPanel():Void
    {
        panelTitle.text = "💀  Boss";

        if (stageData == null) { buildFieldRows([]); return; }

        var boss = JsonHelper.get(stageData, "boss");
        if (boss == null)
        {
            buildFieldRows([{ key: "boss_none", label: "No boss defined", value: "" }]);
            return;
        }

        buildFieldRows([
            { key: "boss_id",        label: "ID",           value: JsonHelper.getString(boss, "id",    "") },
            { key: "boss_name",      label: "Name",         value: JsonHelper.getString(boss, "name",  "") },
            { key: "boss_title",     label: "Title",        value: JsonHelper.getString(boss, "title", "") },
            { key: "boss_hp",        label: "HP",           value: Std.string(JsonHelper.getInt(boss, "hp", 1000)) },
            { key: "boss_score",     label: "Clear Score",  value: Std.string(JsonHelper.getInt(boss, "score", 50000)) },
            { key: "boss_trigger",   label: "Trigger Time", value: Std.string(JsonHelper.getFloat(boss, "triggerTime", 60)) + "s" },
            { key: "boss_spawnX",    label: "Spawn X",      value: Std.string(JsonHelper.getInt(boss, "spawnX", 224)) },
            { key: "boss_targetY",   label: "Target Y",     value: Std.string(JsonHelper.getInt(boss, "targetY", 96)) },
            { key: "boss_color",     label: "Color",        value: JsonHelper.getString(boss, "color", "#FF3C50") },
            { key: "boss_phases",    label: "Phases",       value: Std.string(JsonHelper.getArray(boss, "phases").length) },
            { key: "boss_portrait",  label: "Portrait",     value: JsonHelper.getString(boss, "portrait", "") }
        ]);
    }

    // ==================== Scoring Panel ====================

    function showScoringPanel():Void
    {
        panelTitle.text = "⭐  Scoring";

        if (stageData == null) { buildFieldRows([]); return; }

        var sc = JsonHelper.get(stageData, "scoring");
        buildFieldRows([
            { key: "sc_graze",        label: "Graze",          value: Std.string(JsonHelper.getInt(sc, "graze",          3)) },
            { key: "sc_enemyKill",    label: "Enemy Kill",     value: Std.string(JsonHelper.getInt(sc, "enemyKill",      100)) },
            { key: "sc_midBoss",      label: "Mid-Boss Clear", value: Std.string(JsonHelper.getInt(sc, "midBossClear",   5000)) },
            { key: "sc_bossClear",    label: "Boss Clear",     value: Std.string(JsonHelper.getInt(sc, "bossClear",      50000)) },
            { key: "sc_livesBonus",   label: "Lives Bonus",    value: Std.string(JsonHelper.getInt(sc, "livesRemaining", 10000)) },
            { key: "sc_bombsBonus",   label: "Bombs Bonus",    value: Std.string(JsonHelper.getInt(sc, "bombsRemaining", 3000)) },
            { key: "sc_noMiss",       label: "No Miss Bonus",  value: Std.string(JsonHelper.getInt(sc, "noMiss",         20000)) },
            { key: "sc_noBomb",       label: "No Bomb Bonus",  value: Std.string(JsonHelper.getInt(sc, "noBomb",         10000)) }
        ]);
    }

    // ==================== Preview ====================

    function refreshPreview():Void
    {
        for (line in previewLines) line.text = "";
        if (stageData == null) return;

        var lines:Array<String> = [];

        lines.push("Stage: "     + JsonHelper.getString(stageData, "name", "?"));
        lines.push("ID: "        + JsonHelper.getString(stageData, "id", "?"));
        lines.push("Difficulty: "+ JsonHelper.getString(stageData, "difficulty", "?"));
        lines.push("Order: "     + JsonHelper.getInt(stageData, "order", 1));
        lines.push("");

        var waves  = JsonHelper.getArray(stageData, "waves");
        var boss   = JsonHelper.get(stageData, "boss");
        var midBoss = JsonHelper.get(stageData, "midBoss");

        lines.push("Waves: " + waves.length);
        if (midBoss != null)
            lines.push("Mid-Boss: " + JsonHelper.getString(midBoss, "name", "?"));
        if (boss != null)
        {
            lines.push("Boss: " + JsonHelper.getString(boss, "name", "?"));
            lines.push("  HP: " + JsonHelper.getInt(boss, "hp", 0));
            lines.push("  Phases: " + JsonHelper.getArray(boss, "phases").length);
        }
        lines.push("");

        var music = JsonHelper.get(stageData, "music");
        if (music != null)
            lines.push("BGM: " + JsonHelper.getString(music, "bgm", "none"));

        for (i in 0...Std.int(Math.min(lines.length, previewLines.length)))
            previewLines[i].text = lines[i];
    }

    // ==================== Update ====================

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        inputCooldown -= elapsed;

        if (notifTimer > 0)
        {
            notifTimer -= elapsed;
            if (notifTimer <= 0)
                FlxTween.tween(notifBG,  {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        }

        if (editingField)
        {
            updateEditMode(elapsed);
            return;
        }

        handleInput(elapsed);

        #if (debug && desktop)
        if (FlxG.keys.justPressed.F2)
            debugDisplay.toggle();
        #end
    }

    // ==================== Input ====================

    #if desktop
    function handleInput(elapsed:Float):Void
    {
        // Ctrl+S — Save
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
        {
            saveStage();
            return;
        }

        // Ctrl+L — Load
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.L)
        {
            loadStage(stagePath.length > 0 ? stagePath : "data/stages/stage_01.json");
            return;
        }

        // Ctrl+N — New
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.N)
        {
            newStage();
            return;
        }

        // Esc — Back
        if (FlxG.keys.justPressed.ESCAPE)
        {
            goBack();
            return;
        }

        // Tab — Alterna entre sidebar e campos
        if (FlxG.keys.justPressed.TAB)
        {
            if (fieldRows.length > 0)
            {
                fieldRowSelected = (fieldRowSelected + 1) % fieldRows.length;
                updateFieldSelection();
            }
            return;
        }

        // ↑↓ na sidebar
        if (FlxG.keys.justPressed.UP || (FlxG.keys.pressed.UP && inputCooldown <= 0))
        {
            changeSidebarSelection(-1);
            inputCooldown = INPUT_COOLDOWN;
        }
        else if (FlxG.keys.justPressed.DOWN || (FlxG.keys.pressed.DOWN && inputCooldown <= 0))
        {
            changeSidebarSelection(1);
            inputCooldown = INPUT_COOLDOWN;
        }

        // Enter — Edita campo selecionado
        if (FlxG.keys.justPressed.ENTER && fieldRows.length > 0)
            startEditing();
    }
    #else
    function handleInput(elapsed:Float):Void {}
    #end

    // ==================== Edit Mode ====================

    #if desktop
    function updateEditMode(elapsed:Float):Void
    {
        editCursorTimer += elapsed;
        editCursor.visible = Math.sin(editCursorTimer * 8) > 0;

        // Backspace
        if (FlxG.keys.justPressed.BACKSPACE && editBuffer.length > 0)
        {
            editBuffer = editBuffer.substr(0, editBuffer.length - 1);
            updateEditDisplay();
        }

        // Esc — Cancela
        if (FlxG.keys.justPressed.ESCAPE)
        {
            stopEditing(false);
            return;
        }

        // Enter — Confirma
        if (FlxG.keys.justPressed.ENTER)
        {
            stopEditing(true);
            return;
        }

        // Captura teclas
        var chars = "abcdefghijklmnopqrstuvwxyz0123456789_-./# ";
        var shift  = FlxG.keys.pressed.SHIFT;

        for (c in chars.split(""))
        {
            var key = c.toUpperCase();
            if (Reflect.field(FlxG.keys.justPressed, key) == true)
            {
                var ch = shift ? c.toUpperCase() : c;
                editBuffer += ch;
                updateEditDisplay();
                break;
            }
        }
    }
    #end

    function startEditing():Void
    {
        if (fieldRows.length == 0 || fieldRowSelected >= fieldValues.length) return;

        editingField = true;
        editBuffer   = fieldValues[fieldRowSelected].text;
        editCursorTimer = 0;

        fieldValues[fieldRowSelected].color = FlxColor.YELLOW;
        editCursor.alpha = 1;
        updateEditDisplay();

        setStatus("Editing — Enter to confirm, Esc to cancel", FlxColor.YELLOW);
    }

    function stopEditing(confirm:Bool):Void
    {
        editingField = false;
        editCursor.alpha = 0;

        if (confirm)
        {
            fieldValues[fieldRowSelected].text = editBuffer;
            applyFieldEdit(fieldKeys[fieldRowSelected], editBuffer);
            isDirty = true;
            dirtyIndicator.text = "● UNSAVED";
            notify("Field updated.", FlxColor.fromRGB(100, 255, 120));
        }

        fieldValues[fieldRowSelected].color = FlxColor.WHITE;
        updateFieldSelection();
        setStatus("Ready", FlxColor.fromRGB(100, 200, 120));
    }

    function updateEditDisplay():Void
    {
        if (fieldRowSelected >= fieldValues.length) return;
        fieldValues[fieldRowSelected].text = editBuffer + "|";

        var fv = fieldValues[fieldRowSelected];
        editCursor.x = fv.x + fv.textWidth + 2;
        editCursor.y = fv.y + 2;
    }

    function applyFieldEdit(key:String, value:String):Void
    {
        if (stageData == null) return;

        // Campos simples de info
        switch (key)
        {
            case "id":         Reflect.setField(stageData, "id",         value);
            case "name":       Reflect.setField(stageData, "name",       value);
            case "subtitle":   Reflect.setField(stageData, "subtitle",   value);
            case "difficulty": Reflect.setField(stageData, "difficulty", value);
            case "order":      Reflect.setField(stageData, "order",      Std.parseInt(value) ?? 1);
            default:           trace('[StageEditor] Unhandled field: $key = $value');
        }

        refreshPreview();
    }

    // ==================== Save ====================

    function saveStage():Void
    {
        if (stageData == null)
        {
            notify("Nothing to save.", FlxColor.YELLOW);
            return;
        }

        // No ambiente de build, salvar em arquivo não é trivial
        // Aqui exibimos o JSON serializado no trace para copiar
        var json = haxe.Json.stringify(stageData, null, "  ");
        trace("[StageEditor] Save output:\n" + json);

        isDirty = false;
        dirtyIndicator.text = "";
        notify("Saved to trace output!", FlxColor.fromRGB(100, 255, 120));
        setStatus("Saved", FlxColor.fromRGB(100, 255, 120));
    }

    // ==================== Sidebar ====================

    function changeSidebarSelection(dir:Int):Void
    {
        sidebarSelected = (sidebarSelected + dir + SIDEBAR_PANELS.length) % SIDEBAR_PANELS.length;
        currentPanel    = panelFromIndex(sidebarSelected);
        updateSidebar();
        refreshPanel();
    }

    function panelFromIndex(i:Int):EditorPanel
    {
        return switch (i)
        {
            case 0: PANEL_INFO;
            case 1: PANEL_BACKGROUND;
            case 2: PANEL_WAVES;
            case 3: PANEL_MIDBOSS;
            case 4: PANEL_BOSS;
            case 5: PANEL_SCORING;
            default: PANEL_INFO;
        };
    }

    function updateSidebar():Void
    {
        for (i in 0...sidebarLabels.length)
        {
            var isSelected = i == sidebarSelected;
            sidebarLabels[i].color = isSelected ? FlxColor.YELLOW : FlxColor.fromRGB(180, 180, 220);
            sidebarLabels[i].size  = isSelected ? 15 : 14;
        }

        if (sidebarSelected < sidebarItems.length)
        {
            sidebarCursor.y = sidebarItems[sidebarSelected].y;
            sidebarCursor.alpha = 0.6 + Math.sin(haxe.Timer.stamp() * 4) * 0.4;
        }
    }

    // ==================== Field Selection ====================

    function updateFieldSelection():Void
    {
        for (i in 0...fieldRows.length)
        {
            var isSelected = i == fieldRowSelected;
            fieldRows[i].color   = isSelected ? FlxColor.fromRGB(20, 20, 50) : FlxColor.fromRGB(14, 14, 30);
            fieldLabels[i].color = isSelected ? FlxColor.CYAN : FlxColor.fromRGB(140, 140, 200);
        }
    }

    // ==================== Helpers ====================

    function notify(msg:String, col:FlxColor):Void
    {
        notifText.text  = msg;
        notifText.color = col;
        notifBG.color   = FlxColor.fromRGBFloat(col.redFloat * 0.1, col.greenFloat * 0.1, col.blueFloat * 0.1);

        FlxTween.cancelTweensOf(notifBG);
        FlxTween.cancelTweensOf(notifText);
        notifBG.alpha   = 0.9;
        notifText.alpha = 1;
        notifTimer = 2.5;
    }

    function setStatus(msg:String, col:FlxColor):Void
    {
        footerStatus.text  = msg;
        footerStatus.color = col;
    }

    function goBack():Void
    {
        if (isDirty)
        {
            notify("Unsaved changes! Press Esc again to discard.", FlxColor.YELLOW);
            isDirty = false; // Segunda vez vai
            return;
        }
        FlxG.switchState(menus.debug.EditorState.new);
    }
}