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
var credits:=125600.0
var metal:=230400.0
var oil:=98200.0
var crystal:=56100.0
var power:=1200.0
var mode:="base"
var map_index:=0
var selected_building:=-1
var build_type:=-1
var selected_unit:=0
var buildings:Array[Dictionary]=[]
var building_levels:=PackedInt32Array([5,4,4,4,4,3,4,3,3,2])
var unit_stock:=PackedInt32Array([20,16,12,9,8,7,6,5,4,2,12,8,6,6,5,5,8,8,10,2])
var drag_camera:=false
var touch_points:={}
var pinch_last:=0.0
var battle_targets:Array[Dictionary]=[]
var battle_units:Array[Dictionary]=[]
var battle_damage:=0.0
var battle_elapsed:=0.0
var battle_map:=1
var ground:MeshInstance3D
var terrain_material:StandardMaterial3D
var sun:DirectionalLight3D

func _ready()->void:
	_setup_environment()
	_setup_world()
	_setup_camera()
	_setup_ui()
	_seed_home_base()
	_apply_map_theme(0)
	_toast("GODOT 3D HOME PLANET ONLINE")

func _process(delta:float)->void:
	if mode=="base": _economy_tick(delta)
	elif mode=="battle": _battle_tick(delta)
	_update_top_bar()

func _setup_environment()->void:
	var env:=WorldEnvironment.new()
	var e:=Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color("07111f")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("819bb8")
	e.ambient_light_energy=0.48
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	e.glow_enabled=true
	env.environment=e
	add_child(env)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-58,-38,0)
	sun.light_energy=1.35
	sun.shadow_enabled=true
	add_child(sun)

func _setup_world()->void:
	world_root=Node3D.new();add_child(world_root)
	home_root=Node3D.new();world_root.add_child(home_root)
	battle_root=Node3D.new();battle_root.visible=false;world_root.add_child(battle_root)
	decor_root=Node3D.new();world_root.add_child(decor_root)
	ground=MeshInstance3D.new()
	var pm:=PlaneMesh.new();pm.size=Vector2(72,52);ground.mesh=pm
	terrain_material=StandardMaterial3D.new();terrain_material.roughness=.9;ground.material_override=terrain_material;world_root.add_child(ground)
	_create_roads(home_root)
	_create_decor(decor_root,0)

func _setup_camera()->void:
	camera=Camera3D.new();camera.position=Vector3(26,34,32);camera.rotation_degrees=Vector3(-48,38,0)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=31;camera.current=true;add_child(camera)

