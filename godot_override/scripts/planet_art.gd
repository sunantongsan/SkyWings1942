extends RefCounted
## Authored GLB instances, restrained environment dressing and mobile effects.
const ROOT := "res://assets/models/"
const NAMES := ["galactic_core","fusion_reactor","metal_extractor","oil_processor","crystal_mine","resource_vault","star_hangar","research_lab","laser_tower","shield_generator","gold_refinery","missile_bastion","vehicle_factory","barracks","godot_citadel","astral_well","summoning_sanctum","runebolt_spire","vehicle_camp","air_camp","infantry_camp"]
var obstacles:Dictionary={}
var scene_cache: Dictionary = {}
var materials: Dictionary = {}
var box_meshes: Dictionary = {}

func model(name: String) -> Node3D:
	if not scene_cache.has(name):
		scene_cache[name] = load(ROOT + name + ".glb")
	return (scene_cache[name] as PackedScene).instantiate() as Node3D

func building(kind: int, enemy: bool) -> Node3D:
	var root := model(NAMES[kind])
	if enemy:
		for mesh in root.find_children("*", "MeshInstance3D", true, false):
			for i in mesh.mesh.get_surface_count():
				var original: Material = mesh.get_active_material(i)
				if original is StandardMaterial3D and original.emission_enabled:
					var red := original.duplicate() as StandardMaterial3D
					red.albedo_color = Color("ff6952")
					red.emission = Color("ff452c")
					mesh.set_surface_override_material(i, red)
	if kind in [9,14]:
		var shield := MeshInstance3D.new()
		shield.name = "ShieldField"
		var sphere := SphereMesh.new()
		sphere.radius = 3.25
		sphere.height = 6.5
		sphere.radial_segments = 32
		sphere.rings = 16
		shield.mesh = sphere
		shield.position.y = 0.5
		shield.scale.y = 0.82
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/shield.gdshader")
		if enemy: mat.set_shader_parameter("shield_color",Color("ff7a5f"))
		shield.material_override = mat
		shield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(shield)
	if kind in [0,1,4,9,14,15,16,17]:
		var halo:=MeshInstance3D.new()
		var plane:=QuadMesh.new();plane.size=Vector2(2.3,2.3);halo.mesh=plane
		halo.position=Vector3(0,4.3 if kind==0 else 2.2,0)
		var glow:=ShaderMaterial.new();glow.shader=load("res://shaders/energy_halo.gdshader")
		if kind==4 or kind>=14:glow.set_shader_parameter("tint",Color("c58bff"))
		if enemy:glow.set_shader_parameter("tint",Color("ff805c"))
		halo.material_override=glow;halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(halo)
	return root

func mat(color: Color, emission := false) -> StandardMaterial3D:
	var key := str(color) + str(emission)
	if materials.has(key): return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	if emission:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = color
	materials[key] = material
	return material

func terrain() -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var plane:=PlaneMesh.new();plane.size=Vector2(192,192);mesh.mesh=plane
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/terrain.gdshader")
	mesh.material_override = material
	return mesh

func elevation(x: float,z: float) -> float:
	return -0.02

