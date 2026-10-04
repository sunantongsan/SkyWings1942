extends RefCounted
var mats = {}
func material(hex: String) -> StandardMaterial3D:
	if mats.has(hex): return mats[hex]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.95
	mats[hex] = m
	return m
func box(parent: Node3D, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	n.mesh = mesh; n.material_override = material(color); n.position = pos
	parent.add_child(n)
	return n
func cone(parent: Node3D, pos: Vector3, r: float, top: float, height: float, color: String, segments = 8) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.bottom_radius = r; mesh.top_radius = top; mesh.height = height; mesh.radial_segments = segments
	n.mesh = mesh; n.material_override = material(color); n.position = pos
	parent.add_child(n)
	return n
func roof(parent: Node3D, y: float, width: float, color: String):
	var n = cone(parent, Vector3(0,y,0),width,0.12,0.95,color,4)
	n.rotation_degrees.y = 45
	n.scale.z = 0.8
	box(parent,Vector3(0,y+0.48,0),Vector3(width*1.25,0.14,0.15),"d3b579")
	for x in [-1,1]:
		box(parent,Vector3(x*width*0.73,y-0.28,0),Vector3(0.18,0.3,width*1.2),color).rotation_degrees.z = x*20
var scene_cache: Dictionary = {}
var walk_library: AnimationLibrary
var house_meshes: Dictionary = {}
func source_scene(path: String) -> PackedScene:
	if not scene_cache.has(path):scene_cache[path]=load("res://assets/donor/"+path)
	return scene_cache[path]
func mesh_transform(node: Node3D, root: Node3D) -> Transform3D:
	var result=node.transform;var parent=node.get_parent()
	while parent!=root and parent is Node3D:
		result=parent.transform*result;parent=parent.get_parent()
	return result
func model_bounds(root: Node3D) -> AABB:
	var bounds=AABB();var first=true
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		var value=mesh_transform(mesh,root)*mesh.get_aabb()
		if first:bounds=value;first=false
		else:bounds=bounds.merge(value)
	return bounds
func donor(path: String, width: float, part="", height_limit=5.0) -> Node3D:
	var out=Node3D.new();var scene=source_scene(path).instantiate()
	if not part.is_empty():
		var piece=scene.get_node(part).duplicate();scene.free();scene=piece;scene.transform=Transform3D.IDENTITY
	out.add_child(scene)
	if path=="hitherton_buildings.glb" and scene is MeshInstance3D:
		if not house_meshes.has(part):
			var source=scene.mesh;var recolored=ArrayMesh.new();var bounds=source.get_aabb()
			var palette={"House Player":"866f42","House_2":"ba8b46","House_3":"387e94","House_4":"596f9f","shop":"b45b43","Arena":"708468"}
			for surface in range(source.get_surface_count()):
				var arrays=source.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL];var colors=PackedColorArray()
				for i in range(vertices.size()):
					var roof_face=normals[i].y>0.15 and vertices[i].y>bounds.position.y+bounds.size.y*0.35
					colors.append(Color(palette.get(part,"708468")) if roof_face else Color("e7d9bc"))
				arrays[Mesh.ARRAY_COLOR]=colors;recolored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=0.95;recolored.surface_set_material(surface,mat)
			house_meshes[part]=recolored
		scene.mesh=house_meshes[part]
	for collision in scene.find_children("*","CollisionObject3D",true,false):collision.free()
	var bounds=model_bounds(out)
	var size=minf(width/maxf(bounds.size.x,bounds.size.z),height_limit/maxf(bounds.size.y,0.01))
	scene.scale*=size
	scene.position-=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*size
	return out
func courtyard(level: int) -> Node3D:
	var root=Node3D.new();root.set_meta("courtyard",true)
	# Open, ground-level 2x2 courtyard. No roof obscures the training floor.
	box(root,Vector3(0,0.025,0),Vector3(5.85,0.05,5.85),"aba591")
	for x in range(6):
		for z in range(6):
			box(root,Vector3(-2.42+x*0.97,0.065,-2.42+z*0.97),Vector3(0.91,0.03,0.91),"d0cbb7" if (x+z)%2==0 else "c1bea9")
	for z in [-2.72,2.72]:box(root,Vector3(0,0.09,z),Vector3(5.7,0.08,0.12),"b59a53" if level<5 else "e0b94d")
	for x in [-2.72,2.72]:box(root,Vector3(x,0.09,0),Vector3(0.12,0.08,5.7),"b59a53")
	# Wooden practice dummies and a sword rack keep the central arena clear.
	for x in [-1.9,0.0,1.9]:
		cone(root,Vector3(x,0.75,-2.1),0.12,0.12,1.4,"856044",8)
		box(root,Vector3(x,1,-2.1),Vector3(0.9,0.12,0.12),"987452")
		cone(root,Vector3(x,1.6,-2.1),0.19,0.19,0.28,"c6a679",8)
	for x in [-2.2,2.2]:
		cone(root,Vector3(x,1,2.2),0.055,0.055,2,"72573e",6)
		box(root,Vector3(x+0.28,1.7,2.2),Vector3(0.55,0.6,0.04),"467f99" if level<5 else "9c4152")
	for i in range(mini(5,1+level/2)):
		box(root,Vector3(-1.1+i*0.4,0.65,2.3),Vector3(0.06,0.9,0.05),"becdd1")
		box(root,Vector3(-1.1+i*0.4,0.35,2.3),Vector3(0.25,0.05,0.08),"bb9a59")
	box(root,Vector3(0,0.3,2.35),Vector3(2.6,0.12,0.12),"785c43")
	cone(root,Vector3(0,0.092,0),1.05,1.05,0.018,"899c96",32)
	box(root,Vector3(0,0.11,0),Vector3(0.08,0.015,1.5),"ece4c9")
	box(root,Vector3(0,0.11,0.45),Vector3(0.55,0.015,0.08),"ece4c9")
	return root
