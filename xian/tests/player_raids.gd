extends SceneTree
func _initialize():call_deferred("run")
func texts(node: Node) -> String:
	var result=""
	if node is Label or node is Button:result+=node.text+"\n"
	for child in node.get_children():result+=texts(child)
	return result
func run():
	var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene)
	await process_frame
	scene.api.refresh_token="";scene.api.busy=true;scene.close_modal();scene.mode="home"
	scene.server_time=1000;scene.since_sync=0
	var buildings=[{"id":"hall","level":2,"x":7,"y":7,"finish":0},{"id":"servant","level":1,"x":5,"y":7,"finish":0},{"id":"wall","level":3,"x":5,"y":9,"finish":0}]
	var report={"id":"test-report","attacker":"สำนักทดสอบ","time":970,"finish":995,"water":600,"rice":480,"stone":60}
	scene.state={"name":"ฐานทดสอบ","map":"bamboo","water":400,"rice":320,"stone":40,"jade":77,"army":[0,0,0,0,0,0,0,0,0,0],"jobs":[],"buildings":buildings,"last_defense":report,"defense_history":[report],"repair_pending":true,"repair_until":1020}
	scene.caps={"water":1000,"rice":1000,"stone":100,"workers":1,"busy":0,"army":20}
	scene.draw_base();scene.show_side()
	assert(scene.repair_visual)
	var rubble=0
	for child in scene.world.get_children():
		if child.get_meta("ruins",false):rubble+=1
	assert(rubble==3,"All damaged buildings must be visible as ruins")
	assert(texts(scene.side).contains("เอาคืน สำนักทดสอบ"))
	assert(texts(scene.side).contains("20 วินาที"))
	scene.since_sync=20;scene._process(0)
	assert(not scene.repair_visual,"Repair visuals must end at exactly 20 seconds")
	assert(scene.base_cache.size()==3)
	assert(scene.state.buildings==buildings,"Repair must preserve layout and upgrade levels")
	assert(scene.state.jade==77)
	scene.mode="raid";scene.show_side()
	assert(texts(scene.side).contains("ค้นหาสำนักผู้เล่น"))
	assert(not texts(scene.side).contains("ค้นหาสำนักบอท"))
	print("XIAN_PLAYER_RAIDS_UI_PASSED");quit()