func _setup_ui()->void:
	ui=CanvasLayer.new();add_child(ui)
	var top:=PanelContainer.new();top.position=Vector2(18,14);top.size=Vector2(1884,88);top.add_theme_stylebox_override("panel",_style(Color(.02,.055,.10,.95),16,Color("239eda"),1));ui.add_child(top)
	top_label=Label.new();top_label.add_theme_font_size_override("font_size",24);top_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;top.add_child(top_label)
	var left:=VBoxContainer.new();left.position=Vector2(20,122);left.add_theme_constant_override("separation",10);ui.add_child(left)
	left.add_child(_button("BUILD",func():_toggle_build(),Vector2(190,72)))
	left.add_child(_button("UNITS",func():_toggle_units(),Vector2(190,72)))
	left.add_child(_button("GALAXY",func():_toggle_galaxy(),Vector2(190,72)))
	left.add_child(_button("CENTER",func():_center_camera(),Vector2(190,64)))
	left.add_child(_button("ZOOM +",func():_zoom(-2.0),Vector2(190,64)))
	left.add_child(_button("ZOOM -",func():_zoom(2.0),Vector2(190,64)))
	var info:=PanelContainer.new();info.position=Vector2(1450,122);info.size=Vector2(435,255);info.add_theme_stylebox_override("panel",_style(Color(.02,.06,.11,.94),16,Color("2acfff"),1));ui.add_child(info)
	var iv:=VBoxContainer.new();iv.add_theme_constant_override("separation",8);info.add_child(iv)
	selected_label=Label.new();selected_label.text="SELECT A BUILDING";selected_label.add_theme_font_size_override("font_size",22);iv.add_child(selected_label)
	selected_detail=Label.new();selected_detail.text="Tap a structure to inspect and upgrade.";selected_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;selected_detail.add_theme_font_size_override("font_size",20);iv.add_child(selected_detail)
	iv.add_child(_button("UPGRADE",func():_upgrade_selected(),Vector2(0,50)))
	build_panel=_make_build_panel();ui.add_child(build_panel);build_panel.visible=false
	units_panel=_make_units_panel();ui.add_child(units_panel);units_panel.visible=false
	galaxy_panel=_make_galaxy_panel();ui.add_child(galaxy_panel);galaxy_panel.visible=false
	toast=Label.new();toast.position=Vector2(600,95);toast.size=Vector2(720,55);toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast.add_theme_font_size_override("font_size",19);toast.add_theme_color_override("font_color",Color("ffcf63"));toast.visible=false;ui.add_child(toast)
	victory_panel=PanelContainer.new();victory_panel.position=Vector2(620,320);victory_panel.size=Vector2(680,380);victory_panel.visible=false;victory_panel.add_theme_stylebox_override("panel",_style(Color(.015,.04,.08,.97),26,Color("ffca42"),3));ui.add_child(victory_panel)
	var vv:=VBoxContainer.new();vv.alignment=BoxContainer.ALIGNMENT_CENTER;vv.add_theme_constant_override("separation",18);victory_panel.add_child(vv)
	var vt:=Label.new();vt.text="VICTORY";vt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;vt.add_theme_font_size_override("font_size",44);vt.add_theme_color_override("font_color",Color("ffcc4d"));vv.add_child(vt)
	var vr:=Label.new();vr.name="Reward";vr.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;vr.add_theme_font_size_override("font_size",18);vv.add_child(vr)
	vv.add_child(_button("RETURN HOME",func():_return_home(),Vector2(0,62)))

func _make_build_panel()->PanelContainer:
	var panel:=PanelContainer.new();panel.position=Vector2(220,675);panel.size=Vector2(1235,385);panel.add_theme_stylebox_override("panel",_style(Color(.02,.06,.11,.97),18,Color("2acfff"),2))
	var grid:=GridContainer.new();grid.columns=5;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);panel.add_child(grid)
	for i in 10:
		var b:=Button.new();b.custom_minimum_size=Vector2(230,170);b.text="%s\nMetal %d"%[BUILDING_NAMES[i],BUILDING_COST[i]];b.add_theme_font_size_override("font_size",20)
		var path:="res://assets/buildings/%s.png"%_building_file(i)
		if ResourceLoader.exists(path):b.icon=load(path);b.expand_icon=true;b.icon_max_width=92
		b.add_theme_stylebox_override("normal",_style(Color(.025,.10,.17,.95),14,Color(.1,.30,.43),1));b.add_theme_stylebox_override("hover",_style(Color(.04,.17,.26,.98),14,Color("2acfff"),2))
		b.pressed.connect(func(idx=i):_begin_build(idx));grid.add_child(b)
	return panel

func _make_units_panel()->PanelContainer:
	var panel:=PanelContainer.new();panel.position=Vector2(220,610);panel.size=Vector2(1235,450);panel.add_theme_stylebox_override("panel",_style(Color(.02,.06,.11,.97),18,Color("8b7cff"),2))
	var grid:=GridContainer.new();grid.columns=5;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);panel.add_child(grid)
	for i in 20:
		var b:=Button.new();b.custom_minimum_size=Vector2(230,100);b.text="%02d  %s\nStock %d"%[i+1,UNIT_NAMES[i],unit_stock[i]];b.add_theme_font_size_override("font_size",19)
		b.add_theme_stylebox_override("normal",_style(Color(.025,.09,.16,.96),12,Color(.18,.24,.45),1));b.add_theme_stylebox_override("hover",_style(Color(.07,.12,.26,.98),12,Color("8b7cff"),2))
		b.pressed.connect(func(idx=i):_train_unit(idx));grid.add_child(b)
	return panel

