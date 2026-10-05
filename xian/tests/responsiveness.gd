extends SceneTree
func _initialize():call_deferred("run")
func touch(game,pos,pressed):
 var e=InputEventScreenTouch.new();e.index=0;e.position=pos;e.pressed=pressed;game._input(e)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.close_modal();game.api.busy=true;game.mode="home"
 var state={"name":"test","map":"bamboo","water":100,"rice":100,"stone":10,"jade":0,"army":[0,0,0,0,0,0,0,0,0,0],"jobs":[],"buildings":[{"id":"hall","x":7,"y":7,"level":1,"finish":0},{"id":"tank","x":4,"y":4,"level":1,"finish":0}]}
 var payload={"state":state,"capacity":{"water":1000,"rice":1000,"stone":100},"catalog":[]}
 game.receive(payload);await process_frame
 var key=JSON.stringify(state.buildings[0]);var original=game.base_cache[key]
 state.water=200;game.receive(payload);await process_frame
 assert(game.base_cache[key]==original,"Resource sync replaced unchanged building")
 state.buildings.append({"id":"kitchen","x":10,"y":10,"level":1,"finish":0});game.receive(payload);await process_frame
 assert(game.base_cache[key]==original,"Building another structure replaced unchanged hall")
 game.queue_free();await process_frame
 var battle=load("res://scripts/offline_practice.gd").new();battle.test_mode=true;root.add_child(battle)
 await process_frame;await process_frame
 var selected=battle.selected_kind;var start=Vector2(1100,430)
 touch(battle,start,true)
 var drag=InputEventScreenDrag.new();drag.index=0;drag.position=start-Vector2(0,180);drag.relative=Vector2(0,-180);battle._input(drag)
 touch(battle,drag.position,false)
 assert(battle.troop_scroll.scroll_vertical>0,"Troop list did not scroll")
 assert(battle.selected_kind==selected,"Swipe selected a troop")
 assert(battle.sim.units.is_empty(),"Swipe deployed a troop")
 battle.troop_scroll.scroll_vertical=0;await process_frame;await process_frame
 var point=battle.unit_buttons[1].get_global_rect().get_center();touch(battle,point,true);touch(battle,point,false)
 assert(battle.selected_kind==1,"Tap failed to select troop")
 print("XIAN_RESPONSIVENESS_PASSED");quit()
