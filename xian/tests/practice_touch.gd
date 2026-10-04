extends SceneTree
func _initialize():call_deferred("run")
func touch(game,index,pos,pressed):
 var e=InputEventScreenTouch.new();e.index=index;e.position=pos;e.pressed=pressed;game._unhandled_input(e)
func drag(game,index,pos,relative):
 var e=InputEventScreenDrag.new();e.index=index;e.position=pos;e.relative=relative;game._unhandled_input(e)
func run():
 var game=load("res://scripts/offline_practice.gd").new();root.add_child(game);await process_frame
 game.test_mode=true;game.camera.size=64
 var origin=game.camera.unproject_position(game.world_pos(Vector2(1,7)))
 touch(game,0,origin,true);touch(game,0,origin,false)
 assert(game.sim.units.size()==1)
 var start_pivot=game.pivot
 touch(game,0,Vector2(400,300),true);drag(game,0,Vector2(440,310),Vector2(40,10));touch(game,0,Vector2(440,310),false)
 assert(game.pivot!=start_pivot and game.sim.units.size()==1)
 var old_size=game.camera.size
 touch(game,0,Vector2(350,300),true);touch(game,1,Vector2(550,300),true)
 drag(game,1,Vector2(650,300),Vector2(100,0))
 touch(game,1,Vector2(650,300),false);touch(game,0,Vector2(350,300),false)
 assert(game.camera.size<old_size and game.sim.units.size()==1)
 print("XIAN_PRACTICE_TOUCH_PASSED");quit()
