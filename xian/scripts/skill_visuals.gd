extends RefCounted
var art
func build(parent: Node3D,start: Vector3,target: Vector3,kind: int):
 if art.fx_count>=24:return
 art.fx_count+=1
 var root=Node3D.new();root.name="Skill_"+str(kind);root.set_script(preload("res://scripts/skill_effect.gd"));root.art=art;root.kind=kind;root.start=start+Vector3(0,1,0);root.target=target+Vector3(0,0.65,0);parent.add_child(root)
 root.tree_exited.connect(func():art.fx_count=maxi(0,art.fx_count-1))
 if kind==2:root.start=start+Vector3(0,1.8,0)+(target-start).normalized()*0.8
 var a=root.start;var b=root.target
 match kind:
  2:
   root.duration=0.8
   for i in range(8):
    var p=art.realistic.puff(root,Color("ff8a24") if i%3 else Color("ffe4a1"));p.material_override=fire_material();root.particles.append(p)
  4,8:
   var color="7bd9f5" if kind==4 else "ff7623"
   root.core=art.orb(root,a,Vector3.ONE*0.34,color)
   var glow=art.realistic.puff(root.core,Color(0.35,0.8,1,0.65) if kind==4 else Color(1,0.4,0.07,0.75));glow.scale=Vector3.ONE*1.8
   for i in range(5):root.particles.append(art.realistic.puff(root,Color(0.3,0.8,1,0.35) if kind==4 else Color(1,0.4,0.05,0.5)))
  1,5:
   var carrier=Node3D.new();root.add_child(carrier);root.core=carrier;carrier.position=a
   var direction=(b-a).normalized();carrier.quaternion=Quaternion(Vector3.FORWARD,direction)
   if kind==1:art.box(carrier,Vector3.ZERO,Vector3(0.07,0.08,1.0),"b8f2ff")
   else:
    var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(20):
     var t=-1.3+i*2.6/20;var u=-1.3+(i+1)*2.6/20
     for v in [Vector3(cos(t)*0.9,sin(t)*0.9,0),Vector3(cos(t)*1.08,sin(t)*1.08,0),Vector3(cos(u)*1.08,sin(u)*1.08,0),Vector3(cos(t)*0.9,sin(t)*0.9,0),Vector3(cos(u)*1.08,sin(u)*1.08,0),Vector3(cos(u)*0.9,sin(u)*0.9,0)]:mesh.surface_add_vertex(v)
    mesh.surface_end();var blade=MeshInstance3D.new();blade.mesh=mesh;blade.material_override=art.clear_material("ffb75c",0.95);blade.material_override.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;carrier.add_child(blade)
  7:
   root.duration=0.75;root.wave=art.ring(root,b-Vector3(0,0.55,0),1,0.035,"bca281");root.wave.material_override=art.clear_material("cebda0",0.7)
   for i in range(9):root.particles.append(art.orb(root,b,Vector3.ONE*0.16,"8c8274"))
   for i in range(6):
    var angle=i*TAU/6;art.beam(root,b-Vector3(0,0.6,0),b+Vector3(cos(angle)*1.3,-0.6,sin(angle)*1.3),0.025,"514b42")
  9:
   root.duration=0.65
   lightning(root,b+Vector3(0,6,0),b,0.06)
   for i in [-1,1]:lightning(root,b+Vector3(0,2,0),b+Vector3(i*1.5,0,i*0.7),0.025)
  6:
   root.duration=0.45
   for i in range(3):art.beam(root,b+Vector3(-0.45+i*0.15,0.55,0),b+Vector3(0.1+i*0.15,-0.25,0.2),0.025,"ffe4bd")
  3:
   root.duration=0.45
   for i in range(4):
    var coin=art.orb(root,b+Vector3(0,i*0.13,0),Vector3(0.09,0.09,0.03),"ebcd70")
    var tween=coin.create_tween();tween.tween_property(coin,"position",a,0.45)
  _:
   root.duration=0.45;art.impact_fx(parent,b,kind)
func lightning(root: Node3D,a: Vector3,b: Vector3,width: float):
 var previous=a
 for i in range(1,9):
  var p=a.lerp(b,i/8.0)
  if i<8:p+=Vector3(sin(i*7.1)*0.24,0,cos(i*3.7)*0.2)
  art.beam(root,previous,p,width,"cae8ff");previous=p

func fire_material() -> ShaderMaterial:
 var mat=ShaderMaterial.new();mat.shader=preload("res://scripts/fire_plume.gdshader");return mat
