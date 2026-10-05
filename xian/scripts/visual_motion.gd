extends Node3D
# Local visual-only loops survive static batching and run in home, raids and practice.
var kind=""
var elapsed=0.0
func _process(delta: float):
 elapsed+=minf(delta,0.1)
 animate(elapsed)
func animate(time: float):
 if kind in ["smoke","embers","black_smoke"]:
  var i=0
  for puff in get_children():
   var phase=fposmod(time*0.34+float(i)/maxi(1,get_child_count()),1.0)
   puff.position=Vector3(sin(phase*5+i)*0.12,phase*(1.3 if kind=="smoke" else 1.8),cos(phase*4+i)*0.08)
   puff.scale=Vector3.ONE*(0.13+phase*(0.28 if kind=="smoke" else 0.6))
   puff.material_override.albedo_color.a=sin(phase*PI)*(0.6 if kind=="black_smoke" else 0.28)
   i+=1
 elif kind=="slinger":
  position.z=-0.08*maxf(0,sin(time*3+get_parent().position.x))
 elif kind=="fire":
  for i in range(get_child_count()):get_child(i).scale.y=0.65+abs(sin(time*5+i))*0.5
 elif kind=="pump":
  var angle=sin(time*2.8)*0.25
  $Handle.rotation.z=angle
  for name in ["ArmLeft","ArmRight"]:
   var arm=get_node(name);var z=-0.16 if name=="ArmLeft" else 0.16
   var start=Vector3(0.83,1.02,z)
   var end=Vector3(-0.48+cos(angle)*0.96,1.39+sin(angle)*0.96,z)
   arm.position=(start+end)*0.5
   arm.scale.y=start.distance_to(end)/Vector3(0.35,0.37,0).length()
   arm.quaternion=Quaternion(Vector3.UP,(end-start).normalized())
  $Stream.scale.x=0.65+0.35*abs(cos(time*2.8));$Stream.scale.z=$Stream.scale.x
 elif kind=="saw":
  $Saw.position.x=sin(time*6)*0.14
