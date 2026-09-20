extends RefCounted
## Persistent haulers: travel -> search -> return -> unload. No reward at discovery.
const GOLD_SITE:=Vector3(110,0,-18)
const COIN_SITE:=Vector3(132,0,18)
const SPEED:=6.0
var host:Node3D
var workers:Array[Dictionary]=[]
var orders:Array[Dictionary]=[]
var coin_count:=0
var grid:AStarGrid2D
var layout_key:=""
var routes:Dictionary={}
var forest_root:Node3D
var status:Label3D
func _init(game:Node3D)->void:host=game
func core()->Dictionary:
	for b in host.buildings:
		if b.type==0 and b.get("job","")!="build":return b
	return {}
func queue_finish(producer:int)->float:
	var finish:=0.0
	for job in orders:
		if int(job.producer)==producer:finish=maxf(finish,float(job.finish))
	return finish
func next_finish()->float:
	var finish:=INF
	for job in orders:finish=minf(finish,float(job.finish))
	return finish
func complete_orders(now:float)->bool:
	var changed:=false
	for i in range(orders.size()-1,-1,-1):
		if float(orders[i].finish)<=now:coin_count+=1;orders.remove_at(i);changed=true
	if changed:sync_workers()
	return changed
func build_coin_truck()->void:
	if host.mode!="base":return
	var producer:int=host._producer_for(12)
	if producer<0 or host.buildings[producer].level<2 or host.buildings[producer].get("job","")!="":host._toast("Complete a level 2 Vehicle Factory first.");return
	if host._producer_queue_count(producer)>=host._producer_queue_limit(producer):host._toast("Factory queue full.");return
	if coin_count+orders.size()>=3:host._toast("Maximum 3 Coin Prospectors.");return
	if host.metal<4000 or host.oil<1200:host._toast("Coin Prospector costs 4000 Metal and 1200 Oil.");return
	host.metal-=4000;host.oil-=1200
	orders.append({"producer":producer,"finish":host._facility_finish(12,producer)+60})
	host._save_profile();host._refresh_progress();host._toast("Coin Prospector queued • 60s. Coins arrive when it returns to the Core.")
func gold_nodes()->Array[Node3D]:
	var result:Array[Node3D]=[]
	for w in workers:
		if w.kind=="gold" and is_instance_valid(w.get("node")):result.append(w.node)
	return result
func sync_workers()->void:
	if core().is_empty():return
	ensure_forest()
	var capacity:=0
	for b in host.buildings:
		if b.type==10 and b.get("job","")!="build":capacity+=3
	for kind in ["gold","coin"]:
		var desired:int=mini(host.miner_count,capacity) if kind=="gold" else coin_count
		var existing:=0
		for w in workers:
			if w.kind==kind:existing+=1
		for i in range(existing,desired):
			workers.append({"id":i+(0 if kind=="gold" else 1000),"kind":kind,"pos":core().pos+Vector3(4,0,4),"phase":"outbound","dig":20.0,"cargo":0,"cycle":0,"new":true})
	var added:bool=workers.any(func(w):return w.get("new",false))
	if added:
		refresh_grid()
		if grid:
			for w in workers:
				if w.get("new",false):w.pos=dock();w.erase("new")
	for w in workers:
		if not is_instance_valid(w.get("node")):
			var n:Node3D=host.art.model("mining_vehicle" if w.kind=="gold" else "coin_prospector");host.home_root.add_child(n);n.position=w.pos;w["node"]=n
			var label:=Label3D.new();label.font_size=26;label.pixel_size=.015;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position.y=3.2;n.add_child(label);w["label"]=label
func save_state()->Dictionary:
	var data:Array=[]
	for w in workers:data.append({"id":w.id,"kind":w.kind,"pos":[w.pos.x,0,w.pos.z],"phase":w.phase,"dig":w.dig,"cargo":w.cargo,"cycle":w.cycle})
	return {"coin_count":coin_count,"orders":orders,"workers":data}
func load_state(data:Dictionary)->void:
	coin_count=int(data.get("coin_count",0));orders.assign(data.get("orders",[]));workers.clear()
	for saved in data.get("workers",[]):
		var w:Dictionary=saved.duplicate();w.pos=Vector3(saved.pos[0],0,saved.pos[2]);workers.append(w)
	layout_key="";sync_workers()
