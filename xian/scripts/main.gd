extends Node3D
const Art = preload("res://scripts/art.gd")
const API = preload("res://scripts/api.gd")
var art = Art.new()
var api: Node
var state: Dictionary = {}
var catalog: Array = []
var caps: Dictionary = {}
var world: Node3D
var terrain: Node3D
var camera: Camera3D
var ui: Control
var side: VBoxContainer
var toast: Label
var top: Label
var clock_label: Label
var modal: PanelContainer
var mode = "login"
var chosen_map = "bamboo"
var chosen_build = ""
var selected = -1
var moving = false
var match_pick = -1
var server_time = 0.0
var since_sync = 0.0
var poll = 0.0
var actors: Array = []
var pan_start = Vector2.ZERO
var dragging = false
var pivot = Vector3.ZERO
var last_buildings = ""
var map_drawn = ""
var battle_visual = false
var battle_nodes: Array = []
var auth_status: Label
var auth_controls: Array[Control] = []
var auth_signup = false
var sidebar_scroll: ScrollContainer
var menu_touch = -1
var menu_start = Vector2.ZERO
var menu_start_scroll = 0.0
var menu_scrolling = false
var menu_button: Button
var menu_velocity = 0.0
var menu_scroll_value = 0.0
var menu_last_time = 0.0
var fingers: Dictionary = {}
var pinching = false
var card_origin = Vector2.ZERO
var card_kind = ""
var card_drag = false
var build_cards: Array = []
var preview: Node3D
var preview_tile: MeshInstance3D
var preview_model: Node3D
var preview_cell = Vector2i(-1,-1)
var preview_ok = false
var placement_drag = false
var font = preload("res://assets/NotoSansThai.ttf")

func _ready():
	Engine.max_fps = 30
	api = API.new(); add_child(api)
	api.updated.connect(receive)
	api.failed.connect(message)
	api.auth_notice.connect(message)
	api.auth_working.connect(auth_loading)
	api.authenticated.connect(func(): message("เชื่อมต่อแล้ว กำลังเปิดสำนัก…"))
	var light = DirectionalLight3D.new(); light.rotation_degrees = Vector3(-55,-35,0); light.light_energy = 1.2; add_child(light)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color("aec7bf")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color("d9e4dc"); e.ambient_light_energy = 0.75
	env.environment=e; add_child(env)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size=48; camera.far=300; add_child(camera)
	position_camera()
	terrain=Node3D.new(); add_child(terrain)
	world=Node3D.new(); add_child(world)
	var layer=CanvasLayer.new(); add_child(layer)
	ui=Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(ui)
	var theme=Theme.new();theme.default_font=font;theme.default_font_size=18
	for name in ["normal","hover","pressed","disabled"]:
		var st=StyleBoxFlat.new(); st.bg_color=Color("214c45") if name=="normal" else Color("376b5e")
		if name=="disabled":st.bg_color=Color("3d4844")
		st.set_corner_radius_all(9); st.set_content_margin_all(10)
		st.border_color=Color("b49a62");st.set_border_width_all(1);theme.set_stylebox(name,"Button",st)
	theme.set_color("font_color","Label",Color("f3e7c8"));ui.theme=theme
	var header=panel(Vector2(16,12),Vector2(1248,66));top=label(header,"XIAN OF CLANS   •   เซียน ออฟ แคลน",24)
	var sidebar=panel(Vector2(960,92),Vector2(304,530))
	var scroll=ScrollContainer.new();sidebar_scroll=scroll;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.scroll_deadzone=12;sidebar.add_child(scroll)
	side=VBoxContainer.new();side.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(side)
	var footer=panel(Vector2(16,634),Vector2(1248,70));var row=HBoxContainer.new();footer.add_child(row)
	for pair in [["สำนัก","home"],["ก่อสร้าง","build"],["ฝึกศิษย์","train"],["บุกสำนัก","raid"],["จับคู่ฝึกปราณ","match"],["หยก / เช็กอิน","jade"]]:
		button(row,pair[0],navigate.bind(pair[1]))
	button(row,"−",zoom.bind(5.0));button(row,"+",zoom.bind(-5.0))
	toast=Label.new();toast.position=Vector2(28,588);toast.size=Vector2(915,42);toast.add_theme_color_override("font_color",Color("ffe7a5"));toast.add_theme_color_override("font_shadow_color",Color.BLACK);toast.add_theme_constant_override("shadow_offset_x",2);toast.add_theme_constant_override("shadow_offset_y",2);ui.add_child(toast)
	draw_terrain("bamboo")
	show_login()
	if not api.refresh_token.is_empty(): api.resume()

