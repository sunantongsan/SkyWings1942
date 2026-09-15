extends RefCounted
var host:Node3D
var panel:PanelContainer
var clearing:=false
var obstacle_id:=-1
func _init(game:Node3D)->void:host=game
func day()->int:return floori(maxf(host.colony_time,Time.get_unix_time_from_system())/86400.0)
func price(finish:float)->int:return maxi(1,ceili((finish-host.colony_time)/60.0))
func layout()->void:
	if not is_instance_valid(panel):return
	var size:Vector2=host.get_viewport().get_visible_rect().size
	panel.position=Vector2(24,105);panel.size=Vector2(size.x-48,size.y-220)
func show_panel()->void:
	if host.mode!="base" or not host.has_colony:return
	if is_instance_valid(panel):panel.queue_free()
	panel=host._panel("GODOT COIN • %d / DAILY REWARDS & SPEED UPS"%host.godot_coins)
	host.ui_root.add_child(panel);host.build_panel.hide();host.units_panel.hide();host.info_panel.hide()
	var grid:GridContainer=host._scroll_grid(panel,3)
	var daily:Button=host._button("DAILY LOGIN\n+20 GODOT COIN",claim_daily,Vector2(320,86));daily.disabled=day()<=host.last_coin_day;grid.add_child(daily)
	for resource in ["Metal","Oil","Credits","Crystal"]:
		grid.add_child(host._button("10 COIN → 1,000 "+resource,func(r=resource):exchange(r),Vector2(320,86)))
	grid.add_child(host._button("CLEAR ROCKS / TREES\n100 Metal + 50 Oil • 25% coin chance",begin_clear,Vector2(320,86)))
	for i in host.buildings.size():
		var b:Dictionary=host.buildings[i]
		if b.get("job","")=="":continue
		grid.add_child(host._button("FINISH %s\n%s • %d COIN"%[b.job.to_upper(),host.BUILDING_NAMES[b.type],price(b.finish)],func(index=i):speed_build(index),Vector2(320,86)))
	for kind in [6,12,13]:
		var finish:=first_finish(kind)
		if finish<=host.colony_time:continue
		grid.add_child(host._button("FINISH NEXT UNIT\n%s • %d COIN"%[host.BUILDING_NAMES[kind],price(finish)],func(k=kind):speed_line(k),Vector2(320,86)))
	if obstacle_id>=0 and host.art.obstacles.has(obstacle_id):
		grid.add_child(host._button("BLAST SELECTED OBSTACLE\n100 Metal + 50 Oil",clear_selected,Vector2(320,86)))
	layout()
func claim_daily()->void:
	if host.mode!="base" or not host.has_colony or day()<=host.last_coin_day:return
	host.last_coin_day=day();host.godot_coins+=20;host._save_profile();show_panel();host._toast("Daily reward: +20 GODOT COIN")
func exchange(resource:String)->void:
	if host.mode!="base" or resource not in ["Metal","Oil","Credits","Crystal"]:return
	if host.godot_coins<10:host._toast("Requires 10 GODOT COIN");return
	host.godot_coins-=10
	match resource:
		"Metal":host.metal=minf(1e12,host.metal+1000)
		"Oil":host.oil=minf(1e12,host.oil+1000)
		"Credits":host.credits=minf(1e12,host.credits+1000)
		"Crystal":host.crystal=minf(1e12,host.crystal+1000)
	host._save_profile();show_panel();host._update_top_bar()
func speed_build(index:int)->void:
	if host.mode!="base" or index<0 or index>=host.buildings.size():return
	var b:Dictionary=host.buildings[index]
	if b.get("job","")=="":return
	var cost:=price(b.finish)
	if host.godot_coins<cost:host._toast("Not enough GODOT COIN");return
	host.godot_coins-=cost;b.finish=host.colony_time+.001
	host._advance_colony(host.colony_time+.002);host._save_profile();show_panel()
func first_finish(kind:int)->float:
	var finish:=INF
	if kind==6 and host.drone_finish>0:finish=minf(finish,host.drone_finish)
	if kind==12 and host.miner_finish>0:finish=minf(finish,host.miner_finish)
	for job in host.training_queue:
		if host.UNIT_FACILITY[int(job.type)]==kind:finish=minf(finish,job.finish)
	return 0.0 if finish==INF else finish
func speed_line(kind:int)->void:
	if host.mode!="base":return
	var finish:=first_finish(kind)
	if finish<=host.colony_time:return
	var cost:=price(finish)
	if host.godot_coins<cost:host._toast("Not enough GODOT COIN");return
	host.godot_coins-=cost
	var shift:float=finish-host.colony_time-.001
	for job in host.training_queue:
		if host.UNIT_FACILITY[int(job.type)]==kind:job.finish-=shift
	if kind==6 and host.drone_finish>0:host.drone_finish-=shift
	if kind==12 and host.miner_finish>0:host.miner_finish-=shift
	host.training_queue.sort_custom(func(a,b):return float(a.finish)<float(b.finish))
	host._advance_colony(host.colony_time+.002);host._save_profile();show_panel()
func begin_clear()->void:
	if host.mode!="base":return
	clearing=true;obstacle_id=-1;host.build_type=-1;host.moving_building=-1
	if is_instance_valid(panel):panel.hide()
	host.build_panel.hide();host.units_panel.hide();host._toast("Tap a rock or tree. Review the cost, then BLAST to clear it.")
func select_obstacle(pos:Vector3)->void:
	var best:=4.0;obstacle_id=-1
	for id in host.art.obstacles:
		var distance:float=pos.distance_to(host.art.obstacles[id])
		if distance<best:best=distance;obstacle_id=id
	if obstacle_id<0:host._toast("Tap closer to a rock or tree.");return
	clearing=false;show_panel()
func clear_selected()->void:
	if host.mode!="base" or obstacle_id<0 or obstacle_id in host.cleared_obstacles or not host.art.obstacles.has(obstacle_id):return
	if host.metal<100 or host.oil<50:host._toast("Clearing requires 100 Metal and 50 Oil");return
	var pos:Vector3=host.art.obstacles[obstacle_id]
	host.metal-=100;host.oil-=50;host.cleared_obstacles.append(obstacle_id)
	var rng:=RandomNumberGenerator.new();rng.seed=1942+host.home_planet*10000+obstacle_id*73
	var reward:int=rng.randi_range(1,5) if rng.randf()<.25 else 0
	host.godot_coins+=reward;obstacle_id=-1
	host._save_profile();host._explode(pos+Vector3.UP);host._create_decor(host.decor_root,host.home_planet)
	show_panel();host._toast("Obstacle cleared • +%d GODOT COIN"%reward)
