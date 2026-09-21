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
	assert(game.onboarding.page=="planets" and not game.has_colony)
	assert(game.buildings.is_empty() and game.unit_stock[0]==0)
	assert(not FileAccess.file_exists(QA_SAVE),"Opening the world picker must not create a colony")
	await shot("00-direct-homeworld-picker")
	assert(game.onboarding.panel.get_rect().end.y<=720,"World picker must fit on screen")
	game.onboarding.show_help();await shot("00a-field-guide");game.onboarding.welcome()
	game.onboarding.choose_world()
	assert(game.onboarding.planet_buttons.size()==15 and game.onboarding.confirm_button.disabled)
	game.onboarding.select_world(2)
	assert(not FileAccess.file_exists(QA_SAVE),"Preview must not settle a planet")
	await shot("00b-choose-homeworld")
	game.onboarding._confirm_world()
	assert(game.has_colony and game.home_planet==2 and game.mode=="base")
	assert(game.onboarding.page=="video","New colony opens the first video lesson")
	if DisplayServer.get_name()!="headless":
		assert(is_instance_valid(game.onboarding.video) and game.onboarding.video.is_playing())
		await create_timer(.7).timeout
		assert(game.onboarding.video.stream_position>0,"Offline tutorial video advances")
		await shot("00h-first-video-lesson")
	game.onboarding.close_lesson(false)
	assert(not game.onboarding.screen.visible and game.buildings.is_empty(),"Video playback never constructs anything in the real colony")
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
			assert(game.buildings.size()==4 and game.onboarding.page.is_empty() and game.mode=="base")
			await shot("00f-direct-resume")
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

	game._begin_build(19);game._place_building(Vector3(-70,0,0));game._advance_colony(game.colony_time+31)
	assert(game.garrison.capacity(0)==10,"Tutorial builds a real Air Camp before training")
	game._toggle_units();await process_frame;await process_frame
	var sc:ScrollContainer
	for candidate in game.units_panel.find_children("*","ScrollContainer",true,false):
		if candidate.get_child_count()>0 and candidate.get_child(0) is GridContainer:sc=candidate;break
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
	assert(saved.tutorial_step==13 and saved.home_planet==2 and saved.buildings.size()==11)
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
	game._begin_build(1);game._place_building(Vector3(80,0,0))
	game._advance_colony(game.colony_time+16)
	game._begin_build(12);game._place_building(Vector3(43,0,0))
	game._advance_colony(game.colony_time+46)
	assert(game.building_levels[12]==1)
	game._begin_build(13);game._place_building(Vector3(70,0,0))
	game._advance_colony(game.colony_time+31)
	assert(game.building_levels[13]==1)
	for pair in [[18,16],[20,32]]:
		game._begin_build(pair[0]);game._place_building(Vector3(-70,0,pair[1]));game._advance_colony(game.colony_time+31)
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
	game._advance_colony(game.colony_time+181)
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
	game._begin_build(11);game._place_building(Vector3(35,0,-15));game._advance_colony(game.colony_time+46)
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

	# Preview shares placement checks, and armies can exceed the old active-unit cap.
	game._begin_build(1);game.placement_guide.pointer=Vector3.ZERO;game.placement_guide.has_pointer=true;game.placement_guide.tick()
	assert(not game._placement_reason(Vector3.ZERO).is_empty())
	assert(game.placement_guide.footprint.material_override.albedo_color.r>game.placement_guide.footprint.material_override.albedo_color.g)
	var buildings_before:int=game.buildings.size();game._place_building(Vector3.ZERO)
	assert(game.buildings.size()==buildings_before,"Red construction footprint cannot be placed")
	game.placement_guide.pointer=Vector3(-30,0,-20);game.placement_guide.tick()
	assert(game._placement_reason(Vector3(-30,0,-20)).is_empty())
	assert(game.placement_guide.footprint.material_override.albedo_color.g>game.placement_guide.footprint.material_override.albedo_color.r)
	await shot("21-green-red-building-placement")
	game._place_building(Vector3(-30,0,-20));assert(game.buildings.size()==buildings_before+1)
	game._advance_colony(game.colony_time+16)
	game.unit_stock[0]=60;game.unit_stock[10]=30;game.unit_stock[18]=35
	game._start_battle(1);game.deploy_kind=0;game.deploy_count=0
	game.placement_guide.tick()
	assert(game._deployment_reason(Vector3.ZERO)!="" and game._deployment_reason(Vector3(-18,0,0))=="")
	await shot("22-green-red-deployment-zones")
	game._deploy_fleet(Vector3(-18,0,0));assert(game.battle_units.size()==60)
	game._launch_assault()
	game.deploy_kind=10;game._deploy_fleet(Vector3(18,0,0))
	game.deploy_kind=18;game._deploy_fleet(Vector3(0,0,18))
	assert(game.battle_units.size()==125 and game.unit_stock[0]==0 and game.unit_stock[10]==0 and game.unit_stock[18]==0,"Deploy ALL before and during battle without a 24-unit cap")
	for unit in game.battle_units:
		var pos:Vector3=unit.node.position
		assert(absf(pos.x)<=34 and absf(pos.z)<=30 and (absf(pos.x)>=16 or absf(pos.z)>=13),"Every unit spawns inside deployment bands")
		var forward:Vector3=-unit.node.global_basis.z if unit.type<10 else unit.node.global_basis.z
		assert(forward.normalized().dot(Vector3(-pos.x,0,-pos.z).normalized())>.99,"Models face the enemy rather than flying backwards")
	# A destroyed nearby target must not hold up later units in the same simulation tick.
	game.battle_targets[0].hp=0
	var distances:Array[float]=[]
	for unit in game.battle_units:
		var closest:=INF
		for target in game.battle_targets:
			if target.hp>0:closest=minf(closest,Vector2(unit.node.position.x,unit.node.position.z).distance_to(Vector2(target.pos.x,target.pos.z)))
		distances.append(closest)
	game.battle_units[0].hp=0;game.battle_units[0].node.free()
	game._battle_tick(.1)
	for i in game.battle_units.size():
		var unit:Dictionary=game.battle_units[i]
		if unit.hp<=0 or distances[i]<=game._attack_range(unit.type):continue
		var closest:=INF
		for target in game.battle_targets:
			if target.hp>0:closest=minf(closest,Vector2(unit.node.position.x,unit.node.position.z).distance_to(Vector2(target.pos.x,target.pos.z)))
		assert(closest<distances[i],"Every distant living unit advances toward a living target")
	var healthy:Dictionary=game.battle_units[1]
	healthy.hp=healthy.max_hp*.5
	game.battle_targets[1].hp=game.battle_targets[1].max_hp*.25
	game.status_bars.tick()
	assert(is_equal_approx(game.status_bars.world_rows[str(healthy.node.get_instance_id())].hp.value,50),"Unit health bar uses current and maximum HP")
	assert(is_equal_approx(game.status_bars.world_rows[str(game.battle_targets[1].node.get_instance_id())].hp.value,25),"Building health bar tracks damage")
	assert(game.status_bars.raid_bar.visible and game.status_bars.raid_bar.value<100)
	await process_frame
	assert(game.status_bars.world_rows[str(healthy.node.get_instance_id())].hp.size.y<=8,"Army health bars remain thin instead of inheriting panel padding")
	await shot("24-health-bars-and-battle-timer")
	await shot("23-unrestricted-mixed-army")
	game._return_home()
	print("PLACEMENT_COLORS_UNRESTRICTED_ARMIES_FACING_AND_ADVANCE_PASSED")

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
	game._advance_colony(float(core.finish)+1)
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
	var removed:=-1
	for id in game.art.obstacles:
		var clear_of_buildings:=true
		for building in game.buildings:
			if building.pos.distance_to(game.art.obstacles[id])<6:clear_of_buildings=false
		if clear_of_buildings:removed=int(id);break
	assert(removed>=0)
	var obstacle_pos:Vector3=game.art.obstacles[removed]
	game._dismiss_menus();game.coin_system.clearing=false
	game.camera_focus=obstacle_pos;game._position_camera();game.camera.size=24
	var selection_cost:float=game.metal
	await touch_at(game.camera.unproject_position(obstacle_pos))
	assert(game.coin_system.obstacle_id==removed and game.coin_system.panel.visible and game.selection_ring.visible,"Tap obstacle directly to select it")
	assert(game.metal==selection_cost and game.clearing_jobs.is_empty(),"Selecting does not spend resources")
	await shot("25-direct-obstacle-selection")
	var before_clear_metal:float=game.metal
	var before_clear_oil:float=game.oil
	var saved_drone_count:int=game.drone_count
	game.drone_count=1
	await touch_at(game.coin_system.remove_button.get_global_rect().get_center())
	assert(game.clearing_jobs.size()==1 and game._builder_busy(),"Clearing reserves a construction drone")
	assert(game.metal==before_clear_metal-100 and game.oil==before_clear_oil-50)
	assert(removed not in game.cleared_obstacles and game.art.obstacles.has(removed),"Obstacle remains until drone finishes")
	assert(not game._build_lock_reason(1).is_empty(),"Occupied clearing drone cannot also build")
	game.coin_system.obstacle_id=removed;game.coin_system.clear_selected()
	assert(game.clearing_jobs.size()==1 and game.metal==before_clear_metal-100,"Repeated taps do not charge twice")
	game.drone_count=saved_drone_count
	game._save_profile();game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	assert(game.clearing_jobs.size()==1 and int(game.clearing_jobs[0].id)==removed,"Active drone clearing persists on reload")
	var clear_job:Dictionary=game.clearing_jobs[0]
	game.camera_focus=Vector3(clear_job.pos[0],0,clear_job.pos[2]);game._position_camera();game.camera.size=24
	game.onboarding.guide.hide();game.info_panel.hide()
	game._industry_tick(3.0);game._update_work_display()
	await shot("20-drone-clearing-and-coin-header")
	assert(game.resource_labels.size()==7 and game.resource_labels[6].text==game._fmt(game.godot_coins),"Coin has its own live resource card")
	var coin_card:Control=game.header.get_child(7)
	await touch_at(coin_card.get_global_rect().get_center())
	assert(is_instance_valid(game.coin_system.panel) and game.coin_system.panel.visible,"Coin resource card opens its menu")
	game._dismiss_menus()
	game._advance_colony(float(clear_job.started)+10)
	await touch_at(game.camera.unproject_position(Vector3(clear_job.pos[0],0,clear_job.pos[2])))
	game.coin_system.tick();game.status_bars.tick()
	assert(game.coin_system.obstacle_bar.visible and is_equal_approx(game.coin_system.obstacle_bar.value,50),"Reselected obstacle shows halfway progress")
	assert(game.coin_system.remove_button.disabled,"Active removal cannot be purchased again")
	await shot("26-obstacle-removal-progress")
	game._dismiss_menus()
	game._advance_colony(float(clear_job.finish)+1)
	game.status_bars.tick();assert(not game.status_bars.world_rows.has("clear_"+str(removed)),"Completed job removes its progress bar")
	assert(game.clearing_jobs.is_empty() and not game._builder_busy())
	assert(removed in game.cleared_obstacles and not game.art.obstacles.has(removed))
	var coin_after_clear:int=game.godot_coins
	game.coin_system.complete_clear(clear_job);assert(game.godot_coins==coin_after_clear,"Job completion pays only once")
	print("DRONE_CLEARING_COST_BUSY_SAVE_RELOAD_COMPLETION_AND_COIN_HEADER_PASSED")
	balance=game.godot_coins;previous_metal=game.metal
	game.coin_system.obstacle_id=removed;game.coin_system.clear_selected()
	assert(game.godot_coins==balance and game.metal==previous_metal,"Cleared obstacles cannot pay twice")
	game._select_building_at(game.buildings[0].pos)
	var previous_level:int=game.buildings[0].level
	game._upgrade_selected();assert(game.buildings[0].get("job","")=="upgrade")
	var upgrade_job:Dictionary=game.buildings[0]
	game._advance_colony((float(upgrade_job.started)+float(upgrade_job.finish))*.5)
	game._train_unit(10);game._train_unit(18)
	game.units_panel.hide();game._dismiss_menus();game.info_panel.hide()
	game.camera_focus=upgrade_job.pos;game.camera.size=36;game._position_camera();game.status_bars.tick()
	assert(is_equal_approx(game.status_bars.world_rows[str(upgrade_job.node.get_instance_id())].task.value,50),"Upgrade bar reflects elapsed time")
	assert(game.status_bars.jobs().size()>=3,"Independent production and building timers each have progress bars")
	await shot("27-construction-and-production-progress")
	game.coin_system.speed_build(0)
	assert(game.buildings[0].level==previous_level+1 and game.buildings[0].get("job","")=="","Coin speed-up completes the selected building upgrade")
	game.coin_system.show_panel();await shot("19-godot-coin-rewards")
	game._dismiss_menus()
	print("DIRECT_OBSTACLE_SELECTION_HEALTH_AND_TIMED_PROGRESS_BARS_PASSED")
	print("COIN_DAILY_EXCHANGE_SPEEDUP_OBSTACLES_AND_REINFORCEMENTS_PASSED")
	await check_godot_faction()
	await check_cartoon_roster()
	await check_living_garrison()
	await check_yards_and_rewards()
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
	print("DIRECT_ENTRY_AND_OFFLINE_VIDEO_LESSONS_PASSED")
	print("GALAXY_VISUAL_AND_GAMEPLAY_CHECKS_PASSED")
	print("NEW_COLONY_TOUCH_ORDER_SAVE_RELOAD_AND_RAID_PASSED")
	quit(0)

