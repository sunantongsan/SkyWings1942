extends RefCounted
var host:Node3D
var panel:PanelContainer
var clearing:=false
var obstacle_id:=-1
var work_markers:Dictionary={}
var last_beam:=-1.0
var obstacle_panel:=false
var obstacle_bar:ProgressBar
var remove_button:Button
func _init(game:Node3D)->void:host=game
func day()->int:return floori(maxf(host.colony_time,Time.get_unix_time_from_system())/86400.0)
func price(finish:float)->int:return maxi(1,ceili((finish-host.colony_time)/60.0))
func layout()->void:
	if not is_instance_valid(panel):return
	var size:Vector2=host.get_viewport().get_visible_rect().size
	if obstacle_panel:panel.position=Vector2(size.x-394,108);panel.size=Vector2(370,260)
	else:panel.position=Vector2(24,105);panel.size=Vector2(size.x-48,size.y-220)
func show_panel()->void:
	obstacle_panel=false
	if host.mode!="base" or not host.has_colony:return
	if is_instance_valid(panel):panel.queue_free()
	panel=host._panel("GODOT COIN • %d / SAVED AD BOOST • %ds"%[host.godot_coins,host.rewarded_ads.boost_seconds])
	host.ui_root.add_child(panel);host.build_panel.hide();host.units_panel.hide();host.info_panel.hide()
	var grid:GridContainer=host._scroll_grid(panel,3)
	var daily:Button=host._button("DAILY LOGIN\n+20 GODOT COIN",claim_daily,Vector2(320,86));daily.disabled=day()<=host.last_coin_day;grid.add_child(daily)
	grid.add_child(host._button("AD PRIVACY OPTIONS",func():host.rewarded_ads.privacy(),Vector2(320,86)))
	for resource in ["Metal","Oil","Credits","Crystal"]:
		grid.add_child(host._button("10 COIN → 1,000 "+resource,func(r=resource):exchange(r),Vector2(320,86)))
	grid.add_child(host._button("CLEAR ROCKS / TREES\n100 Metal + 50 Oil • 1 drone • 20s",begin_clear,Vector2(320,86)))
	for i in host.buildings.size():
		var b:Dictionary=host.buildings[i]
		if b.get("job","")=="":continue
		grid.add_child(host._button("FINISH %s\n%s • %d COIN"%[b.job.to_upper(),host.BUILDING_NAMES[b.type],price(b.finish)],func(index=i):speed_build(index),Vector2(320,86)))
		if host.rewarded_ads.boost_seconds>0:grid.add_child(host._button("USE SAVED BOOST\n"+host.BUILDING_NAMES[b.type],func(index=i):host.rewarded_ads.use_saved(index),Vector2(320,86)))
		grid.add_child(host._button("WATCH AD • −50s\n"+host.BUILDING_NAMES[b.type],func(index=i):host.rewarded_ads.request_build(index),Vector2(320,86)))
	for index in host.buildings.size():
		var kind:int=host.buildings[index].type
		if kind not in [6,12,13,16]:continue
		var finish:=first_finish(kind,index)
		if finish<=host.colony_time:continue
		grid.add_child(host._button("FINISH NEXT UNIT\n%s #%d • %d COIN"%[host.BUILDING_NAMES[kind],index+1,price(finish)],func(k=kind,owner=index):speed_line(k,owner),Vector2(320,86)))
	if obstacle_id>=0 and host.art.obstacles.has(obstacle_id):
		grid.add_child(host._button("ASSIGN DRONE TO CLEAR\n100 Metal + 50 Oil • 20s",clear_selected,Vector2(320,86)))
	layout()
func claim_daily()->void:
	if host.mode!="base" or not host.has_colony or day()<=host.last_coin_day:return
	host.last_coin_day=day();host.godot_coins+=20;host._save_profile();host._dismiss_menus();host._toast("Daily reward: +20 GODOT COIN")
