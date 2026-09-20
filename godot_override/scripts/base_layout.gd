extends RefCounted
var host:Node3D
var candidate:=-1
var active:=false
var start:=Vector2.ZERO
var touch_id:=-2
func _init(game:Node3D)->void:host=game
func half_size(kind:int)->Vector2:return Vector2(3,.7) if kind==24 else (Vector2(6.5,5) if kind in [18,19,20] else Vector2(3.1,3.1))
func overlaps(pos:Vector3,kind:int,yaw:float,other:Dictionary)->bool:
	var a:=half_size(kind);var b:=half_size(int(other.type))
	var angle:float=float(other.get("yaw",0))
	var ax:=Vector2(cos(yaw),-sin(yaw));var az:=Vector2(sin(yaw),cos(yaw))
	var bx:=Vector2(cos(angle),-sin(angle));var bz:=Vector2(sin(angle),cos(angle))
	var gap:=Vector2(pos.x-other.pos.x,pos.z-other.pos.z)
	for axis in [ax,az,bx,bz]:
		var radius:float=a.x*absf(axis.dot(ax))+a.y*absf(axis.dot(az))+b.x*absf(axis.dot(bx))+b.y*absf(axis.dot(bz))
		if absf(gap.dot(axis))>=radius-.01:return false
	return true
func rotate_selected()->void:
	if host.mode!="base" or host.selected_building<0:return
	var b:Dictionary=host.buildings[host.selected_building]
	if b.type!=24:host._toast("Select a wall to rotate it.");return
	var previous:float=float(b.get("yaw",0))
	b["yaw"]=fposmod(previous+PI/2,TAU)
	var moving:int=host.moving_building;host.moving_building=host.selected_building
	var reason:String=host._placement_reason(b.pos);host.moving_building=moving
	if not reason.is_empty():b.yaw=previous;host._toast(reason);return
	b.node.rotation.y=b.yaw;host._save_profile();host.placement_guide.cache_key=""
	host._toast("Wall rotated 90°. Drag it to reposition.")
func cancel()->void:
	if active and candidate>=0:
		var b:Dictionary=host.buildings[candidate];b.node.position=b.pos
		host._update_rank_label(b)
		host.moving_building=-1
	candidate=-1;active=false;touch_id=-2
func input(event:InputEvent)->bool:
	if event is InputEventMouse and event.device==-1:return false
	if host.mode!="base" or host.build_type>=0 or host.galaxy_panel.visible or host.build_panel.visible or host.units_panel.visible or host.onboarding.screen.visible:return false
	if host.coin_system.clearing or (is_instance_valid(host.coin_system.panel) and host.coin_system.panel.visible):return false
	if is_instance_valid(host.rewarded_ads.result_panel) and host.rewarded_ads.result_panel.visible:return false
	var down:=false;var up:=false;var motion:=false;var pos:=Vector2.ZERO
	if event is InputEventScreenTouch:
		if candidate>=0 and event.index!=touch_id:
			cancel();host.drag_camera=false;return false
		down=event.pressed;up=not event.pressed;pos=event.position
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		down=event.pressed;up=not event.pressed;pos=event.position
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:motion=true;pos=event.position
	else:return false
	if down and host.moving_building<0:
		candidate=-1
		var hit=host._ground_hit(pos)
		if hit==null:return false
		var nearest:=INF
		for i in host.buildings.size():
			var b:Dictionary=host.buildings[i]
			var local:Vector3=(hit-b.pos).rotated(Vector3.UP,-float(b.get("yaw",0)))
			var size:=half_size(b.type)
			if absf(local.x)<=size.x and absf(local.z)<=size.y and hit.distance_to(b.pos)<nearest:
				candidate=i;nearest=hit.distance_to(b.pos)
		start=pos;touch_id=event.index if event is InputEventScreenTouch else -1
		return false
	if candidate<0:return false
	if motion and (active or pos.distance_to(start)>12):
		if not active:
			active=true;host.selected_building=candidate;host.moving_building=candidate;host._dismiss_menus()
		var hit=host._ground_hit(pos)
		if hit!=null:
			var b:Dictionary=host.buildings[candidate]
			b.node.position=Vector3(snappedf(hit.x,1),0,snappedf(hit.z,1));host._update_rank_label(b)
			host.placement_guide.point_at(pos)
		return true
	if up:
		if not active:candidate=-1;return false
		var hit=host._ground_hit(pos)
		if hit!=null:host._move_building(hit)
		if host.moving_building>=0:cancel()
		candidate=-1;active=false;touch_id=-2;host.drag_camera=false;host.touch_points.clear();host.pointer_moved=true
		return true
	return false