func check_godot_faction()->void:
	game._advance_colony(game.colony_time+500)
	game._return_home();game.onboarding.guide.hide();game.info_panel.hide()
	game.selected_building=-1;game.status_bars.tick()
	for b in game.buildings:
		if b.hp==b.max_hp:assert(not game.status_bars.world_rows[str(b.node.get_instance_id())].hp.visible,"Healthy home buildings hide their HP bars")
	var core:Dictionary=game.buildings[0]
	game._select_building_at(core.pos);game.status_bars.tick()
	assert(game.status_bars.world_rows[str(core.node.get_instance_id())].hp.visible,"Selection reveals health")
	game.info_panel.hide();core.hp-=1;game.status_bars.tick()
	assert(game.status_bars.world_rows[str(core.node.get_instance_id())].hp.visible,"Damaged home buildings reveal health")
	core.hp=core.max_hp
	var old_save:Dictionary=game.profile_store.read_profile(QA_SAVE)
	old_save.unit_stock.resize(20)
	assert(game.profile_store._valid(old_save),"Previous 20-unit saves remain valid")
	game.metal=100000;game.oil=100000;game.credits=100000
	assert(not game._build_lock_reason(16).is_empty(),"Godot production requires its Citadel and Well")
	for kind in [14,15,16,17]:
		game._begin_build(kind)
		assert(game.build_type==kind,"Godot structure unlock order")
		var pos:=Vector3(34+(kind-14)%2*9,0,45+floori((kind-14)/2.0)*9)
		game._place_building(pos)
		assert(game.buildings.back().type==kind and game.buildings.back().job=="build")
		game._advance_colony(game.colony_time+game.BUILD_SECONDS[kind]+1)
	assert(game.building_levels[14]==1 and game.building_levels[15]==1 and game.building_levels[16]==1)
	assert(game._can_fire(game.buildings.back()),"Runebolt Spire attacks at level one")
	assert(game._unit_lock_reason(20).is_empty() and not game._unit_lock_reason(21).is_empty())
	game._train_unit(20);game._advance_colony(game.colony_time+60)
	assert(game.unit_stock[20]==1)
	var sanctum_index:int=game.buildings.size()-2
	game.selected_building=sanctum_index;game._upgrade_selected();game._advance_colony(game.colony_time+500)
	assert(game._unit_lock_reason(21).is_empty() and not game._unit_lock_reason(22).is_empty())
	game.selected_building=sanctum_index;game._upgrade_selected();game._advance_colony(game.colony_time+500)
	game._train_unit(21);game._train_unit(22);game._advance_colony(game.colony_time+200)
	assert(game.unit_stock[21]==1 and game.unit_stock[22]==1)
	game._save_profile();game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	assert(game.unit_stock.size()==24 and game.unit_stock[22]==1 and game.building_levels[16]==3,"Faction buildings and troops survive reload")
	game.camera_focus=Vector3(38,0,51);game.camera.size=29;game._position_camera()
	game.info_panel.hide();game.onboarding.guide.hide()
	var showcase:Array=[]
	for kind in range(20,23):
		var actor:Node3D=game._unit_model(kind);game.home_root.add_child(actor);actor.position=Vector3(33+(kind-20)*4,0,62);showcase.append(actor)
	await shot("28-godot-fantasy-colony")
	game._show_production(16);await shot("29-godot-summoning-roster");game.units_panel.hide()
	for actor in showcase:actor.queue_free()
	game.unit_stock[20]=4;game.unit_stock[21]=4;game.unit_stock[22]=4
	game._start_battle(4);game.deploy_kind=20;game.deploy_count=4;game.placement_guide.tick()
	assert(game.battle_targets[0].type==14 and game.terrain_material.get_shader_parameter("deployment_active"),"Godot rival bases have persistent terrain deployment colors")
	await shot("30-godot-deployment-colors")
	game._deploy_fleet(Vector3(0,0,15));game._launch_assault();game.deploy_kind=22;game.placement_guide.tick()
	assert(game.terrain_material.get_shader_parameter("deployment_active"),"Colors remain after ATTACK while reserves exist")
	game._deploy_fleet(Vector3(-18,0,0));game.deploy_kind=21;game._deploy_fleet(Vector3(18,0,0))
	for i in 45:game._battle_tick(.1);game.visual_time+=.1;game._projectile_tick(.1)
	var magic:=false
	for bolt in game.missiles:
		if bolt.get("arcane",false):magic=true
	assert(magic,"Godot forces and defenses fire visible arcane projectiles")
	var keep:Dictionary=game.battle_targets[0]
	game._destroy_entity(keep,true)
	assert(not keep.node.find_child("ShieldField",true,false).visible,"Destroyed Citadel shields switch off instead of becoming opaque wreck spheres")
	await shot("31-godot-battle-magic")
	game._return_home();game.placement_guide.tick()
	assert(not game.terrain_material.get_shader_parameter("deployment_active"),"Battle overlay clears on returning home")
	print("GODOT_FACTION_MODELS_UNLOCKS_TRAINING_COMBAT_SAVE_AND_DEPLOYMENT_COLORS_PASSED")