func _make_galaxy_panel()->PanelContainer:
	var panel:=PanelContainer.new();panel.position=Vector2(265,120);panel.size=Vector2(1390,880);panel.add_theme_stylebox_override("panel",_style(Color(.008,.02,.065,.985),24,Color("527dff"),2))
	var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",14);panel.add_child(outer)
	var title:=Label.new();title.text="GALAXY MAP • 15 WORLDS";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",30);outer.add_child(title)
	var grid:=GridContainer.new();grid.columns=5;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);outer.add_child(grid)
	for i in 15:
		var b:=Button.new();b.custom_minimum_size=Vector2(250,190);b.text="%02d\n%s\nThreat Lv.%d\nATTACK"%[i+1,MAP_NAMES[i],2+i*2];b.add_theme_font_size_override("font_size",20)
		var col:Color=MAP_ACCENT[i];b.add_theme_stylebox_override("normal",_style(Color(col.r*.12,col.g*.12,col.b*.12,.96),20,col,2));b.add_theme_stylebox_override("hover",_style(Color(col.r*.22,col.g*.22,col.b*.22,.98),20,Color.WHITE,2))
		b.pressed.connect(func(idx=i):_start_battle(idx));grid.add_child(b)
	return panel

func _building_file(i:int)->String:return ["galactic_core","fusion_reactor","metal_extractor","oil_processor","crystal_mine","resource_vault","star_hangar","research_lab","laser_tower","shield_generator"][i]

func _seed_home_base()->void:
	var pos=[Vector3(0,0,0),Vector3(-7,0,-4),Vector3(-12,0,4),Vector3(10,0,6),Vector3(12,0,-5),Vector3(-2,0,10),Vector3(5,0,12),Vector3(4,0,-10),Vector3(-14,0,-8),Vector3(15,0,-9)]
	for i in 10:_spawn_building(home_root,i,pos[i],building_levels[i],false)

func _spawn_building(parent:Node3D,type:int,pos:Vector3,level:int,enemy:bool)->Dictionary:
	var root:=Node3D.new();root.position=pos;parent.add_child(root)
	var base:=Color("4b5969") if not enemy else Color("5b4244");var accent:=Color("27c7ff") if not enemy else Color("ff4738")
	match type:
		0:_model_core(root,base,accent)
		1:_model_reactor(root,base,accent)
		2:_model_extractor(root,base,Color("ff9b3c"))
		3:_model_oil(root,base,Color("ff6e2e"))
		4:_model_crystal(root,base,Color("b75cff"))
		5:_model_vault(root,base,accent)
		6:_model_hangar(root,base,accent)
		7:_model_lab(root,base,accent)
		8:_model_laser(root,base,Color("ff2e2e") if enemy else Color("45a8ff"))
		9:_model_shield(root,base,accent)
	root.scale=Vector3.ONE*(1.0+(level-1)*.035)
	var d={"node":root,"type":type,"level":level,"pos":pos,"hp":350.0+level*120.0,"max_hp":350.0+level*120.0}
	if parent==home_root:buildings.append(d)
	return d

func _create_roads(parent:Node3D)->void:
	var mat:=_mat(Color("252b31"))
	for p in [Vector3(0,.02,0),Vector3(0,.02,8),Vector3(0,.02,-8)]:
		var r:=_box(Vector3(34,.05,2.2),mat);r.position=p;parent.add_child(r)
	for p in [Vector3(-8,.02,0),Vector3(8,.02,0)]:
		var r:=_box(Vector3(2.2,.05,27),mat);r.position=p;parent.add_child(r)

func _create_decor(parent:Node3D,theme:int)->void:
	for c in parent.get_children():c.queue_free()
	var rng:=RandomNumberGenerator.new();rng.seed=1942+theme*97
	for i in 55:
		var x:=rng.randf_range(-32,32);var z:=rng.randf_range(-22,22)
		if Vector2(x,z).length()<8:continue
		var rock:=_sphere(rng.randf_range(.25,.65),_mat(MAP_GROUND[theme].lightened(.1)));rock.position=Vector3(x,rng.randf_range(.12,.28),z);rock.scale.y=rng.randf_range(.5,1.6);parent.add_child(rock)

