extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
const Sim=preload("res://scripts/practice_sim.gd")
const Defense=preload("res://scripts/campaign_defenses.gd")
func _initialize():call_deferred("run")
func run():
 var hashes={}
 for n in range(1,91):
  var stage=Campaign.stage(n);assert(stage==Campaign.stage(n));assert(stage.reserve.size()==10)
  var signature=JSON.stringify(stage.buildings);assert(not hashes.has(signature),"Repeated layout "+str(n));hashes[signature]=true
  var occupied={};var halls=0
  for b in stage.buildings:
   var p=Vector2i(b.x,b.y);assert(p.x>1 and p.y>1 and p.x<14 and p.y<14);assert(not occupied.has(p));occupied[p]=true
   if b.kind=="hall":halls+=1
  assert(halls==1)
  for t in stage.traps:assert(not occupied.has(Vector2i(t.x,t.y)))
  var sim=Sim.new();sim.setup_campaign(n);assert(sim.campaign_mode)
  assert(sim.can_deploy(Vector2i(0,7)));assert(not sim.can_deploy(Vector2i(8,8)))
  sim.started=true;sim.elapsed=180.0;sim.step(0.1);assert(not sim.finished,"Campaign must not time out")
  sim.clear_targets()
 var sim=Sim.new();sim.setup_campaign(31);sim.buildings.clear();sim.defenders.clear();sim.traps.clear()
 sim.add_building("cannon",Vector2i(7,7),9999);sim.rebuild_grid()
 sim.deploy(0,Vector2i(0,7));sim.deploy(1,Vector2i(0,8));sim.units[0].pos=Vector2(7,9);sim.units[1].pos=Vector2(7,8)
 for u in sim.units:u.windup=1000
 sim.step(0.1);assert(sim.units[0].hp<sim.units[0].max_hp and sim.units[1].hp==sim.units[1].max_hp)
 sim.buildings[0].kind="air_defense";sim.buildings[0].cooldown=0
 var ground_hp=sim.units[0].hp;sim.step(0.1);assert(sim.units[0].hp==ground_hp and sim.units[1].hp<sim.units[1].max_hp)
 # Mortar ignores nearby targets and airborne units.
 sim.buildings[0].kind="mortar";sim.buildings[0].cooldown=0;sim.units[0].pos=Vector2(7,8);sim.step(0.1);assert(sim.units[0].hp==ground_hp)
 sim.units[0].pos=Vector2(7,10);sim.step(0.1);assert(sim.units[0].hp<ground_hp)
 # A mine only detonates once, against the appropriate altitude.
 sim.buildings.clear();sim.rebuild_grid();sim.traps=[{"kind":"bomb","pos":Vector2(7,8),"triggered":false}]
 sim.units[0].pos=Vector2(1,1);sim.step(0.1);assert(not sim.traps[0].triggered)
 sim.units[0].pos=Vector2(7,8);sim.units[0].hp=1000;sim.step(0.1);assert(sim.traps[0].triggered)
 var after=sim.units[0].hp;sim.step(0.1);assert(sim.units[0].hp==after)
 sim.clear_targets()
 # Slow walkers must make progress between periodic path recalculations.
 sim.setup_campaign(35);sim.buildings.clear();sim.defenders.clear();sim.traps.clear();sim.add_building("hall",Vector2i(10,7),99999);sim.rebuild_grid()
 sim.deploy(4,Vector2i(1,7))
 for tick in range(200):sim.step(0.1)
 assert(sim.units[0].pos.x>5.0,"Slow unit oscillates on route start")
 sim.clear_targets()
 var progress=load("res://scripts/campaign_progress.gd").new();progress.path="user://campaign_test.json"
 for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(progress.path+suffix)
 progress.load_progress();assert(progress.unlocked()==1 and progress.total()==0)
 assert(progress.record(2,3)==ERR_INVALID_PARAMETER)
 assert(progress.record(1,2)==OK);assert(progress.unlocked()==2)
 assert(progress.record(1,1)==OK);assert(progress.total()==2)
 var restored=load("res://scripts/campaign_progress.gd").new();restored.path=progress.path;restored.load_progress();assert(restored.total()==2)
 for n in range(2,91):assert(progress.record(n,3)==OK)
 assert(progress.total()==269 and progress.unlocked()==90);assert(progress.record(1,3)==OK);assert(progress.total()==270)
 var file=FileAccess.open(progress.path,FileAccess.WRITE);file.store_string("broken");file.close()
 restored.load_progress();assert(restored.total()==269,"Recover last complete save")
 for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(progress.path+suffix)
 var game=load("res://scripts/offline_practice.gd").new();game.campaign_mode=true;game.test_mode=true;game.progress.path="user://campaign_ui_test.json";root.add_child(game);await process_frame
 assert(game.campaign_map.visible);assert(game.overlay_open());game.place_at(Vector2(450,400));assert(game.sim.units.is_empty())
 game.start_level(2);assert(game.level==1,"Locked level must stay locked")
 game.start_level(1);assert(not game.overlay_open());assert(game.sim.buildings[0].kind=="hall")
 for b in game.sim.buildings:b.hp=0
 game.finish();assert(game.progress.total()==3 and game.progress.unlocked()==2 and game.overlay_open())
 game.start_level(2);assert(game.level==2 and not game.sim.finished and game.sim.traps.all(func(t):return not t.triggered))
 for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(game.progress.path+suffix)
 game.queue_free();await process_frame
 print("XIAN_CAMPAIGN_PASSED 90 unique layouts; targeting, traps, no timer, saves, recovery, locks and UI");quit()
