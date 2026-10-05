extends SceneTree
func _initialize():call_deferred("run")
func run():
 var art=load("res://scripts/art.gd").new();art.architecture_enabled=true # Optional retained prototype, not production art.
 for kind in load("res://scripts/village_architecture.gd").KINDS:
  for level in [1,5,10]:
   var model=art.building(kind,level,0.5);root.add_child(model)
   assert(model.get_meta("architecture",false))
   var bounds=art.model_bounds(model)
   assert(bounds.size.x<3.01 and bounds.size.z<3.01,kind+str(bounds))
   assert(bounds.position.y>=-0.05 and bounds.end.y<4.2,kind+str(bounds))
   model.free()
 print("XIAN_ARCHITECTURE_PASSED");quit()
