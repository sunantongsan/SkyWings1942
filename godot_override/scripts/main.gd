extends Node3D

const BUILDING_NAMES := ["Galactic Core","Fusion Reactor","Metal Extractor","Oil Processor","Crystal Mine","Resource Vault","Star Hangar","Research Lab","Laser Tower","Shield Generator","Gold Refinery","Missile Bastion","Vehicle Factory","Barracks","Godot Citadel","Astral Well","Summoning Sanctum","Runebolt Spire","Vehicle Camp","Air Camp","Infantry Camp"]
const BUILDING_COST := [0,700,500,600,800,900,1200,1200,850,1300,1500,1200,1400,1000,1800,1000,1500,1300,900,900,700]
const UNIT_NAMES := ["Fighter","Interceptor","Bomber","Heavy Fighter","Stealth Fighter","Gunship","Missile Cruiser","Destroyer","Battle Cruiser","Carrier","Battle Tank","Siege Tank","Artillery","Rocket Launcher","Mech Warrior","Sniper Unit","Shield Drone","Repair Drone","Assault Soldier","Elite Commander","Rune Guardian","Crystal Golem","Starweaver","Attack Pigeon"]
const MAP_NAMES := ["Terra","Volcanis","Cryon","Desertus","Noctis","Aquara","Mechanis","Toxicus","Nebularis","Asteroid Belt","Ruins","Orbit Station","Moon Base","Gas Giant","Wormhole"]
const MAP_GROUND := [Color("315b3a"),Color("592820"),Color("a9c7d8"),Color("8a633d"),Color("24293a"),Color("1d566c"),Color("4f5960"),Color("45622f"),Color("392851"),Color("47443f"),Color("5a5144"),Color("4a5058"),Color("74736d"),Color("8a6c49"),Color("251c48")]
const MAP_ACCENT := [Color("42d884"),Color("ff6a36"),Color("9de7ff"),Color("ffc05c"),Color("7688ff"),Color("43d7ff"),Color("9faeba"),Color("83e342"),Color("d268ff"),Color("c2b19c"),Color("ffce81"),Color("5ae8ff"),Color("e5e6ea"),Color("ff9f5c"),Color("a968ff")]

