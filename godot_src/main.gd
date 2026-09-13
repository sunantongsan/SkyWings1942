extends Node2D

const WORLD_SIZE := Vector2(2600, 1800)
const BLUE := Color("36c9ff")
const GOLD := Color("ffb23b")
const PANEL := Color(0.025, 0.075, 0.13, 0.94)

const BUILDING_IDS := ["galactic_core","fusion_reactor","metal_extractor","oil_processor","crystal_mine","resource_vault","star_hangar","research_lab","laser_tower","shield_generator"]
const BUILDING_NAMES := ["Galactic Core","Fusion Reactor","Metal Extractor","Oil Processor","Crystal Mine","Resource Vault","Star Hangar","Research Lab","Laser Tower","Shield Generator"]
const UNIT_IDS := ["fighter","interceptor","bomber","heavy_fighter","stealth_fighter","gunship","missile_cruiser","destroyer","battle_cruiser","carrier","battle_tank","siege_tank","artillery","rocket_launcher","mech_warrior","sniper_unit","shield_drone","repair_drone","assault_soldier","elite_commander"]
const MAP_IDS := ["terra","volcanis","cryon","desertus","noctis","aquara","mechanis","toxicus","nebularis","asteroid_belt","ruins","orbit_station","moon_base","gas_giant","wormhole"]

var building_tex: Array[Texture2D] = []
var unit_tex: Array[Texture2D] = []
var map_tex: Array[Texture2D] = []
var buildings: Array[Dictionary] = []
var enemy_buildings: Array[Dictionary] = []
var army: Array[Dictionary] = []

var terrain: Sprite2D
var world: Node2D
var battle_layer: Node2D
var camera: Camera2D
var ui: CanvasLayer
var galaxy: Control
var build_panel: PanelContainer
var info_panel: PanelContainer
var info_label: Label
var resources_label: Label
var splash: Control

var mode := "splash"
var selected_building := -1
var build_type := -1
var target_map := 0
var dragging := false
var last_drag := Vector2.ZERO
var touches := {}
var pinch_dist := 0.0

var credits := 125600.0
var metal := 230400.0
var oil := 98200.0
var crystal := 56100.0
var battle_time := 0.0
var battle_damage := 0.0

func _ready() -> void:
    _load_assets()
    _make_world()
    _make_ui()
    _seed_base()
    _make_splash()

func _load_assets() -> void:
    for id in BUILDING_IDS:
        building_tex.append(load("res://assets/buildings/%s.svg" % id))
    for id in UNIT_IDS:
        unit_tex.append(load("res://assets/units/%s.svg" % id))
    for id in MAP_IDS:
        map_tex.append(load("res://assets/maps/%s.svg" % id))

func _make_world() -> void:
    terrain = Sprite2D.new()
    terrain.texture = map_tex[0]
    terrain.position = WORLD_SIZE * 0.5
    terrain.scale = Vector2(WORLD_SIZE.x / 1024.0, WORLD_SIZE.y / 1024.0)
    terrain.z_index = -1000
    add_child(terrain)
    world = Node2D.new()
    add_child(world)
    camera = Camera2D.new()
    camera.position = WORLD_SIZE * 0.5
    camera.zoom = Vector2(0.72,0.72)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 8.0
    add_child(camera)

