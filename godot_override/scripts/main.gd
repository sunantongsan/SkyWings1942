extends Node3D

const BUILDING_NAMES := ["Galactic Core","Fusion Reactor","Metal Extractor","Oil Processor","Crystal Mine","Resource Vault","Star Hangar","Research Lab","Laser Tower","Shield Generator"]
const BUILDING_COST := [0,700,500,600,800,900,1200,1200,850,1300]
const UNIT_NAMES := ["Fighter","Interceptor","Bomber","Heavy Fighter","Stealth Fighter","Gunship","Missile Cruiser","Destroyer","Battle Cruiser","Carrier","Battle Tank","Siege Tank","Artillery","Rocket Launcher","Mech Warrior","Sniper Unit","Shield Drone","Repair Drone","Assault Soldier","Elite Commander"]
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
var credits:=3000.0
var metal:=10000.0
var oil:=1000.0
var crystal:=500.0
var power:=0.0
var mode:="base"
var map_index:=0
var selected_building:=-1
var build_type:=-1
var moving_building:=-1
var selected_unit:=0
var buildings:Array[Dictionary]=[]
var building_levels:=PackedInt32Array([0,0,0,0,0,0,0,0,0,0])
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
const BUILD_ORDER := [0,1,2,5,3,4,6,8,7,9]
const LANDING_SITES := [Vector3(0,0,0),Vector3(-7,0,-4),Vector3(-12,0,4),Vector3(10,0,6),Vector3(12,0,-5),Vector3(-2,0,10),Vector3(5,0,12),Vector3(4,0,-10),Vector3(-14,0,-8),Vector3(18,0,-11)]
const POWER_DEMAND := [0,0,20,30,25,10,40,35,25,35]
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
const BUILD_SECONDS := [8,15,20,25,30,25,40,45,30,45]
var colony_time := 0.0
var training_queue:Array = []
var work_label:Label


func _ready()->void:
	_setup_environment()
	_setup_world()
	_setup_camera()
	_setup_ui()
	onboarding=preload("res://scripts/onboarding.gd").new(self)
	_load_profile()
	_apply_map_theme(home_planet if has_colony else 0)
	_setup_life()
	profile_ready=true
	_refresh_progress()
	onboarding.welcome()

func _process(delta:float)->void:
	if has_colony:_advance_colony(maxf(colony_time,Time.get_unix_time_from_system()))
	if mode=="battle": _battle_tick(delta)
	_visual_tick(delta)
	autosave_time+=delta
	if autosave_time>=10.0:_save_profile();autosave_time=0.0
	top_refresh += delta
	if top_refresh > 0.15:
		_update_top_bar()
		_update_work_display()
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
	var colors:=[Color("ecc779"),Color("b4c8d6"),Color("edaa76"),Color("c995f2"),Color("82dec3")]
	for i in 5:
		var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",_style(Color("112a36"),12,Color("36505e"),1));header.add_child(card)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",0);card.add_child(column)
		var caption:=Label.new();caption.text=["CREDITS","METAL","OIL","CRYSTAL","POWER"][i];caption.add_theme_font_size_override("font_size",13);caption.modulate=colors[i];column.add_child(caption)
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
	info_panel=PanelContainer.new();info_panel.custom_minimum_size=Vector2(286,0);info_panel.visible=false
	info_panel.add_theme_stylebox_override("panel",_style(Color("112a36"),14,Color("75cabb"),1));ui_root.add_child(info_panel)
	var iv:=VBoxContainer.new();iv.add_theme_constant_override("separation",12);info_panel.add_child(iv)
	selected_label=Label.new();selected_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;selected_label.add_theme_font_size_override("font_size",23);iv.add_child(selected_label)
	selected_detail=Label.new();selected_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;selected_detail.add_theme_font_size_override("font_size",17);selected_detail.modulate=Color("a8c4cd");iv.add_child(selected_detail)
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
	var grid:=_scroll_grid(panel,5)
	for i in BUILD_ORDER:
		var b:=_asset_button(BUILDING_NAMES[i],"%s METAL • %ds"%[_fmt(BUILDING_COST[i]),BUILD_SECONDS[i]],"buildings/"+_building_file(i),Vector2(200,158))
		var reason:=_build_lock_reason(i)
		b.disabled=not reason.is_empty()
		if b.disabled:
			b.get_child(0).modulate=Color(.45,.55,.6)
			b.tooltip_text=reason
			b.get_child(0).get_child(b.get_child(0).get_child_count()-1).text="CORE ALREADY BUILT" if i==0 and building_levels[0]>0 else ("LOCKED • STEP %02d"%(BUILD_ORDER.find(i)+1) if tutorial_step<10 else "MORE POWER REQUIRED")
		b.pressed.connect(func(idx=i):_begin_build(idx));grid.add_child(b)
	return panel