var camera:Camera3D
var world_root:Node3D
var home_root:Node3D
var battle_root:Node3D
var decor_root:Node3D
var ui:CanvasLayer
var top_label:Label
var selected_label:Label
var selected_detail:Label
var toast:Label
var build_panel:PanelContainer
var units_panel:PanelContainer
var galaxy_panel:PanelContainer
var victory_panel:PanelContainer
var rewarded_ads:RefCounted
var ad_button:Button
var saved_boost_button:Button
var app_paused:=false
var garrison:RefCounted
var battle_feedback:RefCounted
var status_bars:RefCounted
var placement_guide:RefCounted
var coin_system:RefCounted
var godot_coins:=0
var last_coin_day:=-1
var cleared_obstacles:Array=[]
var clearing_jobs:Array=[]
var raid_stock:=PackedInt32Array()
var reserve_panel:PanelContainer
var reserve_buttons:Dictionary={}
var credits:=3000.0
var metal:=10000.0
var oil:=1000.0
var crystal:=500.0
var power:=0.0
var gold:=0.0
var drone_count:=1
var miner_count:=0
var miner_finish:=0.0
var drone_finish:=0.0
var industry_visuals:Array[Node3D]=[]
var drone_visuals:Array[Node3D]=[]
var home_attackers:Array[Dictionary]=[]
const DRONE_PRICES := [200,400,800,1500,2500,4000,6000,9000,13000]
var mode:="base"
var map_index:=0
var selected_building:=-1
var build_type:=-1
var moving_building:=-1
var selected_unit:=0
var buildings:Array[Dictionary]=[]
var building_levels:=PackedInt32Array([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
var unit_stock:=PackedInt32Array([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
var drag_camera:=false
var touch_points:={}
var pinch_last:=0.0
var battle_targets:Array[Dictionary]=[]
var battle_units:Array[Dictionary]=[]
var battle_damage:=0.0
var battle_elapsed:=0.0
var battle_map:=1
var ground:MeshInstance3D
var terrain_material:ShaderMaterial
var sun:DirectionalLight3D
var art = preload("res://scripts/planet_art.gd").new()
var ui_root: Control
var header: HBoxContainer
var dock: HBoxContainer
var info_panel: PanelContainer
var resource_labels: Array[Label] = []
var status_label: Label
var animators: Array[Dictionary] = []
var scouts: Array[Node3D] = []
var selection_ring: MeshInstance3D
var visual_time := 0.0
var mouse_start := Vector2.ZERO
var pointer_moved := false
var touch_start := Vector2.ZERO
var gesture_multi := false
var camera_focus := Vector3.ZERO
var top_refresh := 0.0
var toast_tween: Tween
var battle_cooldown := 0.0
var awaiting_deployment := false
var deploy_kind:=0
var deploy_count:=8
var deployed_stock:=PackedInt32Array()
var deployment_groups:Array[int]=[]
var deployment_bar:HBoxContainer
var deploy_picker:OptionButton
var deploy_status:Label
var missiles:Array[Dictionary]=[]
var wreck_root:Node3D
var unit_icon_cache:Dictionary={}
const GROUND_ASSETS := ["battle_tank","siege_tank","artillery","rocket_launcher","mech_warrior","sniper_unit","shield_drone","repair_drone","assault_soldier","elite_commander"]
const BUILD_ORDER := [0,1,2,5,3,4,6,8,7,9]
const LANDING_SITES := [Vector3(0,0,0),Vector3(-7,0,-4),Vector3(-12,0,4),Vector3(10,0,6),Vector3(12,0,-5),Vector3(-2,0,10),Vector3(5,0,12),Vector3(4,0,-10),Vector3(-14,0,-8),Vector3(18,0,-11)]
const POWER_DEMAND := [0,0,20,30,25,10,40,35,25,35,30,40,45,25,20,0,40,30,10,10,10]
var home_planet := -1
var has_colony := false
var tutorial_step := 0
var tutorial_dismissed := false
var profile_path := "user://colony_v1.json"
var profile_store = preload("res://scripts/profile_store.gd").new()
var onboarding:RefCounted
var autosave_time := 0.0
var profile_ready := false
var roads_root:Node3D
var landing_marker:MeshInstance3D
var landing_label:Label3D
const BUILD_SECONDS := [8,15,20,25,30,25,40,45,30,45,40,45,45,30,50,30,45,35,30,30,25]
var colony_time := 0.0
var training_queue:Array = []
var production_kind:=6
var production_building:=-1
var drone_producer:=-1
var miner_producer:=-1
const UNIT_FACILITY := [6,6,6,6,6,6,6,6,6,6,12,12,12,12,13,13,6,6,13,13,16,16,16,6]
const UNIT_TIER := [1,2,2,3,4,3,4,5,6,7,1,3,2,4,3,2,2,2,1,5,1,2,3,1]
var work_label:Label


func _ready()->void:
	unit_stock.resize(UNIT_NAMES.size())
	building_levels.resize(BUILDING_NAMES.size())
	_setup_environment()
	_setup_world()
	_setup_camera()
	_setup_ui()
	onboarding=preload("res://scripts/onboarding.gd").new(self)
	coin_system=preload("res://scripts/coin_system.gd").new(self)
	placement_guide=preload("res://scripts/placement_guide.gd").new(self)
	status_bars=preload("res://scripts/status_bars.gd").new(self)
	garrison=preload("res://scripts/home_garrison.gd").new(self)
	battle_feedback=preload("res://scripts/battle_feedback.gd").new(self)
	battle_feedback.sound_button=dock.get_child(8);battle_feedback.set_enabled(battle_feedback.enabled,false)
	rewarded_ads=preload("res://scripts/rewarded_ads.gd").new(self)
	_load_profile()
	_apply_map_theme(home_planet if has_colony else 0)
	_setup_life()
	_sync_industry_visuals()
	profile_ready=true
	_refresh_progress()
	onboarding.welcome()

func _process(delta:float)->void:
	placement_guide.tick()
	if has_colony:_advance_colony(maxf(colony_time,Time.get_unix_time_from_system()))
	if mode=="battle": _battle_tick(delta)
	garrison.tick(delta)
	battle_feedback.tick(delta)
	if mode=="base":_home_defense_tick(delta)
	_projectile_tick(delta)
	_visual_tick(delta)
	status_bars.tick()
	rewarded_ads.tick()
	autosave_time+=delta
	if autosave_time>=10.0:_save_profile();autosave_time=0.0
	top_refresh += delta
	if top_refresh > 0.15:
		_update_top_bar()
		_update_work_display()
		if mode=="battle":_refresh_deployment()
		top_refresh = 0.0

func _setup_environment()->void:
	var env:=WorldEnvironment.new()
	var e:=Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color("172b39")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("b3d6dc")
	e.ambient_light_energy=0.35
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.environment=e
	add_child(env)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-52,-28,0)
	sun.light_color=Color("fff0d1")
	sun.light_energy=0.8
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=100
	sun.shadow_bias=0.04
	add_child(sun)
	var fill:=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-32,140,0)
	fill.light_color=Color("8ecee5")
	fill.light_energy=0.18
	add_child(fill)

func _setup_world()->void:
	world_root=Node3D.new();add_child(world_root)
	wreck_root=Node3D.new();wreck_root.name="BattleWreckage";world_root.add_child(wreck_root)
	home_root=Node3D.new();world_root.add_child(home_root)
	battle_root=Node3D.new();battle_root.visible=false;world_root.add_child(battle_root)
	decor_root=Node3D.new();world_root.add_child(decor_root)
	ground=art.terrain()
	terrain_material=ground.material_override
	world_root.add_child(ground)
	selection_ring=MeshInstance3D.new()
	var ring:=TorusMesh.new()
	ring.inner_radius=3.2;ring.outer_radius=3.3
	ring.rings=40;ring.ring_segments=6
	selection_ring.mesh=ring
	selection_ring.material_override=art.mat(Color("8ff9d5"),true)
	selection_ring.visible=false
	world_root.add_child(selection_ring)
	landing_marker=MeshInstance3D.new()
	var landing_mesh:=TorusMesh.new();landing_mesh.inner_radius=2.8;landing_mesh.outer_radius=2.95;landing_mesh.rings=40;landing_mesh.ring_segments=6
	landing_marker.mesh=landing_mesh;landing_marker.material_override=art.mat(Color("ffe19b"),true);world_root.add_child(landing_marker);landing_marker.hide()
	landing_label=Label3D.new();landing_label.font_size=48;landing_label.pixel_size=.022;landing_label.outline_size=4;landing_label.no_depth_test=true;landing_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;landing_label.modulate=Color("ffe7a5");world_root.add_child(landing_label);landing_label.hide()

func _setup_camera()->void:
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect=Camera3D.KEEP_HEIGHT
	camera.size=36
	camera.current=true
	camera.far=220
	add_child(camera)
	_center_camera()

func _setup_ui()->void:
	ui=CanvasLayer.new();add_child(ui)
	ui_root=Control.new();ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(ui_root)
	header=HBoxContainer.new();header.add_theme_constant_override("separation",8);ui_root.add_child(header)
	var brand:=PanelContainer.new();brand.custom_minimum_size=Vector2(225,72)
	brand.add_theme_stylebox_override("panel",_style(Color("112a36"),12,Color("426373"),1));header.add_child(brand)
	var bv:=VBoxContainer.new();brand.add_child(bv)
	var title:=Label.new();title.text="GALAXY 1942";title.add_theme_font_size_override("font_size",23);bv.add_child(title)
	status_label=Label.new();status_label.text="TERRA  /  HOME PLANET";status_label.add_theme_font_size_override("font_size",13);status_label.modulate=Color("79cdbf");bv.add_child(status_label)
	status_label.mouse_filter=Control.MOUSE_FILTER_STOP
	status_label.gui_input.connect(func(event:InputEvent):
		if event is InputEventScreenTouch and event.pressed:coin_system.show_panel()
		elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:coin_system.show_panel())
	var colors:=[Color("ecc779"),Color("b4c8d6"),Color("edaa76"),Color("c995f2"),Color("82dec3"),Color("ffd065"),Color("63e6ef")]
	for i in 7:
		var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",_style(Color("112a36"),12,Color("36505e"),1));header.add_child(card)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",0);card.add_child(column)
		var caption_row:=HBoxContainer.new();caption_row.add_theme_constant_override("separation",4);column.add_child(caption_row)
		if i==6:
			var icon:=TextureRect.new();icon.texture=load("res://assets/icons/godot_coin.svg");icon.custom_minimum_size=Vector2(20,20);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption_row.add_child(icon)
			card.mouse_filter=Control.MOUSE_FILTER_STOP
			card.gui_input.connect(func(event:InputEvent):
				if event is InputEventScreenTouch and event.pressed:coin_system.show_panel()
				elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:coin_system.show_panel())
		var caption:=Label.new();caption.text=["CREDITS","METAL","OIL","CRYSTAL","POWER","GOLD","GODOT COIN"][i];caption.add_theme_font_size_override("font_size",13);caption.modulate=colors[i];caption_row.add_child(caption)
		column.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var value:=Label.new();value.text="0";value.add_theme_font_size_override("font_size",25);column.add_child(value);resource_labels.append(value)
	dock=HBoxContainer.new();dock.add_theme_constant_override("separation",10);ui_root.add_child(dock)
	dock.add_child(_button("BUILD",_toggle_build,Vector2(180,64)))
	dock.add_child(_button("FLEET",_toggle_units,Vector2(180,64)))
	var galaxy_button:=_button("GALAXY MAP",_toggle_galaxy,Vector2(224,64))
	galaxy_button.add_theme_stylebox_override("normal",_style(Color("176d75"),12,Color("69d9c8"),1));dock.add_child(galaxy_button)
	dock.add_child(_button("HOME",_home_action,Vector2(120,64)))
	dock.add_child(_button("+",func():_zoom(-3),Vector2(64,64)))
	dock.add_child(_button("−",func():_zoom(3),Vector2(64,64)))
	dock.add_child(_button("GUIDE",func():onboarding.show_help(),Vector2(104,64)))
	var yard_button:=_button("GARRISON",func():garrison.focus(),Vector2(130,64));yard_button.add_theme_font_size_override("font_size",17);dock.add_child(yard_button)
	var sound_button:=_button("SFX ON",func():battle_feedback.set_enabled(not battle_feedback.enabled),Vector2(80,64));sound_button.add_theme_font_size_override("font_size",15);dock.add_child(sound_button)
	info_panel=PanelContainer.new();info_panel.custom_minimum_size=Vector2(286,0);info_panel.visible=false
	info_panel.add_theme_stylebox_override("panel",_style(Color("112a36"),14,Color("75cabb"),1));ui_root.add_child(info_panel)
	var info_scroll:=ScrollContainer.new();info_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;info_panel.add_child(info_scroll)
	var iv:=VBoxContainer.new();iv.size_flags_horizontal=Control.SIZE_EXPAND_FILL;iv.add_theme_constant_override("separation",8);info_scroll.add_child(iv)
	info_scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	selected_label=Label.new();selected_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;selected_label.add_theme_font_size_override("font_size",23);iv.add_child(selected_label)
	selected_detail=Label.new();selected_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;selected_detail.add_theme_font_size_override("font_size",17);selected_detail.modulate=Color("a8c4cd");iv.add_child(selected_detail)
	iv.add_child(_button("PRODUCE",func():
		if selected_building>=0 and buildings[selected_building].type in [6,12,13,16]:_show_production(buildings[selected_building].type,selected_building)
		else:_toast("Select a production building or Summoning Sanctum."),Vector2(0,54)))
	iv.add_child(_button("SPEED UP",func():coin_system.show_panel(),Vector2(0,48)))
	ad_button=_button("WATCH AD • −50s",func():rewarded_ads.request_build(selected_building),Vector2(0,44));iv.add_child(ad_button)
	saved_boost_button=_button("USE SAVED BOOST",func():rewarded_ads.use_saved(selected_building),Vector2(0,44));iv.add_child(saved_boost_button);saved_boost_button.hide()
	iv.add_child(_button("UPGRADE",_upgrade_selected,Vector2(0,58)))
	iv.add_child(_button("MOVE",_begin_move,Vector2(0,48)))
	iv.add_child(_button("CLOSE",func():info_panel.hide();selection_ring.hide(),Vector2(0,44)))
	build_panel=_make_build_panel();ui_root.add_child(build_panel);build_panel.hide()
	units_panel=_make_units_panel();ui_root.add_child(units_panel);units_panel.hide()
	galaxy_panel=_make_galaxy_panel();ui_root.add_child(galaxy_panel);galaxy_panel.hide()
	toast=Label.new();toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast.add_theme_font_size_override("font_size",18);toast.modulate=Color("d6f4de");toast.mouse_filter=Control.MOUSE_FILTER_IGNORE;toast.add_theme_color_override("font_outline_color",Color("10222c"));toast.add_theme_constant_override("outline_size",6);ui_root.add_child(toast)
	victory_panel=_panel("VICTORY  /  WORLD SECURED")
	var vv:VBoxContainer=victory_panel.get_child(0)
	var vr:=Label.new();vr.name="Reward";vr.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;vr.add_theme_font_size_override("font_size",22);vv.add_child(vr)
	vv.add_child(_button("RETURN HOME",_return_home,Vector2(0,64)))
	ui_root.add_child(victory_panel);victory_panel.hide()
	work_label=Label.new();work_label.add_theme_font_size_override("font_size",18)
	work_label.add_theme_color_override("font_outline_color",Color("10222c"));work_label.add_theme_constant_override("outline_size",7)
	work_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;work_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(work_label)
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()
	_update_top_bar()

func _make_build_panel()->PanelContainer:
	var panel:=_panel("CONSTRUCTION  /  DEVELOP YOUR HOMEWORLD")
	var actions:=HBoxContainer.new();panel.get_child(0).add_child(actions)
	actions.add_child(_button("GODOT COIN / REWARDS",func():coin_system.show_panel(),Vector2(310,52)))
	actions.add_child(_button("CLEAR ROCKS / TREES",func():coin_system.begin_clear(),Vector2(310,52)))
	actions.add_child(_button("DEFENSE DRILL",_start_defense_drill,Vector2(230,52)))
	var grid:=_scroll_grid(panel,5)
	for i in BUILD_ORDER+[18,19,20,10,11,12,13,14,15,16,17]:
		var b:=_asset_button(BUILDING_NAMES[i],"%s M / %d O • %ds"%[_fmt(BUILDING_COST[i]),_building_oil_cost(i),BUILD_SECONDS[i]],"buildings/"+_building_file(i),Vector2(200,158))
		var reason:=_build_lock_reason(i)
		b.disabled=not reason.is_empty()
		if b.disabled:
			b.get_child(0).modulate=Color(.45,.55,.6)
			b.tooltip_text=reason
			b.get_child(0).get_child(b.get_child(0).get_child_count()-1).text=reason
		b.pressed.connect(func(idx=i):_begin_build(idx));grid.add_child(b)
	return panel

func _producer_for(kind:int)->int:
	if production_building>=0 and production_building<buildings.size() and buildings[production_building].type==kind:return production_building
	for i in buildings.size():
		if buildings[i].type==kind and buildings[i].get("job","")=="":return i
	return -1
func _producer_queue_count(index:int)->int:
	var count:=0
	for job in training_queue:
		if int(job.get("producer",-1))==index:count+=1
	return count
func _producer_queue_limit(index:int)->int:
	return mini(20,8+2*(int(buildings[index].level)-1)) if index>=0 else 0
func _facility_finish(kind:int,index:int=-1)->float:
	if index<0:index=_producer_for(kind)
	var finish:float=colony_time
	if kind==6 and drone_producer==index:finish=maxf(finish,drone_finish)
	if kind==12 and miner_producer==index:finish=maxf(finish,miner_finish)
	for job in training_queue:
		if int(job.get("producer",-1))==index:finish=maxf(finish,float(job.finish))
	return finish

func _production_level(kind:int)->int:
	var level:=0
	for building in buildings:
		if building.type==kind and building.get("job","")=="":level=maxi(level,building.level)
	return level

func _unit_lock_reason(idx:int,index:int=-1)->String:
	if tutorial_step<11:return "Complete the Core upgrade mission"
	if index<0:index=_producer_for(UNIT_FACILITY[idx])
	if index<0:return "Build "+BUILDING_NAMES[UNIT_FACILITY[idx]]
	var producer:Dictionary=buildings[index]
	if producer.type!=UNIT_FACILITY[idx]:return "Wrong producer for this unit."
	if producer.get("job","")!="":return "This producer is under construction."
	if producer.level<UNIT_TIER[idx]:return "This producer needs level %d"%UNIT_TIER[idx]
	var group:int=garrison.category(idx) if garrison else 0
	if garrison and garrison.stock(group)+garrison.queued(group)>=garrison.capacity(group):return "Build or upgrade "+["Air Camp","Vehicle Camp","Infantry Camp"][group]
	if _producer_queue_count(index)>=_producer_queue_limit(index):return "This producer's queue is full."
	return ""

func _show_production(kind:int,index:int=-1)->void:
	production_kind=kind
	production_building=index if index>=0 else _producer_for(kind)
	_dismiss_menus();_refresh_progress();units_panel.show()

func _make_units_panel()->PanelContainer:
	var producer:int=_producer_for(production_kind)
	var level:int=buildings[producer].level if producer>=0 else 0
	var panel:=_panel("%s #%d / LV %d / QUEUE %d OF %d"%[BUILDING_NAMES[production_kind].to_upper(),producer+1,level,_producer_queue_count(producer),_producer_queue_limit(producer)])
	var picker:=OptionButton.new();picker.custom_minimum_size=Vector2(350,48)
	var choice:=0
	for i in buildings.size():
		if buildings[i].type!=production_kind:continue
		picker.add_item("%s #%d • LV %d • %d queued"%[BUILDING_NAMES[production_kind],i+1,buildings[i].level,_producer_queue_count(i)],i)
		if i==producer:picker.select(choice)
		choice+=1
	picker.item_selected.connect(func(item:int):_show_production(production_kind,picker.get_item_id(item)))
	panel.get_child(0).add_child(picker)
	var tabs:=HBoxContainer.new();panel.get_child(0).add_child(tabs)
	for kind in [6,12,13,16]:
		var button:=_button("GODOT SANCTUM" if kind==16 else BUILDING_NAMES[kind].to_upper(),func(k=kind):_show_production(k),Vector2(225,54))
		button.add_theme_font_size_override("font_size",17)
		if kind==production_kind:button.add_theme_stylebox_override("normal",_style(Color("176d75"),12,Color("69d9c8"),1))
		tabs.add_child(button)
	tabs.add_child(_button("SPEED UP",func():coin_system.show_panel(),Vector2(170,54)))
	var grid:=_scroll_grid(panel,4)
	var roster:Array=range(UNIT_NAMES.size())
	if production_kind==6:roster.erase(23);roster.insert(1,23)
	for i in roster:
		if UNIT_FACILITY[i]!=production_kind:continue
		var cost:int=_unit_credit_cost(i)
		var reason:=_unit_lock_reason(i,producer)
		var detail:String="LV %d • Ready %d • %ds\n%d C / %d O"%[UNIT_TIER[i],unit_stock[i],_unit_train_seconds(i),cost,_unit_oil_cost(i)] if reason.is_empty() else "LOCKED • "+reason
		var b:=_asset_button(UNIT_NAMES[i],detail,"units/"+_unit_asset(i),Vector2(230,168))
		b.disabled=not reason.is_empty()
		if b.disabled:b.get_child(0).modulate=Color(.45,.55,.6)
		b.pressed.connect(func(idx=i,owner=producer):_train_unit(idx,owner));grid.add_child(b)
	if production_kind==12:
		var miner:=_asset_button("Mining Vehicle","LV 1 • 15s • 600 M / 150 O\nRequires Gold Refinery","units/mining_vehicle",Vector2(230,168))
		miner.disabled=level<1 or building_levels[10]<1 or miner_finish>0
		miner.pressed.connect(_build_miner);grid.add_child(miner)
	if production_kind==6:
		var drone:=_asset_button("Construction Drone","LV 1 • 15s • %d / 10 • %d Gold"%[drone_count,DRONE_PRICES[mini(drone_count-1,8)]],"units/construction_drone",Vector2(230,168))
		drone.disabled=level<1 or drone_count>=10 or drone_finish>0
		drone.pressed.connect(_buy_drone);grid.add_child(drone)
	return panel

func _make_galaxy_panel()->PanelContainer:
	var panel:=_panel("GALAXY MAP / AI OUTPOSTS")
	var grid:=_scroll_grid(panel,5)
	for i in 15:
		var b:=_asset_button(MAP_NAMES[i],("GODOT / LV %02d / %s" if i in [4,8,10,14] else "LEVEL %02d / %s")%[i+1,"EASY" if i<3 else ("NORMAL" if i<7 else ("HARD" if i<11 else "EXTREME"))],"",Vector2(200,130))
		b.add_theme_stylebox_override("normal",_style(MAP_ACCENT[i].darkened(0.82),12,MAP_ACCENT[i].darkened(0.35),1))
		if i==home_planet:
			b.disabled=true
			b.get_child(0).get_child(1).text="YOUR HOMEWORLD"
		b.pressed.connect(func(idx=i):_start_battle(idx));grid.add_child(b)
	return panel

func _building_file(i:int)->String:return ["galactic_core","fusion_reactor","metal_extractor","oil_processor","crystal_mine","resource_vault","star_hangar","research_lab","laser_tower","shield_generator","gold_refinery","missile_bastion","vehicle_factory","barracks","godot_citadel","astral_well","summoning_sanctum","runebolt_spire","vehicle_camp","air_camp","infantry_camp"][i]

func _spawn_building(parent:Node3D,type:int,pos:Vector3,level:int,enemy:bool)->Dictionary:
	var root:Node3D=art.building(type,enemy)
	root.position=pos;parent.add_child(root)
	root.scale=Vector3.ONE*(1.0+(level-1)*.025)
	for part_name in ["Rotor","Radar","Drill","Turret"]:
		var part:Node3D=root.find_child(part_name,true,false)
		if part:animators.append({"node":part,"kind":part_name,"home":parent==home_root})
	if type==3: art.particles(root,Vector3(0,4.4,-.25),Color("9db4b6"),true,false)
	var d={"node":root,"type":type,"level":level,"pos":pos,"hp":350.0+level*120.0,"max_hp":350.0+level*120.0}
	var rank:=Label3D.new();rank.font_size=44;rank.pixel_size=.018;rank.outline_size=8
	rank.billboard=BaseMaterial3D.BILLBOARD_ENABLED;rank.modulate=Color("ffd873")
	rank.no_depth_test=true;root.add_child(rank);rank.top_level=true;d["rank_label"]=rank
	_update_rank_label(d)
	if parent==home_root:buildings.append(d)
	return d

func _create_roads(parent:Node3D)->void:
	art.roads(parent)

func _create_decor(parent:Node3D,theme:int)->void:
	art.decor(parent,theme,cleared_obstacles if mode=="base" else [])

func _apply_map_theme(idx:int)->void:
	map_index=idx
	var soil:Color=MAP_GROUND[idx].darkened(0.28)
	var grass:Color=MAP_GROUND[idx].lightened(0.05)
	if idx==0:soil=Color("354b43");grass=Color("526f50")
	if idx==2:soil=Color("3d586e");grass=Color("618498")
	terrain_material.set_shader_parameter("soil_color",soil)
	terrain_material.set_shader_parameter("grass_color",grass)
	sun.light_color=MAP_ACCENT[idx].lerp(Color("fff0d1"),.88)
	_create_decor(decor_root,idx)
	if garrison:garrison.signature=""

func _unit_model(type:int,enemy:=false)->Node3D:
	var model:Node3D=art.model(_unit_asset(type))
	if type<10:model.scale=Vector3.ONE*(0.5+type*.035)
	var turret:Node3D=model.find_child("Turret",true,false)
	var weapon:Node3D=model.find_child("Weapon",true,false)
	if turret and weapon:
		var local:Vector3=weapon.position-turret.position
		weapon.owner=null;weapon.reparent(turret,false);weapon.position=local
	var parts:Dictionary={}
	for part_name in ["Turret","Weapon","LeftLeg","RightLeg","LeftArm","RightArm","Rotor","LeftWing","RightWing"]:
		var part:Node3D=model.find_child(part_name,true,false)
		if part:parts[part_name]=part
	model.set_meta("parts",parts);model.set_meta("airborne",_is_air_unit(type))
	if weapon:model.set_meta("weapon_rest",weapon.position)
	if enemy:
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			for surface in mesh.mesh.get_surface_count():
				var material:Material=mesh.get_active_material(surface)
				if material is StandardMaterial3D and material.emission_enabled:
					var red:StandardMaterial3D=material.duplicate();red.emission=Color("ff654b");red.albedo_color=Color("ff654b")
					mesh.set_surface_override_material(surface,red)
	return model

func _begin_build(idx:int)->void:
	if mode!="base" or not has_colony:return
	var reason:=_build_lock_reason(idx)
	if not reason.is_empty():_toast(reason);return
	moving_building=-1
	_dismiss_menus()
	coin_system.clearing=false
	build_type=idx;build_panel.hide();units_panel.hide();galaxy_panel.hide();info_panel.hide();selection_ring.hide()
	_toast("Tap clear terrain to place "+BUILDING_NAMES[idx]+". The glowing site is a suggestion.")
	onboarding.refresh_guide()
	_update_landing_marker()

func _upgrade_selected()->void:
	if mode!="base" or not has_colony:return
	if tutorial_step<10:_toast("Complete the construction missions before upgrading.");return
	if selected_building<0 or selected_building>=buildings.size():_toast("SELECT A BUILDING FIRST");return
	var b:Dictionary=buildings[selected_building]
	if tutorial_step==10 and b.type!=0:_toast("Upgrade the Galactic Core first.");return
	if b.get("job","")!="":_toast("This building is already under construction.");return
	if b.level>=100:_toast("Maximum level reached.");return
	var cost:int=500+int(b.type)*120+int(b.level)*360
	if metal<cost:_toast("NOT ENOUGH METAL");return
	if _builder_busy():_toast("Construction drone busy. Wait for the current job.");return
	metal-=cost
	b["job"]="upgrade";b["started"]=colony_time;b["finish"]=colony_time+_upgrade_seconds(b.level+1)
	_add_work_marker(b)
	_refresh_progress();_save_profile();_dismiss_menus()
	_toast("Upgrade started. The new level unlocks when construction finishes.")

func _upgrade_seconds(target_level:int)->int:
	const TIMES:=[0,0,30,120,300,900,1800,3600,7200,14400,28800]
	if target_level<TIMES.size():return TIMES[maxi(2,target_level)]
	return mini(172800,28800+(target_level-10)*14400)
func _duration(seconds:float)->String:
	var n:=maxi(0,ceili(seconds))
	if n>=3600:return "%dh %dm"%[n/3600,(n%3600)/60]
	if n>=60:return "%dm %ds"%[n/60,n%60]
	return "%ds"%n

func _unit_credit_cost(kind:int)->int:return 40 if kind==23 else 180+kind*35
func _unit_oil_cost(kind:int)->int:return 5 if kind==23 else int(_unit_credit_cost(kind)*.4)
func _unit_train_seconds(kind:int)->int:return 3 if kind==23 else 5+kind*2
func _is_air_unit(kind:int)->bool:return kind<10 or kind==23

func _train_unit(idx:int,producer:int=-1)->void:
	if mode!="base":return
	if idx<0 or idx>=UNIT_NAMES.size():return
	if producer<0:producer=_producer_for(UNIT_FACILITY[idx])
	var reason:=_unit_lock_reason(idx,producer)
	if not reason.is_empty():_toast(reason);return
	var c:=_unit_credit_cost(idx)
	if credits<c or oil<_unit_oil_cost(idx):_toast("NOT ENOUGH RESOURCES");return
	credits-=c;oil-=_unit_oil_cost(idx);selected_unit=idx
	var start:float=_facility_finish(UNIT_FACILITY[idx],producer)
	training_queue.append({"type":idx,"producer":producer,"finish":start+_unit_train_seconds(idx)})
	training_queue.sort_custom(func(a,b):return float(a.finish)<float(b.finish))
	_refresh_progress();_setup_life();_save_profile()
	_dismiss_menus();onboarding.refresh_guide()
	_toast("%s queued at %s #%d."%[UNIT_NAMES[idx],BUILDING_NAMES[UNIT_FACILITY[idx]],producer+1])

func _toggle_build()->void:
	if mode!="base" or not has_colony:return
	build_panel.visible=not build_panel.visible;units_panel.hide();galaxy_panel.hide();info_panel.hide()
	onboarding.refresh_guide()

func _toggle_units()->void:
	if mode!="base" or building_levels[6]==0 or tutorial_step<11:_toast("Complete construction and upgrade your Core to unlock training.");return
	units_panel.visible=not units_panel.visible;build_panel.hide();galaxy_panel.hide();info_panel.hide()
	onboarding.refresh_guide()

func _toggle_galaxy()->void:
	if mode!="base" or tutorial_step<12:_toast("Train 8 Fighters before your first raid.");return
	galaxy_panel.visible=not galaxy_panel.visible;units_panel.hide();build_panel.hide();info_panel.hide()
	onboarding.refresh_guide()

func _start_battle(idx:int)->void:
	if mode!="base" or tutorial_step<12 or idx<0 or idx>=15:return
	if idx==home_planet:_toast("This world is your home. Choose a rival outpost.");return
	if Array(unit_stock).reduce(func(a,b):return a+b,0)<=0:_toast("Train a fleet before attacking.");return
	build_type=-1;landing_marker.hide();landing_label.hide()
	build_panel.hide();units_panel.hide()
	if is_instance_valid(coin_system.panel):coin_system.panel.hide()
	_save_profile()
	mode="battle";battle_map=idx;galaxy_panel.visible=false;info_panel.hide();selection_ring.hide();home_root.visible=false;battle_root.visible=true
	for c in battle_root.get_children():c.queue_free()
	_clear_wrecks()
	battle_targets.clear();battle_units.clear();battle_damage=0;battle_elapsed=0;_apply_map_theme(idx)
	var epos=[Vector3(0,0,-5),Vector3(-8,0,-1),Vector3(8,0,-1),Vector3(-5,0,5),Vector3(5,0,5),Vector3(-13,0,6),Vector3(13,0,6)];var etypes=[14,17,17,15,16,14,15] if idx in [4,8,10,14] else [0,8,8,9,6,2,3]
	for i in epos.size():battle_targets.append(_spawn_building(battle_root,etypes[i],epos[i],1+idx,true))
	for i in floori(idx/3.0):
		battle_targets.append(_spawn_building(battle_root,17 if idx in [4,8,10,14] else 11,Vector3(-12+i*8,0,-12),1+idx,true))
	raid_stock=unit_stock.duplicate()
	awaiting_deployment=true;deployed_stock.resize(UNIT_NAMES.size());deployed_stock.fill(0);deployment_groups.clear()
	deploy_count=8
	for kind in UNIT_NAMES.size():
		if unit_stock[kind]>0:deploy_kind=kind;break
	camera_focus=Vector3.ZERO;_position_camera();camera.size=44
	_toast("Choose a squad, then tap an outer edge. Place several groups before ATTACK.");_refresh_progress();_show_deployment()

func _deployment_reason(pos:Vector3)->String:
	if not pos.is_finite():return "Invalid position."
	if absf(pos.x)>22 or absf(pos.z)>20 or (absf(pos.x)<16 and absf(pos.z)<13):return "Deploy in the green outer area."
	if raid_stock.size()<=deploy_kind or raid_stock[deploy_kind]-deployed_stock[deploy_kind]<=0:return "No reserves of this type."
	return ""

func _deployment_positions(anchor:Vector3,amount:int)->Array[Vector3]:
	var cells:Array[Vector3]=[]
	for x in range(-22,23,2):
		for z in range(-20,21,2):
			if abs(x)>=16 or abs(z)>=14:cells.append(Vector3(x,0,z))
	cells.sort_custom(func(a,b):return a.distance_squared_to(anchor)<b.distance_squared_to(anchor))
	var positions:Array[Vector3]=[]
	for i in amount:positions.append(cells[i%cells.size()])
	return positions

func _placement_reason(pos:Vector3)->String:
	if not pos.is_finite():return "Invalid position."
	if mode!="base":return "Return home to build."
	if moving_building>=0:
		if moving_building>=buildings.size() or buildings[moving_building].get("job","")!="":return "Wait for construction to finish."
	elif build_type>=0:
		var reason:=_build_lock_reason(build_type)
		if not reason.is_empty():return reason
		if metal<BUILDING_COST[build_type] or oil<_building_oil_cost(build_type):return "Not enough Metal or Oil."
	else:return "Select a building first."
	var placing_kind:int=buildings[moving_building].type if moving_building>=0 else build_type
	if placing_kind in [18,19,20]:
		for i in buildings.size():
			if i==moving_building:continue
			var other:Dictionary=buildings[i]
			var margin:Vector2=Vector2(14,11) if other.type in [18,19,20] else Vector2(9,8)
			if absf(pos.x-other.pos.x)<margin.x and absf(pos.z-other.pos.z)<margin.y:return "The whole camp needs clear ground."
		for obstacle in art.obstacles.values():
			if absf(pos.x-obstacle.x)<9 and absf(pos.z-obstacle.z)<8:return "Clear the rocks or trees before building this camp."
	if garrison and garrison.blocked(pos,moving_building):return "Keep the garrison yards clear."
	for i in buildings.size():
		if i!=moving_building and buildings[i].pos.distance_to(pos)<6.1:return "Too close to another building."
	return ""

func _deploy_fleet(pos:Vector3)->void:
	if mode!="battle":return
	var reason:=_deployment_reason(pos)
	if not reason.is_empty():_toast(reason);return
	var roster:Array[int]=[]
	var available:int=raid_stock[deploy_kind]-deployed_stock[deploy_kind]
	var amount:int=available if deploy_count==0 else mini(deploy_count,available)
	if amount<=0:_toast("No reserves remaining of this type.");return
	for i in amount:roster.append(deploy_kind)
	deployment_groups.append(amount);deployed_stock[deploy_kind]+=amount
	if not awaiting_deployment:unit_stock[deploy_kind]-=amount;_save_profile()
	var positions:=_deployment_positions(pos,amount)
	for i in roster.size():
		var kind:int=roster[i]
		var n:Node3D=_unit_model(kind,false)
		n.position=positions[i]
		n.position.y=_unit_height(kind)
		battle_root.add_child(n)
		n.look_at(Vector3(0,n.position.y,0),Vector3.UP,not _is_air_unit(kind))
		battle_units.append({"node":n,"type":kind,"hp":220.0+kind*30.0,"max_hp":220.0+kind*30.0,"damage":12.0+kind*1.5,"speed":2.7+kind*.08})
		if kind>=20:
			var stats:Array=[[480.0,27.0,3.4],[1050.0,45.0,2.0],[330.0,36.0,3.0],[90.0,5.0,4.2]][kind-20]
			var unit:Dictionary=battle_units.back();unit.hp=stats[0];unit.max_hp=stats[0];unit.damage=stats[1];unit.speed=stats[2]
	_refresh_deployment()
	_toast("Squad placed. Choose another type or location, then ATTACK." if awaiting_deployment else "Reinforcements deployed!")

func _battle_tick(delta:float)->void:
	if awaiting_deployment:return
	_defense_tick(battle_targets,battle_units,delta,battle_map+1)
	var survivors:=0
	for u in battle_units:
		if u.get("hp",0)>0 and is_instance_valid(u.node):survivors+=1
	if survivors==0 and _reserve_count()==0:_finish_battle(false);return
	battle_elapsed+=delta;var total:=0.0;var alive_hp:=0.0;var alive:Array=[]
	for e in battle_targets:
		total+=e.max_hp
		if e.hp>0:alive_hp+=e.hp;alive.append(e)
	battle_damage=100.0*(1.0-alive_hp/max(1.0,total))
	if alive.is_empty() or battle_elapsed>150:_finish_battle(alive.is_empty());return
	for u in battle_units:
		if u.get("hp",0)<=0 or not is_instance_valid(u.node):continue
		var n:Node3D=u.node
		var target:Dictionary={};var best:=INF
		for e in alive:
			if e.hp<=0 or not is_instance_valid(e.node):continue
			var distance:float=Vector2(n.position.x,n.position.z).distance_to(Vector2(e.pos.x,e.pos.z))
			if distance<best:best=distance;target=e
		if target.is_empty():continue
		var moving:bool=best>_attack_range(u.type)
		if moving:n.position=n.position.move_toward(Vector3(target.pos.x,n.position.y,target.pos.z),u.speed*delta)
		if best>.01:n.look_at(Vector3(target.pos.x,n.position.y,target.pos.z),Vector3.UP,not _is_air_unit(u.type))
		_animate_unit(u,delta,moving,target.pos)
		if not moving:
			if target.hp<=0:continue
			target.hp-=u.damage*delta*2.2
			if visual_time-float(u.get("last_shot",-1.0))>0.55:
				var muzzle:Vector3=n.global_position+Vector3.UP
				var parts:Dictionary=n.get_meta("parts",{})
				if parts.has("Weapon"):muzzle=parts.Weapon.global_position+parts.Weapon.global_basis.z*(-.4 if _is_air_unit(u.type) else 1.4)
				_fire_animation(n);_muzzle_flash(muzzle)
				_weapon_effect(muzzle,target.node,target.pos+Vector3(0,1.8,0),u.type in [2,6,7,10,11,12,13],u.type in [20,21,22])
				u["last_shot"]=visual_time
			if target.hp<=0 and is_instance_valid(target.node):_destroy_entity(target,true)

func _finish_battle(win:bool)->void:
	if mode!="battle":return
	if win:
		mode="victory"
		battle_feedback.victory()
		if is_instance_valid(reserve_panel):reserve_panel.hide()
		if is_instance_valid(deployment_bar):deployment_bar.hide()
		var reward:=Vector4(8000+battle_map*700,4200+battle_map*350,2600+battle_map*220,900+battle_map*90);credits+=reward.x;metal+=reward.y;oil+=reward.z;crystal+=reward.w
		var l:Label=victory_panel.find_child("Reward",true,false);l.text="%s conquered\nDamage 100%%\n+%d Credits   +%d Metal   +%d Oil   +%d Crystal"%[MAP_NAMES[battle_map],int(reward.x),int(reward.y),int(reward.z),int(reward.w)];victory_panel.visible=true
		if tutorial_step==12:tutorial_step=13
		_save_profile()
	else:_return_home();battle_feedback.defeat();_toast("FLEET WITHDREW — regroup and try again")

func _return_home()->void:
	if not has_colony:return
	battle_feedback.clear()
	mode="base";victory_panel.hide();battle_root.hide();home_root.show()
	if is_instance_valid(deployment_bar):deployment_bar.hide()
	if is_instance_valid(reserve_panel):reserve_panel.hide()
	dock.show();_clear_missiles();_clear_wrecks()
	_apply_map_theme(home_planet);_center_camera();_refresh_progress();_save_profile();_toast("Returned to "+MAP_NAMES[home_planet]+".")

func _economy_tick(delta:float)->void:
	if not has_colony:return
	var refineries:=0
	for b in buildings:
		if b.type==10 and b.get("job","")!="build":refineries+=1
	gold=minf(1e12,gold+delta*2.0*mini(miner_count,refineries*3))
	for b in buildings:
		if b.get("job","")=="build":continue
		match int(b.type):
			0:credits=minf(1e12,credits+delta*3.5*b.level)
			2:metal=minf(1e12,metal+delta*2.7*b.level)
			3:oil=minf(1e12,oil+delta*2.0*b.level)
			4:crystal=minf(1e12,crystal+delta*.9*b.level)

func _update_top_bar()->void:
	if resource_labels.size()!=7:return
	var values:=[credits,metal,oil,crystal,power,gold,float(godot_coins)]
	for i in 7:resource_labels[i].text=_fmt(values[i])
	status_label.text=(MAP_NAMES[maxi(home_planet,0)].to_upper()) if mode in ["base","welcome"] else "%s  /  %d%%"%[MAP_NAMES[battle_map].to_upper(),int(battle_damage)]

func _fmt(v:float)->String:
	if v>=1000000:return "%.2fM"%(v/1000000.0)
	if v>=1000:return "%.1fK"%(v/1000.0)
	return "%d"%int(v)

func _select_building_at(pos:Vector3)->void:
	var best=-1;var dist=3.6
	for i in buildings.size():
		var d:float=buildings[i].pos.distance_to(pos)
		if d<dist:dist=d;best=i
	selected_building=best
	if best<0:info_panel.hide();selection_ring.hide();return
	info_panel.show();selection_ring.show();selection_ring.position=buildings[best].pos+Vector3(0,.1,0)
	var b:Dictionary=buildings[best]
	selected_label.text="%s • %s"%[BUILDING_NAMES[b.type],_rank_text(b.level)]
	var weapon:String="Auto-defense unlocks at 5 stars"
	if _can_fire(b):weapon="AUTO-DEFENSE • %.1f damage / shot\nRange %.1f m"%[_shot_damage(b,home_planet+1),_weapon_range(b)]
	selected_detail.text="HP %d/%d\nUpgrade: %d Metal • %s\n%s"%[int(b.hp),int(b.max_hp),500+b.type*120+b.level*360,_duration(_upgrade_seconds(b.level+1)),weapon]
	if b.type in [18,19,20]:selected_detail.text+="\nCapacity: %d → %d next star\nMaximum 3 camps of this type"%[garrison.capacity_for_level(b.level),garrison.capacity_for_level(b.level+1)]
	if b.type in [6,12,13,16]:
		selected_detail.text+="\nOwn queue: %d / %d"%[_producer_queue_count(best),_producer_queue_limit(best)]
		var next_units:Array[String]=[]
		for kind in range(UNIT_NAMES.size()):
			if UNIT_FACILITY[kind]==b.type and UNIT_TIER[kind]==b.level+1:next_units.append(UNIT_NAMES[kind])
		selected_detail.text+="\nNext level: "+(", ".join(next_units) if not next_units.is_empty() else "More HP and stronger defense")

func _place_building(pos:Vector3)->void:
	if mode!="base" or not has_colony or build_type<0:return
	pos=Vector3(snappedf(pos.x,1.0),0,snappedf(pos.z,1.0))
	var reason:=_placement_reason(pos)
	if not reason.is_empty():_toast(reason);return
	var cost:int=BUILDING_COST[build_type]
	var kind:=build_type
	metal-=cost;oil-=_building_oil_cost(kind)
	var structure:Dictionary=_spawn_building(home_root,kind,pos,1,false)
	structure["job"]="build";structure["started"]=colony_time;structure["finish"]=colony_time+BUILD_SECONDS[kind]
	_add_work_marker(structure);build_type=-1
	_ensure_roads();_refresh_progress();_save_profile()
	_toast(BUILDING_NAMES[kind]+" construction started.")

func _ground_hit(screen_pos:Vector2)->Variant:
	var origin:=camera.project_ray_origin(screen_pos);var dir:=camera.project_ray_normal(screen_pos);return Plane(Vector3.UP,0).intersects_ray(origin,dir)

func _unhandled_input(event:InputEvent)->void:
	# Keep touch-to-mouse emulation for Control buttons; world gestures use raw touches.
	if event is InputEventMouse and event.device==-1:return
	if onboarding and onboarding.screen.visible:return
	if rewarded_ads and is_instance_valid(rewarded_ads.result_panel) and rewarded_ads.result_panel.visible:return
	if galaxy_panel.visible or build_panel.visible or units_panel.visible or victory_panel.visible:return
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag:placement_guide.point_at(event.position)
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:_zoom(-2);return
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:_zoom(2);return
		if event.button_index==MOUSE_BUTTON_LEFT:
			drag_camera=event.pressed
			if event.pressed:mouse_start=event.position;pointer_moved=false
			elif not pointer_moved:_tap_world(event.position)
	elif event is InputEventMouseMotion and drag_camera:
		if event.position.distance_to(mouse_start)>8:pointer_moved=true
		if pointer_moved:_pan(event.position,event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index]=event.position
			if touch_points.size()==1:touch_start=event.position;pointer_moved=false;gesture_multi=false
			else:gesture_multi=true;pinch_last=0
		else:
			var tap:bool=touch_points.size()==1 and not gesture_multi and not pointer_moved
			touch_points.erase(event.index);pinch_last=0
			if tap:_tap_world(event.position)
	elif event is InputEventScreenDrag:
		if not touch_points.has(event.index):return
		touch_points[event.index]=event.position
		if touch_points.size()==1 and not gesture_multi:
			if event.position.distance_to(touch_start)>8:pointer_moved=true
			if pointer_moved:_pan(event.position,event.relative)
		elif touch_points.size()>=2:
			var k:=touch_points.keys();var d:float=touch_points[k[0]].distance_to(touch_points[k[1]])
			if pinch_last>0 and d>1:camera.size=clampf(camera.size*pinch_last/d,24,52)
			pinch_last=d

func _clamp_camera()->void:
	if mode=="battle":
		camera_focus.x=clampf(camera_focus.x,-24,24);camera_focus.z=clampf(camera_focus.z,-20,20)
	_position_camera()

func _center_camera()->void:
	camera_focus=Vector3(0,0,1)
	camera.size=36
	_position_camera()

func _zoom(delta:float)->void:camera.size=clampf(camera.size+delta,24,52)

func _explode(pos:Vector3)->void:
	art.particles(world_root,pos+Vector3.UP,Color("ffb564"),false,true)
	art.particles(world_root,pos+Vector3.UP,Color("647575"),true,true)
	var flash:=OmniLight3D.new();flash.position=pos+Vector3(0,2,0);flash.light_color=Color("ff9b56");flash.light_energy=4;flash.omni_range=6;world_root.add_child(flash)
	var tw:=create_tween();tw.tween_property(flash,"light_energy",0,.45);tw.finished.connect(flash.queue_free)

func _toast(s:String)->void:
	if toast_tween:toast_tween.kill()
	toast.text=s;toast.visible=true;toast.modulate.a=1
	toast_tween=create_tween();toast_tween.tween_interval(2.5);toast_tween.tween_property(toast,"modulate:a",0,.5)

func _box(size:Vector3,mat:Material)->MeshInstance3D:
	var n:=MeshInstance3D.new();var m:=BoxMesh.new();m.size=size;n.mesh=m;n.material_override=mat;return n
func _cyl(r1:float,r2:float,h:float,mat:Material)->MeshInstance3D:
	var n:=MeshInstance3D.new();var m:=CylinderMesh.new();m.bottom_radius=r1;m.top_radius=r2;m.height=h;n.mesh=m;n.material_override=mat;return n
func _cone(r:float,h:float,mat:Material)->MeshInstance3D:return _cyl(r,0,h,mat)
func _sphere(r:float,mat:Material)->MeshInstance3D:
	var n:=MeshInstance3D.new();var m:=SphereMesh.new();m.radius=r;m.height=r*2;n.mesh=m;n.material_override=mat;return n
func _mat(color:Color,emit:=Color.TRANSPARENT,energy:=0.0,alpha:=1.0)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=Color(color.r,color.g,color.b,alpha);m.metallic=.58;m.roughness=.34
	if emit.a>0:m.emission_enabled=true;m.emission=emit;m.emission_energy_multiplier=energy
	if alpha<.999:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
func _button(text:String,cb:Callable,size:Vector2)->Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size=size;b.add_theme_font_size_override("font_size",20)
	b.add_theme_color_override("font_color",Color("dfebec"))
	b.add_theme_color_override("font_disabled_color",Color("72868d"))
	b.add_theme_stylebox_override("disabled",_style(Color("14242c"),12,Color("2e414c"),1))
	b.add_theme_stylebox_override("normal",_style(Color("183644"),12,Color("4a6877"),1))
	b.add_theme_stylebox_override("hover",_style(Color("24515b"),12,Color("83dcc9"),2))
	b.add_theme_stylebox_override("pressed",_style(Color("0f242c"),12,Color("83dcc9"),2))
	b.pressed.connect(cb);return b

func _style(bg:Color,radius:int,border:Color,width:int)->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(width);s.corner_radius_top_left=radius;s.corner_radius_top_right=radius;s.corner_radius_bottom_left=radius;s.corner_radius_bottom_right=radius;s.content_margin_left=14;s.content_margin_right=14;s.content_margin_top=10;s.content_margin_bottom=10;return s

func _position_camera()->void:
	camera.position=camera_focus+Vector3(29,38,33)
	camera.look_at(camera_focus,Vector3.UP)
	if is_instance_valid(ground):ground.position=Vector3(snappedf(camera_focus.x,32),0,snappedf(camera_focus.z,32))

func _pan(pos:Vector2,relative:Vector2)->void:
	var now=_ground_hit(pos)
	var before=_ground_hit(pos-relative)
	if now!=null and before!=null:camera_focus+=before-now;_clamp_camera()

func _tap_world(pos:Vector2)->void:
	if mode=="battle":
		var point=_ground_hit(pos)
		if point!=null:_deploy_fleet(point)
		return
	if mode!="base":return
	var h=_ground_hit(pos)
	if h!=null:
		if coin_system.clearing:coin_system.select_obstacle(h)
		elif moving_building>=0:_move_building(h)
		elif build_type>=0:_place_building(h)
		else:
			_select_building_at(h)
			if selected_building<0:coin_system.select_obstacle(h,false)
			elif is_instance_valid(coin_system.panel):coin_system.panel.hide()

func _panel(title:String)->PanelContainer:
	var p:=PanelContainer.new()
	p.add_theme_stylebox_override("panel",_style(Color("102832"),16,Color("517582"),1))
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);p.add_child(column)
	var row:=HBoxContainer.new();column.add_child(row)
	var label:=Label.new();label.text=title;label.add_theme_font_size_override("font_size",20);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
	row.add_child(_button("CLOSE",func():
		if p==victory_panel:_return_home()
		else:p.hide()
		if onboarding:onboarding.refresh_guide()
	,Vector2(104,48)))
	return p