func panel(pos: Vector2, extent: Vector2) -> PanelContainer:
	var p=PanelContainer.new();p.position=pos;p.size=extent
	var st=StyleBoxFlat.new();st.bg_color=Color(0.055,0.12,0.115,0.96);st.set_corner_radius_all(12);st.border_color=Color("9c8c59");st.set_border_width_all(1);st.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel",st);ui.add_child(p);return p
func label(parent: Node, text: String, size=18) -> Label:
	var l=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func button(parent: Node, text: String, callback: Callable) -> Button:
	var b=Button.new();b.mouse_filter=Control.MOUSE_FILTER_PASS;b.text=text;b.custom_minimum_size=Vector2(0,46);b.pressed.connect(callback);parent.add_child(b);return b
func clear(node: Node):
	for child in node.get_children():node.remove_child(child);child.queue_free()
func message(text: String):
	toast.text=text
	if mode=="login" and is_instance_valid(auth_status): auth_status.text=text
func close_modal():
	if is_instance_valid(modal):modal.queue_free();modal=null
func modal_box(pos=Vector2(300,112),extent=Vector2(600,475)) -> VBoxContainer:
	close_modal();modal=panel(pos,extent);var box=VBoxContainer.new();box.add_theme_constant_override("separation",10);modal.add_child(box);return box
func auth_loading(active: bool):
	for control in auth_controls:
		if not is_instance_valid(control): continue
		if control is Button: control.disabled=active
		if control is LineEdit: control.editable=not active
	if active: message("กำลังติดต่อระบบบัญชี… กรุณารอไม่เกิน 25 วินาที")
func show_login(saved_email = ""):
	mode="login"
	auth_controls.clear()
	var box=modal_box(Vector2(270,82),Vector2(740,547))
	box.add_theme_constant_override("separation",6)
	label(box,"XIAN OF CLANS",30)
	label(box,"สมัครบัญชีใหม่" if auth_signup else "เข้าสู่ระบบ • ใช้บัญชีอีเมลเดิมจากวิถีเซียนได้",20)
	var email=LineEdit.new();email.placeholder_text="อีเมล เช่น name@example.com";email.text=saved_email;email.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS;email.custom_minimum_size.y=46;box.add_child(email)
	var password=LineEdit.new();password.placeholder_text="รหัสผ่าน";password.secret=true;password.custom_minimum_size.y=46;box.add_child(password)
	var confirm=LineEdit.new();confirm.placeholder_text="ยืนยันรหัสผ่าน (อย่างน้อย 8 ตัวอักษร)";confirm.secret=true;confirm.custom_minimum_size.y=46;box.add_child(confirm);confirm.visible=auth_signup
	auth_controls.append_array([email,password,confirm])
	auth_status=label(box,"กรอกอีเมลและรหัสผ่านเพื่อเริ่มต้น",17)
	auth_status.custom_minimum_size.y=62
	auth_status.add_theme_color_override("font_color",Color("ffe7a5"))
	var submit=func():
		if auth_signup and password.text != confirm.text: message("รหัสผ่านทั้งสองช่องไม่ตรงกัน"); return
		api.login(email.text,password.text,auth_signup)
	auth_controls.append(button(box,"สมัครบัญชี" if auth_signup else "เข้าสู่ระบบ",submit))
	password.text_submitted.connect(func(_value): submit.call())
	confirm.text_submitted.connect(func(_value): submit.call())
	auth_controls.append(button(box,"มีบัญชีแล้ว • กลับเข้าสู่ระบบ" if auth_signup else "ยังไม่มีบัญชี • สมัครใหม่",func():auth_signup=not auth_signup;show_login(email.text)))
	auth_controls.append(button(box,"เข้าสู่ระบบด้วย Google",func():api.google_login()))
	auth_controls.append(button(box,"ส่งอีเมลยืนยันอีกครั้ง",func():api.resend_confirmation(email.text)))
	label(box,"หลังยืนยันอีเมล ให้กลับมาเข้าสู่ระบบในเกม • ต้องเชื่อมต่ออินเทอร์เน็ต",15)
