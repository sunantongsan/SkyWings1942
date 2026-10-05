extends SceneTree
const Art=preload("res://scripts/art.gd")
const KINDS=["hall","well","kitchen","tank","granary","spring","crystal","servant","recruit","training","dorm","tower","ward","wall","barracks"]
func _initialize():call_deferred("run")
func run():
 var art=Art.new()
 for kind in KINDS:
  var last_count=-1
  var last_height=-1.0
  for level in range(1,2 if kind=="servant" else 11):
   var model=art.building(kind,level,0.6)
   var bounds=art.model_bounds(model)
   assert(bounds.size.y>0.1 and bounds.size.y<7.0,"Invalid height "+kind)
   var envelope=7.0 if kind=="training" else 4.4
   assert(bounds.size.x<envelope and bounds.size.z<envelope,"Invalid footprint "+kind+str(level)+str(bounds.size))
   var count=0
   for mesh in model.find_children("*","MeshInstance3D",true,false):
    for surface in range(mesh.mesh.get_surface_count()):count+=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
   assert(count!=last_count or not is_equal_approx(bounds.size.y,last_height),"Upgrade visually unchanged: "+kind+str(level))
   last_count=count;last_height=bounds.size.y;model.free()
 for fill in [0.0,0.5,1.0]:
  var pouch=art.building("crystal",5,fill)
  assert(pouch.get_meta("pill_count")==ceili(fill*24))
  assert(pouch.find_child("SheerCloth",true,false).material_override.albedo_color.a<0.4)
  pouch.free()
 for kind in ["granary","tank"]:
  for fill in [0.0,0.5,1.0]:
   var model=art.building(kind,10,fill)
   assert(is_equal_approx(model.get_meta("storage_fill"),fill))
   if kind=="granary":assert(model.get_meta("food_count")==ceili(fill*180))
   else:assert((model.find_child("StoredWater",true,false)!=null)==(fill>0))
   model.free()
 for kind in ["kitchen","spring","granary"]:
  for level in range(1,11):
   var model=art.building(kind,level)
   assert(model.get_meta("floors" if kind=="kitchen" else "tiers")==level)
   model.free()
 var pump=art.building("well",5);root.add_child(pump)
 var moving=pump.find_child("PumpMotion",true,false)
 assert(moving!=null and moving.get_node("Handle").get_child_count()>0)
 moving.animate(0.0);var before=moving.get_node("Handle").rotation.z
 moving.animate(0.4);assert(not is_equal_approx(before,moving.get_node("Handle").rotation.z))
 var scaffold=Node3D.new();root.add_child(scaffold);art.construction_dressing(scaffold,1,0.5)
 var saw=scaffold.find_child("SawMotion",true,false)
 saw.animate(0);saw.animate(0.2);assert(abs(saw.get_node("Saw").position.x)>0.05)
 var burner=art.building("spring",10);root.add_child(burner)
 var smoke=burner.find_child("SmokeMotion",true,false)
 smoke.animate(0);var first=smoke.get_child(0).position
 smoke.animate(0.5);assert(first.distance_to(smoke.get_child(0).position)>0.1)
 pump.queue_free();scaffold.queue_free();burner.queue_free()
 await process_frame
 print("XIAN_BUILDING_LEVELS_PASSED");quit()
