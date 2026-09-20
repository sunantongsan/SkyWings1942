extends SceneTree
const SAVE:="user://qa_offline_campaign.json"
const Campaign=preload("res://scripts/campaign.gd")
var game:Node3D
func _initialize()->void:call_deferred("run")
func open_game()->void:
	game=load("res://scenes/main.tscn").instantiate();game.profile_path=SAVE;root.add_child(game)
	await process_frame;await process_frame
	game.set_process(false)
func shot(name:String)->void:
	await process_frame;await process_frame
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://build/review/"+name+".png")==OK)
func fight(index:int,amount:int,kind:int)->bool:
	game.unit_stock.fill(0);game.unit_stock[kind]=amount;game._campaign_start(index)
	assert(game.mode=="battle")
	game.deploy_kind=kind;game.deploy_count=0;game._deploy_fleet(Vector3(-20,0,4));game._launch_assault()
	for frame in 800:
		if game.mode!="battle":break
		game.visual_time+=.2;game._battle_tick(.2)
	var won:bool=game.mode=="victory"
	game._return_home()
	return won
func run()->void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/review"))
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	var last_hp:=0.0
	var last_reward:=0
	var last_dps:=0.0
	for index in Campaign.COUNT:
		var stage:Dictionary=Campaign.stage(index)
		var hp:=0.0
		var dps:=0.0
		for entry in stage.structures:
			hp+=entry.hp
			if entry.type in [8,11,17] or entry.level>=5:dps+=entry.shot_damage/(2.0 if entry.type==11 else 1.2)
			assert(absf(entry.pos.x)<16 and absf(entry.pos.z)<13)
		assert(hp>last_hp and stage.reward.credits>last_reward)
		assert(stage.difficulty==index+1)
		assert(dps>last_dps,"Enemy damage output must increase at every stage")
		last_hp=hp;last_reward=stage.reward.credits;last_dps=dps
	await open_game()
	game._found_colony(0);game.onboarding.close_lesson(false)
	for kind in game.BUILD_ORDER:game._spawn_building(game.home_root,kind,game.LANDING_SITES[kind],2 if kind==0 else 1,false)
	game._recalculate_colony();game.tutorial_step=12
	game.unit_stock[0]=8;game._refresh_progress();game._toggle_galaxy()
	await shot("50-campaign-frontier")
	game._campaign_select(0);await shot("51-campaign-reward-preview")
	assert(game.galaxy_panel.get_rect().end.y<=720)
	game._campaign_start(1);assert(game.mode=="base","Locked stage cannot start")
	assert(fight(0,8,0),"First base must be beatable with the tutorial's eight Fighters")
	assert(game.campaign_cleared==1 and game.campaign_wins==1)
	var earned:Dictionary=game.campaign_earnings.duplicate()
	game._finish_battle(true);assert(game.campaign_earnings==earned,"Duplicate completion cannot pay twice")
	assert(fight(0,8,0),"Cleared base can be replayed")
	assert(game.campaign_wins==2 and game.campaign_cleared==1)
	game.campaign_cleared=49
	var before:Dictionary=game.campaign_earnings.duplicate()
	assert(not fight(49,8,0),"Final base must defeat the starter squad")
	assert(game.campaign_earnings==before and game.campaign_cleared==49,"Defeat grants no reward or progress")
	assert(fight(49,159,21),"Final base must be beatable with a large advanced army")
	assert(game.campaign_cleared==50)
	var saved_coins:int=game.godot_coins
	assert(saved_coins==Campaign.stage(49).reward.coins)
	game._toggle_galaxy();game._campaign_page_to(4);game._campaign_select(49)
	await shot("52-campaign-complete-replay-rewards")
	game._campaign_select(-2);await shot("53-campaign-total-earned")
	game._save_profile();var saved_earnings:Dictionary=game.campaign_earnings.duplicate()
	game.queue_free();await process_frame;await open_game()
	assert(game.campaign_cleared==50 and game.campaign_earnings==saved_earnings and game.godot_coins==saved_coins)
	game.unit_stock[0]=8;game._campaign_start(49)
	assert(game.battle_reward.coins==0,"Coin cannot be farmed again after restarting")
	game._finish_battle(true)
	assert(game.godot_coins==saved_coins)
	assert(game.campaign_earnings.credits==saved_earnings.credits+Campaign.stage(49).reward.credits)
	game._return_home()
	# Old v0.21 saves have no campaign fields and must retain their colony/coins.
	var old:Dictionary=game.profile_store.read_profile(SAVE)
	for key in ["campaign_cleared","campaign_earnings","campaign_wins"]:old.erase(key)
	assert(game.profile_store.write_profile(SAVE,old))
	game.profile_ready=false
	game.queue_free();await process_frame;await open_game()
	assert(game.has_colony and game.campaign_cleared==0 and game.godot_coins==saved_coins)
	game._toggle_galaxy();game._campaign_page_to(2);game._campaign_select(20)
	await shot("54-campaign-locked-coin-preview")
	root.size=Vector2i(1560,720);game._layout_ui();await shot("55-campaign-wide-screen")
	assert(game.galaxy_panel.get_rect().end.x<=1560)
	game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	print("OFFLINE_50_BASES_DIFFICULTY_REWARDS_REPLAY_SAVE_MIGRATION_PASSED");quit(0)
