extends SceneTree
const Sim=preload("res://scripts/practice_sim.gd")
func _initialize():call_deferred("run")
func run():
 var report=[];var failures=[]
 for n in range(1,91):
  var best=0;var best_damage=0;var fastest=9999.0;var results=[]
  # Separate flanks and focused attacks are both tested; deterministic and reproducible.
  for strategy in range(6):
   if strategy>=2 and best==3:break
   var sim=Sim.new();sim.setup_campaign(n)
   for kind in [4,7,0,2,5,6,1,8,9,3]:
    var count=sim.reserve[kind]
    for i in range(count):
     var points=[Vector2i(1,7),Vector2i(7,1),Vector2i(14,8),Vector2i(8,14)]
     sim.deploy(kind,points[i%4] if strategy==0 else points[((n-1)%4 if strategy==1 else strategy-2)])
   for tick in range(6000):
    sim.step(0.1)
    if sim.finished:break
   best=maxi(best,sim.stars());best_damage=maxi(best_damage,sim.percent());fastest=minf(fastest,sim.elapsed)
   results.append({"strategy":strategy,"stars":sim.stars(),"percent":sim.percent(),"seconds":snappedf(sim.elapsed,0.1),"finished":sim.finished})
   sim.clear_targets()
  if best==0:failures.append(n)
  report.append({"stage":n,"best_stars":best,"best_percent":best_damage,"results":results})
  print("CAMPAIGN ",n," best=",best," damage=",best_damage," time=",snappedf(fastest,0.1))
 DirAccess.make_dir_recursive_absolute("res://build/review")
 var file=FileAccess.open("res://build/review/campaign-balance.json",FileAccess.WRITE);file.store_string(JSON.stringify({"stages":report,"failed_stages":failures},"  "));file.close()
 print("FAILED STAGES ",failures)
 assert(failures.is_empty(),"Campaign requires at least one viable tested attack per stage")
 print("XIAN_CAMPAIGN_BALANCE_PASSED");quit()