func exchange(resource:String)->void:
	if host.mode!="base" or resource not in ["Metal","Oil","Credits","Crystal"]:return
	if host.godot_coins<10:host._toast("Requires 10 GODOT COIN");return
	host.godot_coins-=10
	match resource:
		"Metal":host.metal=minf(1e12,host.metal+1000)
		"Oil":host.oil=minf(1e12,host.oil+1000)
		"Credits":host.credits=minf(1e12,host.credits+1000)
		"Crystal":host.crystal=minf(1e12,host.crystal+1000)
	host._save_profile();host._dismiss_menus();host._update_top_bar()
func speed_build(index:int)->void:
	if host.mode!="base" or index<0 or index>=host.buildings.size():return
	var b:Dictionary=host.buildings[index]
	if b.get("job","")=="":return
	var cost:=price(b.finish)
	if host.godot_coins<cost:host._toast("Not enough GODOT COIN");return
	host.godot_coins-=cost;b.finish=host.colony_time+.001
	host._advance_colony(host.colony_time+.002);host._save_profile();host._dismiss_menus()
func first_finish(kind:int,index:int=-1)->float:
	if index<0:index=host._producer_for(kind)
	var finish:=INF
	if kind==6 and host.drone_finish>0 and host.drone_producer==index:finish=minf(finish,host.drone_finish)
	if kind==12 and host.miner_finish>0 and host.miner_producer==index:finish=minf(finish,host.miner_finish)
	for job in host.training_queue:
		if int(job.get("producer",-1))==index:finish=minf(finish,job.finish)
	return 0.0 if finish==INF else finish
func speed_line(kind:int,index:int=-1)->void:
	if host.mode!="base":return
	if index<0:index=host._producer_for(kind)
	var finish:=first_finish(kind,index)
	if finish<=host.colony_time:return
	var cost:=price(finish)
	if host.godot_coins<cost:host._toast("Not enough GODOT COIN");return
	host.godot_coins-=cost
	var shift:float=finish-host.colony_time-.001
	for job in host.training_queue:
		if int(job.get("producer",-1))==index:job.finish-=shift
	if kind==6 and host.drone_finish>0 and host.drone_producer==index:host.drone_finish-=shift
	if kind==12 and host.miner_finish>0 and host.miner_producer==index:host.miner_finish-=shift
	host.training_queue.sort_custom(func(a,b):return float(a.finish)<float(b.finish))
	host._advance_colony(host.colony_time+.002);host._save_profile();host._dismiss_menus()
func begin_clear()->void:
	if host.mode!="base":return
	clearing=true;obstacle_id=-1;host.build_type=-1;host.moving_building=-1
	if is_instance_valid(panel):panel.hide()
	host.build_panel.hide();host.units_panel.hide();host._toast("Tap a rock or tree. Review the cost, then assign a free drone to clear it.")
func select_obstacle(pos:Vector3,notify_miss:bool=true)->void:
	var best:=4.0;obstacle_id=-1
	for id in host.art.obstacles:
		var distance:float=pos.distance_to(host.art.obstacles[id])
		if distance<best:best=distance;obstacle_id=id
	if obstacle_id<0:
		if notify_miss:host._toast("Tap closer to a rock or tree.")
		if obstacle_panel and is_instance_valid(panel):panel.hide()
		return
	clearing=false;show_obstacle()
func show_obstacle()->void:
	if is_instance_valid(panel):panel.queue_free()
	obstacle_panel=true
	panel=host._panel("ROCK" if obstacle_id%4==0 else "ALIEN TREE");host.ui_root.add_child(panel)
	host.info_panel.hide();host.build_panel.hide();host.units_panel.hide();host.selected_building=-1
	host.selection_ring.position=host.art.obstacles[obstacle_id]+Vector3(0,.1,0);host.selection_ring.show()
	panel.get_child(0).get_child(0).get_child(1).pressed.connect(func():host.selection_ring.hide())
	var label:=Label.new();label.text="Remove with 1 construction drone\n100 Metal + 50 Oil • 20 seconds";label.add_theme_font_size_override("font_size",17);panel.get_child(0).add_child(label)
	obstacle_bar=host.status_bars.make_bar(320,20,Color("62dcf1"));obstacle_bar.show_percentage=true;obstacle_bar.add_theme_font_size_override("font_size",14);panel.get_child(0).add_child(obstacle_bar)
	remove_button=host._button("REMOVE • 100 M / 50 O",clear_selected,Vector2(320,54));panel.get_child(0).add_child(remove_button)
	layout();update_obstacle_panel()
