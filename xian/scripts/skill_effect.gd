extends Node3D
var art
var kind=0
var start=Vector3.ZERO
var target=Vector3.ZERO
var age=0.0
var duration=0.85
var particles: Array=[]
var core: Node3D
var wave: Node3D
var hit=false
func _process(delta: float):
 age+=delta
 var travel=clampf(age/0.35,0,1)
 if is_instance_valid(core):
  core.position=start.lerp(target,travel)
  if kind==4:core.rotation.y=age*6
  if kind==8:core.scale=Vector3.ONE*(0.32+sin(age*35)*0.04)
 if kind==2:
  for i in range(particles.size()):
   var p=particles[i];var t=fposmod(age*2.6+i/float(particles.size()),1.0)
   p.position=start.lerp(target,t)+Vector3(sin(i*2.4)*t*0.4,sin(i*4.1)*t*0.35,cos(i*3.2)*t*0.4)
   p.scale=Vector3.ONE*(0.10+t*0.23);p.material_override.set_shader_parameter("opacity",(1-t*0.45)*0.85*(1-clampf((age-0.5)*3,0,1)))
 elif kind==7:
  for i in range(particles.size()):
   var t=clampf(age/duration,0,1);var a=i*TAU/particles.size();particles[i].position=target+Vector3(cos(a)*t*2.0,sin(t*PI)*0.65,sin(a)*t*2.0);particles[i].scale=Vector3.ONE*0.16*(1-t)
 elif kind in [4,8]:
  for i in range(particles.size()):
   var t=clampf(travel-i*0.04,0,1);particles[i].position=start.lerp(target,t);particles[i].scale=Vector3.ONE*(0.22-i*0.02)
 if is_instance_valid(wave):
  wave.scale=Vector3.ONE*(0.2+age*2.6);wave.material_override.albedo_color.a=maxf(0,0.8-age)
 if not hit and age>=0.35:
  hit=true
  if kind!=7:art.impact_fx(get_parent(),target,kind)
  if is_instance_valid(core):core.hide()
 if kind==9:visible=int(age*35)%3!=0
 if age>=duration:queue_free()
