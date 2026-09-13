extends SceneTree
## Capture the real production scene, and exercise the existing gameplay loop.
var game: Node3D
var output := "res://build/review"
func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output+"/"+name+".png")
	assert(error == OK, "Screenshot must be saved")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(1280,720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await create_timer(0.8).timeout
	game.toast.hide()
	await shot("01-home-planet")
	print("HOME_DRAW_CALLS=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	assert(game.buildings.size()==10,"Ten GLB buildings must be loaded")
	for building in game.buildings:
		assert(building.node.find_children("*","MeshInstance3D",true,false).size()>0)
	game._select_building_at(Vector3.ZERO)
	await shot("02-building-selected")
	var old_level:int=game.buildings[0].level
	var old_metal:float=game.metal
	game._upgrade_selected()
	assert(game.buildings[0].level==old_level+1)
	assert(game.metal<old_metal)
	game.info_panel.hide();game.selection_ring.hide()
	game._toggle_build()
	await shot("03-build-menu")
	game.build_panel.hide()
	var old_count:int=game.buildings.size()
	game.build_type=8
	game._place_building(Vector3(-16,0,14))
	assert(game.buildings.size()==old_count+1,"Construction must place a GLB building")
	var stock:int=game.unit_stock[0]
	game._train_unit(0)
	assert(game.unit_stock[0]==stock+1)
	await shot("04-fleet-menu")
	game.units_panel.hide()
	game._toggle_galaxy()
	await shot("05-galaxy-map")
	game._start_battle(1)
	await create_timer(1.2).timeout
	await shot("06-battle")
	game.set_process(false)
	for u in game.battle_units:u["last_shot"]=100000.0
	for i in 1800:
		if game.mode!="battle":break
		game._battle_tick(.1)
		game._visual_tick(.1)
		if i%20==0:await process_frame
	assert(game.mode=="victory","Existing raid must be winnable")
	var credits_after:float=game.credits
	game._process(.1)
	assert(game.credits==credits_after,"Rewards may only be granted once")
	await shot("07-victory")
	game._return_home()
	assert(game.home_root.visible and not game.battle_root.visible)
	# Wider phones must retain all UI and an expanded world view.
	root.size=Vector2i(1600,720)
	await process_frame
	game._layout_ui()
	assert(game.header.get_rect().end.x<=1600)
	await shot("08-wide-phone")
	print("GALAXY_VISUAL_AND_GAMEPLAY_CHECKS_PASSED")
	quit(0)
