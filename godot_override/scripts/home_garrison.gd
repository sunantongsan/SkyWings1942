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
var roster_panel:PanelContainer
const TITLES:=["AIRFIELD","MOTOR POOL","PARADE GROUND"]
func _init(game:Node3D)->void:
	host=game;root=Node3D.new();root.name="HomeGarrison";host.home_root.add_child(root)
func category(kind:int)->int:
	if host._is_air_unit(kind) or kind in [16,17]:return 0
	return 1 if kind in [10,11,12,13,14,21] else 2
func available(group:int)->bool:
	return host._production_level([6,12,13][group])>0 or (group==2 and host._production_level(16)>0) or counts[group]>0
func box(parent:Node3D,size:Vector3,pos:Vector3,color:Color)->void:
	host.art.cuboid(parent,size,pos,color)
func blocked(pos:Vector3)->bool:
	for pad in pads:
		if absf(pos.x-pad.x)<7.5 and absf(pos.z-pad.z)<6.5:return true
	return false
func find_anchor()->Vector3:
	var center:=Vector3.ZERO
	if not host.buildings.is_empty():center=host.buildings[0].pos
	for ring in range(0,30):
		var candidate:Vector3=center+Vector3(0,0,42+ring*16)
		var clear:=true
		for b in host.buildings:
			if absf(b.pos.x-candidate.x)<27 and absf(b.pos.z-candidate.z)<12:clear=false;break
		if clear:
			for pos in host.art.obstacles.values():
				if absf(pos.x-candidate.x)<25 and absf(pos.z-candidate.z)<10:clear=false;break
		if clear:return candidate
	return center+Vector3(0,0,540)
func sync()->void:
	var key:String=str(host.unit_stock)
	for b in host.buildings:key+=str([b.type,b.pos,b.get("job","")])
	if key==signature:return
	signature=key
	for child in root.get_children():root.remove_child(child);child.queue_free()
	actors.clear();pads.clear();labels.clear();counts=[0,0,0]
	for kind in host.unit_stock.size():counts[category(kind)]+=host.unit_stock[kind]
	if not host.has_colony:return
	anchor=find_anchor()
	for group in 3:
		if not available(group):continue
		var pos:Vector3=anchor+Vector3((group-1)*16,0,0);pads.append(pos)
		var yard:=Node3D.new();root.add_child(yard);yard.position=pos
		box(yard,Vector3(13,.15,10),Vector3(0,.08,0),Color("34484e"))
		for side in [-1,1]:box(yard,Vector3(.12,.03,9.5),Vector3(side*6.2,.17,0),Color("efb952"))
		for x in [-4,0,4]:
			box(yard,Vector3(.09,.025,8),Vector3(x,.17,0),Color("c8d6c7"))
		for z in [-3.8,0,3.8]:box(yard,Vector3(12,.025,.1),Vector3(0,.17,z),Color("c8d6c7"))
		if group==0:
			for x in [-1.0,1.0]:box(yard,Vector3(.15,.03,2),Vector3(x,.18,0),Color("ffd471"))
			box(yard,Vector3(2,.03,.15),Vector3(0,.18,0),Color("ffd471"))
		var label:=Label3D.new();label.font_size=38;label.pixel_size=.019;label.outline_size=7;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true
		label.text="%s\n%d READY • %d PATROL"%[TITLES[group],counts[group],mini(1,counts[group])];label.position=Vector3(0,3.5,-5);yard.add_child(label);labels.append(label)
		# At most nine representatives per category, drawn from real owned quantities.
		var kinds:Array[int]=[];var used:Dictionary={}
		for kind in host.unit_stock.size():
			if category(kind)==group and host.unit_stock[kind]>0:kinds.append(kind);used[kind]=1
		while kinds.size()<mini(9,counts[group]):
			for kind in used:
				if used[kind]<host.unit_stock[kind] and kinds.size()<9:kinds.append(kind);used[kind]+=1
		for i in mini(9,kinds.size()):
			var kind:int=kinds[i];var actor:Node3D=host._unit_model(kind);root.add_child(actor)
			var parked:Vector3=pos+Vector3((i%3-1)*3.8,.22,floori(i/3.0)*2.8-3)
			if kind==23:parked.y=.85
			elif kind in [16,17]:parked.y=1.0
			actor.position=parked
			actors.append({"node":actor,"type":kind,"patrol":i==0,"group":group,"parked":parked,"waypoint":group,"last_shot":-10.0})
func focus()->void:
	if host.mode!="base":return
	sync()
	if pads.is_empty():host._toast("Build a Star Hangar, Vehicle Factory or Barracks first.");return
	host.build_panel.hide();host.units_panel.hide();host.info_panel.hide();host.galaxy_panel.hide()
	if is_instance_valid(host.coin_system.panel):host.coin_system.panel.hide()
	host.camera_focus=anchor;host.camera.size=44;host._position_camera()
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
