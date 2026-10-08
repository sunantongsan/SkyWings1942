extends RefCounted
const NEW_KINDS=["cannon","mortar","air_defense","flame","storm","lightning"]
const NAMES={"cannon":"ป้อมปืนใหญ่","tower":"หอหน้าไม้","mortar":"ป้อมครกหิน","air_defense":"หน้าไม้พิฆาตฟ้า","ward":"หอค่ายกล","flame":"หอเพลิง","storm":"หอสายฟ้า","lightning":"ป้อมสายฟ้า","trap_storm":"ค่ายกลพายุ","trap_sword":"ค่ายกลกระบี่","trap_fire":"ค่ายกลไฟ","bomb":"กับระเบิด","air_mine":"กับดักนภา"}
const STATS={
 "lightning":{"range":5.2,"min_range":0.0,"cooldown":2.0,"damage":90.0,"target":"both","splash":0.0},
 "cannon":{"range":4.8,"min_range":0.0,"cooldown":1.1,"damage":28.0,"target":"ground","splash":0.0},
 "tower":{"range":5.2,"min_range":0.0,"cooldown":1.0,"damage":20.0,"target":"both","splash":0.0},
 "mortar":{"range":6.5,"min_range":2.0,"cooldown":3.0,"damage":58.0,"target":"ground","splash":1.4},
 "air_defense":{"range":6.0,"min_range":0.0,"cooldown":1.5,"damage":80.0,"target":"air","splash":0.0},
 "ward":{"range":4.2,"min_range":0.0,"cooldown":1.8,"damage":30.0,"target":"both","splash":4.2},
 "flame":{"range":4.3,"min_range":0.0,"cooldown":0.6,"damage":18.0,"target":"both","splash":0.0},
 "storm":{"range":4.7,"min_range":0.0,"cooldown":1.7,"damage":50.0,"target":"both","splash":0.0}}
static func eligible(kind: String,air: bool) -> bool:
	var target=STATS[kind].target
	return target=="both" or (target=="air" and air) or (target=="ground" and not air)
# Real mesh mechanisms with the same material atlas, grid and lighting as the village.
static func model(art,kind: String,level: int) -> Node3D:
	var s=preload("res://scripts/sect_art.gd").new();s.art=art
	var root=Node3D.new();root.set_meta("campaign_defense",kind)
	s.block(root,Vector3(0,0.16,0),Vector3(2.7,0.32,2.7),6)
	s.block(root,Vector3(0,0.36,0),Vector3(2.35,0.12,2.35),4)
	for x in [-1,1]:
		for z in [-1,1]:s.block(root,Vector3(x*1.08,0.51,z*1.08),Vector3(0.22,0.28,0.22),8)
	if kind=="cannon" or kind=="mortar":
		s.block(root,Vector3(0,0.72,0),Vector3(1.5,0.55,1.25),3)
		for x in [-0.77,0.77]:s.rod(root,Vector3(x,0.55,-0.5),Vector3(x,0.55,0.5),0.24,8)
		var a=Vector3(0,1.0,0.45);var b=Vector3(0,1.45,-1.1) if kind=="cannon" else Vector3(0,2.0,-0.35)
		s.rod(root,a,b,0.34 if kind=="cannon" else 0.48,8)
		var direction=(b-a).normalized();s.rod(root,b,b+direction*0.09,0.40 if kind=="cannon" else 0.54,9)
		var muzzle=art.cone(root,b+direction*0.10,0.29 if kind=="cannon" else 0.41,0.29 if kind=="cannon" else 0.41,0.015,"151d22",24);muzzle.quaternion=Quaternion(Vector3.UP,direction)
	elif kind=="air_defense":
		s.block(root,Vector3(0,1.25,0),Vector3(0.9,1.7,0.9),6)
		for x in [-0.55,0,0.55]:
			s.rod(root,Vector3(x,1.8,0.6),Vector3(x,2.75,-0.8),0.08,8)
			s.rod(root,Vector3(-0.95,2.3,0.1),Vector3(0.95,2.3,0.1),0.075,3)
			art.cone(root,Vector3(x,2.8,-0.85),0.15,0,0.35,"c6af72",4).rotation.x=-0.6
	else:
		s.block(root,Vector3(0,1.55,0),Vector3(1.12,2.35,1.12),6)
		for y in [0.7,1.4,2.1,2.75]:s.block(root,Vector3(0,y,0),Vector3(1.35,0.12,1.35),9)
		for x in [-0.65,0.65]:s.rod(root,Vector3(x,0.4,0),Vector3(x,3.1,0),0.085,8)
		art.cone(root,Vector3(0,2.97,0),0.65,0.75,0.3,"9b8155",16)
		var color="ef8a3d" if kind=="flame" else "89d6e7"
		art.orb(root,Vector3(0,3.36,0),Vector3(0.45,0.65,0.45),color)
		if kind=="storm":
			for y in [1.0,1.3,1.6,1.9]:art.cone(root,Vector3(0,y,0),0.78,0.78,0.07,"a1adb4",16)
	for i in range(mini(3,level)):
		s.block(root,Vector3(-0.45+i*0.45,0.22,1.37),Vector3(0.18,0.16,0.035),9)
	art.batch_static(root);return root
