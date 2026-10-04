extends SceneTree
const Art=preload("res://scripts/art.gd")
func _initialize():call_deferred("run")
func run():
 var art=Art.new()
 for kind in ["hall","well","kitchen","tank","granary","spring","crystal","servant","recruit","training","dorm","tower","ward","wall"]:
  var model=art.building(kind,1);root.add_child(model)
  assert(model.get_meta("donor_building",false) or model.get_meta("courtyard",false));assert(art.model_bounds(model).size.length()>0.1)
  model.queue_free()
 for kind in [0,1]:
  var model=art.person(kind);root.add_child(model)
  for mesh in model.find_children("*","MeshInstance3D",true,false):assert(not "backpack" in mesh.name.to_lower())
  assert(model.get_meta("donor_character",false))
  var player=model.find_children("*","AnimationPlayer",true,false)[0]
  assert(player.has_animation("movement/walk_fwd"))
  await process_frame;await process_frame
  assert(player.is_playing())
  assert(model.find_child("SwordHand",true,false)!=null)
  model.queue_free()
 await process_frame
 print("XIAN_DONOR_ASSETS_PASSED");quit()
