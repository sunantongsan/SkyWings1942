extends SceneTree
func _initialize():call_deferred("run")
func run():
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.api.refresh_token=""
	assert(scene.camera != null)
	assert(scene.terrain.get_child_count()>0 and scene.terrain.get_child_count()<24)
	assert(scene.art.model_bounds(scene.terrain).size.x>=48)
	scene.draw_terrain("mountain")
	assert(scene.map_drawn=="mountain")
	for kind in ["hall","well","kitchen","tank","granary","spring","crystal","servant","recruit","training","dorm","tower","ward","wall"]:
		var model=scene.art.building(kind,1,0.5)
		assert(model.get_child_count()>0)
		model.free()
	for kind in range(3):scene.art.person(kind).free()
	var id=scene.api.uuid()
	assert(id.length()==36)
	print("XIAN_SMOKE_PASSED")
	quit()