func _make_units_panel()->PanelContainer:
	var panel:=_panel("STAR HANGAR / QUEUED %d OF 20"%training_queue.size())
	var grid:=_scroll_grid(panel,4)
	for i in 20:
		var cost:=180+i*35
		var b:=_asset_button(UNIT_NAMES[i],"Ready %d • %ds • %d C / %d O"%[unit_stock[i],5+i*2,cost,int(cost*.4)],"",Vector2(230,100))
		b.disabled=building_levels[6]==0 or tutorial_step<11 or (tutorial_step<13 and i!=0)
		if b.disabled:b.get_child(0).modulate=Color(.45,.55,.6)
		b.pressed.connect(func(idx=i):_train_unit(idx));grid.add_child(b)
	return panel

func _make_galaxy_panel()->PanelContainer:
	var panel:=_panel("GALAXY MAP / AI OUTPOSTS")
	var grid:=_scroll_grid(panel,5)
	for i in 15:
		var b:=_asset_button(MAP_NAMES[i],"Threat %02d  /  ATTACK"%(2+i*2),"",Vector2(200,130))
		b.add_theme_stylebox_override("normal",_style(MAP_ACCENT[i].darkened(0.82),12,MAP_ACCENT[i].darkened(0.35),1))
		if i==home_planet:
			b.disabled=true
			b.get_child(0).get_child(1).text="YOUR HOMEWORLD"
		b.pressed.connect(func(idx=i):_start_battle(idx));grid.add_child(b)
	return panel

func _building_file(i:int)->String:return ["galactic_core","fusion_reactor","metal_extractor","oil_processor","crystal_mine","resource_vault","star_hangar","research_lab","laser_tower","shield_generator"][i]

func _spawn_building(parent:Node3D,type:int,pos:Vector3,level:int,enemy:bool)->Dictionary:
	var root:Node3D=art.building(type,enemy)
	root.position=pos;parent.add_child(root)
	root.scale=Vector3.ONE*(1.0+(level-1)*.025)
	for part_name in ["Rotor","Radar","Drill","Turret"]:
		var part:Node3D=root.find_child(part_name,true,false)
		if part:animators.append({"node":part,"kind":part_name,"home":parent==home_root})
	if type==3: art.particles(root,Vector3(0,4.4,-.25),Color("9db4b6"),true,false)
	var d={"node":root,"type":type,"level":level,"pos":pos,"hp":350.0+level*120.0,"max_hp":350.0+level*120.0}
	if parent==home_root:buildings.append(d)
	return d

func _create_roads(parent:Node3D)->void:
	art.roads(parent)

func _create_decor(parent:Node3D,theme:int)->void:
	art.decor(parent,theme)

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

func _unit_model(type:int,enemy:=false)->Node3D:
	if type<=9:
		var ship:Node3D=art.model("fighter")
		ship.scale=Vector3.ONE*(0.5+type*.035)
		return ship
	var r:=Node3D.new();var accent:=Color("37d7ff") if not enemy else Color("ff4b3c");var base:=Color("505d6d")
	if type<=13:
		var ch:=_box(Vector3(2.2,.55,3.1),_mat(base));ch.position.y=.45;r.add_child(ch);var turret:=_cyl(.55,.55,.55,_mat(base.lightened(.07)));turret.position.y=.95;r.add_child(turret)
	elif type in [16,17]:
		var orb:=_sphere(.55,_mat(accent,accent,2.2,.8));orb.position.y=1;r.add_child(orb)
	else:
		var body:=_box(Vector3(.7,1.1,.45),_mat(base));body.position.y=1.1;r.add_child(body);var head:=_sphere(.35,_mat(accent.darkened(.2)));head.position.y=1.95;r.add_child(head)
	return r

