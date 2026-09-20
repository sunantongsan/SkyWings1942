extends SceneTree
## Records genuine UI/world actions using an isolated disposable colony. Never touches player saves.
const SAVE:="user://video_capture_only.json"
const FPS:=15
const FRAMES:=120
var game:Node3D
var caption:Label
var marker:Control
var marker2:Control
var overlay:CanvasLayer
class Finger extends Control:
	var phase:=0.0
	func _draw()->void:
		draw_circle(Vector2.ZERO,17,Color(0,0,0,.6))
		draw_circle(Vector2.ZERO,12,Color(1,1,1,.94))
		draw_arc(Vector2.ZERO,23+4*sin(phase),0,TAU,48,Color("5cffb8"),4,true)
func _initialize()->void:call_deferred("run")
func reset_colony(topic:String)->void:
	if is_instance_valid(game):game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	game=load("res://scenes/main.tscn").instantiate();game.profile_path=SAVE;root.add_child(game)
	await process_frame;await process_frame
	game._found_colony(0);game.onboarding.close_lesson(false);game.set_process(false)
	# Keep this disposable colony ahead of wall time: software rendering can take
	# longer than production timers. Advance only one video frame per capture.
	game.colony_time=Time.get_unix_time_from_system()+86400.0
	game.onboarding.guide_suppressed=true;game.onboarding.refresh_guide()
	game.credits=10000;game.metal=20000;game.oil=6000;game.crystal=2000
	if topic=="power":game._spawn_building(game.home_root,0,Vector3.ZERO,1,false)
	elif topic not in ["build"]:
		for kind in game.BUILD_ORDER:game._spawn_building(game.home_root,kind,game.LANDING_SITES[kind],2 if kind==0 else 1,false)
		if topic in ["train","raid","camera"]:game._spawn_building(game.home_root,19,Vector3(-70,0,0),1,false)
	game._recalculate_colony();game._refresh_progress();game._setup_life();game._sync_industry_visuals()
	game.camera.size=36;game._position_camera();game.toast.hide()
	marker.show();marker2.hide()
func point(pos:Vector2,text:String)->void:
	marker.position=pos;caption.text=text
func world_point(pos:Vector3,text:String)->void:
	game.placement_guide.pointer=pos;game.placement_guide.has_pointer=true
	point(game.camera.unproject_position(pos),text)
func label_center(node:Node,text:String)->Vector2:
	if node is Label and node.text==text:return node.get_global_rect().get_center()
	for child in node.get_children():
		var p:=label_center(child,text)
		if p!=Vector2.ZERO:return p
	return Vector2.ZERO
func button_center(node:Node,text:String)->Vector2:
	if node is Button and node.text==text:return node.get_global_rect().get_center()
	for child in node.get_children():
		var p:=button_center(child,text)
		if p!=Vector2.ZERO:return p
	return Vector2.ZERO