func _apply_map_theme(idx:int)->void:
	map_index=idx;terrain_material.albedo_color=MAP_GROUND[idx];terrain_material.metallic=.55 if idx in [6,11] else .05;terrain_material.roughness=.42 if idx in [5,6] else .88;sun.light_color=MAP_ACCENT[idx].lerp(Color.WHITE,.72);_create_decor(decor_root,idx)

func _model_core(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(5.8,.8,5.8),_mat(base)));var body:=_cyl(2.1,1.6,3.4,_mat(base.lightened(.06)));body.position.y=2;r.add_child(body)
	for ang in [0.0,90.0,180.0,270.0]:
		var p:=_cyl(.35,.28,4.2,_mat(base.darkened(.08)));p.position=Vector3(cos(deg_to_rad(ang))*2.2,2.6,sin(deg_to_rad(ang))*2.2);r.add_child(p)
	var orb:=_sphere(.72,_mat(a,a,4,.18));orb.position.y=4.4;r.add_child(orb);var beam:=_cyl(.16,.11,5.5,_mat(a,a,7,.1));beam.position.y=7;r.add_child(beam)

func _model_reactor(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(5,.7,5),_mat(base)));var core:=_cyl(1.5,1.25,2.8,_mat(base.lightened(.04)));core.position.y=1.8;r.add_child(core);var glow:=_cyl(.72,.72,2.5,_mat(a,a,5,.14));glow.position.y=2.3;r.add_child(glow)
	for ang in [45.0,135.0,225.0,315.0]:
		var pod:=_cyl(.45,.45,2,_mat(base));pod.position=Vector3(cos(deg_to_rad(ang))*2,1,sin(deg_to_rad(ang))*2);r.add_child(pod)

func _model_extractor(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(5.2,.7,4.6),_mat(base)));var rig:=_box(Vector3(2.8,2.2,2.6),_mat(base.lightened(.05)));rig.position=Vector3(-.4,1.45,0);r.add_child(rig);var arm:=_box(Vector3(.45,.45,4),_mat(a));arm.position=Vector3(1,3,.2);arm.rotation_degrees=Vector3(0,0,-28);r.add_child(arm)

func _model_oil(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(5.4,.6,4.8),_mat(base)))
	for p in [Vector3(-1.5,1.5,-.8),Vector3(0,1.8,.5),Vector3(1.5,1.4,-.3)]:
		var t:=_cyl(.65,.65,2.7,_mat(base.lightened(.04)));t.position=p;r.add_child(t)
	var g:=_sphere(.45,_mat(a,a,4,.18));g.position=Vector3(.2,2.35,1.3);r.add_child(g)

func _model_crystal(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(5,.55,4.6),_mat(base)))
	for d in [Vector3(0,2.2,0),Vector3(-1.1,1.5,.5),Vector3(1.2,1.7,.2),Vector3(.5,1.2,-1.1),Vector3(-.6,1.1,-1)]:
		var c:=_cone(.55,2.7,_mat(a,a,2.8,.12));c.position=d;r.add_child(c)

func _model_vault(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(5.2,.65,4.8),_mat(base)));var main:=_box(Vector3(3.4,2.7,3.2),_mat(base.lightened(.05)));main.position.y=1.65;r.add_child(main)

func _model_hangar(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(6.3,.55,5.5),_mat(base)));var roof:=_box(Vector3(5.6,2.4,4.5),_mat(base.lightened(.03)));roof.position=Vector3(0,1.55,-.3);r.add_child(roof);var door:=_box(Vector3(3.6,1.8,.16),_mat(Color("07101a"),a,1.8));door.position=Vector3(0,1.2,2.02);r.add_child(door)

func _model_lab(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(5,.6,4.8),_mat(base)));var tower:=_cyl(1.2,1,2.9,_mat(base.lightened(.06)));tower.position.y=1.7;r.add_child(tower);var dome:=_sphere(1,_mat(a,a,2.4,.18));dome.position.y=3.25;dome.scale.y=.65;r.add_child(dome)

func _model_laser(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(4.4,.65,4.4),_mat(base)));var tower:=_cyl(1,.75,3,_mat(base.lightened(.04)));tower.position.y=1.8;r.add_child(tower);var head:=_box(Vector3(2,.8,1.1),_mat(base));head.position=Vector3(0,3.4,0);r.add_child(head);var barrel:=_cyl(.22,.16,3.2,_mat(a,a,3));barrel.position=Vector3(0,3.45,-1.5);barrel.rotation_degrees=Vector3(90,0,0);r.add_child(barrel)

