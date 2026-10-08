extends RefCounted
const KINDS=["trap_storm","trap_sword","trap_fire","lightning"]
const COLORS={"trap_storm":"83dbc9","trap_sword":"b3d9ff","trap_fire":"ff803c","lightning":"93bfff"}
static func ring(art,parent: Node3D,radius: float,y: float,width: float,color: String):
	var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(32):
		var a=i*TAU/32;var b=(i+1)*TAU/32
		var p=Vector3(cos(a)*radius,y,sin(a)*radius);var q=Vector3(cos(b)*radius,y,sin(b)*radius)
		var p2=Vector3(cos(a)*(radius+width),y,sin(a)*(radius+width));var q2=Vector3(cos(b)*(radius+width),y,sin(b)*(radius+width))
		for v in [p,p2,q2,p,q2,q]:mesh.surface_add_vertex(v)
	mesh.surface_end()
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=art.material(color);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node);return node
static func sword(art,parent: Node3D,color: String) -> Node3D:
	var node=Node3D.new();parent.add_child(node)
	art.box(node,Vector3(0,0.55,0),Vector3(0.13,1.1,0.06),color)
	art.cone(node,Vector3(0,1.2,0),0.12,0,0.3,color,4)
	art.box(node,Vector3(0,0.04,0),Vector3(0.52,0.09,0.13),"c4a25d")
	art.box(node,Vector3(0,-0.2,0),Vector3(0.1,0.4,0.1),"544943")
	return node
static func model(art,kind: String,level: int) -> Node3D:
	var root=Node3D.new();root.set_meta("formation",kind)
	var color=COLORS[kind]
	art.cone(root,Vector3(0,0.12,0),1.32,1.25,0.24,"565e65",8)
	ring(art,root,0.95,0.26,0.10,"bfa56b");ring(art,root,0.72,0.28,0.055,color)
	for i in range(8):
		var a=i*TAU/8
		var rune=art.box(root,Vector3(cos(a)*1.1,0.3,sin(a)*1.1),Vector3(0.08,0.045,0.22),color);rune.rotation.y=-a
	if kind=="lightning":
		art.box(root,Vector3(0,1.2,0),Vector3(0.72,1.9,0.72),"586b78")
		for i in range(5):art.cone(root,Vector3(0,0.75+i*0.32,0),0.78,0.78,0.09,"adb8c5",16)
		art.cone(root,Vector3(0,2.45,0),0.5,0.32,0.5,"c4a25d",12)
		art.orb(root,Vector3(0,2.85,0),Vector3.ONE*0.52,color)
		for sign_value in [-1,1]:
			art.beam(root,Vector3(sign_value*0.85,0.3,0),Vector3(sign_value*0.85,2.8,0),0.08,"c4a25d")
			art.cone(root,Vector3(sign_value*0.85,2.98,0),0.16,0,0.4,color,8)
	elif kind=="trap_sword":
		for i in range(3):
			var blade=sword(art,root,color);blade.position=Vector3((i-1)*0.48,0.5,0);blade.rotation.z=(i-1)*-0.22
	elif kind=="trap_fire":
		art.cone(root,Vector3(0,0.55,0),0.4,0.7,0.55,"906a4a",8)
		for i in range(3):art.cone(root,Vector3((i-1)*0.25,1.02,0),0.2,0,0.55,color,6)
	else:
		for i in range(3):
			var band=ring(art,root,0.2+i*0.16,0.45+i*0.3,0.07,color);band.rotation.z=0.18*i
	for i in range(mini(5,level)):
		art.box(root,Vector3(-0.6+i*0.28,0.16,1.24),Vector3(0.12,0.1,0.08),"e5c982")
	art.batch_static(root);return root