func _scroll_grid(panel:PanelContainer,columns:int)->GridContainer:
	var scroll:=preload("res://scripts/touch_scroll.gd").new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.get_child(0).add_child(scroll)
	var grid:=GridContainer.new();grid.columns=columns;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);scroll.add_child(grid)
	return grid

func _asset_button(title:String,detail:String,icon:String,minimum:Vector2)->Button:
	var b:=_button("",func():pass,minimum);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var col:=VBoxContainer.new();col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,10);col.mouse_filter=Control.MOUSE_FILTER_IGNORE;col.alignment=BoxContainer.ALIGNMENT_CENTER;b.add_child(col)
	var path:="res://assets/icons/"+icon+".png"
	if not icon.is_empty() and ResourceLoader.exists(path):
		var image:=TextureRect.new();image.texture=load(path);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size.y=82;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;col.add_child(image)
	for text in [title,detail]:
		var label:=Label.new();label.text=text;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",17 if text==title else 14);label.modulate=Color("dfebec") if text==title else Color("8fc7be");label.mouse_filter=Control.MOUSE_FILTER_IGNORE;col.add_child(label)
	return b

func _layout_ui()->void:
	var size:=get_viewport().get_visible_rect().size
	var margin:=24.0
	if OS.has_feature("android"):
		var safe:=DisplayServer.get_display_safe_area()
		var screen:=DisplayServer.screen_get_size()
		if screen.x>0:
			margin=maxf(margin,maxf(safe.position.x,screen.x-safe.end.x)*size.x/float(screen.x)+8)
	header.position=Vector2(margin,14);header.size=Vector2(size.x-margin*2,76)
	var dock_width:float=dock.get_combined_minimum_size().x
	dock.position=Vector2((size.x-dock_width)/2,size.y-80)
	info_panel.position=Vector2(size.x-margin-286,110);info_panel.size=Vector2(286,size.y-210)
	for panel in [build_panel,units_panel,galaxy_panel]:
		if panel:panel.position=Vector2(margin,105);panel.size=Vector2(size.x-margin*2,size.y-260)
	victory_panel.position=Vector2((size.x-720)/2,170);victory_panel.size=Vector2(720,330)
	toast.position=Vector2(margin,size.y-114);toast.size=Vector2(size.x-margin*2,28)
	if onboarding:onboarding.layout()
	if coin_system:coin_system.layout()
	if mode=="battle":_refresh_deployment()

