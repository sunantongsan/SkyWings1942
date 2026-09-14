extends SceneTree
## Test the shipped new-player flow using an isolated save, then raid and reload.
var game:Node3D
var output:="res://build/review"
const QA_SAVE:="user://qa_first_colony.json"
func _initialize()->void:call_deferred("run")

func shot(name:String)->void:
	await process_frame
	await process_frame
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"/"+name+".png")==OK)

func touch_at(position:Vector2)->void:
	var press:=InputEventScreenTouch.new();press.index=0;press.position=position;press.pressed=true;Input.parse_input_event(press)
	await process_frame
	var release:=InputEventScreenTouch.new();release.index=0;release.position=position;release.pressed=false;Input.parse_input_event(release)
	await process_frame

func open_game()->void:
	game=load("res://scenes/main.tscn").instantiate();game.profile_path=QA_SAVE;root.add_child(game)
	await process_frame
	await process_frame

func run()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(QA_SAVE+suffix):DirAccess.remove_absolute(QA_SAVE+suffix)
	root.size=Vector2i(1280,720)
	await open_game()
	assert(game.onboarding.page=="welcome" and not game.has_colony)
	assert(game.buildings.is_empty() and game.unit_stock[0]==0)
	assert(not FileAccess.file_exists(QA_SAVE),"Opening welcome must not create a colony")
	await shot("00-welcome")
	assert(game.onboarding.panel.get_rect().end.y<=720,"Welcome card must fit on screen")
	game.onboarding.show_help();await shot("00a-field-guide");game.onboarding.welcome()
	game.onboarding.choose_world()
	assert(game.onboarding.planet_buttons.size()==15 and game.onboarding.confirm_button.disabled)
	game.onboarding.select_world(2)
	assert(not FileAccess.file_exists(QA_SAVE),"Preview must not settle a planet")
	await shot("00b-choose-homeworld")
	game.onboarding._confirm_world()
	assert(game.has_colony and game.home_planet==2 and game.mode=="base")
	assert(game.buildings.is_empty() and game.power==0)
	var initial_metal:float=game.metal
	var initial_credits:float=game.credits
	game._economy_tick(1)
	assert(game.metal==initial_metal and game.credits==initial_credits,"An empty colony produces nothing")
	game._begin_build(1);game._place_building(Vector3.ZERO)
	assert(game.buildings.is_empty(),"A reactor cannot precede the Core")
	game._toggle_units();assert(not game.units_panel.visible)
	game._toggle_galaxy();assert(not game.galaxy_panel.visible)
	game.toast.hide()
	await shot("00c-empty-colony")
	assert(game.onboarding.guide.get_rect().end.y<600,"Tutorial card must not cover the bottom controls")
	# The mission button and terrain placement receive Android ScreenTouch events.
	await process_frame
	await touch_at(game.onboarding.guide_action.get_global_rect().get_center())
	assert(game.build_type==0,"Touch must activate the mission action")
	await touch_at(game.camera.unproject_position(Vector3.ZERO))
	assert(game.buildings.size()==1 and game.buildings[0].type==0 and game.buildings[0].level==1)
	assert(game.tutorial_step==0 and game.building_levels[0]==0,"Construction must not unlock facilities early")
	game._update_work_display();await shot("00g-construction-timer")
	var before:float=game.credits
	game._economy_tick(1);assert(game.credits==before,"Unfinished buildings cannot produce")
	game._begin_build(0);game._place_building(Vector3(8,0,0));assert(game.buildings.size()==1,"Busy builder blocks duplicate jobs")
	game._save_profile();game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	assert(game.buildings[0].get("job","")=="build","Active construction survives restart")
	game._advance_colony(game.colony_time+9)
	assert(game.tutorial_step==1 and game.building_levels[1]==0)
	var metal_before:float=game.metal
	game._economy_tick(1)
	assert(game.metal==metal_before,"Metal requires an Extractor")
	await shot("00d-first-core")
	for step in range(1,10):
		var kind:int=game.BUILD_ORDER[step]
		assert(game.tutorial_step==step)
		game._begin_build(kind)
		game._place_building(game.LANDING_SITES[kind])
		assert(game.tutorial_step==step,"Mission must wait for completion")
		game._advance_colony(game.colony_time+game.BUILD_SECONDS[kind]+1)
		assert(game.buildings.size()==step+1 and game.building_levels[kind]==1,"Build one required structure at a time")
		assert(game.tutorial_step==step+1 and game.power>=0)
		if step==1:await shot("00e-first-reactor")
		if step==3:
			# Resume halfway through the tutorial without reseeding or reselecting.
			game._save_profile();game.queue_free();await process_frame
			await open_game()
			assert(game.has_colony and game.home_planet==2 and game.tutorial_step==4)
			assert(game.buildings.size()==4 and game.onboarding.page=="welcome")
			await shot("00f-welcome-back")
			game.onboarding.enter_colony()
	assert(game.buildings.size()==10 and game.tutorial_step==10)
	assert(game._build_lock_reason(0)!="","Only one Core is allowed")
	game.toast.hide();await shot("01-home-planet")
	# A drag must pan rather than place or select an object on release.
	var start_focus:Vector3=game.camera_focus
	var press:=InputEventScreenTouch.new();press.index=0;press.position=Vector2(600,380);press.pressed=true;Input.parse_input_event(press)
	await process_frame
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(640,400);drag.relative=Vector2(40,20);Input.parse_input_event(drag)
	await process_frame
	var release:=InputEventScreenTouch.new();release.index=0;release.position=Vector2(640,400);release.pressed=false;Input.parse_input_event(release)
	await process_frame
	assert(game.camera_focus.distance_to(start_focus)>0.1 and game.selected_building==-1)
	game._center_camera();game._select_building_at(Vector3.ZERO)
	await shot("02-building-selected")
	var old_metal:float=game.metal
	game._upgrade_selected()
	assert(game.buildings[0].level==1 and game._builder_busy())
	game._advance_colony(game.colony_time+31)
	assert(game.buildings[0].level==2 and game.metal<old_metal and game.tutorial_step==11)
	game.info_panel.hide();game.selection_ring.hide()
	game._toggle_build();await shot("03-build-menu");game.build_panel.hide()
	for i in 8:game._train_unit(0)
	assert(game.unit_stock[0]==0 and game.training_queue.size()==8)
	game._update_work_display();await shot("04a-production-queue")
	assert(game.units_panel.get_rect().end.y<=game.work_label.position.y,"Queue timer must remain visible below the menu")
	game._save_profile();game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	assert(game.training_queue.size()==8 and game.unit_stock[0]==0)
	game._advance_colony(game.colony_time+5.1)
	assert(game.unit_stock[0]==1 and game.training_queue.size()==7,"One unit finishes at each queue deadline")
	game._advance_colony(game.colony_time+36)
	assert(game.unit_stock[0]==8 and game.training_queue.is_empty() and game.tutorial_step==12)
	await shot("04-fleet-menu")
	game.units_panel.hide();game._toggle_galaxy()
	await shot("05-galaxy-map")
	game._start_battle(game.home_planet)
	assert(game.mode=="base","The player cannot raid their own homeworld")
	game._start_battle(1)
	assert(game.awaiting_deployment and game.battle_units.is_empty())
	game._deploy_fleet(Vector3.ZERO);assert(game.awaiting_deployment,"Cannot deploy inside enemy base")
	game._deploy_fleet(Vector3(0,0,16))
	assert(not game.awaiting_deployment and game.battle_units.size()==8)
	for u in game.battle_units:assert(u.type==0,"Only trained unit types may deploy")
	await create_timer(0.4).timeout
	await shot("06-battle")
	game.set_process(false)
	for u in game.battle_units:u["last_shot"]=100000.0
	for i in 1800:
		if game.mode!="battle":break
		game._battle_tick(.1);game._visual_tick(.1)
		if i%20==0:await process_frame
	assert(game.mode=="victory" and game.tutorial_step==13,"The tutorial fleet must win the first raid")
	var settled:float=game.credits
	game._process(.1);assert(game.credits==settled,"Victory rewards must settle only once")
	await shot("07-victory")
	game._return_home()
	assert(game.map_index==2,"Returning from battle must restore the chosen world")
	game._save_profile()
	var saved:Dictionary=game.profile_store.read_profile(QA_SAVE)
	assert(saved.tutorial_step==13 and saved.home_planet==2 and saved.buildings.size()==10)
	game.queue_free();await process_frame
	await open_game();game.onboarding.enter_colony()
	assert(game.tutorial_step==13 and game.home_planet==2 and game.unit_stock[0]==8)
	assert(game.buildings[0].level==2)
	game.tutorial_dismissed=true;game._refresh_progress()
	root.size=Vector2i(1600,720);await process_frame;game._layout_ui()
	assert(game.header.get_rect().end.x<=1600)
	await shot("08-wide-phone")
	# Time catch-up is capped, exactly once, and safe against backward clocks.
	var time_before:float=game.colony_time
	var credits_before:float=game.credits
	game._advance_colony(time_before-60);assert(game.credits==credits_before)
	game._advance_colony(time_before+10*3600)
	assert(absf(game.credits-credits_before-8*3600*7.0)<1.0,"Offline production capped at eight hours")
	var caught_up:float=game.credits
	game._advance_colony(game.colony_time);assert(game.credits==caught_up,"No duplicate catch-up")
	game._select_building_at(Vector3.ZERO);game._begin_move();game._move_building(Vector3(-7,0,-4))
	assert(game.buildings[0].pos==Vector3.ZERO,"Relocation cannot overlap structures")
	game._move_building(Vector3(0,0,1));assert(game.buildings[0].pos==Vector3(0,0,1))
	# Verify the last-good backup can recover an invalid primary file.
	game._save_profile();game._save_profile()
	var file:=FileAccess.open(QA_SAVE,FileAccess.WRITE);file.store_string("corrupt");file.close()
	var recovered:Dictionary=game.profile_store.read_profile(QA_SAVE)
	assert(not recovered.is_empty() and game.profile_store.recovered_backup)
	game.profile_ready=false;game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(QA_SAVE+suffix):DirAccess.remove_absolute(QA_SAVE+suffix)
	print("PERSISTENT_CONSTRUCTION_UPGRADE_TRAINING_QUEUE_PASSED")
	print("GALAXY_VISUAL_AND_GAMEPLAY_CHECKS_PASSED")
	print("NEW_COLONY_TOUCH_ORDER_SAVE_RELOAD_AND_RAID_PASSED")
	quit(0)
