extends RefCounted
const NAMES=["นักดาบ","ขี่กระบี่","มังกร","ขโมย","เต่าเทพ","เซียนกระบี่","เสือเทพ","มนุษย์หิน","หงส์เพลิง","เทพ"]
const ASSETS=["fighter","flying","dragon","thief","turtle","sword_sage_red","tiger","stone_warrior","phoenix","deity"]
const POWER=[35,90,150,190,280,380,500,700,950,1300]
const HP=[190,140,700,220,1700,650,850,2200,2200,3600]
# Fraction of incoming damage blocked. Phoenix matches stone HP but has less armor than sage.
const ARMOR=[0.05,0.08,0.18,0.05,0.55,0.30,0.20,0.60,0.15,0.72]
const COOLDOWN=[0.8,1.1,1.8,0.65,2.1,1.3,0.7,1.8,1.6,2.2]
const SKILLS=["ฟันดาบ","กระบี่บิน","ลมหายใจเพลิง","ปีนกำแพงขโมยเสบียง","กระสุนปราณเต่า","คลื่นกระบี่สีชาด","ตะปบล่าเหยื่อ","ทุบปฐพี","ลูกไฟฟินิกซ์","อัสนีพิพากษา"]
const DETAILS=["ประชิด","โจมตีไกล ข้ามกำแพง","พ่นไฟเป็นกรวย เผาต่อเนื่อง","ปีนข้ามกำแพง เลือกคลังทรัพยากรก่อน","เดินช้า เกราะหนา ยิงก้อนพลัง","ชุดแดง มีรัศมี ยิงคลื่นดาบทะลุแนว","วิ่งเร็ว ไล่ล่านักรบทั้งพื้นและฟ้า","เกราะหนา ทุบสิ่งกีดขวางก่อนเดินต่อ","เลือดเท่าคนหิน เกราะต่ำกว่าเซียน ยิงลูกไฟระเบิด","ตัวใหญ่สองเท่า ลอยฟ้า สายฟ้าชิ่ง ทนทานสูงสุด"]
const DAMAGE=[30,43,65,75,85,130,155,190,240,330]
const SPEED=[1.3,1.7,1.4,2.2,0.55,1.6,2.8,0.65,1.8,1.2]
const WATER=[20,40,60,100,200,500,1000,2500,6000,15000]
const RICE=[30,60,90,150,300,750,1500,3750,9000,22500]
const ELIXIR=[0,8,20,40,80,200,400,1000,2400,6000]
const UPGRADE=[0,1000,5000,20000,75000,250000,750000,2000000,5000000,10000000]
static func count(army: Array,kind: int) -> int:return int(army[kind]) if kind<army.size() else 0
static func air(kind: int) -> bool:return kind in [1,2,8,9]
static func reach(kind: int) -> float:return [1.05,3.0,3.2,1.05,3.8,4.0,1.3,1.05,4.0,4.5][kind]
static func summary(army: Array) -> String:
	var parts=PackedStringArray()
	for i in range(10):
		if count(army,i)>0:parts.append(NAMES[i]+" "+str(count(army,i)))
	return " / ".join(parts) if not parts.is_empty() else "ไม่มี"