func _setup_life()->void:
	if garrison:garrison.sync()

func _visual_tick(delta:float)->void:
	if onboarding:onboarding.tick()
	visual_time+=delta
	_industry_tick(delta)
	for i in range(animators.size()-1,-1,-1):
		var item:Dictionary=animators[i]
		if not is_instance_valid(item.node):animators.remove_at(i);continue
		if item.kind=="Turret":pass # Defense targeting controls turret rotation.
		elif item.kind=="Drill":item.node.rotation.y+=delta*1.2
		elif item.kind=="Rotor":item.node.rotation.y+=delta*.45
		elif item.kind=="Radar":item.node.rotation.y+=delta*.3
	for i in scouts.size():
		var a:=visual_time*.075+i*TAU/3
		scouts[i].position=Vector3(cos(a)*18,5.3+sin(a*2)*.35,sin(a)*13)
		scouts[i].rotation.y=-a+PI
	if selection_ring.visible:selection_ring.rotation.y+=delta*.25
	if landing_marker.visible:landing_marker.scale=Vector3.ONE*(1.0+.025*sin(visual_time*3.0))

func _laser(from:Vector3,to:Vector3)->void:
	var beam:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new();mesh.top_radius=.10;mesh.bottom_radius=.10;mesh.height=from.distance_to(to);mesh.radial_segments=6
	beam.mesh=mesh;beam.material_override=art.mat(Color("88f7e4"),true)
	world_root.add_child(beam);beam.position=(from+to)*.5
	var direction:=(to-from).normalized()
	var axis:=Vector3.UP.cross(direction)
	if axis.length()>0.001:beam.quaternion=Quaternion(axis.normalized(),acos(clampf(Vector3.UP.dot(direction),-1,1)))
	elif direction.y<0:beam.rotation.x=PI
	var tw:=create_tween();tw.tween_interval(.18);tw.tween_callback(beam.queue_free)

