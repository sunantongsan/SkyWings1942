extends Node3D
# One shared walkability grid; adjacent-cell strolls cannot cross a wall/building.
var art
var grid: AStarGrid2D
var cell=Vector2i.ZERO
var previous_cell=Vector2i(-1,-1)
var destination=Vector3.ZERO
var activity="stroll"
var unit_kind=0
var elapsed=0.0
var pause=0.0
var serial=0
var defending=false
var defense_target=Vector3.ZERO
func world_cell(c: Vector2i) -> Vector3:return Vector3((c.x-7.5)*3,0,(c.y-7.5)*3)
func _process(delta: float):
	elapsed+=delta
	if defending:
		var target=defense_target
		position=position.move_toward(target,delta*5.2)
		if position.distance_to(target)>0.2:art.pose(self,"walk")
		elif pause<=0:art.pose(self,"attack",0.75);pause=0.95
		pause-=delta;return
	if activity=="sleep":
		art.pose(self,"sleep");return
	if activity=="spar":
		if pause<=0:art.pose(self,"attack",0.65);pause=1.1+serial%2*0.2
		pause-=delta;return
	if activity=="camp":art.pose(self,"idle");return
	if position.distance_to(destination)>0.03:
		position=position.move_toward(destination,delta*1.2);art.pose(self,"walk");return
	pause-=delta;art.pose(self,"idle")
	if pause>0:return
	var choices: Array=[]
	for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		var c=cell+d
		if grid.is_in_boundsv(c) and not grid.is_point_solid(c) and c!=previous_cell:choices.append(c)
	if choices.is_empty():
		if grid.is_in_boundsv(previous_cell) and not grid.is_point_solid(previous_cell):choices.append(previous_cell)
	if choices.is_empty():pause=2;return
	previous_cell=cell;cell=choices[(serial+int(elapsed))%choices.size()];destination=world_cell(cell);pause=0.7
func alarm(target: Vector3):
	defending=true;defense_target=target;pause=0;art.pose(self,"walk")