func _begin_build(idx:int)->void:
	if mode!="base" or not has_colony:return
	var reason:=_build_lock_reason(idx)
	if not reason.is_empty():_toast(reason);return
	moving_building=-1
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
	if b.level>=100:_toast("Maximum level reached.");return
	var cost:int=500+int(b.type)*120+int(b.level)*360
	if metal<cost:_toast("NOT ENOUGH METAL");return
	if _builder_busy():_toast("Construction drone busy. Wait for the current job.");return
	metal-=cost
	b["job"]="upgrade";b["started"]=colony_time;b["finish"]=colony_time+30*b.level
	_add_work_marker(b)
	_refresh_progress();_save_profile();_select_building_at(b.pos)
	_toast("Upgrade started. The new level unlocks when construction finishes.")

func _train_unit(idx:int)->void:
	if mode!="base" or building_levels[6]==0 or tutorial_step<11:_toast("Build your colony and upgrade the Core first.");return
	if idx<0 or idx>=20:return
	if tutorial_step<13 and idx!=0:_toast("Train Fighters for your first mission.");return
	var c:=180+idx*35
	if credits<c or oil<c*.4:_toast("NOT ENOUGH RESOURCES");return
	if training_queue.size()>=20:_toast("Training queue full (20).");return
	credits-=c;oil-=c*.4;selected_unit=idx
	var start:float=colony_time if training_queue.is_empty() else float(training_queue.back().finish)
	training_queue.append({"type":idx,"finish":start+5+idx*2})
	_refresh_progress();_setup_life();_save_profile()
	units_panel.show();onboarding.refresh_guide()
	_toast("%s added to training queue (%d)."%[UNIT_NAMES[idx],training_queue.size()])

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
	_save_profile()
	mode="battle";battle_map=idx;galaxy_panel.visible=false;info_panel.hide();selection_ring.hide();home_root.visible=false;battle_root.visible=true
	for c in battle_root.get_children():c.queue_free()
	battle_targets.clear();battle_units.clear();battle_damage=0;battle_elapsed=0;_apply_map_theme(idx)
	var epos=[Vector3(0,0,-5),Vector3(-8,0,-1),Vector3(8,0,-1),Vector3(-5,0,5),Vector3(5,0,5),Vector3(-13,0,6),Vector3(13,0,6)];var etypes=[0,8,8,9,6,2,3]
	for i in epos.size():battle_targets.append(_spawn_building(battle_root,etypes[i],epos[i],2+idx/4,true))
	awaiting_deployment=true
	camera_focus=Vector3.ZERO;_position_camera();camera.size=44
	_toast("SCOUT THE AI BASE. Tap an outer edge to deploy your fleet.");_refresh_progress()

func _deploy_fleet(pos:Vector3)->void:
	if mode!="battle" or not awaiting_deployment:return
	if absf(pos.x)>22 or absf(pos.z)>20 or (absf(pos.x)<16 and absf(pos.z)<13):
		_toast("Deploy outside the enemy base, near the map edge.");return
	var roster:Array[int]=[]
	for kind in 20:
		for count in mini(unit_stock[kind],24-roster.size()):roster.append(kind)
	for i in roster.size():
		var kind:int=roster[i]
		var n:Node3D=_unit_model(kind,false)
		n.position=Vector3(clampf(pos.x+(i%6-2.5)*1.2,-22,22),3.2,clampf(pos.z+floori(i/6.0)*1.1,-20,20))
		battle_root.add_child(n);battle_units.append({"node":n,"type":kind,"damage":12.0+kind*1.5,"speed":2.7+kind*.08})
	awaiting_deployment=false
	_toast("FLEET DEPLOYED — %d units"%roster.size())

func _battle_tick(delta:float)->void:
	if awaiting_deployment:return
	battle_elapsed+=delta;var total:=0.0;var alive_hp:=0.0;var alive:Array=[]
	for e in battle_targets:
		total+=e.max_hp
		if e.hp>0:alive_hp+=e.hp;alive.append(e)
	battle_damage=100.0*(1.0-alive_hp/max(1.0,total))
	if alive.is_empty() or battle_elapsed>150:_finish_battle(alive.is_empty());return
	for u in battle_units:
		var n:Node3D=u.node
		if not is_instance_valid(n):continue
		var target:Dictionary=alive[0];var best:=Vector2(n.position.x,n.position.z).distance_to(Vector2(target.pos.x,target.pos.z))
		for e in alive:
			var d:=Vector2(n.position.x,n.position.z).distance_to(Vector2(e.pos.x,e.pos.z))
			if d<best:best=d;target=e
		if best>2.5:n.position=n.position.move_toward(Vector3(target.pos.x,n.position.y,target.pos.z),u.speed*delta);n.look_at(Vector3(target.pos.x,n.position.y,target.pos.z),Vector3.UP)
		else:
			if target.hp<=0:continue
			target.hp-=u.damage*delta*2.2
			if visual_time-float(u.get("last_shot",-1.0))>0.55:
				_laser(n.global_position+Vector3.UP,target.pos+Vector3(0,1.8,0))
				u["last_shot"]=visual_time
			if target.hp<=0 and is_instance_valid(target.node):_explode(target.node.global_position);target.node.queue_free()