func show_create():
	if mode=="create":return
	mode="create"
	var box=modal_box()
	label(box,"ตั้งสำนักของคุณ",30)
	var entry=LineEdit.new();entry.placeholder_text="ชื่อสำนัก 2–24 ตัวอักษร";entry.max_length=24;entry.custom_minimum_size.y=50;box.add_child(entry)
	label(box,"เลือกทำเล • ทั้งสองแห่งมีพื้นที่สร้างเท่ากัน")
	button(box,"ป่าไผ่ — ลานหญ้าและป่าเขียว",func():chosen_map="bamboo";draw_terrain(chosen_map);message("เลือกทำเลป่าไผ่"))
	button(box,"ยอดเขา — ลานหินและทะเลหมอก",func():chosen_map="mountain";draw_terrain(chosen_map);message("เลือกทำเลยอดเขา"))
	button(box,"ก่อตั้งสำนัก",func():api.action("create",{"name":entry.text.strip_edges(),"map":chosen_map}))
func receive(payload: Dictionary):
	server_time=float(payload.get("server_time",0));since_sync=0
	catalog=payload.get("catalog",[])
	if payload.get("needs_create",false):show_create();return
	state=payload.get("state",{});caps=payload.get("capacity",{})
	if mode in ["login","create"]:close_modal();mode="home"
	if state.has("raid"):mode="raid"
	if map_drawn!=state.get("map","bamboo"):draw_terrain(state.get("map","bamboo"))
	var encoded=JSON.stringify(state.get("buildings",[]))+str(int(float(state.get("water",0))/maxf(1,float(caps.get("water",1000)))*10))+str(int(float(state.get("rice",0))/maxf(1,float(caps.get("rice",1000)))*10))+str(int(float(state.get("stone",0))/maxf(1,float(caps.get("stone",100)))*10))
	if encoded!=last_buildings and not battle_visual:
		last_buildings=encoded;draw_base()
	if mode=="raid" and state.has("raid") and not battle_visual:draw_battle()
	elif battle_visual and (mode!="raid" or not state.has("raid")):battle_visual=false;draw_base()
	update_top();show_side()
	if mode=="match":show_match()
	message("บันทึกออนไลน์แล้ว")
func now_time() -> float:return server_time+since_sync
func update_top():
	if state.is_empty():return
	top.text="%s  |  น้ำ %d/%d   ข้าว %d/%d   หิน %d/%d   หยก %d" % [state.name,int(state.water),int(caps.get("water",1000)),int(state.rice),int(caps.get("rice",1000)),int(state.stone),int(caps.get("stone",100)),int(state.jade)]
func navigate(target: String):
	if state.is_empty():message("กรุณาเข้าสู่ระบบและตั้งสำนักก่อน");return
	if api.busy:return
	if battle_visual and target!="raid":battle_visual=false;draw_base()
	mode=target;chosen_build="";moving=false;clear_preview();close_modal()
	if target=="match":api.action("match_start")
	elif target=="raid" and not state.has("raid"):api.action("scout")
	elif target=="raid" and state.has("raid"):draw_battle();show_side()
	else:show_side()
