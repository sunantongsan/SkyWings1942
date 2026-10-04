extends SceneTree
const Art=preload("res://scripts/art.gd")
const KINDS=["hall","well","kitchen","tank","granary","spring","crystal","servant","recruit","training","dorm","tower","ward","wall","barracks"]
func _initialize():call_deferred("run")
func run():
 var art=Art.new()
 for kind in KINDS:
  var last_count=-1
  var last_height=-1.0
  for level in range(1,11):
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
 print("XIAN_BUILDING_LEVELS_PASSED");quit()
