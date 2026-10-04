extends SceneTree
class FakeAPI:
 extends "res://scripts/api.gd"
 var actions=[]
 func action(kind: String,args: Dictionary={}):actions.append({"kind":kind,"args":args})
const Walls=preload("res://scripts/wall_layout.gd")
func _initialize():call_deferred("run")
func run():
 var buildings=[]
 for p in [Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(6,5)]:buildings.append({"id":"wall","x":p.x,"y":p.y})
 assert(Walls.mask(buildings,Vector2i(5,4))==5)
 assert(Walls.mask(buildings,Vector2i(6,4))==12)
 assert(Walls.run_indices(buildings,0).size()==3)
 assert(Walls.run_indices(buildings,3).size()==2)
 assert(Walls.line(Vector2i(2,2),Vector2i(5,3)).size()==4)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.close_modal();game.api.queue_free();game.api=FakeAPI.new();game.add_child(game.api);game.state={"buildings":buildings,"army":[0,0,0],"jobs":[]};game.chosen_build="wall"
 game.update_preview(game.camera.unproject_position(game.cell_pos(7,7)))
 game.update_preview(game.camera.unproject_position(game.cell_pos(10,7)))
 assert(game.wall_cells.size()==4 and game.preview_ok)
 game.clear_preview();game.chosen_build="";game.moving=true;game.selected=0;game.wall_group=Walls.run_indices(buildings,0)
 game.update_preview(game.camera.unproject_position(game.cell_pos(7,7)))
 assert(game.wall_cells==[Vector2i(7,7),Vector2i(8,7),Vector2i(9,7)])
 game.clear_preview();game.wall_group.clear();game.moving=false;game.chosen_build="wall"
 var start=game.camera.unproject_position(game.cell_pos(7,7));var end=game.camera.unproject_position(game.cell_pos(10,7))
 var touch=InputEventScreenTouch.new();touch.index=0;touch.position=start;touch.pressed=true;game._input(touch)
 var drag=InputEventScreenDrag.new();drag.index=0;drag.position=end;drag.relative=end-start;game._input(drag)
 touch.position=end;touch.pressed=false;game._input(touch)
 assert(game.api.actions.size()==1)
 assert(game.api.actions[0].kind=="wall_line")
 assert(game.api.actions[0].args.x==7 and game.api.actions[0].args.end_x==10)
 print("XIAN_WALL_CLIENT_PASSED");quit()
