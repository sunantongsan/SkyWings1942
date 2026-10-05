extends SceneTree
const Art=preload("res://scripts/art.gd")
func _initialize():call_deferred("run")
func run():
	var art=Art.new();art.architecture_enabled=false;var names={} # Retained legacy art regression
	for level in range(1,11):
		var wall=art.wall(15,0,level);root.add_child(wall);names[wall.get_meta("material_name")]=true;assert(wall.get_meta("wall_mask")==15);wall.free()
		var ward=art.building("ward",level);root.add_child(ward);assert(ward.find_children("Horn_*","Node3D",false,false).size()==4*level);assert(art.model_bounds(ward).size.y<8);ward.free()
		var well=art.building("well",level);root.add_child(well);var pump=well.get_node("PumpMotion");pump.animate(0);var a=pump.lever.transform;pump.animate(0.55);assert(pump.worker.frame==2);assert(a!=pump.lever.transform);assert(pump.stream.visible);well.free()
	assert(names.size()==10)
	var terrain=Node3D.new();root.add_child(terrain);art.landscape(terrain);assert(art.ground_materials[false].albedo_texture is ImageTexture);terrain.free()
	var grid=AStarGrid2D.new();grid.region=Rect2i(0,0,16,16);grid.update();grid.set_point_solid(Vector2i(7,8))
	var unit=art.person(0);unit.set_script(preload("res://scripts/sect_life.gd"));unit.art=art;unit.grid=grid;unit.cell=Vector2i(7,7);unit.position=unit.world_cell(unit.cell);unit.destination=unit.position;root.add_child(unit)
	for i in range(100):unit._process(0.1);assert(not grid.is_point_solid(unit.cell))
	unit.activity="sleep";unit._process(0.1);var sprite=unit.get_node("CharacterSprite");sprite._process(0.1);assert(sprite.state=="sleep");assert(sprite.texture is AtlasTexture)
	unit.alarm(unit.position+Vector3(3,0,0));unit._process(0.1);assert(unit.defending and sprite.state=="walk")
	unit.free();print("XIAN_SECT_LIFE_PASSED");quit()
