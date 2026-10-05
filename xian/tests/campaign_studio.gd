extends SceneTree
func _initialize():call_deferred("run")
func capture(name: String):
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://build/review/v051-"+name+".png")==OK)
func run():
 root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
 DirAccess.make_dir_recursive_absolute("res://build/review")
 # Exercise the real main-menu entry, including village lighting/environment.
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await process_frame
 main.api.busy=true;main.close_modal();main.open_practice()
 var scene=main.practice;scene.test_mode=true;scene.progress.path="user://campaign_studio.json";await process_frame
 assert(scene.campaign_map.node_buttons.size()==10)
 for button in scene.campaign_map.node_buttons:assert(Rect2(40,192,816,446).encloses(button.get_global_rect()))
 for icon in scene.campaign_map.find_children("*","TextureRect",true,false):assert(icon.size.x<=796 and icon.size.y<=426,"Map artwork must fit assigned rectangles")
 await capture("campaign-map")
 for n in range(1,91):scene.progress.stars[str(n)]=3
 scene.campaign_map.chapter=8;scene.campaign_map.selected=90;scene.campaign_map.refresh()
 await capture("campaign-final-region")
 for n in [1,30,60,90]:
  scene.start_level(n);await capture("stage-%02d"%n)
 for b in scene.sim.buildings:b.hp=0
 scene.finish();await capture("campaign-result")
 main.queue_free();await process_frame
 var art=load("res://scripts/art.gd").new()
 var viewport=SubViewport.new();viewport.size=Vector2i(1280,400);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=6.2;viewport.add_child(camera);camera.position=Vector3(0,9,14);camera.look_at(Vector3(0,1.2,0));camera.make_current()
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0);sun.light_energy=0.95;viewport.add_child(sun)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("182b3c");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d3dfdb");env.environment.ambient_light_energy=0.65;viewport.add_child(env)
 for i in range(5):
  var kind=load("res://scripts/campaign_defenses.gd").NEW_KINDS[i];var model=art.building(kind,5);viewport.add_child(model);model.position.x=(i-2)*3.5
  var bounds=art.model_bounds(model);assert(bounds.position.y>=-0.001 and bounds.size.y>1 and bounds.size.x<=3,"Invalid defensive footprint")
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 assert(viewport.get_texture().get_image().save_png("res://build/review/v051-new-defenses.png")==OK)
 for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute("user://campaign_studio.json"+suffix)
 print("XIAN_CAMPAIGN_STUDIO_PASSED");quit()
