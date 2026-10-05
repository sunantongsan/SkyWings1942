extends RefCounted
# Pure local simulation. No API, account state, currency or online army access.
var buildings: Array = []
var units: Array = []
var shots: Array = []
var reserve: Array = [12,6,4]
var tier=1
var elapsed=0.0
var started=false
var finished=false
var grid=AStarGrid2D.new()
var revision=0
func setup(level: int):
	tier=clampi(level,1,12);buildings.clear();units.clear();shots.clear()
	reserve=[12+int(tier/4)*2,6+int(tier/6),4];elapsed=0;started=false;finished=false;revision=0
	add_building("hall",Vector2i(8,7),850+90*tier)
	for pos in [Vector2i(5,6),Vector2i(10,9)]:add_building("tower",pos,220+50*tier)
	if tier>=3:add_building("tower",Vector2i(10,5),220+50*tier)
	if tier>=5:add_building("ward",Vector2i(5,9),280+65*tier)
	if tier>=8:add_building("ward",Vector2i(9,6),280+65*tier)
	if tier>=10:add_building("tower",Vector2i(8,10),220+50*tier)
	var resources=[Vector2i(3,7),Vector2i(12,8),Vector2i(7,12),Vector2i(8,3)]
	for i in range(resources.size()):add_building(["tank","granary","crystal","spring"][i],resources[i],140+20*tier)
	# Complete connected perimeter; early bases teach entrances, later bases have compartments.
	for x in range(4,12):
		for y in range(4,12):
			if x in [4,11] or y in [4,11]:
				if tier<=2 and (x==7 or y==7):continue
				add_building("wall",Vector2i(x,y),65+18*tier)
	if tier>=5:
		for y in range(5,11):
			if y!=7:add_building("wall",Vector2i(7,y),65+18*tier)
	if tier>=9:
		for x in [5,6,8,9,10]:add_building("wall",Vector2i(x,8),65+18*tier)
	# Alternate layout orientation without changing deterministic difficulty.
	for b in buildings:
		for turn in range((tier-1)%4):b.pos=Vector2(15-b.pos.y,b.pos.x)
	grid.region=Rect2i(0,0,16,16);grid.cell_size=Vector2.ONE
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update();rebuild_grid()
func add_building(kind: String, p: Vector2i, hp: float):
	buildings.append({"kind":kind,"pos":Vector2(p),"hp":hp,"max_hp":hp,"cooldown":0.0})
func rebuild_grid():
	grid.fill_solid_region(grid.region,false)
	for b in buildings:
		if b.hp>0:grid.set_point_solid(Vector2i(b.pos),true)
	revision+=1
func can_deploy(pos: Vector2i) -> bool:
	return grid.region.has_point(pos) and (pos.x<=1 or pos.y<=1 or pos.x>=14 or pos.y>=14) and not grid.is_point_solid(pos)
func deploy(kind: int, pos: Vector2i) -> bool:
	if finished or kind<0 or kind>2 or reserve[kind]<=0 or not can_deploy(pos):return false
	reserve[kind]-=1;started=true
	var hp=[190.0,140.0,440.0][kind]
	units.append({"kind":kind,"pos":Vector2(pos),"hp":hp,"max_hp":hp,"cooldown":0.0,"think":0.0,"target":{},"path":PackedVector2Array(),"revision":-1,"windup":0.0,"pending_target":{},"moving":false})
	return true
func route_to(unit: Dictionary, target: Dictionary) -> PackedVector2Array:
	var start=Vector2i(unit.pos.round());start=start.clamp(Vector2i.ZERO,Vector2i(15,15))
	var was_solid=grid.is_point_solid(start);grid.set_point_solid(start,false)
	var best=PackedVector2Array()
	for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		var end=Vector2i(target.pos)+offset
		if not grid.region.has_point(end) or grid.is_point_solid(end):continue
		var path=grid.get_point_path(start,end)
		if not path.is_empty() and (best.is_empty() or path.size()<best.size()):best=path
	grid.set_point_solid(start,was_solid)
	return best