func _finish_battle(win:bool)->void:
	if mode!="battle":return
	if win:
		mode="victory"
		var reward:=Vector4(8000+battle_map*700,4200+battle_map*350,2600+battle_map*220,900+battle_map*90);credits+=reward.x;metal+=reward.y;oil+=reward.z;crystal+=reward.w
		var l:Label=victory_panel.find_child("Reward",true,false);l.text="%s conquered\nDamage 100%%\n+%d Credits   +%d Metal   +%d Oil   +%d Crystal"%[MAP_NAMES[battle_map],int(reward.x),int(reward.y),int(reward.z),int(reward.w)];victory_panel.visible=true
		if tutorial_step==12:tutorial_step=13
		_save_profile()
	else:_return_home();_toast("FLEET WITHDREW")

func _return_home()->void:
	if not has_colony:return
	mode="base";victory_panel.hide();battle_root.hide();home_root.show()
	_apply_map_theme(home_planet);_center_camera();_refresh_progress();_save_profile();_toast("Returned to "+MAP_NAMES[home_planet]+".")

func _economy_tick(delta:float)->void:
	if not has_colony:return
	for b in buildings:
		if b.get("job","")=="build":continue
		match int(b.type):
			0:credits=minf(1e12,credits+delta*3.5*b.level)
			2:metal=minf(1e12,metal+delta*2.7*b.level)
			3:oil=minf(1e12,oil+delta*2.0*b.level)
			4:crystal=minf(1e12,crystal+delta*.9*b.level)

func _update_top_bar()->void:
	if resource_labels.size()!=5:return
	var values:=[credits,metal,oil,crystal,power]
	for i in 5:resource_labels[i].text=_fmt(values[i])
	status_label.text=(MAP_NAMES[maxi(home_planet,0)].to_upper()+"  /  HOME PLANET") if mode in ["base","welcome"] else "%s  /  %d%%"%[MAP_NAMES[battle_map].to_upper(),int(battle_damage)]

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
	var b:Dictionary=buildings[best];selected_label.text="%s • Lv.%d"%[BUILDING_NAMES[b.type],b.level];selected_detail.text="HP %d/%d\nUpgrade cost %d Metal\nMap theme: %s"%[int(b.hp),int(b.max_hp),500+b.type*120+b.level*360,MAP_NAMES[map_index]]

func _place_building(pos:Vector3)->void:
	if mode!="base" or not has_colony or build_type<0:return
	var reason:=_build_lock_reason(build_type)
	if not reason.is_empty():_toast(reason);return
	pos.x=snappedf(pos.x,1.0);pos.z=snappedf(pos.z,1.0)
	pos.y=0
	if abs(pos.x)>18 or abs(pos.z)>15:_toast("BUILD INSIDE THE BASE AREA");return
	for b in buildings:
		if b.pos.distance_to(pos)<6.1:_toast("TOO CLOSE TO ANOTHER BUILDING");return
	var cost:int=BUILDING_COST[build_type]
	if metal<cost:_toast("NOT ENOUGH METAL");return
	var kind:=build_type
	metal-=cost
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
	if galaxy_panel.visible or build_panel.visible or units_panel.visible or victory_panel.visible:return
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
	camera_focus.x=clampf(camera_focus.x,-18,18)
	camera_focus.z=clampf(camera_focus.z,-14,14)
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

func _pan(pos:Vector2,relative:Vector2)->void:
	var now=_ground_hit(pos)
	var before=_ground_hit(pos-relative)
	if now!=null and before!=null:camera_focus+=before-now;_clamp_camera()

