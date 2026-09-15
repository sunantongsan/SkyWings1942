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

	game._toggle_units();await process_frame;await process_frame
	var sc:ScrollContainer=game.units_panel.find_children("*","ScrollContainer",true,false)[0]
	var funds_before:float=game.credits
	var swipe_start:Vector2=sc.get_global_rect().get_center()
	var swipe_press:=InputEventScreenTouch.new();swipe_press.index=0;swipe_press.position=swipe_start;swipe_press.pressed=true;Input.parse_input_event(swipe_press);await process_frame
	var swipe:=InputEventScreenDrag.new();swipe.index=0;swipe.position=swipe_start-Vector2(0,160);swipe.relative=Vector2(0,-160);Input.parse_input_event(swipe);await process_frame
	var swipe_end:=InputEventScreenTouch.new();swipe_end.index=0;swipe_end.position=swipe.position;swipe_end.pressed=false;Input.parse_input_event(swipe_end);await process_frame
	assert(sc.scroll_vertical>0,"Finger drag must scroll over the unit cards")
	assert(game.training_queue.is_empty() and game.credits==funds_before,"Dragging must not buy units")
	sc.velocity=0;sc.scroll_vertical=0;await process_frame;await process_frame
	var fighter_button:Button=sc.get_child(0).get_child(0)
	await touch_at(fighter_button.get_global_rect().get_center())
	assert(game.training_queue.size()==1,"A stationary finger tap purchases exactly once")
	for i in 7:game._train_unit(0)
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
	game.unit_stock[1]=4
	game._start_battle(1)

	assert(game.awaiting_deployment and game.battle_units.is_empty())
	game._launch_assault();assert(game.awaiting_deployment,"Cannot launch an empty army")
	game.unit_stock[1]=4;game.deploy_kind=1;game.deploy_count=4
	game._deploy_fleet(Vector3(-18,0,0))
	assert(game.battle_units.size()==4 and game.awaiting_deployment)
	for u in game.battle_units:assert(u.type==1 and u.node.position.x<0)
	game.deploy_kind=0;game.deploy_count=4;game._deploy_fleet(Vector3(18,0,0))
	assert(game.battle_units.size()==8 and game.deployment_groups.size()==2)
	assert(game.battle_units[4].type==0 and game.battle_units[4].node.position.x>0)
	await shot("13-separated-deployment-squads")
	game._undo_squad();game._undo_squad()
	assert(game.battle_units.is_empty() and game.deployed_stock[0]==0 and game.deployed_stock[1]==0)
	game.deploy_kind=0;game.deploy_count=8
	game._deploy_fleet(Vector3.ZERO);assert(game.awaiting_deployment,"Cannot deploy inside enemy base")
	game._deploy_fleet(Vector3(0,0,16));game._launch_assault()
	assert(not game.awaiting_deployment and game.battle_units.size()==8)
	for u in game.battle_units:assert(u.type==0,"Only trained unit types may deploy")
	await create_timer(0.4).timeout
	game.deploy_kind=1;game.deploy_count=4
	var reserve_before:int=game.unit_stock[1]
	game._deploy_fleet(Vector3(-18,0,0))
	assert(game.unit_stock[1]==reserve_before-4 and game.battle_units.size()==12,"Reinforcements consume only the deployed reserves")
	game._deploy_fleet(Vector3(-18,0,0));assert(game.battle_units.size()==12,"Cannot deploy the same reserve twice")
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
	assert(game.tutorial_step==13 and game.home_planet==2 and game.unit_stock[0]==0)
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

	# Gold supply chain, parallel builders, map growth and firing defenses.
	game.gold=0;game._buy_drone();assert(game.drone_count==1)
	game._begin_build(10);game._place_building(Vector3(35,0,0))
	assert(game.buildings.back().type==10 and game.buildings.back().get("job","")=="build")
	var no_gold:float=game.gold
	game._advance_colony(game.colony_time+41)
	assert(game.building_levels[10]==1 and game.gold==no_gold,"Refinery requires a mining vehicle")
	game._build_miner();assert(game.miner_finish==0,"Mining vehicle requires a factory")
	game._begin_build(12);game._place_building(Vector3(43,0,0))
	game._advance_colony(game.colony_time+46)
	assert(game.building_levels[12]==1)
	game._begin_build(1);game._place_building(Vector3(60,0,0))
	game._advance_colony(game.colony_time+16)
	game._begin_build(13);game._place_building(Vector3(51,0,0))
	game._advance_colony(game.colony_time+31)
	assert(game.building_levels[13]==1)
	assert(game._unit_lock_reason(10).is_empty() and game._unit_lock_reason(18).is_empty())
	assert(not game._unit_lock_reason(11).is_empty() and not game._unit_lock_reason(19).is_empty())
	var old_queue:int=game.training_queue.size()
	var old_credits:float=game.credits
	game._train_unit(11);assert(game.training_queue.size()==old_queue and game.credits==old_credits,"Locked unit cannot charge resources")
	game._train_unit(10);game._train_unit(18);game._train_unit(0)
	assert(game.training_queue.size()==old_queue+3)
	game._advance_colony(game.colony_time+42)
	assert(game.unit_stock[10]>0 and game.unit_stock[18]>0,"Independent facility queues finish concurrently")
	game._select_building_at(Vector3(43,0,0));game._upgrade_selected()
	assert(not game._unit_lock_reason(10).is_empty(),"Upgrading facility cannot accept new orders")
	game._advance_colony(game.colony_time+31)
	assert(game._unit_lock_reason(12).is_empty() and not game._unit_lock_reason(11).is_empty(),"Factory level two unlocks artillery only")
	game._show_production(12)
	await shot("17-vehicle-production-levels")
	game._show_production(13)
	await shot("18-barracks-production-levels")
	game.units_panel.hide()
	print("FACILITY_GATES_PARALLEL_QUEUES_AND_UPGRADE_UNLOCKS_PASSED")
	var mining_metal:float=game.metal
	var mining_oil:float=game.oil
	game._build_miner()
	assert(game.metal==mining_metal-600 and game.oil==mining_oil-150)
	game._advance_colony(game.colony_time+16)
	assert(game.miner_count==1 and game.industry_visuals.size()==1)
	game._advance_colony(game.colony_time+101)
	assert(game.gold>=200)
	game._buy_drone();assert(game.drone_count==1 and game.drone_finish>0)
	game._advance_colony(game.drone_finish+1);assert(game.drone_count==2)
	game.gold=100000
	for i in 12:
		game._buy_drone()
		game._advance_colony(maxf(game.colony_time,game.drone_finish)+1)
	assert(game.drone_count==10 and game.drone_visuals.size()==10)
	for i in 10:
		game._begin_build(1);game._place_building(Vector3(100+i*8,0,0))
	assert(game._builder_busy(),"Ten active jobs use all drones")
	var count_before:int=game.buildings.size()
	game._begin_build(1);game._place_building(Vector3(200,0,0))
	assert(game.buildings.size()==count_before,"No eleventh construction job")
	game._save_profile();game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	assert(game.drone_count==10 and game.miner_count==1 and game._builder_busy())
	assert(game.buildings.back().pos.x==172,"Expanded colony positions survive save/load")
	game._advance_colony(game.colony_time+16)
	assert(not game._builder_busy())
	game._begin_build(11);game._place_building(Vector3(35,0,10));game._advance_colony(game.colony_time+46)
	assert(game.building_levels[11]==1)
	game.camera_focus=Vector3(35,0,3);game._position_camera();game._update_work_display()
	await shot("09-gold-refinery-and-miner")
	game._toggle_build();await shot("10-ten-construction-drones");game.build_panel.hide()
	game._start_defense_drill()
	assert(game.home_attackers.size()==3)
	var target_hp:float=game.home_attackers[1].hp
	game._home_defense_tick(1.3)
	var was_hit:=false
	for u in game.home_attackers:
		if u.hp<target_hp:was_hit=true
	assert(was_hit,"Home defenses must damage actual enemy units")
	await shot("11-home-defense-drill")
	var valid_profile:Dictionary=game.profile_store.read_profile(QA_SAVE)
	for i in 320:valid_profile.buildings.append({"type":1,"level":1,"pos":[500+i*8,0,0]})
	assert(game.profile_store._valid(valid_profile),"No legacy 300-building save cap")
	game._start_battle(14)
	assert(game.battle_targets.size()==11 and game.battle_targets[0].level==15,"Late worlds have more and stronger defenses")
	game._deploy_fleet(Vector3(0,0,16));game._launch_assault()
	for u in game.battle_units:u.hp=0
	game._battle_tick(.1)
	assert(game.mode=="battle","Reserves keep the battle open after the active squad is destroyed")
	game.deployed_stock=game.raid_stock.duplicate();game._battle_tick(.1)
	assert(game.mode=="base","A destroyed fleet with no reserves loses the battle")
	print("GOLD_MINERS_TEN_DRONES_EXPANDED_MAP_AND_DEFENSE_AI_PASSED")

	# Every building uses the same completed-level five-star unlock.
	for kind in 12:
		var candidate:Dictionary=game._spawn_building(game.battle_root,kind,Vector3.ZERO,4,true)
		assert(game._can_fire(candidate)==(kind in [8,11]),"Civilian buildings below 5 stars cannot fire")
		candidate.level=5;game._update_rank_label(candidate)
		assert(game._can_fire(candidate),"Every completed 5-star building can defend")
		assert(candidate.rank_label.text=="★★★★★")
		var damage5:float=game._shot_damage(candidate,1)
		candidate.level=6;assert(game._shot_damage(candidate,1)>damage5)
		candidate["job"]="build";assert(not game._can_fire(candidate))
		candidate.node.queue_free()
	var core:Dictionary=game.buildings[0]
	core.level=4;game._refresh_progress()
	game._select_building_at(core.pos);game._upgrade_selected()
	assert(core.level==4 and not game._can_fire(core),"Do not unlock defense when the upgrade merely starts")
	game._advance_colony(game.colony_time+121)
	assert(core.level==5 and game._can_fire(core))
	game._update_rank_label(core);assert(core.rank_label.text=="★★★★★")
	var invader:Node3D=game._unit_model(0,true);game.home_root.add_child(invader);invader.position=core.pos+Vector3(0,3,8)
	var foe:Dictionary={"node":invader,"hp":100.0}
	core["fire_wait"]=0;game._defense_tick([core],[foe],1.3,1)
	assert(foe.hp<100,"A five-star Core must actually damage an invader")
	invader.queue_free()
	game.camera_focus=core.pos;game._position_camera();game._select_building_at(core.pos)
	await shot("12-five-star-core-defense")
	game._save_profile();game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	assert(game.buildings[0].level==5 and game._can_fire(game.buildings[0]),"Five-star defense persists on reload")
	assert(game.buildings[0].rank_label.text=="★★★★★")
	print("ALL_BUILDING_STAR_RANKS_AND_LEVEL_FIVE_RETALIATION_PASSED")

	var rocket_target:=Node3D.new();game.world_root.add_child(rocket_target);rocket_target.position=Vector3(12,4,0)
	game._weapon_effect(Vector3(0,4,0),rocket_target,rocket_target.position,true)
	assert(game.missiles.size()==1)
	var origin:Vector3=game.missiles[0].node.position
	game._projectile_tick(.1)
	assert(game.missiles[0].node.position.distance_to(origin)>1,"Missile must visibly travel")
	for i in 60:game._projectile_tick(.1)
	assert(game.missiles.is_empty(),"Missile and impact must clean up")
	rocket_target.queue_free()
	print("TOUCH_SCROLL_SQUAD_PLACEMENT_AND_MOVING_MISSILES_PASSED")
	# Real ground models, walk/recoil animation, and persistent destruction visuals.
	game._clear_wrecks()
	var lineup:Array[Node3D]=[]
	for kind in range(10,20):
		assert(ResourceLoader.exists("res://assets/models/"+game._unit_asset(kind)+".glb"))
		if DisplayServer.get_name()!="headless":assert(ResourceLoader.exists("res://assets/icons/units/"+game._unit_asset(kind)+".png"))
		var model:Node3D=game._unit_model(kind);game.world_root.add_child(model)
		model.position=Vector3((kind-10)%5*4-8,game._unit_height(kind),70+floori((kind-10)/5.0)*5)
		lineup.append(model)
		if kind not in [16,17]:assert(model.position.y<.1,"Ground troops must not float like aircraft")
	var soldier:Node3D=lineup[8]
	var soldier_parts:Dictionary=soldier.get_meta("parts")
	game._animate_unit({"node":soldier,"type":18},.12,true,Vector3.ZERO)
	assert(absf(soldier_parts.LeftLeg.rotation.x)>.1 and soldier_parts.LeftLeg.rotation.x==-soldier_parts.RightLeg.rotation.x)
	var tank:Node3D=lineup[0];var tank_parts:Dictionary=tank.get_meta("parts")
	assert(tank_parts.Weapon.get_parent()==tank_parts.Turret)
	var rest:Vector3=tank.get_meta("weapon_rest");game._fire_animation(tank)
	assert(tank_parts.Weapon.position.z<rest.z,"Tank cannon recoils on firing")
	game.camera_focus=Vector3(0,0,72);game._position_camera();game.camera.size=21
	game.info_panel.hide();game.onboarding.guide.hide()
	await shot("14-ground-force-lineup")
	game._toggle_units();await shot("15-ground-unit-portraits");game.units_panel.hide()
	var destroyed:Dictionary={"node":tank,"type":10,"hp":0}
	game._destroy_entity(destroyed,false)
	assert(is_instance_valid(tank) and game.wreck_root.is_ancestor_of(tank),"Destroyed vehicles leave wreckage instead of disappearing")
	var structure:Dictionary=game._spawn_building(game.battle_root,0,Vector3(1,0,72),1,true)
	game._destroy_entity(structure,true)
	assert(structure.dying and is_instance_valid(structure.node))
	var wreck_count:int=game.wreck_root.get_child_count();game._destroy_entity(structure,true)
	assert(game.wreck_root.get_child_count()==wreck_count,"Destruction starts only once")
	await create_timer(1.3).timeout
	assert(structure.node.scale.y<.3,"Destroyed building collapses into rubble")
	await shot("16-burning-building-and-tank-wreckage")
	await create_timer(11.5).timeout
	assert(game.wreck_root.get_child_count()==0,"Wreckage and smoke expire cleanly")
	for model in lineup:
		if is_instance_valid(model):model.queue_free()
	print("GROUND_MODELS_PORTRAITS_WALK_RECOIL_AND_WRECKAGE_PASSED")
	game.coin_system.claim_daily()
	var coins:int=game.godot_coins
	game.coin_system.claim_daily();assert(game.godot_coins==coins,"Daily reward cannot be claimed twice")
	game.godot_coins=100
	game._train_unit(0);game._train_unit(0)
	var stock:int=game.unit_stock[0]
	game.coin_system.speed_line(6)
	assert(game.unit_stock[0]==stock+1 and game.training_queue.size()==1,"Speed-up finishes exactly one queued unit")
	var balance:int=game.godot_coins
	var previous_metal:float=game.metal
	game.coin_system.exchange("Metal")
	assert(game.godot_coins==balance-10 and game.metal==previous_metal+1000)
	game.coin_system.obstacle_id=game.art.obstacles.keys()[0]
	var removed:int=game.coin_system.obstacle_id
	game.coin_system.clear_selected()
	assert(removed in game.cleared_obstacles and not game.art.obstacles.has(removed))
	balance=game.godot_coins;previous_metal=game.metal
	game.coin_system.obstacle_id=removed;game.coin_system.clear_selected()
	assert(game.godot_coins==balance and game.metal==previous_metal,"Cleared obstacles cannot pay twice")
	game._select_building_at(game.buildings[0].pos)
	var previous_level:int=game.buildings[0].level
	game._upgrade_selected();assert(game.buildings[0].get("job","")=="upgrade")
	game.coin_system.speed_build(0)
	assert(game.buildings[0].level==previous_level+1 and game.buildings[0].get("job","")=="","Coin speed-up completes the selected building upgrade")
	game.coin_system.show_panel();await shot("19-godot-coin-rewards")
	game.coin_system.panel.hide()
	print("COIN_DAILY_EXCHANGE_SPEEDUP_OBSTACLES_AND_REINFORCEMENTS_PASSED")
	# Verify the last-good backup can recover an invalid primary file.
	game._save_profile();game._save_profile()
	var file:=FileAccess.open(QA_SAVE,FileAccess.WRITE);file.store_string("corrupt");file.close()
	var recovered:Dictionary=game.profile_store.read_profile(QA_SAVE)
	assert(not recovered.is_empty() and game.profile_store.recovered_backup)
	assert(recovered.godot_coins==game.godot_coins and recovered.last_coin_day==game.last_coin_day and removed in recovered.cleared_obstacles,"Coin balance, daily claims and obstacle removal persist")
	game.profile_ready=false;game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(QA_SAVE+suffix):DirAccess.remove_absolute(QA_SAVE+suffix)
	print("PERSISTENT_CONSTRUCTION_UPGRADE_TRAINING_QUEUE_PASSED")
	print("GALAXY_VISUAL_AND_GAMEPLAY_CHECKS_PASSED")
	print("NEW_COLONY_TOUCH_ORDER_SAVE_RELOAD_AND_RAID_PASSED")
	quit(0)
