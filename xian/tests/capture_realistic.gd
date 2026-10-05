extends SceneTree
const Art=preload("res://scripts/realistic_art.gd")
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1440,960)
	root.content_scale_size=Vector2i(1440,960)
	var art=Art.new();var canvas=Control.new();root.add_child(canvas)
	var bg=ColorRect.new();bg.color=Color("293a32");bg.size=Vector2(1440,960);canvas.add_child(bg)
	var kinds=["carpenter","servant","well","spring","granary","tank","crystal","kitchen","barracks","tower","ward","hall"]
	for i in range(kinds.size()):
		var view=SubViewport.new();view.size=Vector2i(345,290);view.transparent_bg=true;view.own_world_3d=true;root.add_child(view)
		var tex=TextureRect.new();tex.texture=view.get_texture();tex.position=Vector2((i%4)*360,int(i/4)*320);tex.size=Vector2(345,290);canvas.add_child(tex)
		var camera=Camera3D.new();view.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.5;camera.position=Vector3(40,48,40);camera.look_at(Vector3.ZERO)
		var model=art.building(kinds[i],1);view.add_child(model)
		var s=model.get_node("RealisticVisual");s.offset.y=0
		var label=Label.new();label.text=kinds[i];label.position=tex.position+Vector2(16,292);canvas.add_child(label)
	for i in range(12):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build/review")
	root.get_texture().get_image().save_png("res://build/review/realistic-art.png")
	print("REALISTIC_ART_CAPTURE_PASSED");quit()
