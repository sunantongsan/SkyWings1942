extends RefCounted
const NAMES=["นักดาบ","ขี่กระบี่","มังกร","ขโมย","เต่าเทพ","เซียนกระบี่","เสือเทพ","มนุษย์หิน","หงส์เพลิง","เทพ"]
const ASSETS=["fighter","flying","dragon","thief","turtle","sword_sage","tiger","stone_warrior","phoenix","deity"]
const POWER=[35,90,150,190,280,380,500,700,950,1300]
const HP=[190,140,440,160,1000,300,600,1500,550,1200]
const DAMAGE=[30,43,65,75,85,130,155,190,240,330]
const SPEED=[1.3,1.7,1.4,2.2,0.75,1.6,2.0,0.85,1.8,1.5]
const WATER=[20,40,60,100,200,500,1000,2500,6000,15000]
const RICE=[30,60,90,150,300,750,1500,3750,9000,22500]
const ELIXIR=[0,8,20,40,80,200,400,1000,2400,6000]
const UPGRADE=[0,1000,5000,20000,75000,250000,750000,2000000,5000000,10000000]
static func count(army: Array,kind: int) -> int:return int(army[kind]) if kind<army.size() else 0
static func air(kind: int) -> bool:return kind in [1,2,8,9]
static func reach(kind: int) -> float:return 3.0 if kind in [1,5,8,9] else 1.05
static func summary(army: Array) -> String:
	var parts=PackedStringArray()
	for i in range(10):
		if count(army,i)>0:parts.append(NAMES[i]+" "+str(count(army,i)))
	return " / ".join(parts) if not parts.is_empty() else "ไม่มี"
