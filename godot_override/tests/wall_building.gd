extends SceneTree
const SAVE:="user://qa_v28_walls.json"
var game:Node3D
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,720)
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	game=load("res://scenes/main.tscn").instantiate();game.profile_path=SAVE;root.add_child(game)
	await process_frame;game.set_process(false);game._found_colony(0);game.onboarding.close_lesson(false)
	for kind in game.BUILD_ORDER:game._spawn_building(game.home_root,kind,game.LANDING_SITES[kind],1,false)
	game.tutorial_step=13;game.tutorial_dismissed=true;game._recalculate_colony();game.metal=100000;game.oil=100000
	game._begin_build(1);game._place_building(Vector3(-40,0,0))
	assert(game._builder_busy() and game.buildings.back().job=="build")
	var deadline:float=game.buildings.back().finish
	var metal:float=game.metal
	game._begin_build(24);game._place_building(Vector3(40,0,0))
	var first:Dictionary=game.buildings.back()
	assert(first.type==24 and first.get("job","")=="" and game.metal==metal-game.BUILDING_COST[24])
	assert(game.build_type==24,"Continue building walls without reopening the catalog")
	game._place_building(Vector3(47,0,0));var second:Dictionary=game.buildings.back()
	assert(second.pos==Vector3(46,0,0) and not game.layout.overlaps(second.pos,24,second.yaw,first),"Nearby sections snap flush without overlap")
	game._place_building(Vector3(49,0,-4));var corner:Dictionary=game.buildings.back()
	assert(is_equal_approx(corner.yaw,PI/2) and is_equal_approx(corner.pos.z,-3.7),"Automatic corner alignment")
	game._toggle_build();game._dismiss_menus();assert(game.build_type==-1)
	game._select_building_at(second.pos);game.layout.floating_menu()
	assert(game.info_panel.get_theme_stylebox("panel") is StyleBoxEmpty)
	assert(not game.selected_label.visible and game.info_panel.size.y<350)
	assert(game.buildings[game.BUILD_ORDER.size()].finish==deadline,"Wall placement never advances other construction")
	game.camera_focus=Vector3(44,0,0);game.camera.size=27;game._position_camera();game.onboarding.refresh_guide();game.layout.floating_menu();game.toast.hide()
	await process_frame;await process_frame
	assert(game.wall_delete_button.get_global_rect().end.y<=game.info_panel.get_global_rect().end.y,"Every floating action fits without clipping")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://build/review/83-instant-connected-walls-floating-menu.png")==OK)
	game.info_panel.hide();game.selection_ring.hide()
	await process_frame;await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://build/review/84-connected-wall-corner.png")==OK)
	game._save_profile();var saved:Dictionary=game.profile_store.read_profile(SAVE)
	assert(not saved.is_empty() and is_equal_approx(saved.buildings.back().yaw,corner.yaw))
	print("V28_INSTANT_WALLS_BUSY_DRONE_CONNECTION_CORNERS_FLOATING_MENU_PASSED")
	game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	quit()
