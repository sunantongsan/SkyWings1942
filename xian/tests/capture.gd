extends SceneTree
func _initialize():call_deferred("run")
func run():
	var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene)
	await process_frame
	scene.api.refresh_token="";scene.api.busy=true
	scene.close_modal();scene.mode="home"
	scene.state={"name":"สำนักเมฆาคราม","map":"bamboo","water":1350,"rice":950,"stone":150,"jade":45,"army":[5,3,1],"jobs":[],"buildings":[]}
	scene.caps={"water":3000,"rice":3000,"stone":600,"workers":2,"busy":0,"army":30}
	var kinds=["hall","well","kitchen","tank","granary","spring","crystal","servant","recruit","training","dorm","tower","ward"]
	var positions=[[7,6],[4,5],[9,5],[4,7],[9,7],[6,4],[8,4],[5,9],[7,9],[9,9],[6,11],[4,10],[10,10]]
	for i in range(kinds.size()):
		scene.state.buildings.append({"id":kinds[i],"x":positions[i][0],"y":positions[i][1],"level":1,"finish":0})
	for i in range(4,11):scene.state.buildings.append({"id":"wall","x":i,"y":12,"level":1,"finish":0})
	scene.draw_base();scene.update_top();scene.show_side()
	await process_frame;await process_frame
	DirAccess.make_dir_recursive_absolute("res://build/review")
	root.get_texture().get_image().save_png("res://build/review/bamboo.png")
	scene.draw_terrain("mountain")
	await process_frame;await process_frame
	root.get_texture().get_image().save_png("res://build/review/mountain.png")
	scene.state.match={"board":[],"moves":20,"score":0,"goal":300};scene.state.match_level=1
	for i in range(64):scene.state.match.board.append((i+i/8)%5)
	scene.mode="match";scene.show_match()
	await process_frame;await process_frame
	root.get_texture().get_image().save_png("res://build/review/match.png")
	print("XIAN_CAPTURE_PASSED");quit()
