extends RefCounted
const Troops=preload("res://scripts/troops.gd")
var clocks: Array=[]
var bars: Array=[]
var finish_buttons: Array=[]
func build(game):
	clocks.clear();bars.clear();finish_buttons.clear()
	var side=game.side
	game.label(side,"แตะรูป +1 • ปุ่ม +5 • คิวแยกตามหอ",14)
	var halls=game.state.buildings.filter(func(b):return b.id=="barracks" and int(b.level)>0)
	if halls.is_empty():
		game.label(side,"สร้างหอฝึกนักสู้ให้เสร็จก่อน",18)
		game.button(side,"ไปก่อสร้าง",func():game.navigate("build");game.choose_build("barracks"));return
	if not halls.any(func(b):return str(b.get("uid",""))==game.production_hall):game.production_hall=str(halls[0].get("uid",""))
	var tabs=GridContainer.new();tabs.columns=3;side.add_child(tabs)
	var current: Dictionary={}
	for i in range(halls.size()):
		var hall=halls[i];var id=str(hall.get("uid",""));var count=game.state.jobs.filter(func(j):return str(j.get("producer",""))==id).size()
		var tab=game.button(tabs,"หอ %d • Lv.%d\nคิว %d" % [i+1,int(hall.level),count],game.open_production.bind(id));tab.tooltip_text="ปลดล็อกหอเพิ่มที่สำนักหลัก 1 / 3 / 5 / 7 / 9";tab.custom_minimum_size=Vector2(84,54);tab.add_theme_font_size_override("font_size",14)
		if id==game.production_hall:current=hall;tab.modulate=Color("91e6ff")
	var producer=game.production_hall
	var queue=game.state.jobs.filter(func(j):return str(j.get("producer",""))==producer)
	var paused=bool(current.get("training_paused",false))
	if not queue.is_empty():
		var active=queue[0]
		var clock=game.label(side,"",17);clocks.append({"node":clock,"job":active})
		var bar=ProgressBar.new();bar.custom_minimum_size=Vector2(270,18);side.add_child(bar);bars.append({"node":bar,"job":active})
		var controls=HBoxContainer.new();side.add_child(controls)
		var pause=game.button(controls,"ผลิตต่อ" if paused else "พักการผลิต",game.send.bind("train_resume" if paused else "train_pause",{"producer":producer}))
		pause.custom_minimum_size=Vector2(78,50);pause.add_theme_font_size_override("font_size",12)
		for scope in ["current","all"]:
			var cost=price(queue,scope,game.now_time(),paused)
			var boost=game.button(controls,("เสร็จตัวแรก" if scope=="current" else "เสร็จทั้งคิว")+"\n%d หยก" % cost,game.send.bind("boost_train",{"producer":producer,"scope":scope}))
			boost.custom_minimum_size=Vector2(84,50);boost.add_theme_font_size_override("font_size",12)
			finish_buttons.append({"node":boost,"queue":queue,"scope":scope,"paused":paused});boost.disabled=int(game.state.jade)<cost

	else:game.button(side,"ผลิตต่อ" if paused else "พักการผลิต",game.send.bind("train_resume" if paused else "train_pause",{"producer":producer}))
	var grid=GridContainer.new();grid.columns=2;side.add_child(grid)
	for kind in range(10):
		var box=VBoxContainer.new();grid.add_child(box)
		var amount=queue.filter(func(j):return int(j.type)==kind).size()
		var caption="%s\nมี %d • คิว %d\n+1 • %d วินาที" % [Troops.NAMES[kind],Troops.count(game.state.army,kind),amount,10*(kind+1)]
		if int(current.level)<kind+1:caption="%s\nปลดล็อกหอระดับ %d" % [Troops.NAMES[kind],kind+1]
		var produce=game.button(box,caption,game.enqueue_training.bind(producer,kind,1))
		var sheet=load("res://assets/realistic/"+Troops.ASSETS[kind]+".webp")
		var frame=AtlasTexture.new();frame.atlas=sheet;frame.region=Rect2(0,0,sheet.get_width()/4.0,sheet.get_height()/2.0)
		produce.icon=frame;produce.expand_icon=true;produce.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;produce.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP;produce.add_theme_constant_override("icon_max_width",68);produce.add_theme_font_size_override("font_size",14);produce.custom_minimum_size=Vector2(132,142)
		produce.tooltip_text=Troops.DETAILS[kind]
		produce.disabled=int(current.level)<kind+1 or game.building_level("training")<1 or game.army_total()+game.state.jobs.size()>=int(game.caps.get("army",10))
		game.label(box,"น้ำ %d / ข้าว %d\nโอสถ %d" % [Troops.WATER[kind],Troops.RICE[kind],Troops.ELIXIR[kind]],13)
		var bulk=game.button(box,"+5 เข้าคิว",game.enqueue_training.bind(producer,kind,5));bulk.add_theme_font_size_override("font_size",14);bulk.disabled=produce.disabled
	if not queue.is_empty():
		game.label(side,"คิวตามลำดับ • แตะยกเลิกเพื่อคืนทรัพยากร",14)
		for i in range(mini(8,queue.size())):
			var job=queue[i]
			game.button(side,"%d. %s   × ยกเลิก" % [i+1,Troops.NAMES[int(job.type)]],game.send.bind("train_cancel",{"producer":producer,"job":str(job.id)})).add_theme_font_size_override("font_size",15)
		if queue.size()>8:game.label(side,"และอีก %d หน่วย" % (queue.size()-8),14)
	var refund=game.state.get("train_refund",{})
	if not refund.is_empty():game.label(side,"ทรัพยากรคืนที่รอพื้นที่คลัง: น้ำ %d / ข้าว %d / โอสถ %d" % [refund.get("water",0),refund.get("rice",0),refund.get("stone",0)],14)
	update(game)
static func price(queue: Array,scope: String,now: float,paused: bool) -> int:
	var count=queue.size() if scope=="all" else 1
	var seconds=0.0
	if paused:
		for i in range(count):seconds+=float(queue[i].get("remaining",10*(int(queue[i].type)+1)))
	else:seconds=maxf(0,float(queue[count-1].finish)-now)
	return maxi(1,ceili(seconds/300.0))
func update(game):
	for entry in clocks:
		if not is_instance_valid(entry.node):continue
		var j=entry.job;var paused=bool(j.get("paused",false))
		var remaining=maxi(0,ceili(float(j.get("remaining",0)) if paused else float(j.finish)-game.now_time()))
		entry.node.text="%s • %s %d วินาที" % [Troops.NAMES[int(j.type)],"พัก เหลือ" if paused else "เหลือ",remaining]
	for entry in bars:
		if not is_instance_valid(entry.node):continue
		var j=entry.job;var duration=float(j.get("duration",10*(int(j.type)+1)))
		var remaining=float(j.get("remaining",duration)) if j.get("paused",false) else float(j.finish)-game.now_time()
		entry.node.value=100*clampf(1.0-remaining/duration,0,1)
	for entry in finish_buttons:
		if not is_instance_valid(entry.node):continue
		var cost=price(entry.queue,entry.scope,game.now_time(),entry.paused)
		entry.node.text=("เสร็จตัวแรก" if entry.scope=="current" else "เสร็จทั้งคิว")+"\n%d หยก" % cost
		entry.node.disabled=int(game.state.get("jade",0))<cost
