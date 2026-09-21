extends RefCounted
var host:Node3D
var candidate:=-1
var active:=false
var start:=Vector2.ZERO
var touch_id:=-2
var drag_offset:=Vector3.ZERO
var rotating:=false
var upgrade_all:=false
var scope:HBoxContainer
var one:Button
var all:Button
var done:Button
func _init(game:Node3D)->void:
	host=game
	done=host._button("DONE",func():host.build_type=-1;host.placement_guide.has_pointer=false;done.hide(),Vector2(140,52))
	host.ui_root.add_child(done);done.hide()
	scope=HBoxContainer.new();scope.add_theme_constant_override("separation",8)
	one=host._button("ONE",func():upgrade_all=false;floating_menu(),Vector2(88,40))
	all=host._button("ALL",func():upgrade_all=true;floating_menu(),Vector2(88,40))
	for button in [one,all]:button.toggle_mode=true;button.add_theme_font_size_override("font_size",16);scope.add_child(button)
	host.selected_label.get_parent().add_child(scope);host.selected_label.get_parent().move_child(scope,0);scope.hide()
func half_size(kind:int)->Vector2:return Vector2(3,.7) if kind in [24,25] else (Vector2(6.5,5) if kind in [18,19,20] else Vector2(3.1,3.1))
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
	if b.type not in [24,25]:host._toast("Select a wall to rotate it.");return
	var previous:float=float(b.get("yaw",0))
	b["yaw"]=fposmod(previous+PI/2,TAU)
	var moving:int=host.moving_building;host.moving_building=host.selected_building
	rotating=true
	var reason:String=host._placement_reason(b.pos);host.moving_building=moving;rotating=false
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
		var wall_index:=pick_wall(pos)
		if wall_index>=0:candidate=wall_index
		drag_offset=host.buildings[candidate].pos-hit if candidate>=0 else Vector3.ZERO
		start=pos;touch_id=event.index if event is InputEventScreenTouch else -1
		return false
	if candidate<0:return false
	if motion and (active or pos.distance_to(start)>12):
		if not active:
			active=true;host.selected_building=candidate;host.moving_building=candidate;host._dismiss_menus()
		var hit=host._ground_hit(pos)
		if hit!=null:
			var b:Dictionary=host.buildings[candidate]
			var target:Vector3=hit+drag_offset
			b.node.position=Vector3(snappedf(target.x,1),0,snappedf(target.z,1));host._update_rank_label(b)
			host.placement_guide.pointer=b.node.position;host.placement_guide.has_pointer=true;host.placement_guide.update_cursor()
		return true
	if up:
		if not active:candidate=-1;return false
		var hit=host._ground_hit(pos)
		if hit!=null:host._move_building(hit+drag_offset)
		if host.moving_building>=0:cancel()
		candidate=-1;active=false;touch_id=-2;host.drag_camera=false;host.touch_points.clear();host.pointer_moved=true
		return true
	return false

func delete_selected()->void:
	if host.mode!="base" or host.selected_building<0:return
	var index:int=host.selected_building
	if index>=host.buildings.size() or host.buildings[index].type not in [24,25]:return
	cancel()
	var wall:Dictionary=host.buildings.pop_at(index)
	wall.node.queue_free()
	if host.logistics:
		for job in host.logistics.orders:
			if int(job.producer)>index:job.producer=int(job.producer)-1
	for job in host.training_queue:
		if int(job.get("producer",-1))>index:job.producer=int(job.producer)-1
	for key in ["production_building","drone_producer","miner_producer"]:
		if int(host.get(key))>index:host.set(key,int(host.get(key))-1)
	# Durable ad receipts continue to address the same building after removal.
	# -1 is a removed target: it can be acknowledged but cannot affect another job.
	var claims:Array=host.rewarded_ads.requests.values()
	claims.append(host.rewarded_ads.pending)
	for claim in claims:
		if claim.get("kind","")!="build":continue
		if int(claim.index)==index:claim.index=-1
		elif int(claim.index)>index:claim.index=int(claim.index)-1
	host.selected_building=-1;host.moving_building=-1;host.build_type=-1
	host._dismiss_menus();host.garrison.signature="";host._refresh_progress();host.garrison.sync();host._sync_industry_visuals()
	host._save_profile();host._toast("Wall removed.")

func pick_wall(screen:Vector2)->int:
	# Select the visible 3D wall, not the terrain several metres behind its top.
	var origin:Vector3=host.camera.project_ray_origin(screen)
	var direction:Vector3=host.camera.project_ray_normal(screen)
	var nearest:=INF;var found:=-1
	for i in host.buildings.size():
		var b:Dictionary=host.buildings[i]
		if b.type not in [24,25] or not is_instance_valid(b.node):continue
		var inverse:Transform3D=b.node.global_transform.affine_inverse()
		var box:=AABB(Vector3(-3.1,-.1,-.9),Vector3(6.2,3.8,1.8))
		var hit=box.intersects_ray(inverse*origin,inverse.basis*direction)
		if hit==null:continue
		var distance:float=origin.distance_to(b.node.global_transform*hit)
		if distance<nearest:nearest=distance;found=i
	return found