func refresh_grid()->void:
	var parts:Array=[]
	for b in host.buildings:parts.append([b.type,b.pos,b.get("yaw",0),b.get("job","")=="build"])
	var key:=str(parts)
	if grid and key==layout_key:return
	layout_key=key;routes.clear()
	for w in workers:w.erase("route");w.erase("progress")
	var origin:Vector3=core().pos
	var left:int=floori(minf(origin.x-24,-80)/2);var top:int=floori(minf(origin.z-30,-64)/2)
	var right:int=ceili(maxf(origin.x+24,172)/2);var bottom:int=ceili(maxf(origin.z+30,64)/2)
	if right-left>256 or bottom-top>256:grid=null;return
	grid=AStarGrid2D.new();grid.region=Rect2i(left,top,right-left+1,bottom-top+1);grid.cell_size=Vector2(2,2)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
	for x in range(left,right+1):
		for z in range(top,bottom+1):
			var p:=Vector3(x*2,0,z*2)
			var blocked:bool=p.x>=88 and not (absf(p.z)<4 or (absf(p.x-110)<4 and p.z>=-20 and p.z<=2) or (absf(p.x-132)<4 and p.z>=-2 and p.z<=20))
			if not blocked:
				for b in host.buildings:
					var local:Vector3=(p-b.pos).rotated(Vector3.UP,-float(b.get("yaw",0)))
					if b.type==25 and b.get("job","")=="":
						if absf(local.z)<1.6 and absf(local.x)>1.8 and absf(local.x)<3.5:blocked=true;break
						continue
					var extent:Vector2=host.layout.half_size(b.type)+Vector2(.55,.55)
					if absf(local.x)<extent.x and absf(local.z)<extent.y:blocked=true;break
			grid.set_point_solid(Vector2i(x,z),blocked)
func cell(pos:Vector3)->Vector2i:return Vector2i(roundi(pos.x/2),roundi(pos.z/2))
func dock()->Vector3:
	var origin:Vector3=core().pos
	for offset in [Vector3(4,0,4),Vector3(4,0,-4),Vector3(-4,0,4),Vector3(-4,0,-4),Vector3(6,0,0),Vector3(0,0,6),Vector3(-6,0,0),Vector3(0,0,-6)]:
		var p:=cell(origin+offset)
		if grid.is_in_boundsv(p) and not grid.is_point_solid(p):return Vector3(p.x*2,0,p.y*2)
	return origin
func make_route(from:Vector3,to:Vector3)->Array[Vector3]:
	var result:Array[Vector3]=[]
	if not grid:return result
	var a:=cell(from);var b:=cell(to)
	if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b) or grid.is_point_solid(a) or grid.is_point_solid(b):return result
	var key:=str([a,b])
	if routes.has(key):return routes[key]
	var points:PackedVector2Array=grid.get_point_path(a,b)
	for p in points:result.append(Vector3(p.x,0,p.y))
	routes[key]=result
	return result
func advance(delta:float)->void:
	if delta<=0 or core().is_empty():return
	sync_workers()
	if workers.is_empty():return
	refresh_grid()
	if not grid:return
	var unload:=dock()
	for w in workers:
		if w.get("new",false):w.pos=unload;w.erase("new")
	for w in workers:
		var remaining:float=minf(delta,28800)
		var turns:=0
		while remaining>.00001 and turns<6000:
			turns+=1
			if w.phase=="dig":
				var used:float=minf(remaining,float(w.dig));w.dig-=used;remaining-=used
				if w.dig>.00001:break
				w.cycle+=1
				var rng:=RandomNumberGenerator.new();rng.seed=1942+int(w.id)*991+int(w.cycle)*7919+host.home_planet*17
				w.cargo=120 if w.kind=="gold" else (rng.randi_range(1,3) if rng.randf()<.25 else 0)
				w.dig=20.0
				if w.cargo>0:w.phase="inbound";w.erase("route")
				continue
			var destination:Vector3=unload if w.phase=="inbound" else (GOLD_SITE if w.kind=="gold" else COIN_SITE)
			if not w.has("route") or w.get("destination",Vector3.INF)!=destination:
				w["route"]=make_route(w.pos,destination);w["progress"]=0.0;w["destination"]=destination
				var length:=0.0
				for i in range(1,w.route.size()):length+=w.route[i-1].distance_to(w.route[i])
				w["length"]=length
			if w.route.is_empty():w["blocked"]=true;break
			w["blocked"]=false
			var duration:float=maxf(0,(float(w.length)-float(w.progress))/SPEED)
			var used:float=minf(remaining,duration);remaining-=used;w.progress+=used*SPEED
			var travel:float=w.progress
			w.pos=destination
			for i in range(1,w.route.size()):
				var segment:float=w.route[i-1].distance_to(w.route[i])
				if travel<=segment:w.pos=w.route[i-1].lerp(w.route[i],travel/maxf(segment,.001));break
				travel-=segment
			if used+.00001<duration:break
			w.pos=destination;w.erase("route")
			if w.phase=="inbound":
				if w.kind=="gold":host.gold=minf(1e12,host.gold+int(w.cargo))
				else:host.godot_coins=mini(1000000000000,host.godot_coins+int(w.cargo))
				w.cargo=0;w.phase="outbound"
			else:w.phase="dig";w.dig=20.0
		# Save both cargo and balance together through the normal atomic colony save.
