extends SceneTree
const Art=preload("res://scripts/art.gd")
func _initialize():call_deferred("run")
func run():
	var art=Art.new()
	for kind in art.realistic.WIDTHS:
		if kind=="carpenter":continue
		var previous=Rect2()
		for level in range(1,2 if kind=="servant" else 11):
			var model=art.building(kind,level,0.25);root.add_child(model)
			assert(model.get_meta("realistic_art",false),kind)
			var visual=model.get_node("RealisticVisual")
			assert(visual.texture!=null and visual.pixel_size>0)
			var bounds=art.model_bounds(model)
			assert(bounds.size.y>0.1 and bounds.size.y<8.5,kind+str(bounds))
			if visual.texture is AtlasTexture:
				assert(visual.texture.region!=previous,"Repeated upgrade frame: "+kind)
				previous=visual.texture.region
			if kind in ["tank","granary","crystal"]:assert(model.get_node("StorageAmount").text=="25%")
			model.free()
	for kind in range(3):
		var unit=art.person(kind);root.add_child(unit);art.pose(unit,"walk")
		var sprite=unit.get_node("CharacterSprite");sprite._process(0.15)
		assert(sprite.frame>0);assert(sprite.hframes*sprite.vframes==8)
		unit.position=Vector3(-1,0,1);sprite._process(0.01);assert(sprite.flip_h)
		art.pose(unit,"attack",0.7);assert(sprite.attack_time>0);unit.free()
	var scaffold=Node3D.new();root.add_child(scaffold);art.construction_dressing(scaffold,1,0.4)
	var worker=scaffold.find_children("*","Sprite3D",true,false)[0]
	worker._process(0.2);assert(worker.frame>0)
	var smoke=art.building("spring",5);root.add_child(smoke)
	var motion=smoke.get_node("BlackSmokeMotion");motion.animate(0);var before=motion.get_child(0).position;motion.animate(1)
	assert(before!=motion.get_child(0).position)
	scaffold.free();smoke.free()
	print("XIAN_REALISTIC_ART_PASSED");quit()
