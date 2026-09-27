extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
var game:Node3D
func _initialize()->void:call_deferred("run")
func shot(name:String)->void:
	await process_frame;await process_frame
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://build/review/"+name+".png")==OK)
func run()->void:
	root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/review"))
	for index in 50:
		var health:float=(300.0+index*22.0+index*index*.3)*1.5
		for b in Campaign.stage(index).structures:
			var hp:float=health
			var damage:float=1.5*(2.5+index*.55)*(2.0/1.2 if b.type==11 else 1.0)
			match int(b.type):
				21:hp*=1.25;damage=5.0+index*.6
				22:hp*=1.4;damage=20.0+index*2.0
				23:hp*=1.4;damage=10.0+index
				24:hp*=.7+(index/10)*.2;damage=2.0+index*.5
			assert(is_equal_approx(b.hp,hp*1.9) and is_equal_approx(b.shot_damage,damage*1.9),"Every campaign structure gains exactly 90 percent HP and weapon power")
	game=load("res://scenes/main.tscn").instantiate();game.profile_path="user://qa_v31_performance.json"
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(game.profile_path+suffix):DirAccess.remove_absolute(game.profile_path+suffix)
	root.add_child(game);await process_frame;game.set_process(false)
	game._found_colony(0);game.onboarding.close_lesson(false)
	for kind in game.BUILD_ORDER:game._spawn_building(game.home_root,kind,game.LANDING_SITES[kind],2 if kind==0 else 1,false)
	for i in 3:game._spawn_building(game.home_root,[19,18,20][i],Vector3((i-1)*17,0,40),3,false)
	game.tutorial_step=13;game._recalculate_colony();game.unit_stock[0]=20;game.unit_stock[10]=20;game.unit_stock[18]=20
	var stock:PackedInt32Array=game.unit_stock.duplicate()
	game.performance.set_low(false,false);game.garrison.sync();var standard_count:int=game.garrison.actors.size()
	game.performance.set_low(true,false);game.garrison.sync()
	assert(game.garrison.actors.size()<standard_count and game.unit_stock==stock and game.garrison.counts==[20,20,20])
	assert(not game.sun.shadow_enabled and root.msaa_3d==Viewport.MSAA_DISABLED and is_equal_approx(root.scaling_3d_scale,.75) and Engine.max_fps==30)
	game._toggle_build();game._layout_ui();await shot("90-low-graphics-controls")
	assert(game.performance.button.text=="GRAPHICS: LOW" and game.performance.button.get_global_rect().end.x<=1280)
	game._dismiss_menus();game.campaign_cleared=49;game._campaign_start(49)
	var hp:float=game.battle_targets[0].hp
	game.performance.set_low(false,false);game.performance.set_low(true,false)
	assert(game.battle_targets[0].hp==hp,"Graphics cannot alter battle balance")
	var p:CPUParticles3D=game.art.particles(game.world_root,Vector3.ZERO,Color.WHITE,false,false)
	await process_frame;await process_frame
	assert(p.amount<20 and p.amount>=3)
	game.performance.prepare_particle(p);var reduced:int=p.amount;game.performance.prepare_particle(p);assert(p.amount==reduced,"Repeated LOW must not keep shrinking particles")
	game._layout_ui();await shot("91-low-graphics-fortified-base")
	game._return_home();game.performance.set_low(false,false)
	assert(game.sun.shadow_enabled and root.msaa_3d==Viewport.MSAA_2X and Engine.max_fps==60)
	game.queue_free();await process_frame
	print("V31_FIFTY_BASES_190_PERCENT_LOW_GRAPHICS_INVENTORY_AND_EFFECTS_PASSED");quit()
