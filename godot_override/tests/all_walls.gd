extends SceneTree
const SAVE:="user://qa_v29_all_walls.json"
var game:Node3D
func _initialize()->void:call_deferred("run")
func shot(name:String)->void:
	game.layout.floating_menu();game._update_top_bar();game.toast.hide()
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
	for kind in game.BUILD_ORDER:game._spawn_building(game.home_root,kind,game.LANDING_SITES[kind],1,false)
	game.tutorial_step=13;game.tutorial_dismissed=true;game._recalculate_colony();game.onboarding.refresh_guide()
	var a:Dictionary=game._spawn_building(game.home_root,24,Vector3(40,0,0),1,false)
	var b:Dictionary=game._spawn_building(game.home_root,24,Vector3(46,0,0),3,false)
	var maximum:Dictionary=game._spawn_building(game.home_root,24,Vector3(52,0,0),5,false)
	var gate:Dictionary=game._spawn_building(game.home_root,25,Vector3(58,0,0),2,false)
	game.camera_focus=Vector3(46,0,0);game.camera.size=35;game._position_camera()
	game._select_building_at(maximum.pos);game.layout.upgrade_all=true
	var upgrade:Button
	for child in game.selected_label.get_parent().get_children():
		if child is Button and child.text=="UPGRADE":upgrade=child
	var quote:Dictionary=game.layout.wall_quote();assert(quote.indices.size()==2 and quote.cost==18700)
	game.metal=quote.cost-1;game.layout.floating_menu();assert(upgrade.disabled)
	game._upgrade_selected();assert(game.metal==quote.cost-1 and a.level==1 and b.level==3 and maximum.level==5 and gate.level==2,"Insufficient ALL is an atomic no-op")
	await shot("85-all-walls-unaffordable")
	game.metal=quote.cost;game.layout.floating_menu();assert(not upgrade.disabled,"Selecting a max wall still permits ALL for other walls")
	await shot("86-all-walls-affordable-green")
	game._upgrade_selected();assert(game.metal==0 and a.level==2 and b.level==4 and maximum.level==5 and gate.level==2,"ALL charges the exact sum and adds one level per eligible wall")
	game._upgrade_selected();assert(game.metal==0 and a.level==2 and b.level==4,"Second tap cannot spend absent resources")
	game.layout.upgrade_all=false;game._select_building_at(a.pos);game.metal=game._upgrade_cost(a);game._upgrade_selected()
	assert(a.level==3 and b.level==4,"ONE affects only the selected wall")
	var save:Dictionary=game.profile_store.read_profile(SAVE);assert(not save.is_empty() and save.resources[1]==0)
	assert(upgrade.get_theme_stylebox("normal") is StyleBoxTexture and upgrade.get_theme_stylebox("disabled") is StyleBoxTexture)
	game._toggle_build();game.metal=1000;game.oil=100;game._update_top_bar()
	var enabled:=0;var disabled:=0;var price_preserved:=false
	for button in game.build_panel.find_children("*","Button",true,false):
		if button.has_meta("available"):
			var column:Node=button.get_child(0) if button.get_child_count()>0 else button
			for label in column.get_children():
				if label is Label and label.text=="Fusion Reactor":price_preserved="700" in column.get_child(column.get_child_count()-1).text
			if button.disabled:disabled+=1
			else:enabled+=1
	assert(price_preserved,"Prices remain visible when affordability changes from disabled to enabled")
	assert(enabled>0 and disabled>0,"Catalog reflects resource availability")
	await shot("87-dimensional-build-menu-states")
	print("V29_ALL_WALLS_ATOMIC_COST_MAX_SKIP_ONE_SCOPE_SAVE_GREEN_DISABLED_PASSED")
	game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	quit()
