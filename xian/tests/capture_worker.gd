extends SceneTree
const Art=preload("res://scripts/art.gd")
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1250,810)
 var art=Art.new();var canvas=Control.new();root.add_child(canvas)
 var bg=ColorRect.new();bg.color=Color("182f38");bg.size=Vector2(1280,720);canvas.add_child(bg)
 var kinds=["hall"]
 var names=["ช่างนั่งเลื่อยไม้บนนั่งร้าน"]
 for row in range(1):
  for col in range(1):
   var level=[1,5,10][row]
   var view=SubViewport.new();view.size=Vector2i(900,650);view.transparent_bg=true;view.own_world_3d=true;root.add_child(view)
   var tex=TextureRect.new();tex.texture=view.get_texture();tex.position=Vector2(col*250,row*230);tex.size=Vector2(900,650);canvas.add_child(tex)
   var camera=Camera3D.new();view.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=7.4 if col==0 or col==3 else 4.5;camera.position=Vector3(6,5.6,8);camera.look_at(Vector3(0,2.3 if col==0 or col==3 else 1.4,0))
   var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=0.85;view.add_child(light)
   var world=WorldEnvironment.new();world.environment=Environment.new();world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color.WHITE;world.environment.ambient_light_energy=0.4;view.add_child(world)
   var model=art.building(kinds[col],level,0.65);view.add_child(model);art.construction_dressing(model,1,0.5)
   var label=Label.new();label.text=names[col]+" • Lv."+str(level);label.add_theme_font_override("font",load("res://assets/NotoSansThai.ttf"));label.add_theme_font_size_override("font_size",18);label.position=Vector2(20,650);canvas.add_child(label)
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://build/review")
 root.get_texture().get_image().save_png("res://build/review/worker40.png")
 print("XIAN_WORKER_CAPTURE_PASSED");quit()
