extends RefCounted
## Stock-backed visual representatives: no duplicated inventory or hidden free army.
var host:Node3D
var root:Node3D
var actors:Array[Dictionary]=[]
var pads:Array[Vector3]=[]
var labels:Array[Label3D]=[]
var counts:=[0,0,0]
var signature:=""
var refresh:=0.0
var anchor:=Vector3(0,0,56)
var owners:Array[int]=[]
var focus_index:=-1
const FACILITIES:=[6,12,13,16]
const TITLES:=["AIRFIELD","MOTOR POOL","PARADE GROUND"]
func _init(game:Node3D)->void:
	host=game;root=Node3D.new();root.name="HomeGarrison";host.home_root.add_child(root)
func category(kind:int)->int:
	if host._is_air_unit(kind) or kind in [16,17]:return 0
	return 1 if kind in [10,11,12,13,14,21] else 2
func capacity_for_level(level:int)->int:return 10+5*(maxi(1,level)-1)
func capacity(group:int)->int:
	var total:=0
	for b in host.buildings:
		if b.type==[19,18,20][group] and b.get("job","")!="build":total+=capacity_for_level(b.level)
	return total
func stock(group:int)->int:
	var total:=0
	for kind in host.unit_stock.size():
		if category(kind)==group:total+=host.unit_stock[kind]
	return total
func queued(group:int)->int:
	var total:=0
	for job in host.training_queue:
		if category(int(job.type))==group:total+=1
	return total
func box(parent:Node3D,size:Vector3,pos:Vector3,color:Color)->void:
	host.art.cuboid(parent,size,pos,color)
func blocked(pos:Vector3,ignore:int=-1)->bool:
	for i in pads.size():
		if owners[i]==ignore:continue
		if absf(pos.x-pads[i].x)<9 and absf(pos.z-pads[i].z)<8:return true
	return false
func sync()->void:
	var key:String=str(host.unit_stock)+str(host.training_queue.size())
	for b in host.buildings:key+=str([b.type,b.level,b.pos,b.get("job","")])
	if key==signature:return
	signature=key
	for child in root.get_children():root.remove_child(child);child.queue_free()
	actors.clear();pads.clear();owners.clear();labels.clear();counts=[0,0,0]
	for kind in host.unit_stock.size():counts[category(kind)]+=host.unit_stock[kind]
	if not host.has_colony:return
	var remaining:PackedInt32Array=host.unit_stock.duplicate()
	for index in host.buildings.size():
		var building:Dictionary=host.buildings[index]
		if building.type not in [18,19,20]:continue
		var group:int=[19,18,20].find(int(building.type))
		var pos:Vector3=building.pos;pads.append(pos);owners.append(index)
		var inventory:Dictionary={};var ready:=0
		var room:int=capacity_for_level(building.level)
		# Legacy excess stock is preserved; admission checks prevent further overfilling.
		var last:=true
		for later in range(index+1,host.buildings.size()):
			if host.buildings[later].type==building.type:last=false
		for kind in remaining.size():
			if category(kind)!=group:continue
			var count:int=remaining[kind] if last else mini(remaining[kind],maxi(0,room-ready))
			if count>0:inventory[kind]=count;remaining[kind]-=count;ready+=count
		var yard:=Node3D.new();root.add_child(yard);yard.position=pos
		var label:=Label3D.new();label.font_size=38;label.pixel_size=.019;label.outline_size=7;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true
		label.text="%s • %s\n%d / %d READY • %d QUEUED"%[TITLES[group],host._rank_text(building.level),ready,room,queued(group)];label.position=Vector3(0,3.5,-5);yard.add_child(label);labels.append(label)
		if building.get("job","")=="build":label.text+="\nUNDER CONSTRUCTION";continue
		# Bounded representative models, always backed by this facility's allocated stock.
		var limit:=6 if group==1 else 9
		var kinds:Array[int]=[];var used:Dictionary={}
		for kind in inventory:
			if kinds.size()<limit:kinds.append(kind);used[kind]=1
		while kinds.size()<mini(limit,ready):
			for kind in used:
				if used[kind]<inventory[kind] and kinds.size()<limit:kinds.append(kind);used[kind]+=1
		for i in kinds.size():
			if actors.size()>=60:break
			var kind:int=kinds[i];var actor:Node3D=host._unit_model(kind);root.add_child(actor)
			var parked:Vector3=pos+Vector3((i%3-1)*3.8,.22,floori(i/3.0)*(4.3 if group==1 else 2.8)-3)
			if kind==23:parked.y=.85
			elif kind in [16,17]:parked.y=1.0
			actor.position=parked
			actors.append({"node":actor,"type":kind,"patrol":i==0,"group":group,"parked":parked,"waypoint":group,"last_shot":-10.0,"owner":index})