func show_side():
	build_cards.clear()
	clear(side)
	label(side,"XIAN OF CLANS",23)
	if state.is_empty():label(side,"เริ่มต้นตำนานสำนักของคุณ");return
	label(side,"ช่างว่าง %d/%d • ศิษย์ %d/%d" % [int(caps.get("workers",1))-int(caps.get("busy",0)),int(caps.get("workers",1)),army_total(),int(caps.get("army",10))],16)
	match mode:
		"build":
			label(side,"เลื่อนขึ้นลงเพื่อเลือก\nลากรูปอาคารออกมาวางบนพื้น",20)
			button(side,"ยกเลิกการวาง",func():chosen_build="";clear_preview())
			for c in catalog:
				var card=button(side,"%s\nน้ำ %d ข้าว %d\nหิน %d • %d วิ" % [c.name,c.water,c.rice,c.stone,c.seconds],choose_build.bind(c.id))
				card.icon=building_icon(c.id);card.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT;card.expand_icon=true;card.add_theme_constant_override("icon_max_width",76);card.custom_minimum_size=Vector2(272,100)
				build_cards.append({"node":card,"kind":c.id})
		"train":
			label(side,"ฝึกกองกำลัง",25)
			var portrait=TextureRect.new();portrait.texture=load("res://assets/disciple-reference.jpg");portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(240,125);side.add_child(portrait)
			var names=["ศิษย์ชั้นต้น","ศิษย์ฝึกปราณ","พยัคฆ์วิญญาณ"]
			for i in range(3):
				label(side,"%s: %d คน" % [names[i],int(state.army[i])])
				button(side,"ฝึก • น้ำ %d ข้าว %d หิน %d" % [20*(i+1),30*(i+1),[0,8,20][i]],send.bind("train",{"type":i}))
			label(side,"คิวฝึก: %d คน\nขั้นต้น 10 วิ • ฝึกปราณ 20 วิ\nสัตว์เทวะ 30 วิ" % state.jobs.size())
			label(side,"ฝึกปราณ: สำนัก 2 / โรงฝึก 1\nสัตว์เทวะ: สำนัก 3 / โรงฝึก 2",15)
		"jade":
			label(side,"หยกเซียน",26)
			label(side,"เช็กอิน +5 หยก\nสะสมครบ 7 ครั้ง รับ +20")
			button(side,"รับรางวัลเช็กอิน",send.bind("checkin",{}))
			for pair in [["น้ำ 250","water"],["ข้าว 250","rice"],["หินวิญญาณ 25","stone"]]:button(side,"5 หยก → "+pair[0],send.bind("exchange",{"resource":pair[1]}))
			label(side,"หยกถูกปล้นไม่ได้\nยังไม่เปิดขายเงินจริง",16)
		"raid":show_raid()
		_:
			if selected>=0 and selected<state.buildings.size():
				var b=state.buildings[selected];var c=find_catalog(b.id)
				var portrait=TextureRect.new();portrait.texture=building_icon(b.id);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(180,140);side.add_child(portrait)
				label(side,c.get("name",b.id),26)
				label(side,"ระดับ %d" % int(b.level))
				clock_label=label(side,remaining(b.finish))
				if float(b.finish)>now_time():
					button(side,"เสร็จทันที • %d หยก" % ceili((float(b.finish)-now_time())/300),send.bind("boost",{"index":selected}))
				else:
					label(side,"อัปเกรด: น้ำ %d / ข้าว %d / หิน %d" % [int(c.water*pow(2,b.level)),int(c.rice*pow(2,b.level)),int(c.stone*pow(2,b.level))],16)
					button(side,"อัปเกรด",send.bind("upgrade",{"index":selected}))
				button(side,"ย้ายอาคาร",func():moving=true;message("ลากบนพื้นไปยังช่องสีเขียว แล้วปล่อยเพื่อย้าย"))
			else:
				label(side,"สำนักของคุณ",27)
				label(side,"1. สร้างบ่อน้ำและโรงอาหาร\n2. สร้างโกดังเพิ่มความจุ\n3. รับศิษย์และบุกสำนัก\n4. เล่นจับคู่ระหว่างรอ",20)
				label(side,"แตะอาคารเพื่อดู / อัปเกรด\nลากพื้นเพื่อเลื่อนมุมมอง",16)
			if state.has("last_defense"):
				var d=state.last_defense
				label(side,"ถูกบุกโดย %s\nเสียน้ำ %d ข้าว %d หิน %d" % [d.attacker,d.water,d.rice,d.stone],16)
			button(side,"อัปเดตข้อมูล",send.bind("sync",{}))
func send(action: String,args: Dictionary):api.action(action,args)
func building_icon(kind: String) -> Texture2D:
	return load("res://assets/buildings/"+kind+".png")
func choose_build(kind: String):
	chosen_build=kind;moving=false;clear_preview()
	message("ลากบนพื้นเพื่อวาง "+find_catalog(kind).get("name",kind)+" • เขียว: วางได้ / แดง: วางไม่ได้")
func find_catalog(kind: String) -> Dictionary:
	for c in catalog:
		if c.id==kind:return c
	return {}
func army_total() -> int:
	var total=0
	for n in state.get("army",[]):total+=int(n)
	return total
func remaining(timestamp) -> String:
	var seconds=maxi(0,int(float(timestamp)-now_time()))
	return "พร้อมใช้งาน" if seconds==0 else "กำลังก่อสร้าง • %d:%02d" % [seconds/60,seconds%60]