func cuboid(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emit := false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var key:=str(size)
	if not box_meshes.has(key):
		var box:=BoxMesh.new();box.size=size;box_meshes[key]=box
	n.mesh=box_meshes[key]
	n.position = pos
	n.material_override = mat(color,emit)
	parent.add_child(n)
	return n

func roads(parent: Node3D) -> void:
	# Paved plazas and connected service roads, with inset lanes.
	for x in [-8.0,0.0,8.0]:
		cuboid(parent,Vector3(1.6,0.06,31),Vector3(x,0.035,0),Color("354b4b"))
		for z in range(-14,15,3): cuboid(parent,Vector3(0.07,0.02,0.85),Vector3(x,0.077,z),Color("90a392"))
	for z in [-8.0,0.0,8.0]:
		cuboid(parent,Vector3(35,0.05,1.5),Vector3(0,0.045,z),Color("354b4b"))
	for x in [-18.5,18.5]:
		for z in range(-16,17,4):
			cuboid(parent,Vector3(0.35,0.72,0.4),Vector3(x,0.36,z),Color("526774"))
			cuboid(parent,Vector3(0.28,0.08,0.33),Vector3(x,0.77,z),Color("66d5cf"),true)

	_batch_decor(parent)

func decor(parent: Node3D, theme: int, cleared:Array=[]) -> void:
	obstacles.clear()
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1942+theme*51
	for i in 90:
		var a := rng.randf()*TAU
		var radius := rng.randf_range(28,47)
		var x := cos(a)*radius
		var z := sin(a)*radius*0.8
		var rock := model("rock_%d" % (i%3))
		rock.position = Vector3(x,elevation(x,z)-0.03,z)
		rock.scale = Vector3.ONE*rng.randf_range(0.7,2.4)
		rock.rotation.y = rng.randf()*TAU
		rock.set_meta("obstacle_id",i*4)
		parent.add_child(rock)
		if theme in [0,5,7] and i%2 == 0:
			for j in 3:
				var plant := model("alien_tree")
				var px := x+rng.randf_range(-2.3,2.3)
				var pz := z+rng.randf_range(-2.3,2.3)
				plant.position = Vector3(px,elevation(px,pz),pz)
				plant.scale = Vector3.ONE*rng.randf_range(0.9,1.9)
				plant.set_meta("obstacle_id",i*4+j+1)
				parent.add_child(plant)

	for child in parent.get_children():
		if child.has_meta("obstacle_id"):
			var id:int=child.get_meta("obstacle_id")
			if id in cleared:parent.remove_child(child);child.queue_free()
			else:obstacles[id]=child.position
	_batch_decor(parent)

func _batch_decor(parent:Node3D)->void:
	var batches:Dictionary={}
	for instance in parent.get_children():
		var pieces:Array=[instance] if instance is MeshInstance3D else instance.find_children("*","MeshInstance3D",true,false)
		for part in pieces:
			var key:=str(part.mesh.get_rid())+str(part.material_override)
			if not batches.has(key):batches[key]={"mesh":part.mesh,"material":part.material_override,"transforms":[]}
			batches[key].transforms.append(parent.global_transform.affine_inverse()*part.global_transform)
		instance.queue_free()
	for batch in batches.values():
		var multimesh:=MultiMesh.new()
		multimesh.transform_format=MultiMesh.TRANSFORM_3D
		multimesh.mesh=batch.mesh
		multimesh.instance_count=batch.transforms.size()
		for i in batch.transforms.size():multimesh.set_instance_transform(i,batch.transforms[i])
		var node:=MultiMeshInstance3D.new()
		node.multimesh=multimesh
		node.material_override=batch.material
		parent.add_child(node)

func particles(parent: Node3D, position: Vector3, color: Color, smoke := false, burst := false) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = position
	p.amount = 12 if smoke else 20
	p.lifetime = 2.8 if smoke else 0.75
	p.one_shot = burst
	p.explosiveness = 1.0 if burst else 0.0
	p.direction = Vector3.UP
	p.spread = 20 if smoke else 140
	p.gravity = Vector3(0,0.5,0) if smoke else Vector3(0,-3,0)
	p.initial_velocity_min = 0.35 if smoke else 2
	p.initial_velocity_max = 0.7 if smoke else 5
	p.scale_amount_min = 0.09
	p.scale_amount_max = 0.22 if smoke else 0.12
	var sphere := SphereMesh.new()
	sphere.radial_segments = 6
	sphere.rings = 3
	sphere.radius = 1
	sphere.height = 2
	p.mesh = sphere
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	p.material_override = material
	var ramp := Gradient.new()
	ramp.set_color(0,Color(color,0.5 if smoke else 1.0))
	ramp.set_color(1,Color(color,0.0))
	p.color_ramp = ramp
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0,0.35 if smoke else 1))
	scale_curve.add_point(Vector2(1,1.7 if smoke else 0))
	p.scale_amount_curve = scale_curve
	parent.add_child(p)
	p.emitting = true
	if burst: p.finished.connect(p.queue_free)
	return p