func wall_snap(pos:Vector3,exclude:int=-1)->Dictionary:
	var result:Dictionary={"pos":pos,"yaw":float(host.buildings[exclude].get("yaw",0)) if exclude>=0 else 0.0}
	if rotating:return result
	var nearest:=3.6
	for i in host.buildings.size():
		if i==exclude:continue
		var b:Dictionary=host.buildings[i]
		if b.type not in [24,25] or b.pos.distance_squared_to(pos)>121:continue
		var yaw:float=float(b.get("yaw",0));var axis:=Vector3.RIGHT.rotated(Vector3.UP,yaw)
		var across:=Vector3.RIGHT.rotated(Vector3.UP,yaw+PI/2)
		var candidates:Array=[{"pos":b.pos+axis*6,"yaw":yaw},{"pos":b.pos-axis*6,"yaw":yaw}]
		for side in [-1,1]:
			for turn in [-1,1]:candidates.append({"pos":b.pos+axis*side*3+across*turn*3.7,"yaw":fposmod(yaw+PI/2,TAU)})
		for candidate in candidates:
			var distance:float=pos.distance_to(candidate.pos)
			if distance>=nearest:continue
			var blocked:=false
			for j in host.buildings.size():
				if j!=exclude and overlaps(candidate.pos,24,candidate.yaw,host.buildings[j]):blocked=true;break
			if blocked or host.garrison.blocked(candidate.pos,exclude):continue
			nearest=distance;result=candidate
	return result

func floating_menu()->void:
	done.visible=host.mode=="base" and host.build_type==24 and not host.build_panel.visible
	done.position=Vector2(host.get_viewport().get_visible_rect().size.x/2-70,host.get_viewport().get_visible_rect().size.y-146)
	if not host.info_panel.visible or host.selected_building<0:return
	var b:Dictionary=host.buildings[host.selected_building]
	var wall:bool=b.type in [24,25]
	host.selected_label.visible=not wall;host.selected_detail.visible=true
	host.selected_detail.add_theme_font_size_override("font_size",15 if wall else 17)
	scope.visible=b.type==24
	one.set_pressed_no_signal(not upgrade_all);all.set_pressed_no_signal(upgrade_all)
	var quote:=wall_quote()
	if wall:
		if b.type==24 and upgrade_all:host.selected_detail.text="ALL: %d walls • %d M"%[quote.indices.size(),int(quote.cost)] if not quote.indices.is_empty() else "ALL WALLS AT MAX"
		else:host.selected_detail.text="MAX LEVEL" if b.level>=5 else "%d M • INSTANT"%int(host._upgrade_cost(b))
		if b.type==24 and upgrade_all and host.metal<quote.cost:host.selected_detail.text+="\nNeed %d more Metal"%ceili(quote.cost-host.metal)
	var width:=210.0 if wall else 230.0
	host.info_panel.custom_minimum_size=Vector2(width,0)
	var height:=324.0 if b.type==24 else (248.0 if wall else 330.0)
	host.info_panel.size=Vector2(width,height)
	var screen:Vector2=host.camera.unproject_position(b.pos+Vector3(0,2,0))
	var view:Vector2=host.get_viewport().get_visible_rect().size
	host.info_panel.position=Vector2(clampf(screen.x+65,16,view.x-width-16),clampf(screen.y-height*.5,104,view.y-height-90))
	for control in host.selected_label.get_parent().get_children():
		if control is Button and control.text=="UPGRADE":
			var bulk:bool=b.type==24 and upgrade_all
			var cost:float=quote.cost if bulk else host._upgrade_cost(b)
			control.disabled=host.tutorial_step<10 or (host.tutorial_step==10 and b.type!=0) or host.metal<cost or (not quote.ready if bulk else (b.level>=(5 if wall else 100) or b.get("job","")!="" or (not wall and host._builder_busy())))
			control.tooltip_text="%s Metal"%host._fmt(cost)

func wall_quote()->Dictionary:
	var indices:Array[int]=[];var cost:=0.0;var ready:=true
	for i in host.buildings.size():
		var b:Dictionary=host.buildings[i]
		if b.type!=24 or b.level>=5:continue
		indices.append(i);cost+=host._upgrade_cost(b)
		if b.get("job","")!="":ready=false
	return {"indices":indices,"cost":cost,"ready":ready and not indices.is_empty()}
func upgrade_all_walls()->void:
	if host.mode!="base" or host.tutorial_step<11:return
	var quote:=wall_quote()
	if not quote.ready:host._toast("No walls ready to upgrade.");return
	if host.metal<quote.cost:host._toast("ALL requires %s Metal. No walls upgraded."%host._fmt(quote.cost));return
	host.metal-=quote.cost
	for index in quote.indices:host._complete_upgrade(host.buildings[index])
	host._refresh_progress();host._save_profile();floating_menu()
	host._toast("%d walls upgraded by one level."%quote.indices.size())