func check_cartoon_roster()->void:
	game._return_home();game._advance_colony(game.colony_time+300)
	game.onboarding.guide.hide();game.units_panel.hide();game.info_panel.hide()
	if is_instance_valid(game.coin_system.panel):game._dismiss_menus()
	var credits_before:float=game.credits;var oil_before:float=game.oil
	game._train_unit(23)
	assert(game.training_queue.size()==1 and game.training_queue[0].finish-game.colony_time==3,"Pigeon takes three seconds in an idle Hangar")
	assert(game.credits==credits_before-40 and game.oil==oil_before-5,"Pigeon costs match the displayed price")
	game._advance_colony(game.colony_time+1.5);game.status_bars.tick()
	assert(is_equal_approx(game.status_bars.job_rows.back().bar.value,50),"Pigeon progress uses its real three-second duration")
	game._advance_colony(game.colony_time+1.6);assert(game.unit_stock[23]==1)
	game._save_profile();game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	assert(game.unit_stock.size()==24 and game.unit_stock[23]==1,"New pigeon stock survives save/reload")
	assert(game._unit_icon(23)!=null or DisplayServer.get_name()=="headless")
	game.onboarding.guide.hide();game.info_panel.hide();game.toast.hide()
	# Close-up of actual game-ready models, not an illustration.
	var lineup:Array=[]
	for i in 4:
		var kind:int=[18,10,0,23][i]
		var model:Node3D=game._unit_model(kind);game.home_root.add_child(model)
		model.position=Vector3(-7+i*4.6,1.8 if kind in [0,23] else 0,73)
		model.rotation.y=PI if game._is_air_unit(kind) else 0.0
		lineup.append(model)
	game.camera_focus=Vector3(0,0,73);game.camera.size=16;game._position_camera()
	await shot("32-cartoon-soldier-tank-aircraft-pigeon")
	for model in lineup:model.queue_free()
	game._center_camera();game.camera.size=36;game._position_camera()
	await shot("33-scrap-metal-home-colony")
	game._show_production(6);await shot("34-pigeon-hangar-production");game.units_panel.hide()
	game._start_battle(1);game.deploy_kind=23;game.deploy_count=1;game._deploy_fleet(Vector3(0,0,15))
	var bird:Dictionary=game.battle_units.back()
	assert(bird.type==23 and bird.hp==60 and bird.damage==5 and is_equal_approx(bird.node.position.y,3.2))
	var direction:Vector3=Vector3(-bird.node.position.x,0,-bird.node.position.z).normalized()
	assert((-bird.node.global_basis.z).dot(direction)>.99,"Pigeon faces the enemy beak-first")
	game._animate_unit(bird,.1,true,Vector3.ZERO)
	assert(absf(bird.node.get_meta("parts").LeftWing.rotation.z)>.1,"Pigeon has animated wing pivots")
	game._launch_assault()
	var target:Dictionary=game._assault_target(bird,game.battle_targets)
	assert(not target.is_empty() and game._can_fire(target),"Deployed pigeon prioritizes a weapon")
	var previous:Vector3=bird.node.position
	game._battle_tick(.1)
	assert(bird.node.position.distance_to(target.pos)<previous.distance_to(target.pos),"Pigeon advances toward its weapon target")
	game._return_home()
	print("CARTOON_ASSETS_PIGEON_COST_TIME_PROGRESS_FLIGHT_SAVE_AND_DEPLOYMENT_PASSED")

