extends Sprite3D
var state="idle"
var elapsed=0.0
var flying=false
var attack_time=0.0
var attack_duration=0.8
var previous=Vector3.ZERO
func _ready():previous=get_parent().global_position
func _process(delta: float):
	elapsed+=delta
	var p=get_parent().global_position
	var movement=p-previous;previous=p
	if movement.length_squared()>0.000001:
		# Screen horizontal at the fixed (40,48,40) camera is world X minus Z.
		var horizontal=movement.x-movement.z
		if abs(horizontal)>0.0001:flip_h=horizontal<0
	if attack_time>0:
		attack_time=maxf(0,attack_time-delta)
		position.y=sin((1.0-attack_time/attack_duration)*PI)*0.09
	elif flying:
		frame=int(elapsed*7.0)%8;position.y=0.12+sin(elapsed*2.0)*0.035
	elif state=="walk":
		frame=int(elapsed*9.0)%8;position.y=0
	else:
		frame=0;position.y=0
func set_pose(value: String, duration: float):
	state=value
	if value=="attack":attack_duration=maxf(0.1,duration);attack_time=attack_duration