func _home_action()->void:
	if not has_colony:return
	if mode=="base":_center_camera()
	elif mode in ["battle","victory"]:_return_home()


func _found_colony(planet:int)->void:
	if has_colony or planet<0 or planet>=15:return
	colony_time=Time.get_unix_time_from_system()
	home_planet=planet;has_colony=true;tutorial_step=0;tutorial_dismissed=false
	credits=3000;metal=10000;oil=1000;crystal=500;power=0
	_save_profile();onboarding.enter_colony()

func _build_lock_reason(kind:int)->String:
	if kind<0 or kind>=BUILDING_NAMES.size():return "Unknown structure."
	if _builder_busy():return "Construction drone busy."
	if kind>=14 and kind<=17:
		if tutorial_step<11:return "Complete the Core upgrade mission"
		if kind>14 and building_levels[14]==0:return "Build a Godot Citadel first"
		if kind>15 and building_levels[15]==0:return "Build an Astral Well first"
	if kind in [18,19,20]:
		var count:=0
		for b in buildings:
			if b.type==kind:count+=1
		if count>=3:return "Maximum 3 camps of this type."
	if kind==0 and building_levels[0]>0:return "Your colony already has a Galactic Core."
	if kind<10 and tutorial_step<10 and kind!=BUILD_ORDER[tutorial_step]:return "Next: "+BUILDING_NAMES[BUILD_ORDER[tutorial_step]]
	if kind>=10 and building_levels[3]==0:return "Complete an Oil Processor first."
	if kind==0:
		for b in buildings:
			if b.type==0:return "Your colony already has a Galactic Core."
	if kind<10 and tutorial_step<10:
		for b in buildings:
			if b.type==kind:return "This mission building is under construction."
	if kind!=0 and building_levels[0]==0:return "Build the Galactic Core first."
	if kind not in [0,1] and building_levels[1]==0:return "Build a Fusion Reactor first."
	if POWER_DEMAND[kind]>power:return "Upgrade or build a Fusion Reactor for more Power."
	return ""