func show_raid():
	label(side,"บุกสำนัก",25)
	if state.has("raid"):
		var r=state.raid
		label(side,r.enemy.name)
		clock_label=label(side,"การต่อสู้อัตโนมัติ • %d วิ" % maxi(0,int(r.finish-now_time())))
		label(side,"ส่งศิษย์ %d / %d / %d\nผลคำนวณโดยเซิร์ฟเวอร์" % [r.army[0],r.army[1],r.army[2]],16)
		button(side,"จบการบุก / รับของ",send.bind("raid_claim",{}))
	elif state.has("scout"):
		var s=state.scout
		label(side,s.name,22)
		label(side,("สำนักผู้เล่น" if s.has("player") else "สำนักบอท")+" • ระดับ %d\nพลังป้องกัน %d\nน้ำ %d ข้าว %d หิน %d" % [s.level,s.defense,s.water,s.rice,s.stone])
		label(side,"ส่งกองกำลังทั้งหมด\nหน่วยที่ส่งจะใช้ไปในการบุก",16)
		button(side,"เริ่มบุก (25 วินาที)",send.bind("raid_start",{}))
		button(side,"ค้นหาสำนักผู้เล่น",send.bind("scout",{"mode":"player"}))
		button(side,"ค้นหาสำนักบอท",send.bind("scout",{}))
		label(side,"เริ่มบุกแล้วโล่คุ้มครองจะหมด\nโกดังถูกปล้นได้บางส่วน หยกปลอดภัย",15)
	if state.has("last_raid"):
		label(side,"ผลล่าสุด: %d ดาว" % state.last_raid.stars,22)
func show_match():
	if not state.has("match"):return
	var m=state.match
	var box=modal_box(Vector2(260,88),Vector2(660,532))
	label(box,"ค่ายกลฝึกปราณ • ด่าน %d" % int(state.match_level),24)
	label(box,"คะแนน %d / %d    เหลือ %d เดิน" % [m.score,m.goal,m.moves],20)
	var grid=GridContainer.new();grid.columns=8;grid.add_theme_constant_override("h_separation",5);grid.add_theme_constant_override("v_separation",4);box.add_child(grid)
	var colors=["418d9b","aa8251","9971a6","488e62","b95d57"]
	var symbols=["น้ำ","ตำรา","หิน","หยก","ยา"]
	for i in range(64):
		var v=int(m.board[i]);var tile=button(grid,symbols[v],pick_match.bind(i));tile.custom_minimum_size=Vector2(72,36);tile.add_theme_font_size_override("font_size",16)
		var st=StyleBoxFlat.new();st.bg_color=Color(colors[v]);st.set_content_margin_all(4);st.set_corner_radius_all(8);st.set_border_width_all(3 if i==match_pick else 1);st.border_color=Color("fff0ab");tile.add_theme_stylebox_override("normal",st)
		if int(m.moves)<=0:tile.disabled=true
	if int(m.moves)<=0:
		label(box,("ผ่านด่าน! รับน้ำ 100 ข้าว 100 และหยก 2" if m.get("paid",false) else "ผ่านด่าน! วันนี้รับรางวัลครบ 10 ด่านแล้ว") if m.get("rewarded",false) else "หมดจำนวนเดิน ลองใหม่ได้ครับ",18)
		button(box,"ด่านต่อไป / ลองอีกครั้ง",send.bind("match_start",{}))
	else:label(box,"แตะ 2 ช่องติดกันเพื่อสลับให้เรียง 3 ชิ้น • รางวัลสูงสุด 10 ด่านต่อวัน",15)
	var row=HBoxContainer.new();box.add_child(row)
	button(row,"กลับสำนัก",navigate.bind("home"))
	if int(m.moves)>0:button(row,"สับกระดาน −1 เดิน",send.bind("match_shuffle",{}))
	var ad=button(row,"โฆษณารับหยก • ยังไม่เปิด",func():pass);ad.disabled=true
func pick_match(i: int):
	if api.busy:return
	if match_pick<0:match_pick=i;show_match();return
	var a=match_pick;match_pick=-1
	if a==i:show_match();return
	api.action("match_swap",{"a":a,"b":i})
func cell_pos(x: float,y: float) -> Vector3:return Vector3((x-7.5)*3,0,(y-7.5)*3)
func draw_terrain(kind: String):
	map_drawn=kind;clear(terrain)
	var mountain=kind=="mountain"
	art.box(terrain,Vector3(0,-0.15,0),Vector3(160,0.3,160),"a4aaa0" if mountain else "728854")
	for x in range(16):
		for y in range(16):
			art.box(terrain,cell_pos(x,y)+Vector3(0,0.002,0),Vector3(3,0.004,3),("a3a99e" if (x+y)%2==0 else "9da598") if mountain else ("8b9c68" if (x+y)%2==0 else "859862"))
	var rng=RandomNumberGenerator.new();rng.seed=421
	for i in range(70):
		var angle=rng.randf()*TAU;var radius=rng.randf_range(34,43);var p=Vector3(cos(angle)*radius,0,sin(angle)*radius)
		if mountain:
			art.cone(terrain,p-Vector3(0,5,0),rng.randf_range(4,9),0,rng.randf_range(8,22),"718c87",5)
		else:
			for j in range(3):
				var at=p+Vector3(j*0.6,0,j*0.3)
				art.cone(terrain,at+Vector3(0,3,0),0.1,0.08,6,"426b39",5)
				for h in [2.0,3.4,4.7]:
					art.cone(terrain,at+Vector3(0,h,0),0.12,0.12,0.07,"98ad6a",5)
					for leaf_i in range(3):
						var leaf=art.cone(terrain,at+Vector3(cos(leaf_i*2.1)*0.55,h+0.3,sin(leaf_i*2.1)*0.55),0.26,0,1.6,"48794a",4)
						leaf.rotation_degrees=Vector3(50,leaf_i*120,35)