func visual_tick(delta:float)->void:
	var added:bool=workers.any(func(w):return w.get("new",false))
	if added:
		refresh_grid()
		if grid:
			for w in workers:
				if w.get("new",false):w.pos=dock();w.erase("new")
	for w in workers:
		if not is_instance_valid(w.get("node")):continue
		var direction:Vector3=w.pos-w.node.position
		if direction.length()>.02:w.node.rotation.y=atan2(direction.x,direction.z)
		w.node.position=w.pos;w.node.visible=host.mode=="base" and w.pos.distance_to(host.camera_focus)<100
		w.label.text="NO ROUTE • ADD GATE" if w.get("blocked",false) else ("%d %s • RETURNING"%[w.cargo,"COIN" if w.kind=="coin" else "GOLD"] if w.cargo>0 else ("SEARCHING" if w.phase=="dig" else "TO FOREST"))
		var drill:Node3D=w.node.find_child("Drill",true,false)
		if drill and w.phase=="dig":drill.rotation.y+=delta*5
	for b in host.buildings:
		if b.type!=25 or b.get("job","")!="":continue
		var nearby:=false
		for w in workers:
			if w.pos.distance_to(b.pos)<5:nearby=true;break
		b["gate_open"]=move_toward(float(b.get("gate_open",0)),1.0 if nearby else 0.0,delta*3)
		for side in [-1,1]:
			var leaf:Node3D=b.node.find_child("GateLeft" if side<0 else "GateRight",true,false)
			if leaf:leaf.position.x=side*float(b.gate_open)*2.4
	if is_instance_valid(status):status.text="FOREST MINING\nGold haulers: %d • Coin prospectors: %d\nCargo is credited at the Galactic Core"%[host.miner_count,coin_count]
func show_forest()->void:
	host._dismiss_menus();host.camera_focus=Vector3(116,0,0);host.camera.size=72;host._position_camera();ensure_forest()
func ensure_forest()->void:
	if is_instance_valid(forest_root):return
	forest_root=Node3D.new();host.home_root.add_child(forest_root)
	for road in [[Vector3(108,.035,0),Vector2(104,6)],[Vector3(110,.04,-10),Vector2(6,20)],[Vector3(132,.04,10),Vector2(6,20)]]:
		var mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=road[1];mesh.mesh=plane
		var mat:=StandardMaterial3D.new();mat.albedo_color=Color("766449");mesh.material_override=mat;mesh.position=road[0];forest_root.add_child(mesh)
	for site in [GOLD_SITE,COIN_SITE]:
		var rock:Node3D=host.art.model("rock_1");forest_root.add_child(rock);rock.position=site+Vector3(0,0,3);rock.scale=Vector3(2,1.2,2)
		var sign:=Label3D.new();sign.text="GOLD DEPOSIT" if site==GOLD_SITE else "GODOT COIN VEIN";sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sign.font_size=38;sign.pixel_size=.025;sign.position=site+Vector3(0,4,0);forest_root.add_child(sign)
	status=Label3D.new();status.billboard=BaseMaterial3D.BILLBOARD_ENABLED;status.font_size=34;status.pixel_size=.025;status.position=Vector3(116,5,-34);forest_root.add_child(status)