func _make_ui() -> void:
    ui = CanvasLayer.new()
    add_child(ui)
    var top := PanelContainer.new()
    top.position = Vector2(20,16)
    top.size = Vector2(1880,82)
    top.add_theme_stylebox_override("panel",_panel(Color(0.02,0.06,0.11,0.94),18,BLUE,1))
    ui.add_child(top)
    var h:=HBoxContainer.new()
    h.add_theme_constant_override("separation",22)
    top.add_child(h)
    var title:=Label.new()
    title.text="  GALAXY 1942 • HOME PLANET"
    title.add_theme_font_size_override("font_size",26)
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    h.add_child(title)
    resources_label=Label.new()
    resources_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
    resources_label.add_theme_font_size_override("font_size",16)
    resources_label.custom_minimum_size=Vector2(900,0)
    h.add_child(resources_label)
    _update_resources()
    var left:=VBoxContainer.new()
    left.position=Vector2(22,135)
    left.add_theme_constant_override("separation",12)
    ui.add_child(left)
    left.add_child(_btn("BUILD",func(): build_panel.visible=not build_panel.visible,Vector2(165,58)))
    left.add_child(_btn("GALAXY",func(): _show_galaxy(),Vector2(165,58)))
    left.add_child(_btn("CENTER",func(): _center_camera(),Vector2(165,58)))
    left.add_child(_btn("ZOOM +",func(): _zoom(1.15),Vector2(165,50)))
    left.add_child(_btn("ZOOM -",func(): _zoom(0.87),Vector2(165,50)))

    build_panel=PanelContainer.new()
    build_panel.position=Vector2(215,690)
    build_panel.size=Vector2(1100,360)
    build_panel.visible=false
    build_panel.add_theme_stylebox_override("panel",_panel(PANEL,20,BLUE,2))
    ui.add_child(build_panel)
    var grid:=GridContainer.new()
    grid.columns=5
    grid.add_theme_constant_override("h_separation",10)
    grid.add_theme_constant_override("v_separation",10)
    build_panel.add_child(grid)
    for i in BUILDING_IDS.size():
        var b:=Button.new()
        b.custom_minimum_size=Vector2(205,160)
        b.text="%s\nBUILD"%BUILDING_NAMES[i]
        b.icon=building_tex[i]
        b.expand_icon=true
        b.icon_max_width=92
        b.add_theme_font_size_override("font_size",13)
        b.pressed.connect(func(idx=i): _begin_build(idx))
        grid.add_child(b)

    info_panel=PanelContainer.new()
    info_panel.position=Vector2(1370,755)
    info_panel.size=Vector2(500,260)
    info_panel.visible=false
    info_panel.add_theme_stylebox_override("panel",_panel(PANEL,18,GOLD,2))
    ui.add_child(info_panel)
    var v:=VBoxContainer.new()
    info_panel.add_child(v)
    info_label=Label.new()
    info_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    info_label.add_theme_font_size_override("font_size",18)
    v.add_child(info_label)
    v.add_child(_btn("UPGRADE",func(): _upgrade_selected(),Vector2(0,56)))

func _make_splash() -> void:
    splash=Control.new()
    splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash.mouse_filter=Control.MOUSE_FILTER_STOP
    ui.add_child(splash)
    var bg:=TextureRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.texture=load("res://assets/ui/splash.svg")
    bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    splash.add_child(bg)
    var play:=_btn("ENTER YOUR PLANET",func(): mode="base";splash.queue_free(),Vector2(480,90))
    play.position=Vector2(1260,835)
    play.add_theme_font_size_override("font_size",24)
    splash.add_child(play)

func _seed_base() -> void:
    var pos=[Vector2(1300,820),Vector2(1010,650),Vector2(820,930),Vector2(1690,920),Vector2(1790,620),Vector2(1110,1110),Vector2(1390,1160),Vector2(1490,520),Vector2(700,620),Vector2(1940,820)]
    for i in BUILDING_IDS.size():
        _add_building(i,pos[i],1 if i>4 else 2)

func _add_building(type:int,pos:Vector2,level:int=1) -> void:
    var s:=Sprite2D.new()
    s.texture=building_tex[type]
    s.position=pos
    s.scale=Vector2.ONE*(0.72 if type==0 else 0.58)
    s.z_index=int(pos.y)
    world.add_child(s)
    buildings.append({"type":type,"level":level,"sprite":s,"pos":pos})

func _process(delta:float) -> void:
    if mode=="base":
        credits+=delta*3.0
        for b in buildings:
            if b.type==2:
                metal+=delta*2.0*b.level
            elif b.type==3:
                oil+=delta*1.7*b.level
            elif b.type==4:
                crystal+=delta*0.7*b.level
        _update_resources()
    elif mode=="battle":
        _battle_tick(delta)

func _update_resources() -> void:
    if resources_label:
        resources_label.text="CREDITS %s   METAL %s   OIL %s   CRYSTAL %s"%[_fmt(credits),_fmt(metal),_fmt(oil),_fmt(crystal)]

func _fmt(v:float)->String:
    if v>=1000000:
        return "%.1fM"%(v/1000000.0)
    if v>=1000:
        return "%.1fK"%(v/1000.0)
    return "%d"%int(v)

func _begin_build(t:int)->void:
    build_type=t
    build_panel.visible=false