func _recalculate_colony()->void:
	building_levels.fill(0);power=0
	for b in buildings:
		if b.get("job","")=="build":power-=POWER_DEMAND[b.type];continue
		building_levels[b.type]=maxi(building_levels[b.type],b.level)
		if b.type in [1,15]:power+=(300 if b.type==1 else 220)*b.level
		else:power-=POWER_DEMAND[b.type]

func _refresh_progress()->void:
	_recalculate_colony()
	while tutorial_step<10 and building_levels[BUILD_ORDER[tutorial_step]]>0:tutorial_step+=1
	if tutorial_step==10 and building_levels[0]>=2:tutorial_step=11
	if tutorial_step==11 and unit_stock[0]>=8:tutorial_step=12
	var build_open:=build_panel.visible
	var units_open:=units_panel.visible
	var galaxy_open:=galaxy_panel.visible
	for p in [build_panel,units_panel,galaxy_panel]:p.hide();p.queue_free()
	build_panel=_make_build_panel();ui_root.add_child(build_panel);build_panel.visible=build_open
	units_panel=_make_units_panel();ui_root.add_child(units_panel);units_panel.visible=units_open
	galaxy_panel=_make_galaxy_panel();ui_root.add_child(galaxy_panel);galaxy_panel.visible=galaxy_open
	dock.get_child(0).disabled=mode!="base"
	dock.get_child(1).disabled=mode!="base" or tutorial_step<11
	dock.get_child(2).disabled=mode!="base" or tutorial_step<12
	_layout_ui();_update_top_bar();_update_landing_marker()
	if onboarding:
		# Modal onboarding stays above rebuilt menus.
		ui_root.move_child(onboarding.screen,-1)
		ui_root.move_child(onboarding.guide,-1)
		onboarding.refresh_guide()

func _update_landing_marker()->void:
	var active:=has_colony and mode=="base" and tutorial_step<10 and not _builder_busy()
	landing_marker.visible=active;landing_label.visible=active
	if not active:return
	var kind:int=BUILD_ORDER[tutorial_step]
	landing_marker.position=LANDING_SITES[kind]+Vector3(0,.14,0)
	landing_label.position=LANDING_SITES[kind]+Vector3(0,1.2,0)
	landing_label.text=BUILDING_NAMES[kind].to_upper()+"\n"+("TAP HERE TO BUILD" if build_type==kind else "LANDING SITE")

func _ensure_roads()->void:
	if roads_root or buildings.is_empty():return
	roads_root=Node3D.new();home_root.add_child(roads_root);art.roads(roads_root)

func _save_profile()->bool:
	if not has_colony or not profile_ready:return false
	var records:Array=[]
	for b in buildings:records.append({"type":b.type,"level":b.level,"pos":[b.pos.x,0,b.pos.z],"job":b.get("job",""),"started":b.get("started",0),"finish":b.get("finish",0)})
	var data:Dictionary={"schema":1,"ad_rewards":rewarded_ads.save_state() if rewarded_ads else {},"drone_producer":drone_producer,"miner_producer":miner_producer,"godot_coins":godot_coins,"last_coin_day":last_coin_day,"cleared_obstacles":cleared_obstacles,"clearing_jobs":clearing_jobs,"gold":gold,"drone_count":drone_count,"miner_count":miner_count,"drone_finish":drone_finish,"miner_finish":miner_finish,"colony_time":colony_time,"training_queue":training_queue,"home_planet":home_planet,"tutorial_step":tutorial_step,"tutorial_dismissed":tutorial_dismissed,"resources":[credits,metal,oil,crystal],"unit_stock":Array(unit_stock),"buildings":records}
	if not profile_store.write_profile(profile_path,data):_toast("Could not save progress. Free some device storage and try again.");return false
	return true

func _load_profile()->void:
	var data:Dictionary=profile_store.read_profile(profile_path)
	if data.is_empty():return
	rewarded_ads.load_state(data.get("ad_rewards",{}))
	drone_producer=int(data.get("drone_producer",-1));miner_producer=int(data.get("miner_producer",-1))
	godot_coins=int(data.get("godot_coins",0));last_coin_day=int(data.get("last_coin_day",-1));cleared_obstacles=data.get("cleared_obstacles",[]);clearing_jobs=data.get("clearing_jobs",[])
	drone_finish=float(data.get("drone_finish",0))
	gold=float(data.get("gold",0));drone_count=int(data.get("drone_count",1));miner_count=int(data.get("miner_count",0));miner_finish=float(data.get("miner_finish",0))
	has_colony=true;home_planet=int(data.home_planet);tutorial_step=int(data.tutorial_step);tutorial_dismissed=bool(data.get("tutorial_dismissed",false))
	credits=float(data.resources[0]);metal=float(data.resources[1]);oil=float(data.resources[2]);crystal=float(data.resources[3]);unit_stock=PackedInt32Array(data.unit_stock);unit_stock.resize(UNIT_NAMES.size())
	colony_time=float(data.get("colony_time",Time.get_unix_time_from_system()))
	training_queue=data.get("training_queue",[])
	for b in data.buildings:
		var placed:Dictionary=_spawn_building(home_root,int(b.type),Vector3(b.pos[0],0,b.pos[2]),int(b.level),false)
		if b.get("job","")!="":
			for key in ["job","started","finish"]:placed[key]=b[key]
			_add_work_marker(placed)
	for job in training_queue:
		if not job.has("producer"):job["producer"]=_producer_for(UNIT_FACILITY[int(job.type)])
	if drone_finish>0 and drone_producer<0:drone_producer=_producer_for(6)
	if miner_finish>0 and miner_producer<0:miner_producer=_producer_for(12)
	_advance_colony(maxf(colony_time,Time.get_unix_time_from_system()))
	_recalculate_colony();_ensure_roads()

func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_PAUSED:app_paused=true
	if what==NOTIFICATION_APPLICATION_RESUMED:app_paused=false
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST:_save_profile()
	if what==NOTIFICATION_APPLICATION_RESUMED and has_colony:_advance_colony(maxf(colony_time,Time.get_unix_time_from_system()));_save_profile()

func _exit_tree()->void:
	_save_profile()

func _builder_busy()->bool:
	var busy:=clearing_jobs.size()
	for b in buildings:
		if b.get("job","")!="":busy+=1
	return busy>=drone_count

func _add_work_marker(b:Dictionary)->void:
	var label:=Label3D.new();label.font_size=42;label.pixel_size=.018;label.outline_size=8
	label.position=Vector3(0,6,0);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("ffd483");b.node.add_child(label);label.top_level=true;label.global_position=b.node.global_position+Vector3(0,6,0);b["work_marker"]=label
	if b.job=="build":b.node.scale=Vector3(1,.2,1)

func _advance_colony(now:float)->void:
	if not has_colony:return
	if colony_time<=0:colony_time=now;return
	var changed:=false
	var economy_start:float=maxf(colony_time,now-8*3600)
	while colony_time<now:
		var next:float=now
		for job in clearing_jobs:next=minf(next,maxf(colony_time,float(job.finish)))
		if drone_finish>0:next=minf(next,maxf(colony_time,drone_finish))
		if miner_finish>0:next=minf(next,maxf(colony_time,miner_finish))
		for b in buildings:
			if b.get("job","")!="":next=minf(next,maxf(colony_time,float(b.finish)))
		if not training_queue.is_empty():next=minf(next,maxf(colony_time,float(training_queue[0].finish)))
		_economy_tick(maxf(0,next-maxf(colony_time,economy_start)))
		colony_time=next
		for i in range(clearing_jobs.size()-1,-1,-1):
			if float(clearing_jobs[i].finish)<=colony_time:
				var job:Dictionary=clearing_jobs.pop_at(i)
				coin_system.complete_clear(job);changed=true
		if drone_finish>0 and drone_finish<=colony_time:drone_count+=1;drone_finish=0;changed=true
		if miner_finish>0 and miner_finish<=colony_time:miner_count+=1;miner_finish=0;changed=true
		for b in buildings:
			if b.get("job","")!="" and float(b.finish)<=colony_time:
				if b.job=="upgrade":b.level+=1
				b["job"]="";b.node.scale=Vector3.ONE*(1+(b.level-1)*.025)
				b.max_hp=350.0+b.level*120.0;b.hp=b.max_hp
				if is_instance_valid(b.get("work_marker")):b.work_marker.queue_free();b.erase("work_marker")
				changed=true
		while not training_queue.is_empty() and float(training_queue[0].finish)<=colony_time:
			unit_stock[int(training_queue.pop_front().type)]+=1;changed=true
	if changed:
		_refresh_progress();_setup_life();_sync_industry_visuals()
		if profile_ready:_save_profile()

func _update_work_display()->void:
	if not is_instance_valid(work_label):return
	work_label.visible=mode=="base" or (mode=="battle" and awaiting_deployment)
	if mode=="battle" and awaiting_deployment:
		work_label.text="Select type + squad size • Tap separate map edges • ATTACK when ready"
		work_label.position=Vector2(24,get_viewport().get_visible_rect().size.y-150)
		work_label.size=Vector2(get_viewport().get_visible_rect().size.x-48,32)
		return
	var lines:Array[String]=[]
	for job in clearing_jobs:lines.append("DRONE: CLEARING • %ds"%maxi(0,ceili(float(job.finish)-colony_time)))
	for b in buildings:
		if b.get("job","")=="":continue
		var left:int=maxi(0,int(ceil(float(b.finish)-colony_time)))
		var progress:float=clampf((colony_time-float(b.started))/maxf(1,float(b.finish)-float(b.started)),0,1)
		if b.job=="build":b.node.scale=Vector3(1,.2+.8*progress,1)
		if is_instance_valid(b.get("work_marker")):b.work_marker.hide();b.work_marker.text="%s %d%% • %ds"%[str(b.job).to_upper(),int(progress*100),left]
		lines.append("DRONE: %s • %ds"%[BUILDING_NAMES[b.type],left])
	if not training_queue.is_empty():lines.append("TRAINING: %s • %ds • %d queued"%[UNIT_NAMES[int(training_queue[0].type)],maxi(0,int(ceil(float(training_queue[0].finish)-colony_time))),training_queue.size()])
	var summary:="DRONES %d / 10 • "%drone_count
	if lines.size()>2:lines=[lines[0],"+%d more active jobs"%(lines.size()-1)]
	if drone_finish>0:summary+="NEW DRONE %ds • "%maxi(0,int(ceil(drone_finish-colony_time)))
	if miner_finish>0:summary+="MINER %ds • "%maxi(0,int(ceil(miner_finish-colony_time)))
	work_label.text=summary+"  |  ".join(lines)
	work_label.position=Vector2(24,get_viewport().get_visible_rect().size.y-145)
	work_label.size=Vector2(get_viewport().get_visible_rect().size.x-48,32)
	if selected_building>=0 and info_panel.visible:
		var b:Dictionary=buildings[selected_building]
		if b.get("job","")!="":selected_detail.text="%s in progress\n%s remaining"%[str(b.job).capitalize(),_duration(float(b.finish)-colony_time)]

