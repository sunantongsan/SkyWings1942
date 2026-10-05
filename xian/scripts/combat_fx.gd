extends Node3D
var art
var age=0.0
var duration=0.42
var sparks: Array=[]
var glow: MeshInstance3D
var arc: MeshInstance3D
func _process(delta: float):
	age+=delta;var t=clampf(age/duration,0,1)
	if is_instance_valid(glow):glow.scale=Vector3.ONE*(0.12+0.6*t);glow.material_override.albedo_color.a=(1-t)*0.55
	if is_instance_valid(arc):arc.material_override.albedo_color.a=(1-t)*0.75;arc.scale=Vector3.ONE*(0.7+t*0.4)
	for i in range(sparks.size()):
		var p=sparks[i];var a=i*2.39996;p.position=Vector3(cos(a)*t*0.8,sin(t*PI)*0.35-t*t*0.25,sin(a)*t*0.8);p.scale=Vector3(0.035,0.07,0.035)*(1-t)
	if age>=duration:queue_free()