func _place_building(p:Vector2)->void:
    if build_type<0:
        return
    if p.x<350 or p.x>WORLD_SIZE.x-250 or p.y<250 or p.y>WORLD_SIZE.y-180:
        return
    for b in buildings:
        if b.pos.distance_to(p)<170:
            return
    var cost=500+build_type*140
    if metal<cost:
        return
    metal-=cost
    _add_building(build_type,p,1)
    build_type=-1
    _update_resources()

func _select_building(p:Vector2)->void:
    selected_building=-1
    for i in buildings.size():
        if buildings[i].pos.distance_to(p)<130:
            selected_building=i
            break
    if selected_building>=0:
        var b=buildings[selected_building]
        info_label.text="%s\nLEVEL %d\nUpgrade cost: %d Metal"%[BUILDING_NAMES[b.type],b.level,500+b.level*350]
        info_panel.visible=true
    else:
        info_panel.visible=false

func _upgrade_selected()->void:
    if selected_building<0:
        return
    var b=buildings[selected_building]
    var cost=500+b.level*350
    if metal<cost:
        return
    metal-=cost
    b.level+=1
    b.sprite.scale*=1.035
    buildings[selected_building]=b
    _select_building(b.pos)
    _update_resources()

func _show_galaxy()->void:
    mode="galaxy"
    world.visible=false
    info_panel.visible=false
    build_panel.visible=false
    if galaxy==null:
        galaxy=_make_galaxy()
    galaxy.visible=true

func _make_galaxy()->Control:
    var root:=Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)
    var bg:=TextureRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.texture=load("res://assets/ui/splash.svg")
    bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.modulate=Color(0.35,0.45,0.75,0.9)
    root.add_child(bg)
    var shade:=ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color=Color(0,0.01,0.04,0.66)
    root.add_child(shade)
    var title:=Label.new()
    title.position=Vector2(720,45)
    title.text="GALAXY MAP • 15 WORLDS"
    title.add_theme_font_size_override("font_size",34)
    root.add_child(title)
    var pts=[Vector2(260,200),Vector2(520,180),Vector2(790,235),Vector2(1060,180),Vector2(1340,235),Vector2(1510,390),Vector2(1260,470),Vector2(980,430),Vector2(700,450),Vector2(410,470),Vector2(350,690),Vector2(650,710),Vector2(950,700),Vector2(1240,700),Vector2(1510,680)]
    for i in pts.size():
        var b:=Button.new()
        b.position=pts[i]
        b.size=Vector2(175,100)
        b.text="%s\nLV.%d"%[MAP_IDS[i].replace("_"," ").to_upper(),5+i*2]
        b.icon=map_tex[i]
        b.expand_icon=true
        b.icon_max_width=68
        b.add_theme_font_size_override("font_size",11)
        b.pressed.connect(func(idx=i):_start_battle(idx))
        root.add_child(b)
    var back:=_btn("RETURN HOME",func():_return_home(),Vector2(230,60))
    back.position=Vector2(45,970)
    root.add_child(back)
    return root

func _return_home()->void:
    mode="base"
    world.visible=true
    if galaxy:
        galaxy.visible=false
    if battle_layer:
        battle_layer.queue_free()
        battle_layer=null
    terrain.texture=map_tex[0]
    _center_camera()

func _start_battle(map_index:int)->void:
    target_map=map_index
    mode="battle"
    if galaxy:
        galaxy.visible=false
    world.visible=false
    terrain.texture=map_tex[target_map]
    battle_layer=Node2D.new()
    add_child(battle_layer)
    enemy_buildings.clear()
    army.clear()
    battle_time=0
    battle_damage=0
    var ep=[Vector2(1300,560),Vector2(960,700),Vector2(1640,700),Vector2(1100,920),Vector2(1510,920),Vector2(790,1020),Vector2(1810,1020)]
    var et=[0,8,8,9,6,2,3]
    for i in ep.size():
        var s:=Sprite2D.new()
        s.texture=building_tex[et[i]]
        s.position=ep[i]
        s.scale=Vector2.ONE*(0.72 if i==0 else 0.52)
        s.z_index=int(s.position.y)
        battle_layer.add_child(s)
        enemy_buildings.append({"node":s,"pos":ep[i],"hp":500.0 if i==0 else 260.0,"max":500.0 if i==0 else 260.0})
    var types=[0,2,5,6,16]
    for i in 25:
        var t=types[i%types.size()]
        var s:=Sprite2D.new()
        s.texture=unit_tex[t]
        s.position=Vector2(650+i*48,1450+(i%5)*45)
        s.scale=Vector2.ONE*.42
        s.z_index=int(s.position.y)
        battle_layer.add_child(s)
        army.append({"node":s,"damage":7.0+float(i%5)})
    camera.position=Vector2(1300,950)
    camera.zoom=Vector2(.70,.70)

