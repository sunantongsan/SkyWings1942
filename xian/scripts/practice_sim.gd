extends RefCounted
const Campaign=preload("res://scripts/campaign.gd")
const Defenses=preload("res://scripts/campaign_defenses.gd")
var campaign_mode=false
var campaign_data: Dictionary={}
var traps: Array=[]
const Troops=preload("res://scripts/troops.gd")
# Pure local simulation. No API, account state, currency or online army access.
var buildings: Array = []
var units: Array = []
var shots: Array = []
var defenders: Array=[]
var next_id=0
var stolen={"water":0,"rice":0,"stone":0}
var reserve: Array = [12,6,4]
var tier=1
var elapsed=0.0
var started=false
var finished=false
var grid=AStarGrid2D.new()
var revision=0
func setup(level: int):
	campaign_mode=false;traps.clear()
	clear_targets();next_id=0
	tier=clampi(level,1,12);buildings.clear();units.clear();shots.clear();defenders.clear();stolen={"water":0,"rice":0,"stone":0}
	reserve=[12+int(tier/4)*2,6+int(tier/6),4,0,0,0,0,0,0,0];
	for i in range(3,10):reserve[i]=2 if tier>=i+1 else 0
	elapsed=0;started=false;finished=false;revision=0
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
	if tier>=3:
		defenders.append(combatant(0,Vector2(8,6),1))
	if tier>=6:defenders.append(combatant(1,Vector2(9,7),1))
	if tier>=9:defenders.append(combatant(5,Vector2(8,9),1))
func setup_campaign(number: int):
	setup(1);campaign_mode=true;campaign_data=Campaign.stage(number);tier=number
	buildings.clear();defenders.clear();reserve=campaign_data.reserve.duplicate()
	var power: float=campaign_data.power
	for entry in campaign_data.buildings:
		var hp=190.0*power
		if entry.kind=="hall":hp=650.0*power
		elif entry.kind=="wall":hp=65.0*power
		elif Defenses.STATS.has(entry.kind):hp=260.0*power
		add_building(entry.kind,Vector2i(entry.x,entry.y),hp)
	for entry in campaign_data.guards:defenders.append(combatant(entry.kind,Vector2(entry.x,entry.y),1))
	for entry in campaign_data.traps:traps.append({"kind":entry.kind,"pos":Vector2(entry.x,entry.y),"triggered":false})
	rebuild_grid()
func tick_campaign_defense(b: Dictionary,dt: float):
	if b.hp<=0 or not Defenses.STATS.has(b.kind):return
	var config=Defenses.STATS[b.kind];var target: Dictionary={};var nearest: float=config.range
	# The flame retains its lock; ramping resets when the target dies or leaves range.
	if b.kind=="flame":
		for u in units:
			if u.hp>0 and u.eid==b.get("lock","") and b.pos.distance_to(u.pos)<=config.range:target=u;break
	if target.is_empty():
		for u in units:
			if u.hp<=0 or not Defenses.eligible(b.kind,Troops.air(u.kind)):continue
			var distance: float=b.pos.distance_to(u.pos)
			if distance>=config.min_range and distance<=nearest:nearest=distance;target=u
	if target.is_empty():b["lock"]="";b["ramp"]=0;return
	b.cooldown-=dt
	if b.cooldown>0:return
	b.cooldown=config.cooldown
	var damage: float=config.damage*campaign_data.power
	if b.kind=="flame":
		b["ramp"]=mini(6,int(b.get("ramp",0))+1) if b.get("lock","")==target.eid else 0
		b["lock"]=target.eid;damage*=1.0+b.ramp*0.45
	shots.append({"from":b.pos,"to":target.pos,"kind":1,"enemy":true,"weapon":b.kind,"target_height":2.4 if Troops.air(target.kind) else 0.0})
	if config.splash>0:
		var center: Vector2=b.pos if b.kind=="ward" else target.pos
		for u in units:
			if u.hp>0 and Defenses.eligible(b.kind,Troops.air(u.kind)) and u.pos.distance_to(center)<=config.splash:damage_target(u,damage)
	elif b.kind=="storm":
		damage_target(target,damage)
		var extra=units.filter(func(u):return u.hp>0 and u.eid!=target.eid and u.pos.distance_to(target.pos)<=2.0)
		extra.sort_custom(func(a,c):return a.pos.distance_squared_to(target.pos)<c.pos.distance_squared_to(target.pos))
		for i in range(mini(2,extra.size())):damage_target(extra[i],damage*0.65)
	else:damage_target(target,damage)