func _model_shield(r:Node3D,base:Color,a:Color)->void:
	r.add_child(_box(Vector3(5.8,.6,5.8),_mat(base)))
	for ang in [0.0,90.0,180.0,270.0]:
		var p:=_cyl(.32,.32,3.2,_mat(base.lightened(.08)));p.position=Vector3(cos(deg_to_rad(ang))*2.1,1.8,sin(deg_to_rad(ang))*2.1);r.add_child(p)
	var bubble:=_sphere(3,_mat(a,a,1.7,.09));bubble.position.y=.5;bubble.scale.y=.55;r.add_child(bubble)

func _unit_model(type:int,enemy:=false)->Node3D:
	var r:=Node3D.new();var accent:=Color("37d7ff") if not enemy else Color("ff4b3c");var base:=Color("505d6d")
	if type<=9:
		var body:=_box(Vector3(1.1,.45,2.5),_mat(base));body.position.y=.55;r.add_child(body);var wing:=_box(Vector3(2.8,.16,1),_mat(accent.darkened(.25)));wing.position.y=.52;r.add_child(wing)
	elif type<=13:
		var ch:=_box(Vector3(2.2,.55,3.1),_mat(base));ch.position.y=.45;r.add_child(ch);var turret:=_cyl(.55,.55,.55,_mat(base.lightened(.07)));turret.position.y=.95;r.add_child(turret)
	elif type in [16,17]:
		var orb:=_sphere(.55,_mat(accent,accent,2.2,.1));orb.position.y=1;r.add_child(orb)
	else:
		var body:=_box(Vector3(.7,1.1,.45),_mat(base));body.position.y=1.1;r.add_child(body);var head:=_sphere(.35,_mat(accent.darkened(.2)));head.position.y=1.95;r.add_child(head)
	return r

func _begin_build(idx:int)->void:build_type=idx;build_panel.visible=false;units_panel.visible=false;galaxy_panel.visible=false;_toast("TAP THE TERRAIN TO PLACE %s"%BUILDING_NAMES[idx].to_upper())
func _upgrade_selected()->void:
	if selected_building<0 or selected_building>=buildings.size():_toast("SELECT A BUILDING FIRST");return
	var b:Dictionary=buildings[selected_building];var cost:int=500+int(b.type)*120+int(b.level)*360
	if metal<cost:_toast("NOT ENOUGH METAL");return
	metal-=cost;b.level+=1;building_levels[b.type]=max(building_levels[b.type],b.level);b.node.scale*=1.045;buildings[selected_building]=b;_select_building_at(b.pos);_toast("%s UPGRADED TO LV.%d"%[BUILDING_NAMES[b.type].to_upper(),b.level])

func _train_unit(idx:int)->void:
	var c:=180+idx*35
	if credits<c or oil<c*.4:_toast("NOT ENOUGH RESOURCES");return
	credits-=c;oil-=c*.4;unit_stock[idx]+=1;selected_unit=idx;_toast("%s TRAINED • STOCK %d"%[UNIT_NAMES[idx].to_upper(),unit_stock[idx]])
	units_panel.queue_free();units_panel=_make_units_panel();ui.add_child(units_panel)

func _toggle_build()->void:build_panel.visible=not build_panel.visible;units_panel.visible=false;galaxy_panel.visible=false
func _toggle_units()->void:units_panel.visible=not units_panel.visible;build_panel.visible=false;galaxy_panel.visible=false
func _toggle_galaxy()->void:galaxy_panel.visible=not galaxy_panel.visible;build_panel.visible=false;units_panel.visible=false

