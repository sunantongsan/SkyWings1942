extends RefCounted
# One geometry coordinate system for buildings, ground and their contact shadows.
const KINDS=["hall","barracks","kitchen","granary","spring","crystal","servant","tank","tower","ward"]
var art
func build(kind: String, level: int, fill: float) -> Node3D:
	var lv=clampi(level,1,10)
	var root=Node3D.new();root.set_meta("realistic_art",true);root.set_meta("architecture",true);root.set_meta("visual_level",lv);root.set_meta("storage_fill",fill)
	var stone="a5a894" if lv<5 else "c0beaa"
	art.box(root,Vector3(0,0.035,0),Vector3(2.82,0.07,2.82),stone)
	for i in range(2):art.box(root,Vector3(0,0.05+i*0.05,1.29-i*0.13),Vector3(0.8,0.10,0.25),"cec6ad")
	if kind=="hall":
		var hall=art.donor("hall.gltf",2.7,"",3.5);root.add_child(hall);hall.position.y=0.07
	elif kind in ["barracks","servant","kitchen","granary","crystal","spring"]:
		var house=art.donor("pavilion.gltf",2.35,"",1.95);root.add_child(house);house.position=Vector3(0,0.08,-0.12)
		# Closed rear wall, timber doors and a usable sheltered work area.
		art.box(root,Vector3(0,0.66,-0.76),Vector3(1.65,1.1,0.09),"d1c6a8")
		art.box(root,Vector3(-0.56,0.53,0.16),Vector3(0.5,0.9,0.08),"79583b")
		if kind=="barracks":
			for x in [-0.83,0.83]:
				art.box(root,Vector3(x,0.51,0.72),Vector3(0.07,0.95,0.07),"70563d")
				for j in range(3):art.box(root,Vector3(x+(j-1)*0.16,0.72,0.72),Vector3(0.04,0.8,0.045),"9daeb1")
		elif kind in ["granary","crystal"]:
			for j in range(3):
				var at=Vector3(-0.55+j*0.55,0.29,0.69)
				art.cone(root,at,0.23,0.2,0.42,"b19b6e" if kind=="granary" else "607f78",12)
				art.cone(root,at+Vector3(0,0.23,0),0.19,0.19,0.04,"d9c283" if kind=="granary" else "b5c2a4",12)
		elif kind in ["kitchen","spring"]:
			art.box(root,Vector3(0.55,0.27,0.52),Vector3(0.6,0.42,0.62),"73766c")
			art.cone(root,Vector3(0.55,0.62,0.52),0.28,0.33,0.32,"535c59",16)
			art.cone(root,Vector3(0.55,0.8,0.52),0.34,0.08,0.12,"81847a",16)
			art.box(root,Vector3(0.72,1.15,-0.65),Vector3(0.3,2.05,0.3),"77766c")
		else:
			art.box(root,Vector3(0.3,0.45,0.72),Vector3(0.95,0.12,0.46),"896945")
			for x in [-0.05,0.65]:art.box(root,Vector3(x,0.24,0.72),Vector3(0.08,0.45,0.32),"664e38")
	elif kind=="tank":
		art.cone(root,Vector3(0,0.65,0),1.08,1.08,1.2,stone,20)
		art.cone(root,Vector3(0,1.27,0),1.15,1.15,0.13,"c2bca6",20)
		art.cone(root,Vector3(0,1.34,0),0.98,0.98,0.02,"568f95",20)
		for x in [-0.62,0.62]:art.box(root,Vector3(x,1.36,0),Vector3(0.06,0.05,1.2),"acb9af")
	elif kind=="ward":
		art.box(root,Vector3(0,0.29,0),Vector3(1.7,0.5,1.7),stone)
		var pavilion=art.donor("pavilion.gltf",2.3,"",1.9);root.add_child(pavilion);pavilion.position.y=0.55
		art.cone(root,Vector3(0,0.94,0),0.25,0.25,0.68,"648d91",12)
		art.orb(root,Vector3(0,1.4,0),Vector3.ONE*0.38,"a6d3d4")
	elif kind=="tower":
		art.box(root,Vector3(0,0.96,0),Vector3(1.4,1.85,1.4),stone)
		art.box(root,Vector3(0,1.95,0),Vector3(1.9,0.18,1.9),"7a8177")
		for x in [-0.85,0.85]:
			for z in [-0.85,0.85]:art.box(root,Vector3(x,2.18,z),Vector3(0.22,0.45,0.22),stone)
		art.box(root,Vector3(0,2.12,0),Vector3(1.5,0.10,0.18),"70533b")
		art.box(root,Vector3(0,2.12,0.12),Vector3(0.10,0.10,1.6),"9da7a4")
	# Visible level detail grows within the existing plot rather than stacking floors.
	for j in range(lv):
		art.box(root,Vector3(-1.08+j*0.24,0.14,-1.24),Vector3(0.18,0.14,0.1),"b79d60" if lv>=5 else "777f70")
	if lv>=4:
		for x in [-1.18,1.18]:art.lantern(root,Vector3(x,0,0.98),0.36)
	art.batch_static(root)
	if kind in ["tank","granary","crystal"]:
		var amount=Label3D.new();amount.name="StorageAmount";amount.text=str(roundi(fill*100))+"%";amount.position=Vector3(0,0.25,1.33);amount.font_size=28;amount.pixel_size=0.008;amount.outline_size=6;amount.billboard=BaseMaterial3D.BILLBOARD_ENABLED;root.add_child(amount)
	return root
