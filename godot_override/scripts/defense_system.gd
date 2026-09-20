extends RefCounted
## Typed defense weapons. Shell/rocket damage is applied on impact, never on launch.
const WALL_NAMES:=["Bamboo", "Earth", "Concrete", "Steel", "Fire"]
const WALL_FILES:=["wall_bamboo","wall_earth","wall_concrete","wall_steel","wall_fire"]
var host:Node3D
var projectiles:Array[Dictionary]=[]
func _init(game:Node3D)->void:host=game
func airborne(kind:int)->bool:return host._is_air_unit(kind) or kind in [16,17]
func accepts(tower:Dictionary,unit:Dictionary)->bool:
	var air:=airborne(int(unit.get("type",0)))
	if tower.type==22:return not air
	if tower.type==23:return air
	return true
func weapon_range(tower:Dictionary)->float:
	return [17.0,22.0,25.0,7.5][int(tower.type)-21]+minf(3.0,(tower.level-1)*.25)
func damage(tower:Dictionary)->float:
	return [7.0+tower.level*1.5,40.0+tower.level*12.0,16.0+tower.level*4.0,5.0+tower.level][int(tower.type)-21]
func description(kind:int,level:int=1)->String:
	match kind:
		21:return "Rapid machine guns\nTargets: ground + air"
		22:return "Arcing cannon shells\nGround only • area damage"
		23:return "3 homing missiles per burst\nAir only • ignores ground"
		24:return "%s wall • blocks ground\n%s"%[WALL_NAMES[clampi(level-1,0,4)],"Close-range machine gun" if level>=5 else "Upgrade to change material"]
	return ""
func fire(tower:Dictionary,attackers:Array,delta:float)->void:
	tower["fire_wait"]=float(tower.get("fire_wait",0))-delta
	var target:Dictionary={};var distance:=weapon_range(tower)
	for unit in attackers:
		if unit.get("hp",0)<=0 or not is_instance_valid(unit.node) or not accepts(tower,unit):continue
		var d:float=tower.pos.distance_to(unit.node.global_position)
		if d<=distance:distance=d;target=unit
	if target.is_empty():return
	var turret:Node3D=tower.node.find_child("Turret",true,false)
	if turret:
		var aim:Vector3=target.node.global_position;aim.y=turret.global_position.y
		if turret.global_position.distance_to(aim)>.01:turret.look_at(aim,Vector3.UP,true)
	if tower.fire_wait>0:return
	var origin:Vector3=tower.node.global_position+Vector3(0,3.35 if tower.type==24 else 2.3,0)
	var power:float=float(tower.get("campaign_damage",damage(tower)))
	if tower.type in [21,24]:
		tower.fire_wait=.18 if tower.type==21 else .24
		if turret:origin=turret.global_transform*Vector3(0,.35,1.6 if tower.type==24 else 3.0)
		host._muzzle_flash(origin);tracer(origin,target.node.global_position+Vector3.UP*.6)
		hit(target,power)
	elif tower.type==22:
		if projectiles.size()>=128:return
		tower.fire_wait=3.5
		launch(origin,target,attackers,power,true,3.5+minf(1.5,tower.level*.15))
	else:
		if projectiles.size()>=128:return
		var remaining:int=int(tower.get("burst_remaining",3))-1
		tower["burst_remaining"]=3 if remaining<=0 else remaining
		tower.fire_wait=2.6 if remaining<=0 else .18
		launch(origin,target,attackers,power,false,0)
	tower["shots_fired"]=int(tower.get("shots_fired",0))+1
func tracer(origin:Vector3,destination:Vector3)->void:
	var bullet:MeshInstance3D=host.art.cuboid(host.world_root,Vector3(.09,.7,.09),origin,Color("ffd276"),true)
	var direction:Vector3=destination-origin
	if direction.length()>.01:bullet.quaternion=Quaternion(Vector3.UP,direction.normalized())
	var flight:Tween=host.create_tween();flight.tween_property(bullet,"global_position",destination,.08);flight.tween_callback(bullet.queue_free)
func hit(target:Dictionary,power:float)->void:
	if target.get("hp",0)<=0 or not is_instance_valid(target.node):return
	target.hp-=power
	if target.hp<=0:host._destroy_entity(target,false)
