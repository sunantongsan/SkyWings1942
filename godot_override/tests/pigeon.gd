extends SceneTree
func _initialize()->void:call_deferred("run")
func target(kind:int,x:float,level:int=1)->Dictionary:
	var node:=Node3D.new();root.add_child(node);node.position=Vector3(x,0,0)
	return {"node":node,"type":kind,"level":level,"pos":node.position,"hp":100.0}
func run()->void:
	var game:Node3D=load("res://scripts/main.gd").new()
	var bird:=Node3D.new();root.add_child(bird)
	var unit:Dictionary={"node":bird,"type":23}
	var resource:=target(2,1)
	var mortar:=target(22,10)
	var sam:=target(23,20)
	var wall:=target(24,2)
	var candidates:Array=[resource,sam,wall,mortar]
	assert(game._assault_target(unit,candidates)==mortar,"Nearest weapon has priority over nearby resources and walls")
	unit.type=10;assert(game._assault_target(unit,candidates)==resource,"Other units keep nearest-target behavior")
	unit.type=23;mortar.hp=0
	assert(game._assault_target(unit,candidates)==sam,"Retarget after weapon destruction")
	sam.hp=0;assert(game._assault_target(unit,candidates)==resource,"Fallback when no weapons survive")
	wall.level=5;assert(game._assault_target(unit,candidates)==wall,"Armed fire walls are weapons")
	wall.job="build";assert(game._assault_target(unit,candidates)==resource,"Unfinished weapons are not priority")
	resource.level=5;assert(game._assault_target(unit,candidates)==resource,"Armed veteran buildings count")
	resource.hp=0;wall.hp=0;assert(game._assault_target(unit,candidates).is_empty())
	assert(game.PIGEON_HP==60.0 and game._unit_credit_cost(23)==40 and game._unit_oil_cost(23)==5 and game._unit_train_seconds(23)==3)
	game.free()
	print("V30_PIGEON_PRIORITY_FRAGILE_FALLBACK_PASSED")
	quit()