func focus()->void:
	if host.mode!="base":return
	sync()
	if pads.is_empty():host._toast("Build an Air Camp, Vehicle Camp or Infantry Camp first.");return
	host.build_panel.hide();host.units_panel.hide();host.info_panel.hide();host.galaxy_panel.hide()
	if is_instance_valid(host.coin_system.panel):host.coin_system.panel.hide()
	focus_index=(focus_index+1)%pads.size()
	anchor=pads[focus_index]
	host.camera_focus=anchor;host.camera.size=26;host._position_camera()
	host._toast("READY: %d AIR • %d VEHICLES • %d TROOPS — patrols are included in these totals"%counts)
func steer(pos:Vector3,destination:Vector3,step:float,air:bool)->Vector3:
	var next:=pos.move_toward(destination,step)
	if air:return next
	for b in host.buildings:
		var offset:=Vector2(next.x-b.pos.x,next.z-b.pos.z)
		if offset.length()<4.6:
			var away:=Vector2(pos.x-b.pos.x,pos.z-b.pos.z).normalized()
			var tangent:=Vector3(-away.y,0,away.x)
			if tangent.dot(destination-pos)<0:tangent=-tangent
			return pos+tangent*step
	return next
func tick(delta:float)->void:
	root.visible=host.mode=="base" and host.has_colony
	if not root.visible:return
	refresh-=delta
	if refresh<=0:refresh=.4;sync()
	var center:Vector3=host.buildings[0].pos if not host.buildings.is_empty() else Vector3.ZERO
	var route:=[center+Vector3(-24,0,-20),center+Vector3(24,0,-20),center+Vector3(24,0,20),center+Vector3(-24,0,20)]
	for actor in actors:
		if not is_instance_valid(actor.node):continue
		var target:Dictionary={};var nearest:=INF
		if actor.patrol:
			for enemy in host.home_attackers:
				if enemy.get("hp",0)<=0 or not is_instance_valid(enemy.node):continue
				var distance:float=actor.node.position.distance_to(enemy.node.position)
				if distance<nearest:nearest=distance;target=enemy
		var destination:Vector3=route[int(actor.waypoint)%4] if actor.patrol else actor.parked
		if not target.is_empty():destination=target.node.position
		var airborne:bool=host._is_air_unit(actor.type) or actor.type in [16,17]
		destination.y=host._unit_height(actor.type) if actor.patrol else actor.parked.y
		var moving:bool=actor.patrol and (target.is_empty() or nearest>host._attack_range(actor.type))
		if moving:
			actor.node.position=steer(actor.node.position,destination,delta*(3.6 if airborne else 2.7),airborne)
			if actor.node.position.distance_to(destination)<1:actor.waypoint=(int(actor.waypoint)+1)%4
		var aim:Vector3=destination;aim.y=actor.node.position.y
		if actor.patrol and actor.node.position.distance_to(aim)>.05:actor.node.look_at(aim,Vector3.UP,not host._is_air_unit(actor.type))
		host._animate_unit(actor,delta,moving,destination)
		if not target.is_empty() and not moving and host.visual_time-float(actor.last_shot)>.8:
			actor.last_shot=host.visual_time
			target.hp-=5 if actor.type==23 else 12+actor.type*.5
			host._fire_animation(actor.node)
			host._weapon_effect(actor.node.global_position+Vector3.UP,target.node,target.node.global_position,actor.type in [2,6,10,11,12,13],actor.type in [20,21,22])
			if target.hp<=0:host._destroy_entity(target,false)