func _battle_tick(delta:float)->void:
    battle_time+=delta
    var alive=[]
    var total=0.0
    var hp=0.0
    for e in enemy_buildings:
        total+=e.max
        if e.hp>0:
            hp+=e.hp
            alive.append(e)
    battle_damage=100.0*(1.0-hp/max(1.0,total))
    if alive.is_empty() or battle_time>75.0:
        if alive.is_empty():
            credits+=9000
            metal+=5000
            oil+=3000
            crystal+=1200
        _return_home()
        _update_resources()
        return
    for u in army:
        var n:Sprite2D=u.node
        var target=alive[0]
        var best=n.position.distance_to(target.pos)
        for e in alive:
            var d=n.position.distance_to(e.pos)
            if d<best:
                best=d
                target=e
        if best>90:
            n.position=n.position.move_toward(target.pos,140.0*delta)
            n.z_index=int(n.position.y)
        else:
            target.hp-=u.damage*delta*5.0
            if target.hp<=0 and is_instance_valid(target.node):
                var tw=create_tween()
                tw.tween_property(target.node,"modulate:a",0.0,.35)
                tw.tween_property(target.node,"scale",Vector2.ZERO,.25)

func _center_camera()->void:
    camera.position=WORLD_SIZE*.5
    camera.zoom=Vector2(.72,.72)

func _zoom(m:float)->void:
    var z=clamp(camera.zoom.x*m,.45,1.35)
    camera.zoom=Vector2(z,z)

func _unhandled_input(e:InputEvent)->void:
    if mode!="base":
        return
    if e is InputEventMouseButton:
        if e.button_index==MOUSE_BUTTON_WHEEL_UP and e.pressed:
            _zoom(1.1)
            return
        if e.button_index==MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
            _zoom(.9)
            return
        if e.button_index==MOUSE_BUTTON_LEFT:
            dragging=e.pressed
            last_drag=e.position
            if not e.pressed:
                var wp=get_viewport().get_canvas_transform().affine_inverse()*e.position
                if build_type>=0:
                    _place_building(wp)
                else:
                    _select_building(wp)
    elif e is InputEventMouseMotion and dragging:
        camera.position-=e.relative/camera.zoom.x
    elif e is InputEventScreenTouch:
        if e.pressed:
            touches[e.index]=e.position
        else:
            var single=touches.size()==1
            touches.erase(e.index)
            pinch_dist=0
            if single:
                var wp=get_viewport().get_canvas_transform().affine_inverse()*e.position
                if build_type>=0:
                    _place_building(wp)
                else:
                    _select_building(wp)
    elif e is InputEventScreenDrag:
        touches[e.index]=e.position
        if touches.size()==1:
            camera.position-=e.relative/camera.zoom.x
        elif touches.size()>=2:
            var k=touches.keys()
            var d:float=touches[k[0]].distance_to(touches[k[1]])
            if pinch_dist>0:
                _zoom(d/pinch_dist)
            pinch_dist=d
    camera.position.x=clamp(camera.position.x,300.0,WORLD_SIZE.x-300.0)
    camera.position.y=clamp(camera.position.y,250.0,WORLD_SIZE.y-200.0)

func _btn(text:String,call:Callable,size:Vector2)->Button:
    var b:=Button.new()
    b.text=text
    b.custom_minimum_size=size
    b.add_theme_font_size_override("font_size",16)
    b.add_theme_stylebox_override("normal",_panel(Color(.03,.12,.21,.96),14,Color(.12,.34,.49),1))
    b.add_theme_stylebox_override("hover",_panel(Color(.05,.20,.32,.98),14,BLUE,2))
    b.pressed.connect(call)
    return b

func _panel(bg:Color,r:int,border:Color,w:int)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=bg
    s.border_color=border
    s.set_border_width_all(w)
    s.corner_radius_top_left=r
    s.corner_radius_top_right=r
    s.corner_radius_bottom_left=r
    s.corner_radius_bottom_right=r
    s.content_margin_left=16
    s.content_margin_right=16
    s.content_margin_top=10
    s.content_margin_bottom=10
    return s
