extends SceneTree
class FakeAPI:
 extends "res://scripts/api.gd"
 var actions:Array=[]
 func action(kind:String,args:Dictionary={}):actions.append({"kind":kind,"args":args})
func touch(game,index,pos,pressed):
 var e=InputEventScreenTouch.new();e.index=index;e.position=pos;e.pressed=pressed;game._input(e)
func drag(game,index,pos,relative):
 var e=InputEventScreenDrag.new();e.index=index;e.position=pos;e.relative=relative;game._input(e)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.api.queue_free();game.api=FakeAPI.new();game.add_child(game.api)
 game.close_modal();game.mode="home"
 game.state={"buildings":[{"id":"hall","x":7,"y":7,"level":1,"finish":0}],"army":[0,0,0],"jobs":[]}
 game.caps={}
 assert(not game.valid_cell(Vector2i(7,7)));assert(not game.valid_cell(Vector2i(-1,7)));assert(game.valid_cell(Vector2i(8,7)))
 var before=game.camera.size
 touch(game,0,Vector2(350,300),true);touch(game,1,Vector2(550,300),true)
 drag(game,1,Vector2(650,300),Vector2(100,0))
 assert(game.camera.size<before)
 touch(game,1,Vector2(650,300),false);touch(game,0,Vector2(350,300),false)
 assert(game.api.actions.is_empty())
 game.choose_build("well")
 var target=game.camera.unproject_position(game.cell_pos(8,8))
 touch(game,0,target-Vector2(30,0),true);drag(game,0,target,Vector2(30,0))
 assert(game.preview_ok and game.preview_cell==Vector2i(8,8))
 touch(game,0,target,false)
 assert(game.api.actions.size()==1 and game.api.actions[0].args.x==8)
 target=game.camera.unproject_position(game.cell_pos(7,7))
 game.drop_build(target);assert(game.api.actions.size()==1)
 game.catalog=[{"id":"well","name":"บ่อน้ำ","water":20,"rice":10,"stone":0,"seconds":5}]
 game.mode="build";game.show_side();await process_frame;await process_frame
 var card=game.build_cards[0].node;var start=card.get_global_rect().get_center()
 target=game.camera.unproject_position(game.cell_pos(9,8))
 touch(game,0,start,true);drag(game,0,start-Vector2(50,0),Vector2(-50,0));drag(game,0,target,target-start)
 touch(game,0,target,false)
 assert(game.api.actions.size()==2)
 for i in range(20):game.button(game.side,"รายการทดสอบ",func():pass)
 await process_frame;await process_frame
 var old_scroll=game.sidebar_scroll.scroll_vertical
 touch(game,0,Vector2(1100,450),true);drag(game,0,Vector2(1100,320),Vector2(0,-130));touch(game,0,Vector2(1100,320),false)
 assert(game.sidebar_scroll.scroll_vertical>old_scroll)
 assert(game.api.actions.size()==2)
 game.chosen_build="training"
 assert(not game.valid_cell(Vector2i(6,6)))
 assert(not game.valid_cell(Vector2i(15,14)))
 assert(game.valid_cell(Vector2i(8,8)))
 game.state.buildings.append({"id":"training","x":8,"y":8,"size":2,"level":1,"finish":0})
 game.chosen_build="well"
 for cell in [Vector2i(8,8),Vector2i(9,8),Vector2i(8,9),Vector2i(9,9)]:assert(not game.valid_cell(cell))
 print("XIAN_TOUCH_BUILD_PASSED");quit()
