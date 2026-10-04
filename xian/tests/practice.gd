extends SceneTree
const Sim=preload("res://scripts/practice_sim.gd")
func _initialize():call_deferred("run")
func run():
 var sim=Sim.new();sim.setup(5)
 assert(not sim.deploy(0,Vector2i(7,7)))
 assert(sim.deploy(0,Vector2i(0,7)))
 assert(sim.deploy(1,Vector2i(0,7)))
 assert(sim.deploy(2,Vector2i(0,7)))
 sim.choose_target(sim.units[2]);assert(sim.units[2].target.kind in ["tower","ward"])
 # Every ground route avoids living buildings and walls.
 sim.choose_target(sim.units[0])
 for point in sim.units[0].path:assert(not sim.grid.is_point_solid(Vector2i(point)))
 # A completely enclosed hall forces ground troops to breach a wall.
 sim.buildings=sim.buildings.filter(func(b):return b.kind in ["hall","wall"]);sim.rebuild_grid()
 sim.choose_target(sim.units[0]);assert(sim.units[0].target.kind=="wall")
 sim.choose_target(sim.units[1]);assert(sim.units[1].target.kind=="hall")
 var wall=sim.units[0].target;sim.damage_building(wall,10000);assert(not sim.grid.is_point_solid(Vector2i(wall.pos)))
 for tier in range(1,13):
  sim.setup(tier)
  for k in range(3):
   while sim.reserve[k]>0:assert(sim.deploy(k,Vector2i(0,7)))
  for i in range(1900):sim.step(0.1)
  assert(sim.finished);assert(sim.elapsed<=180.2)
  assert(sim.percent()>0,"Troops failed to damage base")
  print("BASE ",tier," stars=",sim.stars()," damage=",sim.percent()," alive=",sim.alive())
 # Split deployment should remain viable on the final base.
 sim.setup(12)
 for kind in [2,0,1]:
  var count=sim.reserve[kind]
  for i in range(count):
   var positions=[Vector2i(1,6),Vector2i(6,1),Vector2i(14,9),Vector2i(9,14)]
   sim.deploy(kind,positions[i%4])
 for i in range(1900):sim.step(0.1)
 print("SPLIT FINAL BASE stars=",sim.stars()," damage=",sim.percent())
 # Scores are based on destruction, not elapsed time.
 sim.setup(12);assert(sim.stars()==0)
 for b in sim.buildings:b.hp=0
 assert(sim.stars()==3 and sim.percent()==100)
 print("XIAN_OFFLINE_PRACTICE_PASSED");quit()
