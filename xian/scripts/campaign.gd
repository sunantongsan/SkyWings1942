extends RefCounted
# Versioned, deterministic campaign. Original layouts, no network or random seed.
const COUNT=90
const CHAPTERS=["ชายป่าไผ่","หุบเขาหิน","ด่านหมอกคราม","นครกลางน้ำ","ป้อมอัคคี","แดนพยัคฆ์","ภูผาเหล็ก","วังเมฆา","ยอดเขาเก้าสวรรค์"]
const TITLES=["ทางเข้าสำนัก","คลังริมทาง","ประตูสองด้าน","แนวป้องกันคู่","ลานซุ่มโจมตี","กำแพงซ้อน","สามป้อมประสาน","เขาวงกต","วงล้อมพิฆาต","เจ้าด่าน"]
const TIPS=["เริ่มจากอาคารรอบนอก แล้วบุกสำนักหลัก","แบ่งทหารเก็บคลังสองฝั่งก่อนเข้ากลาง","เลือกช่องทางเข้าที่ป้อมคุ้มกันน้อย","แบ่งแนวโจมตีเพื่อลดการยิงรวมเป้าหมาย","อย่าปล่อยทหารทั้งหมดรวมกันตรงจุดเดียว","โจรปีนกำแพงได้ และคนหินช่วยเปิดทาง","ส่งแนวหน้ารับการยิง ก่อนส่งหน่วยโจมตี","มองหาทางที่สั้นที่สุดไปยังสำนักหลัก","ทำลายป้อมเฉพาะทางก่อนส่งทหารที่แพ้ทาง","สำรวจทุกทิศและเก็บทหารสำรองไว้แก้สถานการณ์"]
# Distinct compartment geometry for ten encounters in each region.
const ROOMS=[[[5,5,10,10]],[[3,4,7,10],[9,5,12,11]],[[4,3,11,12]],[[3,3,7,7],[8,8,12,12]],[[3,3,12,12],[6,6,9,9]],[[3,3,12,12],[5,5,10,10]],[[3,3,7,7],[8,3,12,7],[5,8,10,12]],[[3,3,12,12]],[[3,3,12,12],[5,5,10,10]],[[3,3,7,7],[8,3,12,7],[3,8,7,12],[8,8,12,12]]]
static func stage(number: int) -> Dictionary:
	var n=clampi(number,1,COUNT);var chapter=int((n-1)/10);var encounter=(n-1)%10
	var data={"id":n,"chapter":chapter,"name":CHAPTERS[chapter]+" · "+TITLES[encounter],"tip":TIPS[encounter],"visual_level":chapter+1,"buildings":[],"traps":[],"guards":[],"reserve":army(chapter),"power":1.0+chapter*0.50+encounter*0.08}
	var occupied={};var walls={}
	for room in ROOMS[encounter]:
		for x in range(room[0],room[2]+1):
			for y in range(room[1],room[3]+1):
				if x==room[0] or x==room[2] or y==room[1] or y==room[3]:walls[Vector2i(x,y)]=true
	if encounter==7:
		for y in range(4,12):
			if y!=5:walls[Vector2i(6,y)]=true
			if y!=10:walls[Vector2i(9,y)]=true
	# Early entrances teach ground pathing; later encounters require breaches.
	if chapter<2 or encounter<3:
		for p in walls.keys():
			if p.x==7 or (chapter==0 and p.y==8):walls.erase(p)
	var hall=Vector2i(6+chapter%3,6+(encounter+chapter)%3)
	put(data,occupied,"hall",hall)
	var pool=[Vector2i(4,5),Vector2i(11,10),Vector2i(10,4),Vector2i(5,11),Vector2i(9,9),Vector2i(6,6),Vector2i(11,6),Vector2i(4,9),Vector2i(8,4),Vector2i(8,11),Vector2i(4,7),Vector2i(11,8)]
	var kinds=["cannon","tower"]
	if chapter>=1:kinds.append("mortar")
	if chapter>=2:kinds.append("air_defense")
	if chapter>=3:kinds.append("ward")
	if chapter>=4:kinds.append("flame")
	if chapter>=6:kinds.append("storm")
	var count=1+chapter+int(encounter/4)
	if n==1:count=1
	for i in range(mini(12,count)):
		var kind=kinds[(i+int(encounter/3))%kinds.size()]
		put(data,occupied,kind,pool[(i+chapter)%pool.size()])
	for i in range(4+int(chapter/3)):
		var positions=[Vector2i(2,5),Vector2i(13,10),Vector2i(6,13),Vector2i(9,2),Vector2i(2,11),Vector2i(12,2)]
		put(data,occupied,["tank","granary","crystal","spring"][i%4],positions[(i+encounter)%positions.size()])
	for p in occupied.keys():walls.erase(p)
	# First lesson is open; all other maps have a stable, inspectable wall layout.
	if n>1:
		for p in walls.keys():data.buildings.append({"kind":"wall","x":p.x,"y":p.y})
	var free=[]
	for x in range(4,12):
		for y in range(4,12):
			var p=Vector2i(x,y)
			if not occupied.has(p) and not walls.has(p):free.append(p)
	for i in range(mini(chapter+int(encounter/5),free.size())):
		var p=free[(i*7+encounter)%free.size()]
		if data.traps.any(func(t):return t.x==p.x and t.y==p.y):continue
		data.traps.append({"kind":"air_mine" if chapter>=3 and i%3==0 else "bomb","x":p.x,"y":p.y})
	if chapter>=2 and not free.is_empty():
		data.guards.append({"kind":0 if chapter<5 else 5,"x":free[0].x,"y":free[0].y})
	if chapter>=6 and free.size()>1:data.guards.append({"kind":6,"x":free[-1].x,"y":free[-1].y})
	# Rotate complete layouts, guards and traps together, never only the buildings.
	for entry in data.buildings+data.traps+data.guards:
		for turn in range((chapter+encounter)%4):
			var old_x=entry.x;entry.x=15-entry.y;entry.y=old_x
	return data
static func put(data: Dictionary,occupied: Dictionary,kind: String,pos: Vector2i):
	while occupied.has(pos):pos.x=3+(pos.x-2)%10
	occupied[pos]=true;data.buildings.append({"kind":kind,"x":pos.x,"y":pos.y})
static func army(chapter: int) -> Array:
	var reserves=[12+chapter,4+chapter,0,0,0,0,0,0,0,0]
	if chapter>=1:reserves[2]=2
	if chapter>=2:reserves[3]=4
	if chapter>=3:reserves[4]=2
	if chapter>=4:reserves[5]=2
	if chapter>=5:reserves[6]=2
	if chapter>=6:reserves[7]=2
	if chapter>=7:reserves[8]=1
	if chapter>=8:reserves[9]=1
	return reserves
