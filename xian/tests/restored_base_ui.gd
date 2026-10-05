extends SceneTree
class FakeAPI:
 extends "res://scripts/api.gd"
 var actions=[]
 func action(kind: String,args: Dictionary={}):actions.append({"kind":kind,"args":args})
func _initialize():call_deferred("run")
func run():
 var art=load("res://scripts/art.gd").new()
 assert(not art.architecture_enabled)
 for kind in ["hall","kitchen","barracks","spring","crystal","servant","tank","tower"]:
  for level in [1,5,10]:
   var model=art.building(kind,level)
   assert(not model.get_meta("architecture",false))
   assert(model.find_child("GroundFooting",true,false)==null)
   var visual=model.get_node("RealisticVisual")
   var used=visual.texture.get_image().get_used_rect()
   var bottom=(visual.texture.get_height()*0.5-used.end.y+visual.offset.y)*visual.pixel_size
   assert(bottom<0 and bottom>-0.65,"Base must straddle ground anchor: "+kind)
   model.free()
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.api.queue_free();game.api=FakeAPI.new();game.add_child(game.api);game.close_modal()
 game.state={"buildings":[{"id":"hall","x":7,"y":7,"level":1,"finish":0}],"army":[0,0,0],"jobs":[],"water":0,"rice":0,"stone":0}
 game.catalog=[{"id":"hall","name":"สำนักหลัก","water":100,"rice":100,"stone":10,"seconds":10}]
 game.caps={"workers":1,"busy":0}
 game.mode="manage";game.show_side();assert(game.side_panel.visible and not game.base_actions.visible)
 game.focus_building(0);assert(game.selected==0 and game.base_actions.visible)
 await process_frame
 assert(not game.world_area(game.base_actions.get_global_rect().get_center()))
 game.selected_upgrade();assert(not is_instance_valid(game.modal) and game.api.actions.is_empty())
 game.state.water=1000;game.state.rice=1000;game.state.stone=1000
 game.selected_upgrade();assert(is_instance_valid(game.modal) and game.api.actions.is_empty())
 game.close_modal();game.start_selected_move();assert(game.moving and game.api.actions.is_empty())
 game.navigate("manage");assert(not game.moving and not game.base_actions.visible)
 print("XIAN_RESTORED_BASE_UI_PASSED");quit()