func check_living_garrison()->void:
	game._return_home();game.onboarding.guide.hide();game.info_panel.hide()
	game.unit_stock.fill(0);game.unit_stock[0]=8;game.unit_stock[10]=6;game.unit_stock[18]=12;game.unit_stock[23]=4
	game._apply_map_theme(0);game.garrison.sync();game.garrison.focus()
	assert(game.garrison.counts==[12,6,12],"Garrison totals come from owned units")
	assert(game.garrison.actors.size()==24,"Displayed units have a bounded budget")
	var represented:Dictionary={};var patrols:=0
	for actor in game.garrison.actors:
		represented[actor.type]=int(represented.get(actor.type,0))+1
		if actor.patrol:patrols+=1
	for kind in represented:assert(represented[kind]<=game.unit_stock[kind],"Patrol and parked models never exceed real stock")
	assert(patrols==3)
	var stored:PackedInt32Array=game.unit_stock.duplicate()
	var defender:Dictionary=game.garrison.actors[0]
	var origin:Vector3=defender.node.position
	game.garrison.tick(.2)
	assert(defender.node.position.distance_to(origin)>.01,"Patrols actually move")
	var intruder:Node3D=game._unit_model(0,true);game.home_root.add_child(intruder)
	intruder.position=defender.node.position+Vector3(1,0,0)
	var enemy:Dictionary={"node":intruder,"type":0,"hp":100.0,"max_hp":100.0,"target":Vector3.ZERO}
	game.home_attackers.append(enemy);game.visual_time+=2;game.garrison.tick(.1)
	assert(enemy.hp<100,"Patrols damage hostile units without tower assistance")
	assert(game.unit_stock==stored,"Patrolling does not mint or spend units")
	intruder.queue_free();game.home_attackers.clear()
	game._begin_build(1)
	assert(not game._placement_reason(game.garrison.pads[0]).is_empty(),"Construction cannot cover the active yards")
	game.build_type=-1;game.placement_guide.tick();game.toast.hide()
	await shot("35-airfield-motor-pool-and-parade-ground")
	game.unit_stock[0]-=3;game.garrison.sync()
	assert(game.garrison.counts[0]==9,"Yard counts follow consumed reserves")
	root.size=Vector2i(1280,720);await process_frame;game._layout_ui();await process_frame
	assert(game.dock.get_global_rect().position.x>=0 and game.dock.get_global_rect().end.x<=1280,"Garrison and SFX buttons fit landscape phones")
	game._start_battle(1);game._finish_battle(true)
	assert(game.battle_feedback.last_cue=="victory_bugle" and game.battle_feedback.active)
	for i in 4:game.battle_feedback.tick(.43)
	assert(game.battle_feedback.bursts>=4 and game.battle_feedback.fireworks.get_child_count()>0,"Victory creates colored fireworks")
	assert(game.battle_feedback.player.stream.get_length()>1,"Victory bugle contains real audio")
	await create_timer(.35).timeout
	await shot("36-victory-fireworks-and-bugle")
	game._return_home()
	assert(not game.battle_feedback.active and game.battle_feedback.fireworks.get_child_count()==0,"Returning home clears fireworks")
	game._start_battle(1);game._finish_battle(false)
	assert(game.mode=="base" and game.battle_feedback.last_cue=="defeat_brass","Defeat plays its own cue")
	game.battle_feedback.set_enabled(false,false);game.battle_feedback.play("victory_bugle")
	assert(not game.battle_feedback.player.playing,"SFX mute is honored")
	game.battle_feedback.set_enabled(true,false)
	game._save_profile()
	print("GARRISON_STOCK_COUNTS_PATROL_DEFENSE_FIREWORKS_AUDIO_AND_LANDSCAPE_PASSED")

