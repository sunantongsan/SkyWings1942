extends SceneTree
const SAVE:="user://qa_v23_defenses.json"
var game:Node3D
func _initialize()->void:call_deferred("run")
func open_game()->void:
	game=load("res://scenes/main.tscn").instantiate();game.profile_path=SAVE;root.add_child(game)
	await process_frame;await process_frame;game.set_process(false)
func shot(name:String)->void:
	await process_frame;await process_frame
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://build/review/"+name+".png")==OK)
func enemy(kind:int,pos:Vector3)->Dictionary:
	var n:Node3D=game._unit_model(kind,true);game.home_root.add_child(n);n.position=pos+Vector3(0,game._unit_height(kind),0)
	return {"node":n,"type":kind,"hp":1000.0,"max_hp":1000.0}
func run()->void:
	root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/review"))
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	await open_game();game._found_colony(0);game.onboarding.close_lesson(false)
	for kind in game.BUILD_ORDER:game._spawn_building(game.home_root,kind,game.LANDING_SITES[kind],2 if kind==0 else 1,false)
	game._spawn_building(game.home_root,1,Vector3(100,0,-30),2,false)
	game.tutorial_step=13;game._recalculate_colony();game.metal=1000000;game.oil=100000
	for index in 50:
		var stage:Dictionary=game.Campaign.stage(index)
		for entry in stage.structures:
			if entry.type>=21:continue
			assert(is_equal_approx(entry.hp,(300.0+index*22.0+index*index*.3)*1.5))
			assert(is_equal_approx(entry.shot_damage,(2.5+index*.55)*(2.0/1.2 if entry.type==11 else 1.0)*1.5))
	var built:Array[Dictionary]=[]
	for kind in [21,22,23,24]:
		game._begin_build(kind);game._place_building(Vector3(40+(kind-21)*8,0,0))
		assert(game.buildings.back().type==kind and game.buildings.back().get("job","")=="build")
		game._advance_colony(float(game.buildings.back().finish)+1);built.append(game.buildings.back())
		assert(game.profile_store._valid(game.profile_store.read_profile(SAVE)))
	game.camera_focus=Vector3(52,0,0);game.camera.size=38;game._position_camera();game._dismiss_menus()
	await shot("60-new-defense-buildings")
	var gun:Dictionary=built[0];var mortar:Dictionary=built[1];var sam:Dictionary=built[2];var wall:Dictionary=built[3]
	var ground:Dictionary=enemy(10,gun.pos+Vector3(0,0,6));var air:Dictionary=enemy(0,gun.pos+Vector3(0,0,7))
	game._defense_tick([gun],[ground],.2,1);assert(ground.hp<1000)
	gun.fire_wait=0;game._defense_tick([gun],[air],.2,1);assert(air.hp<1000)
	ground.node.queue_free();air.node.queue_free()
	var a:Dictionary=enemy(10,mortar.pos+Vector3(0,0,7))
	var b:Dictionary=enemy(18,mortar.pos+Vector3(2,0,7))
	var c:Dictionary=enemy(0,mortar.pos+Vector3(0,0,7))
	var far:Dictionary=enemy(10,mortar.pos+Vector3(9,0,7))
	game._defense_tick([mortar],[c],.2,1);assert(game.defenses.projectiles.is_empty(),"Mortar never targets air")
	game._defense_tick([mortar],[a,b,c,far],.2,1)
	assert(a.hp==1000 and b.hp==1000,"No splash damage before impact")
	game.defenses.tick(.3);game.camera_focus=mortar.pos;game.camera.size=24;game._position_camera()
	await shot("61-artillery-shell-in-flight")
	for i in 25:game.defenses.tick(.1)
	assert(a.hp<1000 and b.hp<1000 and c.hp==1000 and far.hp==1000,"Ground splash respects radius and excludes aircraft")
	await shot("62-artillery-ground-impact")
	for unit in [a,b,c,far]:unit.node.queue_free()
	var plane:Dictionary=enemy(0,sam.pos+Vector3(0,0,9));var tank:Dictionary=enemy(10,sam.pos+Vector3(0,0,6))
	game._defense_tick([sam],[tank],.2,1);assert(game.defenses.projectiles.is_empty(),"SAM never launches at ground")
	for i in 3:
		game._defense_tick([sam],[plane,tank],.2,1);game.defenses.tick(.04)
	assert(game.defenses.projectiles.size()==3 and plane.hp==1000)
	game._defense_tick([sam],[plane,tank],.2,1);assert(game.defenses.projectiles.size()==3,"Burst has three rockets and a reload gap")
	game.defenses.tick(.04);game.camera_focus=sam.pos;game._position_camera();await shot("63-sam-three-rocket-burst")
	for i in 20:game.defenses.tick(.1)
	assert(plane.hp<1000 and tank.hp==1000)
	assert(game.defenses.accepts(sam,{"type":16}) and not game.defenses.accepts(mortar,{"type":17}),"Hover drones are air targets")
	plane.node.queue_free();tank.node.queue_free()
	for rank in range(1,6):
		assert(wall.level==rank and wall.node.scene_file_path.ends_with(game.defenses.WALL_FILES[rank-1]+".glb"))
		assert(game._can_fire(wall)==(rank==5))
		if rank<5:
			game.selected_building=game.buildings.find(wall);game._upgrade_selected()
			assert(wall.level==rank+1 and wall.get("job","")=="")
			game._advance_colony(game.colony_time+1)
	game.selected_building=game.buildings.find(wall);game._upgrade_selected();assert(wall.level==5 and wall.get("job","")=="")
	# Rotating, dragging, collision rollback and doubled instant costs.
	game.selected_building=game.buildings.find(wall)
	game.layout.rotate_selected();assert(is_equal_approx(wall.node.rotation.y,PI/2))
	assert(not game.defenses.blocking_wall(wall.pos+Vector3(-5,0,2),wall.pos+Vector3(5,0,2),[wall]).is_empty())
	assert(game.defenses.blocking_wall(wall.pos+Vector3(-5,0,4),wall.pos+Vector3(5,0,4),[wall]).is_empty())
	var old_position:Vector3=wall.pos
	game.camera_focus=wall.pos;game._position_camera();game._dismiss_menus()
	var press:=InputEventScreenTouch.new();press.index=0;press.pressed=true;press.position=game.camera.unproject_position(wall.pos)
	game._unhandled_input(press)
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=game.camera.unproject_position(wall.pos+Vector3(0,0,10));drag.relative=drag.position-press.position
	game._unhandled_input(drag);assert(game.layout.active)
	var release:=InputEventScreenTouch.new();release.index=0;release.pressed=false;release.position=drag.position
	game._unhandled_input(release);assert(wall.pos==old_position+Vector3(0,0,10) and not game.layout.active)
	game.selected_building=game.buildings.find(wall);game._begin_move();game._move_building(built[0].pos)
	assert(wall.pos==old_position+Vector3(0,0,10),"Invalid drop preserves original location")
	game.moving_building=-1
	var tower:Dictionary=built[0];game.selected_building=game.buildings.find(tower)
	var cost:float=game._upgrade_cost(tower);var balance:float=game.metal
	game._upgrade_selected();assert(tower.level==2 and is_equal_approx(game.metal,balance-cost))
	assert(game._upgrade_cost(tower)==cost*2 and tower.get("job","")=="")
	game._upgrade_selected();assert(tower.level==3 and is_equal_approx(game.metal,balance-cost*3))
	var attacker:Dictionary=enemy(10,wall.pos+Vector3(0,0,6))
	game._defense_tick([wall],[attacker],.3,1);assert(attacker.hp<1000)
	attacker.node.position=wall.pos+Vector3(0,0,12);var hp:float=attacker.hp
	wall.fire_wait=0;game._defense_tick([wall],[attacker],1,1);assert(attacker.hp==hp,"Fire wall gun is short range")
	assert(not game.defenses.blocking_wall(wall.pos+Vector3(0,0,5),wall.pos-Vector3(0,0,5),[wall]).is_empty())
	wall.hp=0;assert(game.defenses.blocking_wall(wall.pos+Vector3(0,0,5),wall.pos-Vector3(0,0,5),[wall]).is_empty());wall.hp=wall.max_hp
	attacker.node.queue_free()
	game.build_type=24;assert(game._placement_reason(wall.pos+Vector3(6,0,0)).is_empty(),"Wall sections connect end to end")
	assert(not game._placement_reason(wall.pos+Vector3(2,0,0)).is_empty(),"Wall footprints cannot overlap")
	game.build_type=-1
	for rank in range(1,6):game._spawn_building(game.home_root,24,Vector3(35+rank*8,0,-22),rank,false)
	game.camera_focus=Vector3(59,0,-22);game.camera.size=42;game._position_camera();await shot("64-five-wall-materials")
	game._save_profile();game.queue_free();await process_frame;await open_game()
	var walls:=0
	for entry in game.buildings:
		if entry.type==24:
			walls+=1;assert(entry.node.scene_file_path.ends_with(game.defenses.WALL_FILES[entry.level-1]+".glb"))
	assert(walls==6 and game.building_levels[21]==3 and game.building_levels[22]==1 and game.building_levels[23]==1)
	game.camera_focus=Vector3(64,0,10);game.camera.size=22;game._position_camera();game._select_building_at(Vector3(64,0,10))
	await shot("65-fire-wall-upgrade-details")
	assert(is_equal_approx(game.buildings[14].node.rotation.y,PI/2))
	game._toggle_build();await shot("66-defense-construction-menu")
	game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	print("V23_DIFFICULTY_150_PERCENT_TYPED_WEAPONS_IMPACT_WALLS_SAVE_PASSED");quit(0)