func tick_traps():
	for trap in traps:
		if trap.triggered:continue
		var air=trap.kind=="air_mine"
		for u in units:
			if u.hp<=0 or Troops.air(u.kind)!=air or u.pos.distance_to(trap.pos)>1.0:continue
			trap.triggered=true
			shots.append({"from":trap.pos,"to":u.pos,"kind":8,"enemy":true,"weapon":trap.kind,"trap":true})
			for victim in units:
				if victim.hp>0 and Troops.air(victim.kind)==air and victim.pos.distance_to(trap.pos)<=1.6:damage_target(victim,(100.0 if air else 65.0)*campaign_data.power)
			break
func add_building(kind: String, p: Vector2i, hp: float):
	buildings.append({"eid":"b"+str(buildings.size()),"kind":kind,"pos":Vector2(p),"hp":hp,"max_hp":hp,"cooldown":0.0,"burn":0.0,"stock":200.0})
func rebuild_grid():
	grid.fill_solid_region(grid.region,false)
	for b in buildings:
		if b.hp>0:grid.set_point_solid(Vector2i(b.pos),true)
	revision+=1
func can_deploy(pos: Vector2i) -> bool:
	return grid.region.has_point(pos) and (pos.x<=1 or pos.y<=1 or pos.x>=14 or pos.y>=14) and not grid.is_point_solid(pos)
func deploy(kind: int, pos: Vector2i) -> bool:
	if finished or kind<0 or kind>9 or reserve[kind]<=0 or not can_deploy(pos):return false
	reserve[kind]-=1;started=true
	units.append(combatant(kind,Vector2(pos),0))
	return true
func combatant(kind: int,pos: Vector2,team: int) -> Dictionary:
	var hp=float(Troops.HP[kind]);next_id+=1
	return {"eid":"u"+str(next_id),"entity":"unit","team":team,"kind":kind,"pos":pos,"hp":hp,"max_hp":hp,"cooldown":0.0,"think":0.0,"target":{},"path":PackedVector2Array(),"revision":-1,"windup":0.0,"pending_target":{},"moving":false,"climbing":0.0,"burn":0.0}
func route_to(unit: Dictionary, target: Dictionary) -> PackedVector2Array:
	var start=Vector2i(unit.pos.round());start=start.clamp(Vector2i.ZERO,Vector2i(15,15))
	var climb_cells=[]
	if unit.kind==3:
		for b in buildings:
			if b.kind=="wall" and b.hp>0:climb_cells.append(Vector2i(b.pos));grid.set_point_solid(Vector2i(b.pos),false)
	var was_solid=grid.is_point_solid(start);grid.set_point_solid(start,false)
	var best=PackedVector2Array()
	for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		var end=Vector2i(target.pos)+offset
		if not grid.region.has_point(end) or grid.is_point_solid(end):continue
		var path=grid.get_point_path(start,end)
		if not path.is_empty() and (best.is_empty() or path.size()<best.size()):best=path
	grid.set_point_solid(start,was_solid)
	for cell in climb_cells:grid.set_point_solid(cell,true)
	# A fractional position may already be past the rounded start cell. Do not
	# walk backwards to that cell every replan (slow units otherwise oscillate).
	if best.size()>1:
		var segment=best[1]-best[0];var offset: Vector2=unit.pos-best[0]
		if offset.dot(segment)>0 and absf(offset.cross(segment))<0.05:best.remove_at(0)
	return best