func draw_base():
	clear(world);actors=[]
	for b in state.get("buildings",[]):
		var resource={"tank":"water","granary":"rice","crystal":"stone"}.get(b.id,"")
		var fill=float(state.get(resource,0))/maxf(1,float(caps.get(resource,1000)))
		var model=art.building(b.id,int(b.level),fill);model.position=cell_pos(b.x,b.y);world.add_child(model)
		var body=StaticBody3D.new();body.set_meta("index",state.buildings.find(b));model.add_child(body)
		var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(2.6,3.4,2.6);collision.shape=shape;collision.position.y=1.7;body.add_child(collision)
		if float(b.finish)>now_time():
			art.box(model,Vector3(0,0.4,1.25),Vector3(2.5,0.2,0.12),"deb264")
			var worker=art.person(0);world.add_child(worker);actors.append({"node":worker,"from":cell_pos(5,7),"to":model.position+Vector3(1.1,0,1.1),"phase":actors.size(),"kind":0})
		if b.id in ["well","kitchen","spring"] and int(b.level)>0:
			var target={"well":"tank","kitchen":"granary","spring":"crystal"}[b.id]
			for storage in state.buildings:
				if storage.id==target and int(storage.level)>0:
					var person=art.person(0);world.add_child(person)
					art.box(person,Vector3(0.4,0.65,0),Vector3(0.35,0.4,0.35),"62b4c1" if b.id=="well" else "d2bb79")
					actors.append({"node":person,"from":model.position+Vector3(1,0,0),"to":cell_pos(storage.x,storage.y)+Vector3(1,0,0),"phase":actors.size(),"kind":0});break
	for kind in range(3):
		for i in range(mini(8,int(state.army[kind]))):
			var person=art.person(kind);world.add_child(person)
			actors.append({"node":person,"from":cell_pos(6+i*0.4,9+kind),"to":cell_pos(7+i*0.4,10+kind),"phase":i,"kind":kind})
func position_camera():
	camera.position=pivot+Vector3(40,48,40);camera.look_at(pivot)
func zoom(amount: float):camera.size=clampf(camera.size+amount,18,80)
func world_area(pos: Vector2) -> bool:
	return Rect2(0,82,950,500).has_point(pos)
func clear_preview():
	if is_instance_valid(preview):preview.queue_free()
	preview=null;preview_ok=false;placement_drag=false
func valid_cell(cell: Vector2i) -> bool:
	if cell.x<0 or cell.y<0 or cell.x>15 or cell.y>15:return false
	for i in range(state.get("buildings",[]).size()):
		var b=state.buildings[i]
		if moving and i==selected:continue
		if int(b.x)==cell.x and int(b.y)==cell.y:return false
	return true
func update_preview(pos: Vector2):
	if not world_area(pos):
		preview_ok=false
		if is_instance_valid(preview):preview.visible=false
		return
	var hit=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(pos),camera.project_ray_normal(pos))
	if hit==null:return
	preview_cell=Vector2i(roundi(hit.x/3+7.5),roundi(hit.z/3+7.5))
	preview_ok=valid_cell(preview_cell)
	if not is_instance_valid(preview):
		preview=Node3D.new();add_child(preview)
		preview_tile=art.box(preview,Vector3(0,0.06,0),Vector3(2.95,0.08,2.95),"54dd7c")
		var kind=chosen_build if not moving else str(state.buildings[selected].id)
		preview_model=art.building(kind,1);preview.add_child(preview_model);preview_model.position.y=0.12
	preview.visible=true;preview.position=cell_pos(preview_cell.x,preview_cell.y)
	preview_tile.material_override=art.material("54dd7c" if preview_ok else "ed5555")
func drop_build(pos: Vector2):
	update_preview(pos)
	if not preview_ok or api.busy:
		message("วางไม่ได้: เลือกช่องว่างภายในสำนัก" if not preview_ok else "กำลังบันทึก กรุณารอสักครู่");return
	if moving:
		api.action("move",{"index":selected,"x":preview_cell.x,"y":preview_cell.y});moving=false
	else:api.action("build",{"type":chosen_build,"x":preview_cell.x,"y":preview_cell.y})
	clear_preview()
