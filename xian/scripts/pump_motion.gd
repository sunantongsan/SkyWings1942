extends Node3D
var elapsed=0.0
var worker: Sprite3D
var lever: MeshInstance3D
var stream: MeshInstance3D
var drops: Array=[]
var gems: Array=[]
# Per-frame hand locations projected from the generated sheet. Fixed feet/pivot.
const HANDS=[Vector2(-0.235,1.50),Vector2(-0.39,0.98),Vector2(-0.43,0.65),Vector2(-0.38,0.98)]
func _process(delta: float):
	elapsed+=delta;animate(elapsed)
func animate(time: float):
	var f=int(time*4)%4;worker.frame=f
	var hand=HANDS[f];var origin=Vector3(-0.65,1.40,0)
	var tip=Vector3(0.53,0.14,0)+Vector3(0.707,0,-0.707)*hand.x+Vector3(-0.457,0.762,-0.457)*hand.y
	lever.position=(origin+tip)*0.5;lever.mesh.height=origin.distance_to(tip);lever.quaternion=Quaternion(Vector3.UP,(tip-origin).normalized())
	stream.scale.x=0.65+0.35*abs(sin(time*TAU));stream.scale.z=stream.scale.x
	for i in range(drops.size()):
		var t=fposmod(time*1.8+i/6.0,1.0);drops[i].position=Vector3(-0.65+sin(i*2.4)*t*0.17,0.51+sin(t*PI)*0.11,0.62+cos(i*2.4)*t*0.17)
	for i in range(gems.size()):gems[i].material_override.emission_energy_multiplier=0.3+maxf(0,sin(time*3+i*1.3))*1.4