func launch(origin:Vector3,target:Dictionary,attackers:Array,power:float,shell:bool,radius:float)->void:
	var body:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=.25 if shell else .15;mesh.height=.5 if shell else .9;mesh.radial_segments=8;mesh.rings=4;body.mesh=mesh
	body.material_override=host.art.mat(Color("ffae45") if shell else Color("77dfff"),true)
	host.world_root.add_child(body);body.global_position=origin
	if not shell:
		var trail:MeshInstance3D=host.art.cuboid(body,Vector3(.12,.55,.12),Vector3(0,-.6,0),Color("ff712d"),true)
		trail.name="RocketExhaust"
	projectiles.append({"node":body,"target":target,"attackers":attackers.duplicate(),"origin":origin,"destination":Vector3(target.node.global_position.x,.05,target.node.global_position.z) if shell else target.node.global_position,"age":0.0,"duration":maxf(.6,origin.distance_to(target.node.global_position)/17.0),"power":power,"shell":shell,"radius":radius,"context":host.mode})
	host._muzzle_flash(origin)
func tick(delta:float)->void:
	for i in range(projectiles.size()-1,-1,-1):
		var p:Dictionary=projectiles[i]
		if p.context!=host.mode or not is_instance_valid(p.node):
			if is_instance_valid(p.node):p.node.queue_free()
			projectiles.remove_at(i);continue
		p.age+=delta
		var impact:=false
		if p.shell:
			var t:float=minf(1.0,p.age/p.duration)
			p.node.global_position=p.origin.lerp(p.destination,t)+Vector3.UP*(4.0*5.5*t*(1.0-t))
			impact=t>=1
		else:
			if p.target.get("hp",0)>0 and is_instance_valid(p.target.node):p.destination=p.target.node.global_position+Vector3.UP*.5
			var direction:Vector3=p.destination-p.node.global_position
			p.node.global_position=p.node.global_position.move_toward(p.destination,delta*26)
			if direction.length()>.01:p.node.quaternion=Quaternion(Vector3.UP,direction.normalized())
			impact=p.node.global_position.distance_to(p.destination)<.3 or p.age>=4
		if not impact:continue
		if p.shell:
			for unit in p.attackers:
				if unit.get("hp",0)<=0 or not is_instance_valid(unit.node) or airborne(int(unit.get("type",0))):continue
				if Vector2(unit.node.global_position.x,unit.node.global_position.z).distance_to(Vector2(p.destination.x,p.destination.z))<=p.radius:hit(unit,p.power)
			var ring:MeshInstance3D=host.art.cuboid(host.world_root,Vector3(.1,.1,.1),p.destination,Color("ff9735"),true)
			# A expanding ground ring makes the actual splash radius visible.
			var torus:=TorusMesh.new();torus.inner_radius=p.radius-.12;torus.outer_radius=p.radius;torus.rings=24;torus.ring_segments=6;ring.mesh=torus;ring.scale=Vector3(.15,.15,.15)
			var fade:Tween=host.create_tween();fade.tween_property(ring,"scale",Vector3(1,.15,1),.3);fade.tween_callback(ring.queue_free)
		elif p.target.get("hp",0)>0 and is_instance_valid(p.target.node) and airborne(int(p.target.get("type",0))) and p.target.node.global_position.distance_to(p.node.global_position)<1.5:hit(p.target,p.power)
		host._explode(p.node.global_position);p.node.queue_free();projectiles.remove_at(i)
func clear()->void:
	for p in projectiles:
		if is_instance_valid(p.node):p.node.queue_free()
	projectiles.clear()
func blocking_wall(start:Vector3,end:Vector3,defenders:Array)->Dictionary:
	var found:Dictionary={};var distance:=INF
	for b in defenders:
		if b.type!=24 or b.hp<=0 or not is_instance_valid(b.node) or b.get("job","")=="build":continue
		var center:Vector3=b.pos
		var box:=AABB(center+Vector3(-3.1,-1,-.9),Vector3(6.2,8,1.8))
		if box.intersects_segment(Vector3(start.x,1,start.z),Vector3(end.x,1,end.z)):
			var d:=start.distance_to(center)
			if d<distance:found=b;distance=d
	return found
