extends SceneTree
func _initialize():call_deferred("run")
func run():
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.api.busy=true;game.api.refresh_token="";game.close_modal();game.server_time=1000;game.since_sync=0
	game.state={"name":"สำนักอัสนีเมฆา","map":"bamboo","water":1800,"rice":1400,"stone":280,"jade":80,"army":[5,3,1,0,0,0,0,0,0,0],"jobs":[{"id":"j1","type":0,"producer":"a","duration":10,"remaining":10,"finish":1008,"paused":false}],"buildings":[{"id":"hall","level":5,"x":7,"y":5,"finish":0},{"id":"barracks","uid":"a","level":3,"x":4,"y":5,"finish":0},{"id":"barracks","uid":"b","level":2,"x":10,"y":5,"finish":0},{"id":"training","level":2,"size":2,"x":7,"y":10,"finish":0},{"id":"trap_storm","level":2,"x":4,"y":9,"finish":0},{"id":"trap_sword","level":2,"x":6,"y":9,"finish":0},{"id":"trap_fire","level":2,"x":10,"y":9,"finish":0},{"id":"lightning","level":2,"x":10,"y":7,"finish":0}]}
	game.caps={"workers":2,"busy":0,"army":40,"water":3000,"rice":3000,"stone":500};game.production_hall="a";game.mode="train";game.draw_base();game.update_top();game.show_side()
	await process_frame;await process_frame
	DirAccess.make_dir_recursive_absolute("res://build/review")
	root.get_texture().get_image().save_png("res://build/review/v053-production.png")
	game.mode="home";game.show_side();game.pivot=Vector3(0,0,1);game.camera.size=38;game.position_camera()
	for entry in [["trap_storm",4,9],["trap_sword",6,9],["trap_fire",10,9],["lightning",10,7]]:
		game.art.formation_fx(game.world,entry[0],game.cell_pos(entry[1],entry[2]),game.cell_pos(8,9))
	for effect in game.world.get_children():
		if effect.get_script()==preload("res://scripts/formation_fx.gd"):
			effect.set_process(false);effect._process(0.12)
	await process_frame;await process_frame
	root.get_texture().get_image().save_png("res://build/review/v053-formations.png")
	print("XIAN_V053_CAPTURE_PASSED");quit()