func pan_view(relative: Vector2):
	pivot+=Vector3(-relative.x-relative.y,0,relative.x-relative.y)*camera.size/1400.0
	pivot.x=clampf(pivot.x,-28,28);pivot.z=clampf(pivot.z,-28,28);position_camera()
func card_at(pos: Vector2) -> String:
	if not Rect2(960,92,304,530).has_point(pos):return ""
	for c in build_cards:
		if is_instance_valid(c.node) and c.node.get_global_rect().has_point(pos):return c.kind
	return ""
func menu_input(event) -> bool:
	var menu_rect=Rect2(960,92,304,530)
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION and menu_rect.has_point(event.position):return true
	if event is InputEventScreenTouch:
		if event.pressed and menu_rect.has_point(event.position) and fingers.is_empty():
			menu_touch=event.index;menu_start=event.position;menu_start_scroll=sidebar_scroll.scroll_vertical;menu_velocity=0;menu_scrolling=false;card_drag=false;card_kind=card_at(event.position);menu_button=null;menu_last_time=Time.get_ticks_msec()/1000.0
			for child in side.find_children("*","Button",true,false):
				if child.get_global_rect().has_point(event.position):menu_button=child;break
			return true
		if not event.pressed and event.index==menu_touch:
			if card_drag:drop_build(event.position)
			elif not menu_scrolling and event.position.distance_to(menu_start)<12 and is_instance_valid(menu_button) and not menu_button.disabled:menu_button.pressed.emit()
			menu_touch=-1;menu_button=null;card_drag=false;card_kind="";return true
	if event is InputEventScreenDrag and event.index==menu_touch:
		var diff=event.position-menu_start
		var now=Time.get_ticks_msec()/1000.0
		if not menu_scrolling and not card_drag and not card_kind.is_empty() and absf(diff.x)>18 and absf(diff.x)>absf(diff.y):choose_build(card_kind);card_drag=true
		if card_drag:update_preview(event.position)
		elif absf(diff.y)>12 or menu_scrolling:
			menu_scrolling=true;menu_scroll_value=menu_start_scroll-diff.y;sidebar_scroll.scroll_vertical=roundi(menu_scroll_value)
			menu_velocity=clampf(-event.relative.y/maxf(now-menu_last_time,0.016),-1400,1400)
		menu_last_time=now;return true
	return false
func _input(event):
	if state.is_empty() or is_instance_valid(modal):return
	if menu_input(event):get_viewport().set_input_as_handled();return
	if event is InputEventScreenTouch:
		if event.pressed:
			if fingers.is_empty():
				card_kind=card_at(event.position);card_origin=event.position;card_drag=false
			if world_area(event.position) or not card_kind.is_empty():
				fingers[event.index]=event.position
				if fingers.size()==1:pan_start=event.position;dragging=false
				else:pinching=true;clear_preview();card_kind=""
				if world_area(event.position):get_viewport().set_input_as_handled()
		elif fingers.has(event.index):
			if not pinching:
				if card_drag or placement_drag:drop_build(event.position)
				elif world_area(event.position) and not dragging:tap_ground(event.position)
			fingers.erase(event.index)
			if fingers.is_empty():pinching=false;card_kind="";card_drag=false;placement_drag=false
			if world_area(event.position):get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		if fingers.size()>=2:
			var points=fingers.values();var before=points[0].distance_to(points[1])
			fingers[event.index]=event.position;points=fingers.values()
			var after=points[0].distance_to(points[1])
			if before>1 and after>1:camera.size=clampf(camera.size*before/after,18,80)
			get_viewport().set_input_as_handled();return
		fingers[event.index]=event.position
		if pinching:return
		if not card_kind.is_empty() and not card_drag:
			var delta=event.position-card_origin
			if absf(delta.y)>18 and absf(delta.y)>absf(delta.x):card_kind="";fingers.erase(event.index);return
			if absf(delta.x)>18 and absf(delta.x)>absf(delta.y):choose_build(card_kind);card_drag=true
			else:return
		if card_drag or not chosen_build.is_empty() or moving:
			placement_drag=true;update_preview(event.position)
		else:
			if event.position.distance_to(pan_start)>8:dragging=true
			if dragging:pan_view(event.relative)
		get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture and world_area(event.position):
		camera.size=clampf(camera.size/event.factor,18,80);get_viewport().set_input_as_handled()
