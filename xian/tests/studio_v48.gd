extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
 var art=load("res://scripts/art.gd").new()
 DirAccess.make_dir_recursive_absolute("res://assets/ui/buildings")
 DirAccess.make_dir_recursive_absolute("res://build/review")
 for kind in ["hall","barracks","training","well","kitchen","granary","spring","crystal","servant","tank","tower","ward","wall"]:
  var viewport=SubViewport.new();viewport.size=Vector2i(192,192);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
  var model=art.building(kind,1,0.5);viewport.add_child(model)
  var bounds=art.model_bounds(model);var target=Vector3(0,bounds.end.y*0.45,0)
  var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=maxf(3.8,maxf(bounds.size.x,bounds.size.z)*1.55);viewport.add_child(camera);camera.position=target+Vector3(40,48,40);camera.look_at(target);camera.make_current()
  var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0);sun.light_energy=0.95;viewport.add_child(sun)
  var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d3dfdb");env.environment.ambient_light_energy=0.65;viewport.add_child(env)
  for i in range(3):await process_frame
  await RenderingServer.frame_post_draw
  assert(not viewport.get_texture().get_image().is_invisible())
  assert(viewport.get_texture().get_image().save_png("res://assets/ui/buildings/"+kind+".png")==OK)
  viewport.queue_free();await process_frame
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);await process_frame
 scene.api.busy=true;scene.close_modal();scene.mode="home";scene.selected=-1
 scene.state={"name":"สำนักเมฆาคราม","map":"bamboo","water":20000,"rice":20000,"stone":5000,"jade":150,"army":[4,1,0,2,0,1,0,0,0,0],"jobs":[],"buildings":[]}
 scene.caps={"water":24000,"rice":24000,"stone":8000,"workers":3,"busy":0,"army":80}
 var kinds=["hall","well","kitchen","tank","granary","spring","crystal","servant","barracks","training","tower","ward"]
 var spots=[[7,6],[4,5],[10,5],[4,7],[10,7],[6,4],[8,4],[5,9],[7,9],[9,9],[4,10],[12,10]]
 for i in range(kinds.size()):
  scene.state.buildings.append({"id":kinds[i],"x":spots[i][0],"y":spots[i][1],"level":5 if i%2==0 else 2,"finish":0})
  scene.catalog.append({"id":kinds[i],"name":{"hall":"สำนักหลัก","well":"บ่อน้ำ","kitchen":"โรงครัว","granary":"ยุ้งฉาง","barracks":"หอฝึกนักสู้","training":"ลานฝึกกระบี่","spring":"โรงปรุงโอสถ","crystal":"คลังโอสถ","servant":"เรือนช่าง","tank":"อ่างเก็บน้ำ","tower":"หอหน้าไม้","ward":"หอค่ายกล"}.get(kinds[i],kinds[i]),"water":100,"rice":50,"stone":10,"seconds":30})
 for x in range(4,13):scene.state.buildings.append({"id":"wall","x":x,"y":12,"level":5,"finish":0})
 scene.draw_base();scene.update_top();scene.show_side();scene.camera.size=33
 for i in range(12):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/v048-village.png")
 scene.selected=0;scene.show_side()
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/v048-building.png")
 scene.mode="build";scene.show_side()
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/v048-build-menu.png")
 scene.show_settings()
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/v048-settings.png")
 print("XIAN_STUDIO_V48_PASSED");quit()