func _start_battle(idx:int)->void:
	mode="battle";battle_map=idx;galaxy_panel.visible=false;home_root.visible=false;battle_root.visible=true
	for c in battle_root.get_children():c.queue_free()
	battle_targets.clear();battle_units.clear();battle_damage=0;battle_elapsed=0;_apply_map_theme(idx)
	var epos=[Vector3(0,0,-5),Vector3(-8,0,-1),Vector3(8,0,-1),Vector3(-5,0,5),Vector3(5,0,5),Vector3(-13,0,6),Vector3(13,0,6)];var etypes=[0,8,8,9,6,2,3]
	for i in epos.size():battle_targets.append(_spawn_building(battle_root,etypes[i],epos[i],2+idx/4,true))
	var count:int=min(24,unit_stock[0]+unit_stock[1]+unit_stock[2])
	for i in count:
		var t:int=i%6;var n:Node3D=_unit_model(t,false);n.position=Vector3(-10+(i%8)*2.6,.25,17+(i/8)*2);battle_root.add_child(n);battle_units.append({"node":n,"type":t,"damage":8.0+t*1.5,"speed":2.7+t*.08})
	camera.position=Vector3(25,34,34);camera.size=34;_toast("ATTACKING %s"%MAP_NAMES[idx].to_upper())

func _battle_tick(delta:float)->void:
	battle_elapsed+=delta;var total:=0.0;var alive_hp:=0.0;var alive:Array=[]
	for e in battle_targets:
		total+=e.max_hp
		if e.hp>0:alive_hp+=e.hp;alive.append(e)
	battle_damage=100.0*(1.0-alive_hp/max(1.0,total))
	if alive.is_empty() or battle_elapsed>150:_finish_battle(alive.is_empty());return
	for u in battle_units:
		var n:Node3D=u.node
		if not is_instance_valid(n):continue
		var target:Dictionary=alive[0];var best:=n.position.distance_to(target.pos)
		for e in alive:
			var d:=n.position.distance_to(e.pos)
			if d<best:best=d;target=e
		if best>2.5:n.position=n.position.move_toward(target.pos,u.speed*delta);n.look_at(Vector3(target.pos.x,n.position.y,target.pos.z),Vector3.UP)
		else:
			target.hp-=u.damage*delta*2.2
			if target.hp<=0 and is_instance_valid(target.node):_explode(target.node.global_position);target.node.queue_free()

func _finish_battle(win:bool)->void:
	if mode!="battle":return
	if win:
		var reward:=Vector4(8000+battle_map*700,4200+battle_map*350,2600+battle_map*220,900+battle_map*90);credits+=reward.x;metal+=reward.y;oil+=reward.z;crystal+=reward.w
		var l:Label=victory_panel.find_child("Reward",true,false);l.text="%s conquered\nDamage 100%%\n+%d Credits   +%d Metal   +%d Oil   +%d Crystal"%[MAP_NAMES[battle_map],int(reward.x),int(reward.y),int(reward.z),int(reward.w)];victory_panel.visible=true
	else:_return_home();_toast("FLEET WITHDREW")

func _return_home()->void:mode="base";victory_panel.visible=false;battle_root.visible=false;home_root.visible=true;_apply_map_theme(0);_center_camera();_toast("RETURNED TO HOME PLANET")
func _economy_tick(delta:float)->void:credits+=delta*3.5;metal+=delta*(2.0+building_levels[2]*.7);oil+=delta*(1.5+building_levels[3]*.5);crystal+=delta*(.6+building_levels[4]*.22);power=800+building_levels[1]*160
func _update_top_bar()->void:
	if not top_label:return
	var prefix:="HOME PLANET • TERRA" if mode=="base" else "BATTLE • %s • DAMAGE %d%%"%[MAP_NAMES[battle_map],int(battle_damage)]
	top_label.text="%s        CREDITS %s     METAL %s     OIL %s     CRYSTAL %s     POWER %s"%[prefix,_fmt(credits),_fmt(metal),_fmt(oil),_fmt(crystal),_fmt(power)]
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
	if best<0:selected_label.text="SELECT A BUILDING";selected_detail.text="Tap a structure to inspect and upgrade.";return
	var b:Dictionary=buildings[best];selected_label.text="%s • Lv.%d"%[BUILDING_NAMES[b.type],b.level];selected_detail.text="HP %d/%d\nUpgrade cost %d Metal\nMap theme: %s"%[int(b.hp),int(b.max_hp),500+b.type*120+b.level*360,MAP_NAMES[map_index]]

