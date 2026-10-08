extends SceneTree
const Sim=preload("res://scripts/practice_sim.gd")
const Formation=preload("res://scripts/formation_art.gd")
func _initialize():call_deferred("run")
func all_text(node: Node) -> String:
	var result=""
	if node is Label or node is Button:result+=node.text+"\n"
	for child in node.get_children():result+=all_text(child)
	return result
func run():
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.api.busy=true;game.api.refresh_token="";game.close_modal();game.server_time=1000;game.since_sync=0
	game.state={"name":"สำนักทดสอบ","map":"bamboo","water":1000,"rice":1000,"stone":100,"jade":30,"army":[0,0,0,0,0,0,0,0,0,0],"jobs":[{"id":"j1","type":0,"producer":"a","duration":10,"remaining":10,"finish":1010,"paused":false},{"id":"j2","type":1,"producer":"b","duration":20,"remaining":20,"finish":1020,"paused":false}],"buildings":[{"id":"hall","level":9,"x":7,"y":7,"finish":0},{"id":"barracks","uid":"a","level":1,"x":3,"y":3,"finish":0},{"id":"barracks","uid":"b","level":2,"x":5,"y":3,"finish":0},{"id":"training","level":2,"size":2,"x":7,"y":10,"finish":0}]}
	game.caps={"workers":1,"busy":0,"army":40};game.production_hall="a";game.mode="train";game.draw_base();game.show_side()
	assert(all_text(game.side).contains("หอ 1 • Lv.1"));assert(all_text(game.side).contains("หอ 2 • Lv.2"))
	assert(all_text(game.side).contains("พักการผลิต"));assert(all_text(game.side).contains("เสร็จทั้งคิว"));assert(all_text(game.side).contains("× ยกเลิก"))
	game.enqueue_training("a",0,1);game.enqueue_training("a",0,1)
	assert(game.train_requests.size()==1 and game.train_requests[0].quantity==2,"Repeated clicks must queue even during requests")
	game.train_requests.clear()
	game.since_sync=5;game.production_ui.update(game);assert(is_equal_approx(game.production_ui.bars[0].node.value,50.0))
	for kind in Formation.KINDS:
		for level in [1,5,10]:
			var model=game.art.building(kind,level);assert(model.get_child_count()>0);model.free()
		game.art.formation_fx(game.world,kind,Vector3.ZERO,Vector3(4,0,0))
	var sim=Sim.new();sim.setup_campaign(31);sim.buildings.clear();sim.units.clear();sim.defenders.clear();sim.traps.clear()
	var near=sim.combatant(0,Vector2(5,5),0);var far=sim.combatant(0,Vector2(15,15),0);sim.units=[near,far]
	for kind in ["trap_storm","trap_sword","trap_fire"]:
		near.hp=190;far.hp=190;sim.traps=[{"kind":kind,"pos":Vector2(5,5),"triggered":false}];sim.shots.clear()
		sim.tick_formation_traps(0.1)
		assert(near.hp<190 and far.hp==190,"Formation must only damage in range")
		assert(sim.shots.size()==1 and sim.shots[0].weapon==kind)
		sim.tick_formation_traps(0.1);assert(sim.shots.size()==1,"Trap must not retrigger")
	near.hp=190;far.hp=190;sim.add_building("lightning",Vector2i(5,4),500)
	sim.tick_campaign_defense(sim.buildings[0],0.1);assert(near.hp<190 and far.hp==190)
	var health=near.hp;sim.tick_campaign_defense(sim.buildings[0],0.1);assert(near.hp==health,"Lightning cooldown enforced")
	await process_frame
	print("XIAN_PRODUCTION_DEFENSES_UI_PASSED");quit()
