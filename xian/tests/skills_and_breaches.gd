extends SceneTree
const Sim=preload("res://scripts/practice_sim.gd")
const Troops=preload("res://scripts/troops.gd")
func _initialize():call_deferred("run")
func blank():
 var sim=Sim.new();sim.setup(10);sim.clear_targets();sim.buildings.clear();sim.defenders.clear();sim.rebuild_grid();return sim
func run():
 var sim=blank()
 sim.add_building("hall",Vector2i(6,5),1000);sim.add_building("tank",Vector2i(8,5),1000);sim.add_building("wall",Vector2i(5,5),1000);sim.rebuild_grid()
 var thief=sim.combatant(3,Vector2(3,5),0);sim.choose_target(thief)
 assert(thief.target.kind=="tank","Thief must prioritize stores")
 assert(not thief.path.is_empty())
 sim.resolve_skill(thief,thief.target);assert(sim.stolen.water==25 and thief.target.stock==175)
 var stone=sim.combatant(7,Vector2(3,5),0);sim.choose_target(stone);assert(stone.target.kind=="wall","Stone must smash obstruction instead of detouring")
 var guard=sim.combatant(1,Vector2(7,5),1);sim.defenders.append(guard)
 var tiger=sim.combatant(6,Vector2(3,5),0);sim.choose_target(tiger);assert(tiger.target.eid==guard.eid,"Tiger must hunt airborne defenders")
 sim.resolve_skill(tiger,guard);assert(guard.hp<guard.max_hp)
 sim=blank();sim.add_building("hall",Vector2i(6,5),1000);sim.add_building("tank",Vector2i(7,5),1000);sim.add_building("crystal",Vector2i(4,8),1000);sim.rebuild_grid()
 var dragon=sim.combatant(2,Vector2(4,5),0);sim.resolve_skill(dragon,sim.buildings[0]);assert(sim.buildings[0].burn>0 and sim.buildings[1].burn>0 and sim.buildings[2].hp==1000)
 var sage=sim.combatant(5,Vector2(4,5),0);var before=sim.buildings[1].hp;sim.resolve_skill(sage,sim.buildings[0]);assert(sim.buildings[1].hp<before)
 var phoenix=sim.combatant(8,Vector2(4,5),0);before=sim.buildings[1].hp;sim.resolve_skill(phoenix,sim.buildings[0]);assert(sim.buildings[1].hp<before and sim.buildings[2].hp==1000)
 assert(Troops.HP[8]==Troops.HP[7] and Troops.ARMOR[8]<Troops.ARMOR[5])
 assert(Troops.HP[9]>Troops.HP[7] and Troops.ARMOR[9]>Troops.ARMOR[7])
 assert(Troops.SPEED[4]<Troops.SPEED[0] and Troops.SPEED[6]>Troops.SPEED[3])
 sim=blank()
 for x in range(6,10):sim.add_building("tank",Vector2i(x,5),2000)
 var deity=sim.combatant(9,Vector2(3,5),0);sim.resolve_skill(deity,sim.buildings[0])
 assert(sim.buildings[0].hp<2000 and sim.buildings[1].hp<2000 and sim.buildings[2].hp<2000 and sim.buildings[3].hp==2000)
 sim=blank();sim.add_building("tank",Vector2i(8,5),2000);sim.add_building("wall",Vector2i(5,5),2000);sim.rebuild_grid()
 thief=sim.combatant(3,Vector2(3,5),0);sim.units.append(thief);sim.started=true
 var climbed=false
 for i in range(60):sim.step(0.1);climbed=climbed or thief.climbing>0
 assert(climbed and sim.buildings[1].hp==2000 and sim.stolen.water>0,"Thief must climb intact wall and steal")
 var game=load("res://scripts/offline_practice.gd").new();root.add_child(game);await process_frame;game.test_mode=true
 game.start_level(6);await process_frame
 var count=vertices(game.battlefield.get_node("Terrain"))
 game.start_level(6);await process_frame
 assert(vertices(game.battlefield.get_node("Terrain"))==count,"Restart baked old walls into terrain")
 var index=-1
 for i in range(game.sim.buildings.size()):
  if game.sim.buildings[i].kind=="wall":index=i;break
 var wall=game.sim.buildings[index];var node=game.models[index].node
 game.sim.damage_building(wall,99999);game.test_mode=false;game._process(0.01);game.test_mode=true
 assert(node.get_parent()==null and not node.visible,"Destroyed wall still rendered")
 assert(not game.sim.grid.is_point_solid(Vector2i(wall.pos)),"Breach still blocks navigation")
 await process_frame;assert(not is_instance_valid(node))
 game.start_level(10);game.test_mode=false
 for kind in range(10):
  assert(game.sim.deploy(kind,Vector2i(0,7)))
  var actor=game.art.person(kind);game.battlefield.add_child(actor);actor.position=game.world_pos(Vector2(0,7));game.unit_models.append({"node":actor,"bar":game.health_bar(actor,3)})
 for i in range(160):game._process(0.1);await process_frame
 assert(game.sim.units.size()==10 and game.guard_models.size()==3)
 game.free();sim.clear_targets();print("XIAN_SKILLS_BREACHES_PASSED");quit()
func vertices(node):
 var count=0
 for mesh in node.find_children("*","MeshInstance3D",true,false):
  for surface in range(mesh.mesh.get_surface_count()):count+=mesh.mesh.surface_get_array_len(surface)
 return count
