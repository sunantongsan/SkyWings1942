extends SceneTree
const Art=preload("res://scripts/art.gd")
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1250,810)
 var art=Art.new();var canvas=Control.new();root.add_child(canvas)
 var bg=ColorRect.new();bg.color=Color("182f38");bg.size=Vector2(1280,720);canvas.add_child(bg)
 var kinds=["servant","granary","granary","granary","hall"]
 var names=["เพิงช่าง","ปิ่นโต • ว่าง","ปิ่นโต • ครึ่งหนึ่ง","ปิ่นโต • เต็ม","ซากอาคาร"]
 for row in range(3):
  for col in range(5):
   var level=[1,5,10][row]
   var view=SubViewport.new();view.size=Vector2i(248,190);view.transparent_bg=true;view.own_world_3d=true;root.add_child(view)
   var tex=TextureRect.new();tex.texture=view.get_texture();tex.position=Vector2(col*250,row*230);tex.size=Vector2(248,190);canvas.add_child(tex)
   var camera=Camera3D.new();view.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=6.5;camera.position=Vector3(6,5.6,8);camera.look_at(Vector3(0,1.9,0))
   var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=0.85;view.add_child(light)
   var world=WorldEnvironment.new();world.environment=Environment.new();world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color.WHITE;world.environment.ambient_light_energy=0.4;view.add_child(world)
   if col==4:
    var holder=Node3D.new();view.add_child(holder);art.ruins(holder,Vector3.ZERO)
   else:view.add_child(art.building(kinds[col],level,[0.0,0.0,0.5,1.0][col]))
   var label=Label.new();label.text=("เพิงช่าง • ไม่อัปเกรด" if col==0 else ("ซากอาคารและควัน" if col==4 else names[col]+" • Lv."+str(level)));label.add_theme_font_override("font",load("res://assets/NotoSansThai.ttf"));label.add_theme_font_size_override("font_size",18);label.position=Vector2(col*250+12,row*230+198);canvas.add_child(label)
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://build/review")
 root.get_texture().get_image().save_png("res://build/review/buildings41.png")
 print("XIAN_WORKSHOP_CAPTURE_PASSED");quit()
