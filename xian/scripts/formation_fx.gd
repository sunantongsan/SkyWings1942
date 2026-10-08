extends Node3D
const Models=preload("res://scripts/formation_art.gd")
var kind=""
var age=0.0
var duration=4.0
var pieces: Array=[]
var tint: StandardMaterial3D
func setup(art,weapon: String,start: Vector3,target: Vector3):
	kind=weapon;position=start;duration=0.65 if kind in ["lightning","storm"] else 4.0
	var color=Models.COLORS.get(kind,"93bfff")
	tint=art.clear_material(color,0.8).duplicate();tint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;tint.emission_enabled=true;tint.emission=Color(color);tint.emission_energy_multiplier=1.4
	if kind in ["lightning","storm"]:
		var source=Vector3(0,3.0,0);var end=target-start+Vector3(0,0.9,0);var previous=source
		for i in range(1,10):
			var point=source.lerp(end,float(i)/9)
			if i<9:point+=Vector3(sin(i*8.7)*0.34,cos(i*3.9)*0.28,sin(i*4.3)*0.34)
			art.beam(self,previous,point,0.12,color);previous=point
		art.orb(self,end,Vector3.ONE*0.25,color)
	elif kind=="trap_storm":
		Models.ring(art,self,9.2,0.13,0.09,color)
		for i in range(7):
			var band=Models.ring(art,self,0.6+i*0.30,0.25+i*0.68,0.12,color);band.rotation.z=0.12*sin(i*2);pieces.append(band)
		for i in range(9):pieces.append(art.orb(self,Vector3.ZERO,Vector3(0.45,0.18,0.22),color))
	elif kind=="trap_sword":
		Models.ring(art,self,7.4,0.15,0.1,color)
		for i in range(12):
			var blade=Models.sword(art,self,color);blade.rotation.z=PI;pieces.append(blade)
	elif kind=="trap_fire":
		Models.ring(art,self,7.1,0.15,0.12,color)
		for i in range(16):pieces.append(art.cone(self,Vector3.ZERO,0.40,0,1.8,color,6))
	for mesh in find_children("*","MeshInstance3D",true,false):mesh.material_override=tint;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _process(delta: float):
	age+=delta
	if age>=duration:queue_free();return
	tint.albedo_color.a=minf(0.8,(duration-age)*2.0)
	if kind=="trap_storm":
		rotation.y=age*3.8
		for i in range(pieces.size()):
			if i<7:pieces[i].position=Vector3(sin(age*5+i)*0.18,0,cos(age*4+i)*0.18)
			else:
				var phase=fposmod(age*0.6+i*0.13,1.0);var a=phase*TAU*2+i
				pieces[i].position=Vector3(cos(a)*(1+phase*2.0),phase*5,sin(a)*(1+phase*2.0))
	elif kind=="trap_sword":
		for i in range(pieces.size()):
			var a=i*TAU/pieces.size()+age*1.2;var phase=fposmod(age*1.7+i*0.15,1.0)
			pieces[i].position=Vector3(cos(a)*5.5,0.5+(1-phase)*4.0,sin(a)*5.5)
	elif kind=="trap_fire":
		for i in range(pieces.size()):
			var a=i*2.39996;var radius=1+float(i%5)*1.4
			pieces[i].position=Vector3(cos(a)*radius,0.65,sin(a)*radius);pieces[i].scale.y=0.65+absf(sin(age*8+i))*0.8