func update_obstacle_panel()->void:
	if not obstacle_panel or not is_instance_valid(panel) or not panel.visible:return
	var active:=false
	for job in host.clearing_jobs:
		if int(job.id)==obstacle_id:
			active=true;obstacle_bar.value=host.status_bars.progress(job.started,job.finish)
			remove_button.text="REMOVING • %ds"%maxi(0,ceili(float(job.finish)-host.colony_time))
	obstacle_bar.visible=active
	remove_button.disabled=active or host._builder_busy() or host.metal<100 or host.oil<50
	if not active:remove_button.text="DRONES BUSY" if host._builder_busy() else ("NOT ENOUGH RESOURCES" if host.metal<100 or host.oil<50 else "REMOVE • 100 M / 50 O")
func clear_selected()->void:
	if host.mode!="base" or obstacle_id<0 or obstacle_id in host.cleared_obstacles or not host.art.obstacles.has(obstacle_id):return
	for job in host.clearing_jobs:
		if int(job.id)==obstacle_id:host._toast("A drone is already clearing this obstacle.");return
	if host._builder_busy():host._toast("All construction drones are busy. Wait for a free drone.");return
	if host.metal<100 or host.oil<50:host._toast("Clearing requires 100 Metal and 50 Oil");return
	var pos:Vector3=host.art.obstacles[obstacle_id]
	host.metal-=100;host.oil-=50
	host.clearing_jobs.append({"id":obstacle_id,"pos":[pos.x,0,pos.z],"started":host.colony_time,"finish":host.colony_time+20})
	obstacle_id=-1;clearing=false;host.selection_ring.hide()
	host._refresh_progress();host._sync_industry_visuals();host._save_profile()
	if is_instance_valid(panel):panel.hide()
	host.camera_focus=pos;host._position_camera()
	host._toast("Drone assigned • 100 Metal + 50 Oil • 20 seconds")

func complete_clear(job:Dictionary)->void:
	var id:int=int(job.id)
	if id in host.cleared_obstacles:return
	host.cleared_obstacles.append(id)
	if obstacle_panel and obstacle_id==id:
		if is_instance_valid(panel):panel.hide()
		host.selection_ring.hide();obstacle_id=-1
	var rng:=RandomNumberGenerator.new();rng.seed=1942+host.home_planet*10000+id*73
	var reward:int=rng.randi_range(1,5) if rng.randf()<.25 else 0
	host.godot_coins+=reward
	if host.mode=="base":
		if host.profile_ready:host._explode(Vector3(job.pos[0],1,job.pos[2]));host._toast("Drone finished clearing • +%d GODOT COIN"%reward)
		host._create_decor(host.decor_root,host.home_planet)

func tick()->void:
	update_obstacle_panel()
	var active:Dictionary={}
	for i in host.clearing_jobs.size():
		var job:Dictionary=host.clearing_jobs[i]
		var id:int=int(job.id);active[id]=true
		var target:=Vector3(job.pos[0],1,job.pos[2])
		if not work_markers.has(id):
			var label:=Label3D.new();label.font_size=40;label.pixel_size=.018;label.outline_size=8;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("63e6ef")
			host.home_root.add_child(label);label.position=target+Vector3(0,5,0);work_markers[id]=label
		work_markers[id].hide()
		work_markers[id].text="DRONE CLEARING • %ds"%maxi(0,ceili(float(job.finish)-host.colony_time))
		if host.mode=="base" and i<host.drone_visuals.size() and host.visual_time-last_beam>.4:
			var drone:Node3D=host.drone_visuals[i]
			if drone.position.distance_to(target)<8:host._laser(drone.global_position,target)
	if host.visual_time-last_beam>.4:last_beam=host.visual_time
	for id in work_markers.keys():
		if not active.has(id):
			if is_instance_valid(work_markers[id]):work_markers[id].queue_free()
			work_markers.erase(id)
