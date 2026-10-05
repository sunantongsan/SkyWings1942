extends Sprite3D
var elapsed=0.0
func _process(delta: float):
	elapsed+=delta
	frame=int(elapsed*9.0)%8
