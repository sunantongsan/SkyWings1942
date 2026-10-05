extends SceneTree
class FakeAPI:
 extends "res://scripts/api.gd"
 var actions=[]
 func action(kind: String,args: Dictionary={}):actions.append({"kind":kind,"args":args})
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.api.queue_free();game.api=FakeAPI.new();game.add_child(game.api)
 game.close_modal();game.mode="home"
 game.state={"name":"สำนักทดสอบ","map":"bamboo","water":100,"rice":200,"stone":10,"jade":300,"army":[0,0,0],"jobs":[],"buildings":[{"id":"servant","x":5,"y":7,"level":1,"finish":0}],"checkin_count":3}
 game.catalog=[{"id":"servant","name":"เพิงช่าง","water":0,"rice":0,"stone":0,"seconds":0,"jade_prices":[0,250,500,1000,2000,3500,5000]}]
 game.update_top();assert(game.resource_labels.size()==4 and game.gift_button.visible)
 assert(not game.world_area(game.gift_button.get_global_rect().get_center()))
 assert(game.builder_count()==1 and game.builder_price()==250)
 game.selected=0;game.show_side()
 for b in game.side.find_children("*","Button",true,false):assert(b.text!="อัปเกรด")
 game.checkin_available=true;game.navigate("jade");assert(is_instance_valid(game.modal))
 game.claim_daily();game.claim_daily();assert(game.api.actions.size()==1 and game.api.actions[0].kind=="checkin")
 game.close_modal();game.gift_claiming=false;game.checkin_available=false;game.claim_daily();assert(game.api.actions.size()==1)
 var model=game.art.building("hall",1);game.world.add_child(model)
 game.battle_buildings=[{"node":model,"kind":"hall","width":1,"destroyed":false}]
 game.update_raid_destruction(1,1);assert(not model.visible)
 var ruins=game.world.find_child("Ruins",false,false);assert(ruins!=null)
 var n=game.world.get_child_count();game.update_raid_destruction(1,1);assert(game.world.get_child_count()==n)
 var smoke=ruins.find_child("EmbersMotion",true,false);smoke.animate(0);var old=smoke.get_child(0).position;smoke.animate(1);assert(smoke.get_child(0).position!=old)
 await process_frame;assert(is_instance_valid(ruins))
 print("XIAN_GIFTS_BUILDERS_PASSED");quit()