func record(topic:String)->void:
	await reset_colony(topic)
	var folder:String="res://build/lesson_frames/"+topic
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var kind:int=1 if topic=="power" else (19 if topic=="camp" else 0)
	var site:Vector3=game.LANDING_SITES[kind] if kind<18 else Vector3(-70,0,0)
	if topic=="camp":game.camera_focus=site;game._position_camera()
	for frame in FRAMES:
		match topic:
			"build","power","camp":
				if frame==0:point(game.dock.get_child(0).get_global_rect().get_center(),"1. Tap BUILD")
				if frame==15:game._toggle_build()
				if topic=="camp" and frame>=18 and frame<=30:
					point(Vector2(680,490-(frame-18)*7),"2. Swipe up to find Air Camp")
					for child in game.build_panel.get_child(0).get_children():
						if child is ScrollContainer:child.scroll_vertical=(frame-18)*24
				if frame==(32 if topic=="camp" else 18):point(label_center(game.build_panel,game.BUILDING_NAMES[kind]),"2. Choose "+game.BUILDING_NAMES[kind])
				if frame==42:game._begin_build(kind)
				if frame==45:world_point(site,"3. Tap a GREEN tile")
				if frame==70:game._place_building(site);assert(game.buildings.back().type==kind and game.buildings.back().has("job"))
				if frame>=76:
					caption.text="Building... (demo time accelerated)";marker.hide()
					var b:Dictionary=game.buildings.back()
					if b.get("job","")!="":game._advance_colony(game.colony_time+float(game.BUILD_SECONDS[kind])/30)
				if frame==114:caption.text="Ready! Now try it in your colony."
			"upgrade":
				if frame==0:world_point(Vector3.ZERO,"1. Tap your Galactic Core")
				if frame==20:game._select_building_at(Vector3.ZERO)
				if frame==25:point(button_center(game.info_panel,"UPGRADE"),"2. Tap UPGRADE")
				if frame==58:game._upgrade_selected();assert(game.buildings[0].level==3 and game.buildings[0].get("job","")=="")
				if frame==64:point(Vector2(180,145),"3. Level 3 is ready immediately")
				if frame==105:caption.text="No waiting. The next level costs twice the Metal."
			"train":
				if frame==0:point(game.dock.get_child(1).get_global_rect().get_center(),"1. Tap FLEET")
				if frame==20:game._show_production(6)
				if frame==25:point(label_center(game.units_panel,"Fighter"),"2. Tap a unit repeatedly to queue it")
				if frame in [45,60,75]:game._train_unit(0)
				if frame==80:assert(game.units_panel.visible and game.training_queue.size()==3)
				if frame==90:point(button_center(game.units_panel,"CLOSE"),"3. Tap CLOSE when you are done")
				if frame==112:game.units_panel.hide()
			"raid":
				if frame==0:
					game.unit_stock[0]=8;game.tutorial_step=12;game._refresh_progress()
					point(game.dock.get_child(2).get_global_rect().get_center(),"1. Open GALAXY MAP")
				if frame==15:game._toggle_galaxy()
				if frame==20:point(label_center(game.galaxy_panel,game.Campaign.stage(0).name),"2. Choose a base and check rewards")
				if frame==28:game._campaign_select(0)
				if frame==38:game._campaign_start(0)
				if frame==42:point(Vector2(1130,170),"3. Select your squad on the right")
				if frame==61:world_point(Vector3(-20,0,4),"4. Tap the GREEN outer zone")
				if frame==78:game._deploy_fleet(Vector3(-20,0,4));assert(game.battle_units.size()==8)
				if frame==84:point(button_center(game.deployment_bar,"ATTACK"),"5. Tap ATTACK")
				if frame==99:game._launch_assault();marker.hide();caption.text="Send more reserves whenever you need!"
			"camera":
				if frame<60:
					point(Vector2(590+frame*2,400),"DRAG one finger to move")
					game.camera_focus=Vector3(frame*.12,0,0)
				else:
					point(Vector2(580-(frame-60),400),"PINCH two fingers to zoom")
					marker2.show();marker2.position=Vector2(700+frame-60,400);game.camera.size=36-(frame-60)*.18
				game._position_camera()
		game._advance_colony(game.colony_time+1.0/FPS)
		game._process(1.0/FPS);game.toast.hide()
		marker.phase=frame*.4;marker.queue_redraw();marker2.phase=frame*.4;marker2.queue_redraw()
		await process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png(folder+"/%04d.png"%frame)==OK)
	print("RECORDED_LESSON "+topic)
func run()->void:
	root.size=Vector2i(1280,720)
	overlay=CanvasLayer.new();overlay.layer=100;root.add_child(overlay)
	var panel:=PanelContainer.new();panel.position=Vector2(300,12);panel.size=Vector2(680,76);overlay.add_child(panel)
	var style:=StyleBoxFlat.new();style.bg_color=Color("102832");style.set_corner_radius_all(14);style.content_margin_left=18;style.content_margin_right=18;panel.add_theme_stylebox_override("panel",style)
	caption=Label.new();caption.add_theme_font_size_override("font_size",25);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;panel.add_child(caption)
	marker=Finger.new();marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(marker)
	marker2=Finger.new();marker2.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(marker2)
	for topic in ["build","power","upgrade","camp","train","raid","camera"]:await record(topic)
	game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
	print("LESSON_LOGIC_PASSED" if DisplayServer.get_name()=="headless" else "REAL_GAME_TUTORIAL_RECORDING_PASSED");quit(0)