func _begin_move()->void:
	if mode!="base" or selected_building<0:return
	if buildings[selected_building].get("job","")!="":_toast("Wait until this construction finishes.");return
	moving_building=selected_building;build_type=-1;_dismiss_menus()
	_toast("Tap clear terrain to relocate this structure for free.")

func _move_building(pos:Vector3)->void:
	if mode!="base" or moving_building<0:return
	pos=Vector3(snappedf(pos.x,1),0,snappedf(pos.z,1))
	var reason:=_placement_reason(pos)
	if not reason.is_empty():_toast(reason);return
	var b:Dictionary=buildings[moving_building];b.pos=pos;b.node.position=pos;moving_building=-1
	garrison.signature="";garrison.sync();_sync_industry_visuals();_save_profile();_dismiss_menus();_toast("Structure relocated.")

func _building_oil_cost(kind:int)->int:
	if kind>=18:return 100
	return [300,150,250,200][kind-14] if kind>=14 else (350 if kind==10 else (200 if kind==11 else 0))

func _buy_drone()->void:
	if not has_colony or mode!="base":return
	if _producer_for(6)<0 or buildings[_producer_for(6)].get("job","")!="":_toast("Complete a Star Hangar first.");return
	if drone_finish>0:_toast("Construction drone is in production.");return
	if drone_count>=10:_toast("Maximum 10 construction drones.");return
	var cost:int=DRONE_PRICES[drone_count-1]
	if gold<cost:_toast("Mine %d Gold to unlock the next drone."%cost);return
	gold-=cost;drone_producer=_producer_for(6);drone_finish=_facility_finish(6,drone_producer)+15
	_sync_industry_visuals();_refresh_progress();_save_profile()
	_dismiss_menus();_toast("Construction drone queued in Star Hangar #%d (15s)."%(drone_producer+1))

func _build_miner()->void:
	if mode!="base" or building_levels[10]==0:_toast("Complete a Gold Refinery first.");return
	if _producer_for(12)<0 or buildings[_producer_for(12)].get("job","")!="":_toast("Complete a Vehicle Factory first.");return
	if miner_finish>0:_toast("A mining vehicle is already in production.");return
	var capacity:=0
	for b in buildings:
		if b.type==10 and b.get("job","")!="build":capacity+=3
	if miner_count>=capacity:_toast("Build another refinery for more mining vehicles.");return
	if metal<600 or oil<150:_toast("Mining vehicle costs 600 Metal and 150 Oil.");return
	metal-=600;oil-=150;miner_producer=_producer_for(12);miner_finish=_facility_finish(12,miner_producer)+15
	_save_profile();_dismiss_menus();_toast("Mining vehicle queued in factory #%d (15s)."%(miner_producer+1))

func _sync_industry_visuals()->void:
	for n in industry_visuals:
		if is_instance_valid(n):n.queue_free()
	industry_visuals.clear()
	var refineries:Array[Vector3]=[]
	for b in buildings:
		if b.type==10 and b.get("job","")!="build":refineries.append(b.pos)
	for i in mini(miner_count,refineries.size()*3):
		var truck:Node3D=art.model("mining_vehicle");home_root.add_child(truck)
		truck.set_meta("origin",refineries[floori(i/3.0)]);industry_visuals.append(truck)
	while drone_visuals.size()<drone_count:
		var drone:Node3D=art.model("construction_drone");home_root.add_child(drone);drone_visuals.append(drone)

func _industry_tick(_delta:float)->void:
	var jobs:Array[Vector3]=[]
	for job in clearing_jobs:jobs.append(Vector3(job.pos[0],0,job.pos[2]))
	for b in buildings:
		b.node.visible=b.pos.distance_to(camera_focus)<85
		_update_rank_label(b)
		if b.get("job","")!="":jobs.append(b.pos)
	for i in drone_visuals.size():
		var base:Vector3=jobs[i] if i<jobs.size() else Vector3((i%5)*1.5-3,0,-5-floori(i/5.0)*2)
		var a:float=visual_time+i
		drone_visuals[i].position=drone_visuals[i].position.move_toward(base+Vector3(cos(a)*2,4.5+sin(a)*.3,sin(a)*2),maxf(0,_delta)*25)
		drone_visuals[i].rotation.y=-a
	coin_system.tick()
	for i in industry_visuals.size():
		var origin:Vector3=industry_visuals[i].get_meta("origin")
		var phase:float=fmod(colony_time+i*6.0,20.0)/20.0
		var distance:float=1.0-absf(phase*2-1)
		industry_visuals[i].position=origin+Vector3(3+i%3,0,3+distance*8)
		industry_visuals[i].rotation.y=0 if phase<.5 else PI

func _defense_tick(defenders:Array,attackers:Array,delta:float,difficulty:int)->void:
	for tower in defenders:
		if not _can_fire(tower):continue
		if not is_instance_valid(tower.node):continue
		tower["fire_wait"]=float(tower.get("fire_wait",0))-delta
		var target:Dictionary={}
		var range_limit:float=_weapon_range(tower)
		for unit in attackers:
			if unit.get("hp",0)<=0 or not is_instance_valid(unit.node):continue
			var distance:float=tower.pos.distance_to(unit.node.position)
			if distance<range_limit:range_limit=distance;target=unit
		if target.is_empty():continue
		var turret:Node3D=tower.node.find_child("Turret",true,false)
		if turret:
			var point:Vector3=target.node.global_position;point.y=turret.global_position.y
			if turret.global_position.distance_to(point)>.01:turret.look_at(point,Vector3.UP,true)
		if float(tower.fire_wait)>0:continue
		tower["fire_wait"]=2.0 if tower.type==11 else 1.2
		var damage:float=_shot_damage(tower,difficulty)
		target.hp-=damage
		_weapon_effect(tower.node.global_position+Vector3(0,3,0),target.node,target.node.global_position,tower.type==11,tower.type>=14)
		if target.hp<=0:_destroy_entity(target,false)

func _start_defense_drill()->void:
	if mode!="base" or not home_attackers.is_empty():return
	var ready:=false
	for b in buildings:
		if _can_fire(b):ready=true;break
	if not ready:_toast("Complete a defense tower or upgrade any building to 5 stars.");return
	build_panel.hide();onboarding.refresh_guide()
	var center:=Vector3.ZERO
	for b in buildings:
		if _can_fire(b):center=b.pos;break
	for i in 3:
		var n:Node3D=_unit_model(0,true);home_root.add_child(n)
		n.position=center+Vector3(-4+i*4,3,11)
		home_attackers.append({"node":n,"type":0,"hp":20.0,"max_hp":20.0,"target":center})
	camera_focus=center;_position_camera()
	_toast("DEFENSE DRILL: towers auto-target approaching enemies. No colony damage.")

func _home_defense_tick(delta:float)->void:
	_defense_tick(buildings,home_attackers,delta,home_planet+1)
	for i in range(home_attackers.size()-1,-1,-1):
		var enemy:Dictionary=home_attackers[i]
		if enemy.hp<=0 or not is_instance_valid(enemy.node):home_attackers.remove_at(i);continue
		var target:Vector3=enemy.target+Vector3(0,3,0)
		enemy.node.position=enemy.node.position.move_toward(target,delta*.65)
		if enemy.node.position.distance_to(target)<1:
			enemy.node.queue_free();home_attackers.remove_at(i);_toast("Drill: enemy breached the perimeter. Add or upgrade defenses.")

func _rank_text(level:int)->String:
	return "★".repeat(level) if level<=5 else "★ × %d"%level

func _update_rank_label(b:Dictionary)->void:
	if not is_instance_valid(b.get("rank_label")):return
	b.rank_label.text="CONSTRUCTING" if b.get("job","")=="build" else _rank_text(int(b.level))
	b.rank_label.global_position=b.node.global_position+Vector3(0,5.2*(1+(b.level-1)*.025),0)

func _can_fire(b:Dictionary)->bool:
	return b.hp>0 and b.get("job","")!="build" and (b.type in [8,11,17] or b.level>=5)

func _weapon_range(b:Dictionary)->float:
	return (19.0 if b.type in [11,17] else 12.0)+minf(6.0,b.level*.3)

func _shot_damage(b:Dictionary,difficulty:int)->float:
	var base:float=2.0+difficulty*.8+b.level*.3
	var veteran_bonus:float=maxf(0,b.level-4)*1.5
	return (base+veteran_bonus)*(2.0 if b.type==11 else (1.6 if b.type==17 else 1.0))

func _active_units()->int:
	var count:=0
	for unit in battle_units:
		if unit.get("hp",0)>0:count+=1
	return count

func _reserve_count()->int:
	var count:=0
	for kind in raid_stock.size():count+=raid_stock[kind]-deployed_stock[kind]
	return count

func _build_reserve_panel()->void:
	if is_instance_valid(reserve_panel):reserve_panel.queue_free()
	reserve_buttons.clear()
	reserve_panel=PanelContainer.new();reserve_panel.add_theme_stylebox_override("panel",_style(Color("102832"),12,Color("517582"),1));ui_root.add_child(reserve_panel)
	var column:=VBoxContainer.new();reserve_panel.add_child(column)
	var title:=Label.new();title.text="REINFORCEMENTS";title.add_theme_font_size_override("font_size",19);column.add_child(title)
	var scroll:=preload("res://scripts/touch_scroll.gd").new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
	var cards:=VBoxContainer.new();cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(cards)
	for kind in UNIT_NAMES.size():
		if raid_stock[kind]<=0:continue
		var button:=_button(UNIT_NAMES[kind],func(k=kind):deploy_kind=k;deploy_picker.select(k);_refresh_deployment(),Vector2(240,82))
		button.icon=_unit_icon(kind);button.add_theme_font_size_override("font_size",15);cards.add_child(button);reserve_buttons[kind]=button
	column.add_child(_button("RETREAT",_return_home,Vector2(240,48)))

func _show_deployment()->void:
	if is_instance_valid(deployment_bar):deployment_bar.queue_free()
	deployment_bar=HBoxContainer.new();deployment_bar.add_theme_constant_override("separation",10);ui_root.add_child(deployment_bar)
	deploy_picker=OptionButton.new();deploy_picker.custom_minimum_size=Vector2(300,64);deploy_picker.add_theme_font_size_override("font_size",20)
	deployment_bar.add_child(deploy_picker)
	for kind in UNIT_NAMES.size():
		deploy_picker.add_icon_item(_unit_icon(kind),UNIT_NAMES[kind],kind)
	deploy_picker.select(deploy_kind)
	deploy_picker.item_selected.connect(func(index:int):deploy_kind=index;_refresh_deployment())
	var quantity:=OptionButton.new();quantity.custom_minimum_size=Vector2(170,64);quantity.add_theme_font_size_override("font_size",20)
	for count in [1,4,8,24,0]:quantity.add_item("ALL RESERVES" if count==0 else "SQUAD %d"%count,count)
	quantity.select(2);quantity.item_selected.connect(func(index:int):deploy_count=quantity.get_item_id(index))
	deployment_bar.add_child(quantity)
	deployment_bar.add_child(_button("UNDO SQUAD",_undo_squad,Vector2(180,64)))
	deployment_bar.add_child(_button("ATTACK",_launch_assault,Vector2(160,64)))
	deploy_status=Label.new();deploy_status.add_theme_font_size_override("font_size",20);deployment_bar.add_child(deploy_status)
	_build_reserve_panel()
	dock.hide();_refresh_deployment()

