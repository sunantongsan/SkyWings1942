extends RefCounted
## Deterministic offline campaign. Stage indices are independent of homeworlds.
const COUNT:=50
const TIERS:=["FRONTIER", "CONTESTED", "HARD", "ELITE", "LEGENDARY"]
const NAMES:=["Scout Post", "Supply Depot", "Mining Station", "Patrol Base", "Relay Fort", "Foundry", "Air Command", "Defense Grid", "Stronghold", "Sector Citadel"]
const POSITIONS:=[Vector3(0,0,-5),Vector3(-8,0,-1),Vector3(8,0,-1),Vector3(-5,0,6),Vector3(5,0,6),Vector3(-12,0,7),Vector3(12,0,7),Vector3(-12,0,-9),Vector3(12,0,-9),Vector3(-6,0,-10),Vector3(6,0,-10),Vector3(0,0,7)]

static func stage(index:int)->Dictionary:
	assert(index>=0 and index<COUNT)
	var number:=index+1
	var tier:=index/10
	var count:=3+index/5
	var fantasy:=tier in [2,4]
	var level:=1+index/6
	var health:=300.0+index*22.0+index*index*.3
	var types:Array[int]=[14 if fantasy else 0,17 if fantasy else 8,15 if fantasy else 2]
	for i in range(3,count):types.append((17 if fantasy else (11 if index>=20 and i%3==0 else 8)) if i%2==1 else (16 if fantasy else 6))
	var structures:Array[Dictionary]=[]
	for i in count:
		var pos:Vector3=POSITIONS[i]
		# Mirror sectors without moving any structure into the deployment zone.
		if tier%2==1:pos.x=-pos.x
		structures.append({"type":types[i],"pos":pos,"level":level,"hp":health,"shot_damage":(2.5+index*.55)*(2.0/1.2 if types[i]==11 else 1.0)})
	var coin_bonus:=0 if number<21 else 1+(number-21)/10
	if number>=30 and number%10==0:coin_bonus+=2
	return {"index":index,"number":number,"name":"%02d • %s"%[number,NAMES[index%10]],"tier":TIERS[tier],"theme":(index*7)%15,"structures":structures,"difficulty":number,"recommended":8+index*2,"reward":{"credits":1800+index*320,"metal":900+index*180,"oil":700+index*100,"crystal":100+index*45,"gold":30+index*12,"coins":coin_bonus}}

static func reward(index:int,cleared:int)->Dictionary:
	var result:Dictionary=stage(index).reward.duplicate()
	if index<cleared:result.coins=0
	return result

static func reward_text(value:Dictionary)->String:
	return "%d Credits   •   %d Metal   •   %d Oil\n%d Crystal   •   %d Gold   •   %d GODOT Coin"%[value.get("credits",0),value.get("metal",0),value.get("oil",0),value.get("crystal",0),value.get("gold",0),value.get("coins",0)]