func _unhandled_input(event):
	if state.is_empty() or is_instance_valid(modal):return
	if event.device==InputEvent.DEVICE_ID_EMULATION:return
	if event is InputEventMouseButton:
		if not world_area(event.position):return
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom(-3);return
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom(3);return
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				pan_start=event.position;dragging=false
				if not chosen_build.is_empty() or moving:placement_drag=true;update_preview(event.position)
			elif placement_drag:drop_build(event.position);placement_drag=false
			elif not dragging:tap_ground(event.position)
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		if placement_drag:update_preview(event.position);return
		if event.position.distance_to(pan_start)>8:dragging=true
		if dragging:pan_view(event.relative)
func tap_ground(screen: Vector2):
	if not moving and chosen_build.is_empty() and not battle_visual:
		var origin=camera.project_ray_origin(screen)
		var query=PhysicsRayQueryParameters3D.create(origin,origin+camera.project_ray_normal(screen)*300)
		var hit=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider.has_meta("index"):
			selected=int(hit.collider.get_meta("index"));mode="home";show_side();return
	var point=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(screen),camera.project_ray_normal(screen))
	if point==null:return
	var x=roundi(point.x/3+7.5);var y=roundi(point.z/3+7.5)
	if x<0 or y<0 or x>15 or y>15:return
	if moving or not chosen_build.is_empty():drop_build(screen);return
	selected=-1
	for i in range(state.buildings.size()):
		var b=state.buildings[i]
		if int(b.x)==x and int(b.y)==y:selected=i;break
	mode="home";show_side()
func _process(delta):
	if menu_touch<0 and absf(menu_velocity)>5 and is_instance_valid(sidebar_scroll):
		menu_scroll_value=sidebar_scroll.scroll_vertical+menu_velocity*delta
		sidebar_scroll.scroll_vertical=roundi(menu_scroll_value);menu_velocity*=exp(-7*delta)
	since_sync+=delta;poll+=delta
	if poll>12 and not state.is_empty() and not api.busy and mode!="match":poll=0;api.action("sync")
	var time=Time.get_ticks_msec()/1000.0
	if battle_visual and state.has("raid"):
		var progress=clampf((now_time()-float(state.raid.start))/25.0,0,1)
		for unit in battle_nodes:
			var node=unit.node
			node.position=unit.start.lerp(unit.target,clampf(progress*3,0,1))
			node.position.y=(2.1 if unit.kind==1 else abs(sin(time*4+unit.phase))*0.25)
			node.rotation.y=sin(time*9+unit.phase)*0.18 if progress>0.33 else 0
	for actor in actors:
		var f=(sin(time*0.5+actor.phase)+1)/2
		actor.node.position=actor.from.lerp(actor.to,f)
		actor.node.position.y=abs(sin(time*6+actor.phase))*0.08+(1.7 if actor.kind==1 else 0)
	if is_instance_valid(clock_label) and not state.is_empty():
		if mode=="raid" and state.has("raid"):clock_label.text="การต่อสู้อัตโนมัติ • %d วิ" % maxi(0,int(state.raid.finish-now_time()))
		elif mode=="home" and selected>=0 and selected<state.buildings.size():clock_label.text=remaining(state.buildings[selected].finish)

func draw_battle():
	battle_visual=true;clear(world);actors=[];battle_nodes=[]
	pivot=Vector3.ZERO;position_camera()
	var enemy=state.raid.enemy
	var buildings=enemy.get("buildings",[
		{"id":"hall","x":7,"y":6,"level":1},{"id":"tower","x":5,"y":8,"level":1},
		{"id":"tower","x":9,"y":8,"level":1},{"id":"granary","x":6,"y":6,"level":1},
		{"id":"crystal","x":9,"y":6,"level":1},{"id":"tank","x":8,"y":6,"level":1}])
	for b in buildings:
		var model=art.building(b.id,int(b.level),0.85);model.position=cell_pos(b.x,b.y);world.add_child(model)
	for kind in range(3):
		for i in range(mini(20,int(state.raid.army[kind]))):
			var node=art.person(kind);world.add_child(node)
			var start=cell_pos(4+i*0.45,13+kind*0.5)
			var target=cell_pos(5+i%5,8 if kind==2 else 7)
			battle_nodes.append({"node":node,"start":start,"target":target,"kind":kind,"phase":i})
	message("กำลังบุก "+str(enemy.name)+" • การต่อสู้อัตโนมัติรุ่นทดลอง")