class FakeAdBridge extends RefCounted:
	var ready:=true
	var requested:=""
	var loads:=0
	var showing:=false
	var receipts:Array=[]
	var acks:Array=[]
	func is_ready()->bool:return ready
	func prepare()->void:loads+=1
	func show_rewarded(token:String)->void:requested=token
	func is_showing()->bool:return showing
	func get_reward_receipts()->String:return JSON.stringify(receipts)
	func ack_reward(token:String)->void:receipts.erase(token);acks.append(token)

func check_yards_and_rewards()->void:
	game._return_home();game._dismiss_menus();game.unit_stock.fill(0);game.training_queue.clear()
	game.credits=100000;game.oil=100000;game.metal=100000
	var factory_index:=-1;var camp_index:=-1
	for i in game.buildings.size():
		if game.buildings[i].type==12:factory_index=i
		if game.buildings[i].type==18:camp_index=i
	assert(factory_index>=0 and camp_index>=0)
	var factory:Dictionary=game.buildings[factory_index];var camp:Dictionary=game.buildings[camp_index]
	factory.level=1;camp.level=1
	game.garrison.sync()
	assert(game.garrison.owners.find(factory_index)<0,"Producers must not spawn automatic aprons")
	game.unit_stock[10]=9;game._train_unit(10,factory_index)
	assert(game.garrison.stock(1)+game.garrison.queued(1)==10)
	var credits:float=game.credits;game._train_unit(10,factory_index)
	assert(game.credits==credits and game.garrison.queued(1)==1,"Queued units reserve camp capacity")
	game._advance_colony(float(game.training_queue[0].finish)+1)
	factory.level=5;assert(game.garrison.capacity(1)==10,"Upgrading the factory never increases camp capacity")
	game.selected_building=camp_index;game._upgrade_selected();assert(not game.info_panel.visible)
	assert(game.garrison.capacity(1)==10,"Camp capacity increases only when its upgrade completes")
	game._advance_colony(camp.finish+1);assert(game.garrison.capacity(1)==15)
	game.unit_stock[10]=20;game.garrison.sync();assert(game.unit_stock[10]==20 and not game._unit_lock_reason(10,factory_index).is_empty(),"Legacy excess armies are retained")
	game.unit_stock[10]=8
	game.selected_building=camp_index;game._begin_move();game._move_building(Vector3(-70,0,52))
	assert(camp.pos==Vector3(-70,0,52) and not game.info_panel.visible)
	for offset in [72,92]:
		game._begin_build(18);game._place_building(Vector3(-70,0,offset));game._advance_colony(game.colony_time+31)
	assert(game._build_lock_reason(18).contains("Maximum 3"))
	var buildings_before:int=game.buildings.size();credits=game.metal
	game._begin_build(18);game._place_building(Vector3(-70,0,112))
	assert(game.buildings.size()==buildings_before and game.metal==credits,"A fourth camp is rejected without spending")
	assert(game._build_lock_reason(19).is_empty() and game._build_lock_reason(20).is_empty(),"Camp limits are separate by category")
	game._begin_build(12);game._place_building(Vector3(140,0,30));game._advance_colony(game.colony_time+46)
	var second:int=game.buildings.size()-1;assert(game.buildings[second].type==12)
	game.unit_stock.fill(0);game.training_queue.clear();factory.level=3
	game._show_production(12,second);assert(not game._unit_lock_reason(11,second).is_empty(),"Low-star producer cannot borrow another factory's unlocks")
	game._train_unit(10,second);assert(game.units_panel.visible,"Production stays open for repeated orders")
	game._train_unit(10,factory_index)
	assert(game.training_queue.size()==2 and game.training_queue[0].finish==game.training_queue[1].finish,"Two factories produce concurrently")
	var untouched:float=0
	for job in game.training_queue:
		if job.producer==second:untouched=job.finish
	game.godot_coins=100;game.coin_system.speed_line(12,factory_index)
	assert(game.unit_stock[10]==1 and game.training_queue.size()==1 and game.training_queue[0].producer==second and game.training_queue[0].finish==untouched,"Speed-up affects only its own producer")
	game._save_profile();game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	assert(game.training_queue.size()==1 and game.training_queue[0].producer==second,"Producer assignment survives a restart")
	game._advance_colony(game.training_queue[0].finish+1)
	assert(game.unit_stock[10]==2)
	game.unit_stock[10]=8;game.unit_stock[0]=7;game.unit_stock[18]=8;game.garrison.sync()
	game._dismiss_menus();game.onboarding.guide.hide();game.camera_focus=Vector3(-70,0,32);game.camera.size=62;game._position_camera();game.toast.hide()
	await shot("39-buildable-air-ground-and-infantry-camps")
	game._show_production(12,second);await shot("40-independent-factory-queue");game._dismiss_menus()
	game.unit_stock.fill(0);game.training_queue.clear()
	game._show_production(12,second)
	for i in 3:game._train_unit(10,second)
	assert(game.units_panel.visible and game.training_queue.size()==3,"Three orders without reopening the production menu")
	game.units_panel.get_child(0).get_child(0).get_child(1).pressed.emit()
	assert(not game.units_panel.visible,"Player can close production manually")
	var ads:RefCounted=game.rewarded_ads;var native:Object=ads.bridge;var fake:=FakeAdBridge.new();ads.bridge=fake
	game.selected_building=factory_index;game._upgrade_selected();factory=game.buildings[factory_index]
	factory.finish=game.colony_time+12000
	var initial:float=factory.finish
	ads.offer_build(factory_index);assert(ads.result_panel.visible and fake.requested.is_empty(),"Disclosure is shown before requesting an ad")
	ads.result_panel.get_child(0).get_child(3).pressed.emit()
	assert(fake.requested.is_empty(),"Cancel does not start an ad")
	ads.request_build(factory_index);var token:String=fake.requested
	ads._earned("wrong-token");ads.poll_wait=0;ads.tick();assert(factory.finish==initial)
	ads._closed(token);ads.poll_wait=0;ads.tick();assert(factory.finish==initial,"Closing an unearned ad must not grant a reward")
	fake.ready=false;ads.request_build(factory_index);assert(fake.loads==1 and ads.pending.is_empty())
	fake.ready=true;ads.request_build(factory_index);token=fake.requested
	fake.showing=true;game.app_paused=true;fake.receipts.append(token);ads._earned(token);ads.poll_wait=0;ads.tick()
	assert(absf(factory.finish-(initial-3000))<.01 and token in fake.acks,"Earned receipt reduces 50 minutes even when lifecycle flags remain stale")
	fake.showing=false;game.app_paused=false;ads._closed(token);game.selected_building=0
	ads._earned(token);ads.poll_wait=0;ads.tick();assert(absf(factory.finish-(initial-3000))<.01,"Duplicate callbacks cannot reward twice")
	ads.request_build(factory_index);token=fake.requested;fake.receipts.append(token)
	game._save_profile();game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	ads=game.rewarded_ads;ads.bridge=fake;ads.poll_wait=0;ads.tick();factory=game.buildings[factory_index]
	assert(absf(factory.finish-(initial-6000))<.01 and token in fake.acks,"Missed callback recovers after restart")
	ads.request_build(factory_index);token=fake.requested
	game._advance_colony(factory.finish+1);var coins_before:int=game.godot_coins
	fake.receipts.append(token);ads._closed(token);ads.poll_wait=0;ads.tick()
	assert(game.godot_coins==coins_before and not ads.save_state().has("boost_seconds"),"Finished jobs do not bank time or grant extra coins")
	game._dismiss_menus();game.selected_building=factory_index;game._upgrade_selected();factory=game.buildings[factory_index]
	factory.finish=game.colony_time+120
	ads.request_build(factory_index);token=fake.requested;fake.receipts.append(token);ads._closed(token);ads.poll_wait=0;ads.tick()
	assert(factory.job=="","Short construction finishes immediately")
	assert(ads.result_panel.visible)
	await shot("41-confirmed-ad-reward-receipt")
	assert(ads.result_panel.get_global_rect().end.y <= root.size.y-80,"Reward receipt fits above the bottom HUD")
	ads.request_coins();token=fake.requested;fake.receipts.append(token);ads._closed(token);ads.poll_wait=0;ads.tick()
	assert(game.godot_coins==coins_before+5,"Coin ad grants exactly five Coins")
	ads._earned(token);ads.poll_wait=0;ads.tick();assert(game.godot_coins==coins_before+5)
	assert(game._save_profile(),"Coin receipt can be saved")
	game.queue_free();await process_frame;await open_game();game.onboarding.enter_colony()
	ads=game.rewarded_ads;ads.bridge=fake;assert(game.godot_coins==coins_before+5,"Coin reward survives restart")
	assert(game.coin_system.price(game.colony_time+3000)==5,"Five Coins equal fifty minutes")
	ads.offer_coins();await shot("42-optional-five-coin-reward");game._dismiss_menus()
	ads.bridge=native;game._save_profile()
	print("REPEAT_TRAINING_DIRECT_50_MINUTE_REWARDS_COIN_ADS_AND_RESTART_PASSED")
	print("BUILDABLE_THREE_CAMP_LIMITS_INDEPENDENT_PRODUCERS_MENU_CLOSE_AND_DURABLE_REWARDED_RECEIPTS_PASSED")
