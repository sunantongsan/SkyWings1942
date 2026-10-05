extends SceneTree
const Iso=preload("res://scripts/iso_layout.gd")
var viewport: SubViewport
func _initialize():call_deferred("run")
func capture() -> Image:
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 return viewport.get_texture().get_image()
func coverage(reference: Image,actual: Image) -> Dictionary:
 var ink=0;var lost=0
 for y in range(reference.get_height()):
  for x in range(reference.get_width()):
   var a=reference.get_pixel(x,y)
   if a.a<0.98:continue
   ink+=1
   var b=actual.get_pixel(x,y)
   if Vector3(a.r,a.g,a.b).distance_to(Vector3(b.r,b.g,b.b))>0.08:lost+=1
 return {"pixels":ink,"lost":lost,"ratio":float(lost)/maxi(ink,1)}
func run():
 DirAccess.make_dir_recursive_absolute("res://build/review")
 viewport=SubViewport.new();viewport.size=Vector2i(192,192);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var camera=Camera3D.new();viewport.add_child(camera);camera.size=6.0;Iso.place_camera(camera,Vector3(0,1.3,0));camera.make_current()
 var art=load("res://scripts/art.gd").new()
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-35,0);viewport.add_child(light)
 var environment=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_energy=0.6;viewport.add_child(environment)
 var floor=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(30,30);floor.mesh=plane
 var green=StandardMaterial3D.new();green.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;green.albedo_color=Color("52b44c");floor.material_override=green;viewport.add_child(floor)
 var report=[]
 for kind in ["hall","barracks","kitchen","spring","crystal","tank","tower","servant","granary","well","ward","training","wall"]:
  for level in range(1,2 if kind=="servant" else 11):
   var model=art.building(kind,level);viewport.add_child(model);model.process_mode=Node.PROCESS_MODE_DISABLED
   for node in model.get_children():
    if node.name in ["ContactShadow","StorageAmount","BlackSmokeMotion"]:node.hide()
   var bounds=art.model_bounds(model)
   camera.size=maxf(6.0,maxf(bounds.size.x,bounds.size.z)*1.65)
   Iso.place_camera(camera,Vector3(0,bounds.end.y*0.4,0))
   floor.hide()
   var reference=await capture()
   floor.show()
   var actual=await capture()
   var result=coverage(reference,actual);result["kind"]=kind;result["level"]=level;report.append(result)
   if result.ratio>=0.01:
    reference.save_png("res://build/review/v050-failed-reference.png");actual.save_png("res://build/review/v050-failed-ground.png")
   if result.pixels<=30 or result.ratio>=0.01:
    push_error("Ground visibility failed: "+str(result));quit(1);return
   if level in [1,5,10]:actual.save_png("res://build/review/v050-ground-"+kind+"-"+str(level)+".png")
   model.queue_free();await process_frame
 # A real foreground object must still occlude an image, unlike no_depth_test.
 floor.hide()
 var hall=art.building("hall",5);viewport.add_child(hall);hall.get_node("ContactShadow").hide()
 camera.size=6.0;Iso.place_camera(camera,Vector3(0,1.3,0))
 var baseline=await capture()
 var blocker=MeshInstance3D.new();var cube=BoxMesh.new();cube.size=Vector3(4,4,0.3);blocker.mesh=cube;blocker.material_override=green;viewport.add_child(blocker)
 blocker.position=Vector3(0,1.3,0)+Iso.CAMERA_OFFSET.normalized()*5
 var front=coverage(baseline,await capture())
 if front.ratio<=0.25:push_error("Foreground occlusion not working");quit(1);return
 blocker.position=Vector3(0,1.3,0)-Iso.CAMERA_OFFSET.normalized()*5
 var behind=coverage(baseline,await capture())
 if behind.ratio>=0.01:push_error("Background incorrectly covers artwork");quit(1);return
 var file=FileAccess.open("res://build/review/ground-report.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"buildings":report,"foreground":front,"background":behind}, "  "))
 print("XIAN_GROUND_VISIBILITY_PASSED cases=",report.size()," foreground=",front.ratio," background=",behind.ratio)
 quit()