func choose_target(unit: Dictionary):
	var candidates=buildings.filter(func(b):return b.hp>0 and b.kind!="wall")
	if unit.kind==2:
		var defenses=candidates.filter(func(b):return b.kind in ["tower","ward"])
		if not defenses.is_empty():candidates=defenses
	candidates.sort_custom(func(a,b):return unit.pos.distance_squared_to(a.pos)<unit.pos.distance_squared_to(b.pos))
	unit.target={};unit.path=PackedVector2Array();unit.revision=revision
	if candidates.is_empty():return
	if unit.kind>0:unit.target=candidates[0];return
	var best=PackedVector2Array()
	for b in candidates:
		var path=route_to(unit,b)
		if not path.is_empty() and (best.is_empty() or path.size()<best.size()):best=path;unit.target=b
	if best.is_empty():
		# Breach a reachable wall, then recalculate paths when it falls.
		for b in buildings:
			if b.hp<=0 or b.kind!="wall":continue
			var path=route_to(unit,b)
			if not path.is_empty() and (best.is_empty() or path.size()<best.size()):best=path;unit.target=b
	unit.path=best
func damage_building(b: Dictionary, amount: float):
	if b.hp<=0:return
	b.hp=maxf(0,b.hp-amount)
	if b.hp<=0:rebuild_grid()
func step(dt: float):
	shots.clear()
	if not started or finished:return
	elapsed+=dt
	for u in units:
		u.moving=false
		if u.hp<=0:continue
		u.cooldown-=dt;u.think-=dt
		if u.windup>0:
			u.windup-=dt
			if u.windup<=0 and not u.pending_target.is_empty():damage_building(u.pending_target,[30.0,43.0,65.0][u.kind])
			continue
		if u.target.is_empty() or u.target.get("hp",0)<=0 or u.revision!=revision or u.think<=0:
			choose_target(u);u.think=1.5
		if u.target.is_empty():continue
		var distance=u.pos.distance_to(u.target.pos)
		var reach=3.0 if u.kind==1 else 1.05
		if distance<=reach:
			if u.cooldown<=0:
				u.cooldown=[0.8,1.1,1.2][u.kind]
				shots.append({"from":u.pos,"to":u.target.pos,"kind":u.kind,"enemy":false,"unit":units.find(u)})
				u.pending_target=u.target;u.windup=0.3
		else:
			var target: Vector2=u.target.pos
			if u.kind==0:
				while not u.path.is_empty() and u.pos.distance_to(u.path[0])<0.05:u.path.remove_at(0)
				if u.path.is_empty():continue
				target=u.path[0]
			u.moving=true
			u.pos=u.pos.move_toward(target,[1.3,1.7,1.4][u.kind]*dt)
	for b in buildings:
		if b.hp<=0 or not b.kind in ["tower","ward"]:continue
		b.cooldown-=dt
		if b.cooldown>0:continue
		var target: Dictionary={};var nearest=5.2 if b.kind=="tower" else 4.2
		for u in units:
			if u.hp<=0:continue
			var d=b.pos.distance_to(u.pos)
			if d<nearest:nearest=d;target=u
		if target.is_empty():continue
		b.cooldown=1.0 if b.kind=="tower" else 1.8
		shots.append({"from":b.pos,"to":target.pos,"kind":1,"enemy":true,"weapon":b.kind})
		var damage=10.0+tier*3.0
		if b.kind=="ward":
			for u in units:
				if u.hp>0 and u.pos.distance_to(b.pos)<=4.2:u.hp=maxf(0,u.hp-damage*(1.8 if u.kind==1 else 1.4))
		else:target.hp=maxf(0,target.hp-damage)
	if percent()==100 or elapsed>=180 or (reserve[0]+reserve[1]+reserve[2]==0 and alive()==0):finished=true
func alive() -> int:return units.filter(func(u):return u.hp>0).size()
func percent() -> int:
	var total=0;var destroyed=0
	for b in buildings:
		if b.kind=="wall":continue
		total+=1
		if b.hp<=0:destroyed+=1
	return int(100.0*destroyed/maxi(1,total))
func stars() -> int:
	var count=0
	for b in buildings:
		if b.kind=="hall" and b.hp<=0:count+=1
	if percent()>=50:count+=1
	if percent()==100:count+=1
	return count