func choose_target(unit: Dictionary):
	var enemy_units=units if unit.get("team",0)==1 else defenders
	var living=enemy_units.filter(func(u):return u.hp>0)
	living.sort_custom(func(a,b):return unit.pos.distance_squared_to(a.pos)<unit.pos.distance_squared_to(b.pos))
	if not living.is_empty() and (unit.get("team",0)==1 or unit.kind==6 or unit.pos.distance_to(living[0].pos)<1.8):
		unit.target=living[0];unit.revision=revision;unit.path=route_to(unit,unit.target)
		if unit.path.is_empty() and not Troops.air(unit.kind) and unit.pos.distance_to(unit.target.pos)>Troops.reach(unit.kind):
			var closest=INF
			for wall in buildings:
				if wall.kind!="wall" or wall.hp<=0:continue
				var path=route_to(unit,wall);var score=path.size()+wall.pos.distance_to(living[0].pos)
				if not path.is_empty() and score<closest:closest=score;unit.target=wall;unit.path=path
		return
	if unit.get("team",0)==1:unit.target={};return
	var candidates=buildings.filter(func(b):return b.hp>0 and b.kind!="wall")
	if unit.kind==3:
		var stores=candidates.filter(func(b):return b.kind in ["tank","granary","crystal","spring","well","kitchen"])
		if not stores.is_empty():candidates=stores
	if unit.kind==2:
		var defenses=candidates.filter(func(b):return b.kind in ["tower","ward"] or (campaign_mode and Defenses.STATS.has(b.kind)))
		if not defenses.is_empty():candidates=defenses
	candidates.sort_custom(func(a,b):return unit.pos.distance_squared_to(a.pos)<unit.pos.distance_squared_to(b.pos))
	unit.target={};unit.path=PackedVector2Array();unit.revision=revision
	if candidates.is_empty():return
	if Troops.air(unit.kind):unit.target=candidates[0];return
	if unit.kind==7:
		unit.target=candidates[0]
		var direction: Vector2=(unit.target.pos-unit.pos).normalized();var nearest: float=unit.pos.distance_to(unit.target.pos)
		for obstacle in buildings:
			if obstacle.hp<=0:continue
			var offset: Vector2=obstacle.pos-unit.pos;var projection: float=offset.dot(direction)
			if projection>0.05 and projection<nearest and absf(offset.cross(direction))<0.78:unit.target=obstacle;nearest=projection
		return
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
func damage_target(target: Dictionary,amount: float):
	if target.get("entity","")=="unit":target.hp=maxf(0,target.hp-amount*(1.0-Troops.ARMOR[target.kind]))
	else:damage_building(target,amount)
func enemies(unit: Dictionary) -> Array:
	return units.filter(func(u):return u.hp>0) if unit.get("team",0)==1 else buildings.filter(func(b):return b.hp>0)+defenders.filter(func(u):return u.hp>0)