func _tap_world(pos:Vector2)->void:
	if mode=="battle" and awaiting_deployment:
		var point=_ground_hit(pos)
		if point!=null:_deploy_fleet(point)
		return
	if mode!="base":return
	var h=_ground_hit(pos)
	if h!=null:
		if moving_building>=0:_move_building(h)
		elif build_type>=0:_place_building(h)
		else:_select_building_at(h)

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
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
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
	dock.position=Vector2((size.x-996)/2,size.y-80)
	info_panel.position=Vector2(size.x-margin-286,110);info_panel.size=Vector2(286,260)
	for panel in [build_panel,units_panel,galaxy_panel]:
		if panel:panel.position=Vector2(margin,105);panel.size=Vector2(size.x-margin*2,size.y-200)
	victory_panel.position=Vector2((size.x-720)/2,170);victory_panel.size=Vector2(720,330)
	toast.position=Vector2(margin,size.y-114);toast.size=Vector2(size.x-margin*2,28)
	if onboarding:onboarding.layout()

func _setup_life()->void:
	if building_levels[6]==0:return
	var count:=mini(3,unit_stock[0]+unit_stock[1]+unit_stock[2])
	for i in range(scouts.size(),count):
		var ship:Node3D=art.model("fighter");ship.scale=Vector3.ONE*.48
		home_root.add_child(ship);scouts.append(ship)

func _visual_tick(delta:float)->void:
	if onboarding:onboarding.tick()
	visual_time+=delta
	for i in range(animators.size()-1,-1,-1):
		var item:Dictionary=animators[i]
		if not is_instance_valid(item.node):animators.remove_at(i);continue
		if item.kind=="Turret":item.node.rotation.y=sin(visual_time*.4)*.85
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
	var mesh:=CylinderMesh.new();mesh.top_radius=.045;mesh.bottom_radius=.045;mesh.height=from.distance_to(to);mesh.radial_segments=6
	beam.mesh=mesh;beam.material_override=art.mat(Color("88f7e4"),true)
	world_root.add_child(beam);beam.position=(from+to)*.5
	var direction:=(to-from).normalized()
	var axis:=Vector3.UP.cross(direction)
	if axis.length()>0.001:beam.quaternion=Quaternion(axis.normalized(),acos(clampf(Vector3.UP.dot(direction),-1,1)))
	var tw:=create_tween();tw.tween_interval(.09);tw.tween_callback(beam.queue_free)

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
	if kind<0 or kind>=10:return "Unknown structure."
	if _builder_busy():return "Construction drone busy."
	if kind==0 and building_levels[0]>0:return "Your colony already has a Galactic Core."
	if tutorial_step<10 and kind!=BUILD_ORDER[tutorial_step]:return "Next: "+BUILDING_NAMES[BUILD_ORDER[tutorial_step]]
	if kind!=0 and building_levels[0]==0:return "Build the Galactic Core first."
	if kind not in [0,1] and building_levels[1]==0:return "Build a Fusion Reactor first."
	if POWER_DEMAND[kind]>power:return "Upgrade or build a Fusion Reactor for more Power."
	return ""

func _recalculate_colony()->void:
	building_levels.fill(0);power=0
	for b in buildings:
		if b.get("job","")=="build":continue
		building_levels[b.type]=maxi(building_levels[b.type],b.level)
		if b.type==1:power+=300*b.level
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

func _save_profile()->void:
	if not has_colony or not profile_ready:return
	var records:Array=[]
	for b in buildings:records.append({"type":b.type,"level":b.level,"pos":[b.pos.x,0,b.pos.z],"job":b.get("job",""),"started":b.get("started",0),"finish":b.get("finish",0)})
	var data:Dictionary={"schema":1,"colony_time":colony_time,"training_queue":training_queue,"home_planet":home_planet,"tutorial_step":tutorial_step,"tutorial_dismissed":tutorial_dismissed,"resources":[credits,metal,oil,crystal],"unit_stock":Array(unit_stock),"buildings":records}
	if not profile_store.write_profile(profile_path,data):_toast("Could not save progress. Free some device storage and try again.")

func _load_profile()->void:
	var data:Dictionary=profile_store.read_profile(profile_path)
	if data.is_empty():return
	has_colony=true;home_planet=int(data.home_planet);tutorial_step=int(data.tutorial_step);tutorial_dismissed=bool(data.get("tutorial_dismissed",false))
	credits=float(data.resources[0]);metal=float(data.resources[1]);oil=float(data.resources[2]);crystal=float(data.resources[3]);unit_stock=PackedInt32Array(data.unit_stock)
	colony_time=float(data.get("colony_time",Time.get_unix_time_from_system()))
	training_queue=data.get("training_queue",[])
	for b in data.buildings:
		var placed:Dictionary=_spawn_building(home_root,int(b.type),Vector3(b.pos[0],0,b.pos[2]),int(b.level),false)
		if b.get("job","")!="":
			for key in ["job","started","finish"]:placed[key]=b[key]
			_add_work_marker(placed)
	_advance_colony(maxf(colony_time,Time.get_unix_time_from_system()))
	_recalculate_colony();_ensure_roads()

