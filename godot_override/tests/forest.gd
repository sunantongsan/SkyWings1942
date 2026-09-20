extends SceneTree
const SAVE:="user://qa_v27_forest.json"
var game:Node3D
func _initialize()->void:call_deferred("run")
func shot(name:String)->void:
	await process_frame;await process_frame
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://build/review/"+name+".png")==OK)
func run()->void:
	root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/review"))
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	game=load("res://scenes/main.tscn").instantiate();game.profile_path=SAVE;root.add_child(game)
	await process_frame;game.set_process(false);game._found_colony(0);game.onboarding.close_lesson(false)
	game._spawn_building(game.home_root,0,Vector3.ZERO,1,false)
	game._spawn_building(game.home_root,1,Vector3(-12,0,0),2,false)
	game._spawn_building(game.home_root,10,Vector3(-12,0,12),1,false)
	game._spawn_building(game.home_root,12,Vector3(12,0,12),2,false)
	game.metal=100000;game.oil=100000;game.miner_count=1;game.gold=0
	var l:RefCounted=game.logistics
	l.sync_workers();l.advance(1)
	assert(l.workers.size()==1 and game.gold==0)
	assert(not l.workers[0].get("blocked",false),"Clear road connects the Core to the forest")
	l.advance(25);assert(game.gold==0,"Gold is not passive refinery income")
	l.advance(50);assert(game.gold>=120,"Gold cargo reaches the Core")
	l.build_coin_truck();assert(l.orders.size()==1 and l.coin_count==0)
	game._advance_colony(l.orders[0].finish+1);assert(l.coin_count==1 and l.orders.is_empty())
	var coin:Dictionary=l.workers.back();assert(coin.kind=="coin")
	var balance:int=game.godot_coins
	coin.pos=l.COIN_SITE;coin.phase="inbound";coin.cargo=3;coin.erase("route")
	l.advance(1);assert(game.godot_coins==balance and coin.cargo==3,"Discovery does not credit coins")
	game._save_profile();var saved:Dictionary=game.profile_store.read_profile(SAVE)
	assert(not saved.is_empty() and saved.logistics.workers.back().cargo==3)
	var invalid:Dictionary=saved.duplicate(true);invalid.logistics.workers[0].pos="bad";assert(not game.profile_store._valid(invalid))
	for w in l.workers:w.node.queue_free()
	l.load_state(saved.logistics);coin=l.workers.back();l.advance(30)
	assert(game.godot_coins==balance+3 and coin.cargo==0,"Saved cargo is credited once at home")
	game._save_profile();assert(game.profile_store.read_profile(SAVE).godot_coins==balance+3)
	# A continuous perimeter has no route. Replacing its eastern panel with a gate restores access.
	for x in [-6,0,6]:
		game._spawn_building(game.home_root,24,Vector3(x,0,-9),3,false)
		game._spawn_building(game.home_root,24,Vector3(x,0,9),3,false)
	for z in [-6,0,6]:
		for x in [-9,9]:
			game._spawn_building(game.home_root,24,Vector3(x,0,z),3,false)
			var b:Dictionary=game.buildings.back();b.yaw=PI/2;b.node.rotation.y=PI/2
	l.refresh_grid();assert(l.make_route(Vector3(4,0,4),l.GOLD_SITE).is_empty(),"Closed walls block haulers")
	var gate:Dictionary
	for b in game.buildings:
		if b.pos==Vector3(9,0,0):gate=b;break
	gate.type=25;game._refresh_wall_model(gate);l.refresh_grid()
	assert(not l.make_route(Vector3(4,0,4),l.GOLD_SITE).is_empty(),"Gate corridor restores a real path")
	coin.pos=gate.pos;coin.erase("route");l.visual_tick(.4);assert(gate.gate_open==1)
	assert(gate.node.find_child("GateLeft",true,false)!=null)
	game.camera_focus=Vector3(4,0,0);game.camera.size=32;game._position_camera();game._dismiss_menus()
	await shot("80-friendly-gate-and-prospector")
	coin.pos=l.COIN_SITE;l.workers[0].pos=l.GOLD_SITE;l.visual_tick(.4);assert(gate.gate_open==0)
	l.show_forest();l.visual_tick(.1);await shot("81-forest-roads-and-mining-sites")
	game.tutorial_step=12;game.unit_stock[0]=3;game._start_battle(1);game.deploy_kind=0
	assert(game.deploy_count==1)
	var screen:Vector2=game.camera.unproject_position(Vector3(-20,0,0))
	game._tap_world(screen);assert(game.battle_units.size()==1 and game.deployed_stock[0]==1)
	game._tap_world(screen);assert(game.battle_units.size()==2 and game.deployed_stock[0]==2)
	game._undo_squad();assert(game.battle_units.size()==1)
	await shot("82-one-unit-per-tap")
	print("V27_SINGLE_DEPLOY_FOREST_GATES_CARGO_SAVE_AND_FACTORY_PASSED")
	game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	quit()