func _refresh_deployment()->void:
	if not is_instance_valid(deployment_bar):return
	if raid_stock[deploy_kind]-deployed_stock[deploy_kind]<=0:
		for kind in UNIT_NAMES.size():
			if raid_stock[kind]>deployed_stock[kind]:deploy_kind=kind;deploy_picker.select(kind);break
	deployment_bar.position=Vector2(24,get_viewport().get_visible_rect().size.y-85)
	for kind in UNIT_NAMES.size():
		var available:int=raid_stock[kind]-deployed_stock[kind]
		deploy_picker.set_item_text(kind,"%s (%d)"%[UNIT_NAMES[kind],available])
		deploy_picker.set_item_disabled(kind,available<=0)
	deployment_bar.get_child(2).visible=awaiting_deployment
	deployment_bar.get_child(3).visible=awaiting_deployment
	deploy_status.text="%d ACTIVE / %d RESERVE"%[_active_units(),_reserve_count()]
	for kind in reserve_buttons:
		var remaining:int=raid_stock[kind]-deployed_stock[kind]
		reserve_buttons[kind].text="%s  ×%d"%[UNIT_NAMES[kind],remaining]
		reserve_buttons[kind].disabled=remaining<=0
		reserve_buttons[kind].modulate=Color("76f5dc") if kind==deploy_kind else Color.WHITE
	if is_instance_valid(reserve_panel):
		var screen:=get_viewport().get_visible_rect().size
		reserve_panel.position=Vector2(screen.x-284,104);reserve_panel.size=Vector2(260,screen.y-205)

func _undo_squad()->void:
	if not awaiting_deployment or deployment_groups.is_empty():return
	var amount:int=deployment_groups.pop_back()
	for i in amount:
		var unit:Dictionary=battle_units.pop_back();deployed_stock[unit.type]-=1;unit.node.queue_free()
	_refresh_deployment()

func _launch_assault()->void:
	if mode!="battle" or not awaiting_deployment:return
	if battle_units.is_empty():_toast("Place at least one squad first.");return
	awaiting_deployment=false
	if is_instance_valid(deployment_bar):deployment_bar.hide()
	for kind in UNIT_NAMES.size():unit_stock[kind]-=deployed_stock[kind]
	_save_profile()
	deployment_bar.show();_refresh_deployment()
	dock.hide();_toast("ATTACK — tap an edge to deploy reserves!")

func _weapon_effect(origin:Vector3,target:Node3D,destination:Vector3,rocket:bool,arcane:bool=false)->void:
	if not rocket and not arcane:_laser(origin,destination);return
	if missiles.size()>=64:return
	var body:=MeshInstance3D.new();var shape:=SphereMesh.new();shape.radius=.16;shape.height=.6;body.mesh=shape
	body.material_override=art.mat(Color("c887ff") if arcane else Color("ffd57a"),true);world_root.add_child(body);body.position=origin
	var exhaust:=MeshInstance3D.new();var plume:=SphereMesh.new();plume.radius=.12;plume.height=.75;exhaust.mesh=plume
	exhaust.material_override=art.mat(Color("7cf4ed") if arcane else Color("ff692f"),true);body.add_child(exhaust);exhaust.position.y=-.4
	missiles.append({"node":body,"target":target,"destination":destination,"age":0.0,"context":mode,"arcane":arcane})

func _projectile_tick(delta:float)->void:
	for i in range(missiles.size()-1,-1,-1):
		var rocket:Dictionary=missiles[i]
		if rocket.context!=mode or not is_instance_valid(rocket.node):
			if is_instance_valid(rocket.node):rocket.node.queue_free()
			missiles.remove_at(i);continue
		rocket.age+=delta
		if is_instance_valid(rocket.target):rocket.destination=rocket.target.global_position+Vector3(0,.8,0)
		var direction:Vector3=rocket.destination-rocket.node.position
		if direction.length()<.5 or rocket.age>4:
			var flash:=_sphere(.35,art.mat(Color("c887ff") if rocket.get("arcane",false) else Color("ffd28a"),true));world_root.add_child(flash);flash.position=rocket.node.position
			var fade:=create_tween();fade.tween_property(flash,"scale",Vector3.ONE*2.2,.15);fade.tween_callback(flash.queue_free)
			rocket.node.queue_free();missiles.remove_at(i);continue
		rocket.node.position=rocket.node.position.move_toward(rocket.destination,delta*24)
		var axis:=Vector3.UP.cross(direction.normalized())
		if axis.length()>.001:rocket.node.quaternion=Quaternion(axis.normalized(),acos(clampf(Vector3.UP.dot(direction.normalized()),-1,1)))

func _clear_missiles()->void:
	for rocket in missiles:
		if is_instance_valid(rocket.node):rocket.node.queue_free()
	missiles.clear()

func _unit_asset(kind:int)->String:
	if kind==23:return "attack_pigeon"
	if kind>=20:return ["rune_guardian","crystal_golem","starweaver"][kind-20]
	return "fighter" if kind<10 else GROUND_ASSETS[kind-10]

func _unit_height(kind:int)->float:
	if _is_air_unit(kind):return 3.2
	if kind in [16,17]:return 1.4
	return .03

func _attack_range(kind:int)->float:
	if _is_air_unit(kind):return 2.5
	if kind in [12,13,15,22]:return 12.0
	return 7.0 if kind in [10,11,14] else 5.5

func _unit_icon(kind:int)->Texture2D:
	var asset:=_unit_asset(kind)
	if unit_icon_cache.has(asset):return unit_icon_cache[asset]
	if not ResourceLoader.exists("res://assets/icons/units/"+asset+".png"):return null
	var texture:Texture2D=load("res://assets/icons/units/"+asset+".png")
	var img:=texture.get_image();img.resize(52,44,Image.INTERPOLATE_LANCZOS)
	var icon:=ImageTexture.create_from_image(img);unit_icon_cache[asset]=icon
	return icon

func _animate_unit(unit:Dictionary,delta:float,moving:bool,target:Vector3)->void:
	var parts:Dictionary=unit.node.get_meta("parts",{})
	unit["walk_phase"]=float(unit.get("walk_phase",0))+delta*(7 if unit.type==14 else 11)
	var stride:float=sin(float(unit.walk_phase))*.45 if moving else 0.0
	if parts.has("LeftLeg"):parts.LeftLeg.rotation.x=stride
	if parts.has("RightLeg"):parts.RightLeg.rotation.x=-stride
	if parts.has("LeftArm"):parts.LeftArm.rotation.x=-stride*.35
	if parts.has("RightArm"):parts.RightArm.rotation.x=stride*.35
	if parts.has("Rotor"):parts.Rotor.rotation.y+=delta*2
	if parts.has("LeftWing"):
		parts.LeftWing.rotation.z=sin(float(unit.walk_phase)*1.8)*.65
		parts.RightWing.rotation.z=-parts.LeftWing.rotation.z
	if parts.has("Turret"):
		var aim:Vector3=target;aim.y=parts.Turret.global_position.y
		if parts.Turret.global_position.distance_to(aim)>.01:parts.Turret.look_at(aim,Vector3.UP,true)

func _fire_animation(model:Node3D)->void:
	var parts:Dictionary=model.get_meta("parts",{})
	if not parts.has("Weapon"):return
	var old:Tween=model.get_meta("recoil_tween") if model.has_meta("recoil_tween") else null
	if old and old.is_valid():old.kill()
	var rest:Vector3=model.get_meta("weapon_rest")
	parts.Weapon.position=rest+Vector3(0,0,.16 if model.get_meta("airborne",false) else -.16)
	var recoil:=model.create_tween();recoil.tween_property(parts.Weapon,"position",rest,.22)
	model.set_meta("recoil_tween",recoil)

func _muzzle_flash(pos:Vector3)->void:
	var flash:=_sphere(.18,art.mat(Color("ffe8a8"),true));world_root.add_child(flash);flash.position=pos
	var fade:=flash.create_tween();fade.tween_property(flash,"scale",Vector3.ONE*.05,.12);fade.tween_callback(flash.queue_free)

func _destroy_entity(entity:Dictionary,structure:bool)->void:
	if entity.get("dying",false) or not is_instance_valid(entity.node):return
	entity["dying"]=true;entity.hp=0
	var model:Node3D=entity.node
	var pos:Vector3=model.global_position
	_explode(pos)
	var group:=Node3D.new();group.name="StructureWreck" if structure else "UnitWreck";wreck_root.add_child(group)
	model.reparent(group,true)
	for label in model.find_children("*","Label3D",true,false):label.hide()
	for i in range(animators.size()-1,-1,-1):
		if is_instance_valid(animators[i].node) and model.is_ancestor_of(animators[i].node):animators.remove_at(i)
	var recoil:Tween=model.get_meta("recoil_tween") if model.has_meta("recoil_tween") else null
	if recoil and recoil.is_valid():recoil.kill()
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		# Energy fields and halo quads are effects, never solid wreck geometry.
		if mesh.material_override is ShaderMaterial:mesh.hide()
		else:mesh.material_override=art.mat(Color("41444b"))
	var duration:=1.1 if structure else .55
	var collapse:=model.create_tween().set_parallel(true)
	var crushed:Vector3=model.scale*Vector3(1.05,.23 if structure else .6,1.05)
	collapse.tween_property(model,"scale",crushed,duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collapse.tween_property(model,"rotation:z",.12 if structure else .7,duration)
	collapse.tween_property(model,"position:y",.03,duration)
	var fire:=art.particles(group,Vector3(pos.x,1.4 if structure else .8,pos.z),Color("ff9438"),false,false)
	fire.direction=Vector3.UP;fire.spread=25;fire.gravity=Vector3(0,.8,0);fire.initial_velocity_min=.5;fire.initial_velocity_max=1.8
	fire.amount=12;fire.scale_amount_min=.45;fire.scale_amount_max=.85
	var smoke:=art.particles(group,Vector3(pos.x,2.2 if structure else 1.2,pos.z),Color("42464c"),true,false)
	smoke.amount=12;smoke.scale_amount_min=.45;smoke.scale_amount_max=1.35;smoke.initial_velocity_max=1.4
	for i in (7 if structure else 3):
		var piece:=_box(Vector3(.35,.2,.45),art.mat(Color("60636c")));group.add_child(piece);piece.global_position=pos+Vector3.UP
		_fling_debris(piece,Vector3(cos(i*2.4),0,sin(i*2.4))*(2.0+i*.3))
	var expiry:=group.create_tween();expiry.tween_interval(5);expiry.tween_callback(func():fire.emitting=false)
	expiry.tween_interval(3);expiry.tween_callback(func():smoke.emitting=false)
	expiry.tween_interval(4);expiry.tween_callback(group.queue_free)
	while wreck_root.get_child_count()>12:
		var oldest:=wreck_root.get_child(0);wreck_root.remove_child(oldest);oldest.queue_free()

func _fling_debris(piece:Node3D,offset:Vector3)->void:
	var origin:=piece.position
	var fly:=piece.create_tween()
	fly.tween_method(func(t:float):
		piece.position=origin+offset*t+Vector3(0,sin(t*PI)*2.5-origin.y*t,0)
		piece.rotation=Vector3(t*4,t*3,t*2)
	,0.0,1.0,.9)

func _clear_wrecks()->void:
	for child in wreck_root.get_children():wreck_root.remove_child(child);child.queue_free()

func _dismiss_menus()->void:
	for panel in [build_panel,units_panel,info_panel,galaxy_panel]:
		if is_instance_valid(panel):panel.hide()
	if coin_system and is_instance_valid(coin_system.panel):coin_system.panel.hide()
	if rewarded_ads and is_instance_valid(rewarded_ads.result_panel):rewarded_ads.result_panel.hide()
	if is_instance_valid(selection_ring):selection_ring.hide()
