extends RefCounted
## Deterministic offline campaign. Stage indices are independent of homeworlds.
const COUNT:=50
const DIFFICULTY_MULTIPLIER:=1.5
const TIERS:=["FRONTIER", "CONTESTED", "HARD", "ELITE", "LEGENDARY"]
const NAMES:=["Scout Post", "Supply Depot", "Mining Station", "Patrol Base", "Relay Fort", "Foundry", "Air Command", "Defense Grid", "Stronghold", "Sector Citadel"]
const POSITIONS:=[Vector3(-3.5,0,0),Vector3(-10.5,0,0),Vector3(3.5,0,0),Vector3(-10.5,0,-7),Vector3(-3.5,0,-7),Vector3(10.5,0,-7),Vector3(-10.5,0,7),Vector3(3.5,0,7),Vector3(10.5,0,7)]

static func stage(index:int)->Dictionary:
	assert(index>=0 and index<COUNT)
	var number:=index+1
	var tier:=index/10
	var count:=mini(9,3+index/7)
	var fantasy:=tier in [2,4]
	var level:=1+index/6
	var health:=(300.0+index*22.0+index*index*.3)*DIFFICULTY_MULTIPLIER
	var types:Array[int]=[14 if fantasy else 0,17 if fantasy else 8,15 if fantasy else 2]
	for i in range(3,count):types.append((17 if fantasy else (11 if index>=20 and i%3==0 else 8)) if i%2==1 else (16 if fantasy else 6))
	var structures:Array[Dictionary]=[]
	for i in count:
		var pos:Vector3=POSITIONS[i]
		structures.append({"type":types[i],"pos":pos,"level":level,"hp":health,"shot_damage":DIFFICULTY_MULTIPLIER*(2.5+index*.55)*(2.0/1.2 if types[i]==11 else 1.0)})
	# Complete a front barrier first, then the rear and flanks. Slots are reserved
	# for weapons: no guns buried in resource buildings or wall segments.
	var perimeter:Array[Dictionary]=[]
	for z in [12,-12]:
		for x in [-6,0,6,-12,12]:perimeter.append({"pos":Vector3(x,0,z),"yaw":0.0})
	for x in [-15,15]:
		for z in [-9,-3,3,9]:perimeter.append({"pos":Vector3(x,0,z),"yaw":PI/2})
	for i in mini(18,2+index/2):
		structures.append({"type":24,"pos":perimeter[i].pos,"yaw":perimeter[i].yaw,"level":mini(5,1+tier),"hp":health*(.7+tier*.2),"shot_damage":2.0+index*.5})
	if index>=4:
		structures.append({"type":21,"pos":Vector3(-3.5,0,7),"level":level,"hp":health*1.25,"shot_damage":5.0+index*.6})
	if index>=9:
		structures.append({"type":22,"pos":Vector3(3.5,0,-7),"level":level,"hp":health*1.4,"shot_damage":20.0+index*2.0})
	if index>=14:
		structures.append({"type":23,"pos":Vector3(10.5,0,0),"level":level,"hp":health*1.4,"shot_damage":10.0+index})
	if tier%2==1:
		for entry in structures:entry.pos.z=-entry.pos.z
	var coin_bonus:=5+index*2+(10 if number%10==0 else 0)
	return {"index":index,"number":number,"name":"%02d • %s"%[number,NAMES[index%10]],"tier":TIERS[tier],"theme":(index*7)%15,"structures":structures,"difficulty":number,"recommended":ceili((8+index*2)*DIFFICULTY_MULTIPLIER),"reward":{"credits":1800+index*320,"metal":900+index*180,"oil":700+index*100,"crystal":100+index*45,"gold":30+index*12,"coins":coin_bonus}}

static func reward(index:int,_cleared:int)->Dictionary:
	var result:Dictionary=stage(index).reward.duplicate()
	return result

static func reward_text(value:Dictionary)->String:
	return "%d Credits   •   %d Metal   •   %d Oil\n%d Crystal   •   %d Gold   •   %d GODOT Coin"%[value.get("credits",0),value.get("metal",0),value.get("oil",0),value.get("crystal",0),value.get("gold",0),value.get("coins",0)]
