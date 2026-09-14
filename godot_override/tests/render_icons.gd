extends SceneTree
var names := ["galactic_core","fusion_reactor","metal_extractor","oil_processor","crystal_mine","resource_vault","star_hangar","research_lab","laser_tower","shield_generator","gold_refinery","missile_bastion"]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/icons/buildings"))
	var viewport := SubViewport.new()
	viewport.size=Vector2i(192,160)
	viewport.transparent_bg=true
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var env:=WorldEnvironment.new()
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color(0,0,0,0)
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("aac8dc")
	environment.ambient_light_energy=.7
	env.environment=environment;viewport.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=1.5;viewport.add_child(light)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=8.5;camera.position=Vector3(8,7,10);viewport.add_child(camera);camera.look_at(Vector3(0,1.7,0));camera.current=true
	var units:=["fighter","battle_tank","siege_tank","artillery","rocket_launcher","mech_warrior","sniper_unit","shield_drone","repair_drone","assault_soldier","elite_commander"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/icons/units"))
	for name in names+units:
		var folder:="units" if name in units else "buildings"
		camera.size=5.4 if folder=="units" else 8.5
		camera.look_at(Vector3(0,1.0 if folder=="units" else 1.7,0))
		var model:Node3D=load("res://assets/models/"+name+".glb").instantiate()
		viewport.add_child(model)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img:=viewport.get_texture().get_image()
		assert(img.save_png("res://assets/icons/"+folder+"/"+name+".png")==OK)
		model.queue_free()
		await process_frame
	print("GALAXY_BUILDING_ICONS_RENDERED")
	quit()