func building(kind: String, level: int, fill = 0.5) -> Node3D:
	if kind=="training":return courtyard(level)
	var mapping={"hall":["hall.gltf",""],"recruit":["gate.gltf",""],"dorm":["hitherton_buildings.glb","House_4"],"servant":["hitherton_buildings.glb","House Player"],"kitchen":["hitherton_buildings.glb","shop"],"granary":["hitherton_buildings.glb","House_2"],"well":["pavilion.gltf",""],"tank":["hitherton_buildings.glb","House_3"],"spring":["moon_gate.gltf",""],"crystal":["moon_gate.gltf",""],"tower":["gate.gltf",""],"ward":["pavilion.gltf",""],"wall":["wall.gltf",""]}
	var spec=mapping.get(kind,mapping.hall)
	var root=donor(spec[0],2.7,spec[1],4.2)
	root.set_meta("donor_building",true)
	if kind=="tower":root.scale=Vector3(0.8,1.4,0.8)
	if kind=="wall":root.scale.y=0.55
	if kind=="well" or kind=="spring" or kind=="tank":
		cone(root,Vector3(0,0.22,-0.9),0.65,0.65,0.42,"879ea4",12)
		cone(root,Vector3(0,0.45,-0.9),0.56,0.56,0.03,"57cde0" if kind!="spring" else "72e5b2",12)
		if kind=="spring":cone(root,Vector3(0,0.8,-0.9),0.13,0.04,0.7,"b2f7e5",8)
	if kind=="crystal" or kind=="ward":
		for i in range(3):cone(root,Vector3((i-1)*0.35,0.7,-0.9),0.24,0,0.9+fill,"87def5" if kind=="crystal" else "d2a1ef",5)
	if kind=="granary":
		for i in range(3):cone(root,Vector3(-0.6+i*0.5,0.27,-1),0.26,0.2,0.5,"d8c58e",8)
	if kind=="kitchen":cone(root,Vector3(0.8,0.3,-1),0.35,0.4,0.55,"535e64",10)
	return root
func person(kind: int) -> Node3D:
	var root = Node3D.new()
	var color = "896846" if kind==0 else "74b7d2" if kind==1 else "c4ae70"
	if kind==2:
		box(root,Vector3(0,0.55,0),Vector3(0.55,0.5,1.1),"e8ddb4")
		box(root,Vector3(0,0.85,-0.55),Vector3(0.55,0.5,0.45),"e8ddb4")
		for x in [-0.2,0.2]:
			for z in [-0.4,0.4]: box(root,Vector3(x,0.22,z),Vector3(0.15,0.45,0.15),"b19b65")
	else:
		var model=source_scene("godette.glb").instantiate();root.add_child(model)
		var bounds=model_bounds(root);var factor=1.6/maxf(bounds.size.y,0.01)
		model.scale=Vector3.ONE*factor;model.position.y=-bounds.position.y*factor
		var player=model.get_node("AnimationPlayer")
		if walk_library==null:
			var animations=source_scene("animset_walk_jog_run.glb").instantiate()
			walk_library=AnimationLibrary.new()
			for name in ["walk_fwd","idle"]:
				var anim=animations.get_node("AnimationPlayer").get_animation(name).duplicate();anim.loop_mode=Animation.LOOP_LINEAR;walk_library.add_animation(name,anim)
			animations.free()
		player.add_animation_library("movement",walk_library)
		player.play("movement/idle" if kind==1 else "movement/walk_fwd")
		root.set_meta("donor_character",true)
		if kind==1:
			var sword=donor("godette_sword.glb",1.7,"",0.25);root.add_child(sword);sword.rotation_degrees.z=90;sword.position.y=0.04
	return root