func _place_building(pos:Vector3)->void:
	if build_type<0:return
	if abs(pos.x)>30 or abs(pos.z)>21:_toast("BUILD INSIDE THE BASE AREA");return
	for b in buildings:
		if b.pos.distance_to(pos)<4.4:_toast("TOO CLOSE TO ANOTHER BUILDING");return
	var cost=BUILDING_COST[build_type]
	if metal<cost:_toast("NOT ENOUGH METAL");return
	metal-=cost;_spawn_building(home_root,build_type,pos,1,false);_toast("%s CONSTRUCTION COMPLETE"%BUILDING_NAMES[build_type].to_upper());build_type=-1

func _ground_hit(screen_pos:Vector2)->Variant:
	var origin:=camera.project_ray_origin(screen_pos);var dir:=camera.project_ray_normal(screen_pos);return Plane(Vector3.UP,0).intersects_ray(origin,dir)

func _unhandled_input(event:InputEvent)->void:
	if galaxy_panel.visible or build_panel.visible or units_panel.visible or victory_panel.visible:return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:_zoom(-2);return
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:_zoom(2);return
		if event.button_index==MOUSE_BUTTON_LEFT:
			drag_camera=event.pressed
			if not event.pressed:
				var h=_ground_hit(event.position)
				if h!=null:
					if build_type>=0:_place_building(h)
					else:_select_building_at(h)
	elif event is InputEventMouseMotion and drag_camera:
		camera.position+=Vector3(-event.relative.x*.025,0,-event.relative.y*.025);_clamp_camera()
	elif event is InputEventScreenTouch:
		if event.pressed:touch_points[event.index]=event.position
		else:
			var single=touch_points.size()==1;touch_points.erase(event.index);pinch_last=0
			if single:
				var h=_ground_hit(event.position)
				if h!=null:
					if build_type>=0:_place_building(h)
					else:_select_building_at(h)
	elif event is InputEventScreenDrag:
		touch_points[event.index]=event.position
		if touch_points.size()==1:camera.position+=Vector3(-event.relative.x*.03,0,-event.relative.y*.03);_clamp_camera()
		elif touch_points.size()>=2:
			var k=touch_points.keys();var d:float=touch_points[k[0]].distance_to(touch_points[k[1]])
			if pinch_last>0:camera.size=clamp(camera.size*(pinch_last/d),18,48)
			pinch_last=d

func _clamp_camera()->void:camera.position.x=clamp(camera.position.x,-22,22);camera.position.z=clamp(camera.position.z,12,42)
func _center_camera()->void:camera.position=Vector3(26,34,32);camera.size=31
func _zoom(delta:float)->void:camera.size=clamp(camera.size+delta,18,48)
func _explode(pos:Vector3)->void:
	var flash:=OmniLight3D.new();flash.position=pos+Vector3(0,2,0);flash.light_color=Color("ff6f32");flash.light_energy=8;flash.omni_range=8;world_root.add_child(flash)
	var tw:=create_tween();tw.tween_property(flash,"light_energy",0,.55);tw.finished.connect(func():flash.queue_free())
func _toast(s:String)->void:
	toast.text=s;toast.visible=true;toast.modulate.a=1
	var tw:=create_tween();tw.tween_interval(1.6);tw.tween_property(toast,"modulate:a",0,.65);tw.finished.connect(func():toast.visible=false;toast.modulate.a=1)

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
	var b:=Button.new();b.text=text;b.custom_minimum_size=size;b.add_theme_font_size_override("font_size",23);b.add_theme_stylebox_override("normal",_style(Color(.025,.10,.17,.96),14,Color(.10,.32,.48),1));b.add_theme_stylebox_override("hover",_style(Color(.04,.18,.28,.98),14,Color("2acfff"),2));b.pressed.connect(cb);return b
func _style(bg:Color,radius:int,border:Color,width:int)->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(width);s.corner_radius_top_left=radius;s.corner_radius_top_right=radius;s.corner_radius_bottom_left=radius;s.corner_radius_bottom_right=radius;s.content_margin_left=14;s.content_margin_right=14;s.content_margin_top=10;s.content_margin_bottom=10;return s