func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST:_save_profile()
	if what==NOTIFICATION_APPLICATION_RESUMED and has_colony:_advance_colony(maxf(colony_time,Time.get_unix_time_from_system()));_save_profile()

func _exit_tree()->void:
	_save_profile()

func _builder_busy()->bool:
	for b in buildings:
		if b.get("job","")!="":return true
	return false

func _add_work_marker(b:Dictionary)->void:
	var label:=Label3D.new();label.font_size=42;label.pixel_size=.018;label.outline_size=8
	label.position=Vector3(0,6,0);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("ffd483");b.node.add_child(label);b["work_marker"]=label
	if b.job=="build":b.node.scale=Vector3(1,.2,1)

func _advance_colony(now:float)->void:
	if not has_colony:return
	if colony_time<=0:colony_time=now;return
	var changed:=false
	var economy_start:float=maxf(colony_time,now-8*3600)
	while colony_time<now:
		var next:float=now
		for b in buildings:
			if b.get("job","")!="":next=minf(next,maxf(colony_time,float(b.finish)))
		if not training_queue.is_empty():next=minf(next,maxf(colony_time,float(training_queue[0].finish)))
		_economy_tick(maxf(0,next-maxf(colony_time,economy_start)))
		colony_time=next
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
		_refresh_progress();_setup_life()
		if profile_ready:_save_profile()

func _update_work_display()->void:
	if not is_instance_valid(work_label):return
	work_label.visible=mode=="base" or (mode=="battle" and awaiting_deployment)
	if mode=="battle" and awaiting_deployment:
		work_label.text="AI OUTPOST • Tap an outer edge to deploy up to 24 trained units"
		work_label.position=Vector2(24,get_viewport().get_visible_rect().size.y-150)
		work_label.size=Vector2(get_viewport().get_visible_rect().size.x-48,32)
		return
	var lines:Array[String]=[]
	for b in buildings:
		if b.get("job","")=="":continue
		var left:int=maxi(0,int(ceil(float(b.finish)-colony_time)))
		var progress:float=clampf((colony_time-float(b.started))/maxf(1,float(b.finish)-float(b.started)),0,1)
		if b.job=="build":b.node.scale=Vector3(1,.2+.8*progress,1)
		if is_instance_valid(b.get("work_marker")):b.work_marker.text="%s %d%% • %ds"%[str(b.job).to_upper(),int(progress*100),left]
		lines.append("DRONE: %s • %ds"%[BUILDING_NAMES[b.type],left])
	if not training_queue.is_empty():lines.append("TRAINING: %s • %ds • %d queued"%[UNIT_NAMES[int(training_queue[0].type)],maxi(0,int(ceil(float(training_queue[0].finish)-colony_time))),training_queue.size()])
	work_label.text="  |  ".join(lines)
	work_label.position=Vector2(24,get_viewport().get_visible_rect().size.y-145)
	work_label.size=Vector2(get_viewport().get_visible_rect().size.x-48,32)
	if selected_building>=0 and info_panel.visible:
		var b:Dictionary=buildings[selected_building]
		if b.get("job","")!="":selected_detail.text="%s in progress\n%d seconds remaining"%[str(b.job).capitalize(),maxi(0,int(ceil(float(b.finish)-colony_time)))]

func _begin_move()->void:
	if mode!="base" or selected_building<0:return
	if buildings[selected_building].get("job","")!="":_toast("Wait until this construction finishes.");return
	moving_building=selected_building;build_type=-1;info_panel.hide()
	_toast("Tap clear terrain to relocate this structure for free.")

func _move_building(pos:Vector3)->void:
	if mode!="base" or moving_building<0:return
	pos=Vector3(snappedf(pos.x,1),0,snappedf(pos.z,1))
	if absf(pos.x)>18 or absf(pos.z)>15:_toast("Stay inside the base area.");return
	for i in buildings.size():
		if i!=moving_building and buildings[i].pos.distance_to(pos)<6.1:_toast("Leave space around other buildings.");return
	var b:Dictionary=buildings[moving_building];b.pos=pos;b.node.position=pos;moving_building=-1
	_save_profile();_select_building_at(pos);_toast("Structure relocated.")
