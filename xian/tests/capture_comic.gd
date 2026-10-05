extends SceneTree
const Art=preload("res://scripts/art.gd")
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1250,810)
 var art=Art.new();var canvas=Control.new();root.add_child(canvas)
 var bg=ColorRect.new();bg.color=Color("182f38");bg.size=Vector2(1280,720);canvas.add_child(bg)
 var kinds=["granary","spring","ward","tower","kitchen","barracks"]
 var names=["กล่องข้าวตามสั่ง","หม้อหุงโอสถ","หอกระจายข่าว","บันไดหนังสติ๊ก","โรงเตี๊ยมไก่ย่าง","หอฝึกนักมวย"]
 for row in range(3):
  for col in range(6):
   var level=[1,5,10][row]
   var view=SubViewport.new();view.size=Vector2i(204,190);view.transparent_bg=true;view.own_world_3d=true;root.add_child(view)
   var tex=TextureRect.new();tex.texture=view.get_texture();tex.position=Vector2(col*212,row*230);tex.size=Vector2(204,190);canvas.add_child(tex)
   var camera=Camera3D.new();view.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.6 if col<2 else 8.2 if col>=4 else 6.4;camera.position=Vector3(6,5.6,8);camera.look_at(Vector3(0,1.3 if col<2 else 2.5,0))
   var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=0.85;view.add_child(light)
   var world=WorldEnvironment.new();world.environment=Environment.new();world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color.WHITE;world.environment.ambient_light_energy=0.4;view.add_child(world)
   view.add_child(art.building(kinds[col],level,0.8))
   var label=Label.new();label.text=names[col]+" • "+str(level);label.add_theme_font_override("font",load("res://assets/NotoSansThai.ttf"));label.add_theme_font_size_override("font_size",16);label.position=Vector2(col*212+8,row*230+198);canvas.add_child(label)
 for i in range(10):await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://build/review")
 root.get_texture().get_image().save_png("res://build/review/comic42.png")
 print("XIAN_COMIC_CAPTURE_PASSED");quit()