func resolve_skill(unit: Dictionary,target: Dictionary):
	if target.is_empty() or target.hp<=0:return
	var damage=float(Troops.DAMAGE[unit.kind]);var targets=enemies(unit)
	var direction: Vector2=(target.pos-unit.pos).normalized()
	match unit.kind:
		2:
			for victim in targets:
				var offset: Vector2=victim.pos-unit.pos
				if victim.eid==target.eid or (offset.length()<=3.4 and offset.normalized().dot(direction)>=0.80):damage_target(victim,damage);victim.burn=2.0
		3:
			damage_target(target,damage)
			if target.get("entity","")!="unit" and target.kind in ["tank","granary","crystal","spring","well","kitchen"]:
				var key="water" if target.kind in ["tank","well"] else "rice" if target.kind in ["granary","kitchen"] else "stone"
				var amount=mini(25,int(target.get("stock",0)));target.stock-=amount;stolen[key]+=amount
		5:
			var length: float=unit.pos.distance_to(target.pos)+1.4
			for victim in targets:
				var offset: Vector2=victim.pos-unit.pos
				if offset.dot(direction)>=0 and offset.dot(direction)<=length and absf(offset.cross(direction))<=0.6:damage_target(victim,damage)
		7,8:
			for victim in targets:
				if victim.pos.distance_to(target.pos)<=(1.05 if unit.kind==7 else 1.6):damage_target(victim,damage if victim.eid==target.eid else damage*0.65)
		9:
			var current=target;var hit=[]
			for jump in range(3):
				hit.append(current.eid);damage_target(current,damage*pow(0.8,jump))
				var next=targets.filter(func(v):return v.hp>0 and not v.eid in hit and v.pos.distance_to(current.pos)<=3)
				if next.is_empty():break
				next.sort_custom(func(a,b):return a.pos.distance_squared_to(current.pos)<b.pos.distance_squared_to(current.pos));current=next[0]
		_ :damage_target(target,damage)
func tick_unit(u: Dictionary,dt: float):
	u.moving=false;u.climbing=0.0
	if u.hp<=0:return
	u.cooldown-=dt;u.think-=dt
	if u.windup>0:
		u.windup-=dt
		if u.windup<=0:resolve_skill(u,u.pending_target)
		return
	if u.target.is_empty() or u.target.get("hp",0)<=0 or u.revision!=revision or u.think<=0:
		choose_target(u);u.think=0.35 if u.kind==6 or u.get("team",0)==1 else 1.2
	if u.target.is_empty():return
	if u.pos.distance_to(u.target.pos)<=Troops.reach(u.kind):
		if u.cooldown<=0:
			u.cooldown=Troops.COOLDOWN[u.kind]
			var shot={"from":u.pos,"to":u.target.pos,"kind":u.kind,"enemy":u.get("team",0)==1,"skill":Troops.SKILLS[u.kind],"source_height":2.4 if Troops.air(u.kind) else 0.0,"target_height":2.4 if u.target.get("entity","")=="unit" and Troops.air(u.target.kind) else 0.0}
			shot["guard" if u.get("team",0)==1 else "unit"]=(defenders if u.get("team",0)==1 else units).find(u);shots.append(shot)
			u.pending_target=u.target;u.windup=0.35 if u.kind!=7 else 0.55
	else:
		var destination: Vector2=u.target.pos
		if not Troops.air(u.kind) and u.kind!=7:
			while not u.path.is_empty() and u.pos.distance_to(u.path[0])<0.05:u.path.remove_at(0)
			if u.path.is_empty():return
			destination=u.path[0]
		u.moving=true;u.pos=u.pos.move_toward(destination,float(Troops.SPEED[u.kind])*dt)
		if u.kind==3:
			for b in buildings:
				if b.kind=="wall" and b.hp>0:u.climbing=maxf(u.climbing,maxf(0,1.0-u.pos.distance_to(b.pos)/0.8))
func step(dt: float):
	shots.clear()
	if not started or finished:return
	elapsed+=dt
	for target in buildings+units+defenders:
		if target.hp>0 and target.get("burn",0)>0:target.burn=maxf(0,target.burn-dt);damage_target(target,18*dt)
	for u in units:tick_unit(u,dt)
	for guard in defenders:tick_unit(guard,dt)
	if campaign_mode:tick_traps()
	for b in buildings:
		if campaign_mode:tick_campaign_defense(b,dt);continue
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
				if u.hp>0 and u.pos.distance_to(b.pos)<=4.2:damage_target(u,damage*(1.8 if Troops.air(u.kind) else 1.4))
		else:damage_target(target,damage)
	if percent()==100 or (not campaign_mode and elapsed>=180) or (reserve.reduce(func(a,b):return a+b,0)==0 and alive()==0):finished=true
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

func clear_targets():
	for u in units+defenders:u.target={};u.pending_target={}
