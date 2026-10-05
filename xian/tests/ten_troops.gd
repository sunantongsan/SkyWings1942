extends SceneTree
const Art=preload("res://scripts/art.gd")
const Troops=preload("res://scripts/troops.gd")
const Sim=preload("res://scripts/practice_sim.gd")
func _initialize():call_deferred("run")
func run():
 var art=Art.new();var stage=Node3D.new();root.add_child(stage)
 assert(Troops.UPGRADE[9]==10000000)
 for level in range(1,11):
  var model=art.building("granary",level,0.5);stage.add_child(model)
  assert(model.get_meta("architecture",false) and model.get_meta("visual_level")==level)
  assert(art.model_bounds(model).size.y<4.2)
  model.free()
 var sim=Sim.new();sim.setup(10)
 for kind in range(10):
  assert(sim.deploy(kind,Vector2i(0,7)))
  assert(sim.units[-1].hp==Troops.HP[kind])
  var actor=art.person(kind);stage.add_child(actor);art.pose(actor,"attack",0.8)
  actor.get_node("CharacterSprite")._process(0.4)
  art.strike_fx(stage,Vector3.ZERO,Vector3(1,0,0),kind)
  actor.free()
 for i in range(20):sim.step(0.1)
 await create_timer(1.1).timeout
 assert(art.fx_count==0,"Combat effects leaked")
 stage.free();print("XIAN_TEN_TROOPS_PASSED");quit()
