extends SceneTree
const Art=preload("res://scripts/art.gd")
const KINDS=["hall","barracks","well","kitchen","tank","granary","spring","crystal","servant","recruit","training","dorm","tower","ward","wall"]
func _initialize():call_deferred("run")
func run():
 var viewport=SubViewport.new();viewport.size=Vector2i(192,192);viewport.transparent_bg=true;viewport.own_world_3d=true;root.add_child(viewport)
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 var camera=Camera3D.new();viewport.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.8;camera.position=Vector3(6,6,7);camera.look_at(Vector3(0,1.5,0))
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=1.3;viewport.add_child(light)
 var environment=WorldEnvironment.new();var env=Environment.new();env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=0.6;environment.environment=env;viewport.add_child(environment)
 var art=Art.new()
 for kind in KINDS:
  camera.size=8.5 if kind=="training" else 5.8
  var model=art.building(kind,1,0.7);viewport.add_child(model)
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  viewport.get_texture().get_image().save_png("res://assets/buildings/"+kind+".png")
  viewport.remove_child(model);model.queue_free()
 var person=art.person(0);viewport.add_child(person)
 camera.size=3.5;camera.position=Vector3(2,2.4,3);camera.look_at(Vector3(0,1.1,0))
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 viewport.get_texture().get_image().save_png("res://assets/buildings/disciple.png")
 print("BUILDING_ICONS_RENDERED");quit()
