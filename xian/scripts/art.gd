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
func building(kind: String, level: int, fill = 0.5) -> Node3D:
	var root = Node3D.new()
	box(root,Vector3(0,0.12,0),Vector3(2.6,0.24,2.6),"788681")
	var accent = "397b6d" if level<3 else "366f9c" if level<6 else "976c43"
	match kind:
		"wall":
			box(root,Vector3(0,0.65,0),Vector3(2.8,1.3,0.65),"a7aaa0")
			for x in [-1,0,1]: box(root,Vector3(x,1.4,0),Vector3(0.55,0.35,0.8),"c0beb0")
		"well", "tank", "spring", "crystal":
			cone(root,Vector3(0,0.5,0),1.05,1.05,0.8,"9ba9a0",12)
			cone(root,Vector3(0,0.91,0),0.83,0.83,0.03,"49b7c8",16)
			if kind == "tank":
				for i in range(12):
					var angle=i*TAU/12
					var stave=box(root,Vector3(cos(angle),1.05,sin(angle)),Vector3(0.53,1.5,0.12),"687e7d")
					stave.rotation.y=-angle+PI/2
				cone(root,Vector3(0,0.4+fill*1.5,0),0.93,0.93,0.04,"6de0dc",12)
			elif kind == "crystal" or kind == "spring":
				for i in range(3):
					var q = cone(root,Vector3((i-1)*0.48,1.45,0),0.35,0,1.4+fill,"9ae8ca",5)
					q.rotation_degrees.z = (i-1)*20
			else:
				for x in [-0.8,0.8]: box(root,Vector3(x,1.4,0),Vector3(0.13,1.8,0.13),"644a37")
				roof(root,2.4,1.5,accent)
		"tower", "ward":
			box(root,Vector3(0,1.3,0),Vector3(1.25,2.6,1.25),"9caa9c")
			box(root,Vector3(0,2.6,0),Vector3(2,0.2,2),"c0ae7d")
			roof(root,3.2,1.8,accent)
			if kind == "ward": cone(root,Vector3(0,4,0),0.3,0,0.7,"9ae8ca",5)
			else: box(root,Vector3(0,2.8,-1),Vector3(1.5,0.12,0.2),"644a37")
		_:
			var height = 1.7 if kind == "hall" else 1.2
			box(root,Vector3(0,height/2+0.25,0),Vector3(1.9,height,1.7),"decda4")
			for x in [-0.83,0.83]:
				box(root,Vector3(x,height/2+0.25,-0.9),Vector3(0.15,height,0.15),"8b4e38")
			box(root,Vector3(0,0.7,-0.87),Vector3(0.5,0.9,0.06),"4c3d32")
			roof(root,height+0.65,1.8,accent)
			if kind == "hall": roof(root,height+1.35,1.3,accent)
			if kind == "granary" or kind == "kitchen":
				for i in range(1+int(fill*4)):
					cone(root,Vector3(-0.9+i*0.45,0.42,-1.1),0.24,0.18,0.55,"d7b76e")
			if kind == "training":
				box(root,Vector3(1,1,0),Vector3(0.15,1.8,0.15),"6b4d33")
				box(root,Vector3(1,1.5,0),Vector3(1,0.12,0.12),"6b4d33")
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
		cone(root,Vector3(0,0.6,0),0.25,0.18,0.65,color)
		cone(root,Vector3(0,1.08,0),0.17,0.16,0.3,"e7bd91")
		cone(root,Vector3(0,1.24,0),0.18,0.15,0.1,"343431")
		for x in [-0.12,0.12]: box(root,Vector3(x,0.15,0),Vector3(0.14,0.35,0.15),"49453b")
		box(root,Vector3(0.3,0.63,-0.2),Vector3(0.07,0.07,0.85),"d9e5dd")
		if kind==1: box(root,Vector3(0,-0.07,0),Vector3(0.16,0.08,1.3),"a9dedb")
	return root
