extends Node3D
const Troops=preload("res://scripts/troops.gd")
const VisualStyle=preload("res://scripts/visual_style.gd")
const Art = preload("res://scripts/art.gd")
const Walls=preload("res://scripts/wall_layout.gd")
const API = preload("res://scripts/api.gd")
var practice: Node3D
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
var resource_labels: Dictionary={}
var gift_button: Button
var gift_glow: StyleBoxFlat
var checkin_available=false
var gift_claiming=false
var clock_label: Label
var modal: PanelContainer
var mode = "login"
var chosen_map = "bamboo"
var chosen_build = ""
var selected = -1
var moving = false
var wall_group: Array=[]
var wall_start=Vector2i(-1,-1)
var wall_cells: Array=[]
var wall_axis=-1
var wall_preview_key=""
var match_pick = -1
var server_time = 0.0
var since_sync = 0.0
var poll = 0.0
var actors: Array = []
var home_units: Array=[]
var defense_nodes: Array=[]
var home_defense_time=0.0
var pan_start = Vector2.ZERO
var dragging = false
var pivot = Vector3.ZERO
var last_buildings = ""
var icon_cache: Dictionary={}
var base_cache: Dictionary={}
var side_refresh_pending=false
var side_panel: PanelContainer
var build_category="all"
var selection_marker: Node3D
var low_effects=false
var resource_compact=false
var map_drawn = ""
var battle_visual = false
var battle_nodes: Array = []
var battle_buildings: Array=[]
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
	var display_config=ConfigFile.new()
	if display_config.load("user://display.cfg")==OK:low_effects=display_config.get_value("graphics","low_effects",false)
	art.fx_limit=8 if low_effects else 28
	api = API.new(); add_child(api)
	api.updated.connect(receive)
	api.failed.connect(func(error):
		gift_claiming=false;message(error)
		if mode=="jade" and is_instance_valid(modal):show_gifts()
	)
	api.auth_notice.connect(message)
	api.auth_working.connect(auth_loading)
	api.authenticated.connect(func(): message("เชื่อมต่อแล้ว กำลังเปิดสำนัก…"))
	var light = DirectionalLight3D.new(); light.rotation_degrees = Vector3(-55,-35,0); light.light_energy = 0.78;light.light_color=Color("fff0d5");light.shadow_enabled=true;light.directional_shadow_max_distance=75; add_child(light)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color("aec7bf")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color("c5dce4"); e.ambient_light_energy = 0.38
	env.environment=e; add_child(env)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size=29; camera.far=300;camera.h_offset=6; add_child(camera)
	position_camera()
	terrain=Node3D.new(); add_child(terrain)
	world=Node3D.new(); add_child(world)
	var layer=CanvasLayer.new(); add_child(layer)
	ui=Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(ui)
	ui.theme=VisualStyle.theme()
	var header=panel(Vector2(16,12),Vector2(1248,66));var resources=HBoxContainer.new();header.add_child(resources)
	top=label(resources,"เซียน ออฟ แคลน",20);top.custom_minimum_size.x=220
	for pair in [["water","น้ำ"],["rice","ข้าว"],["stone","โอสถ"],["jade","หยก"]]:
		var group=HBoxContainer.new();group.custom_minimum_size.x=225;resources.add_child(group)
		var icon=TextureRect.new();icon.texture=load("res://assets/ui/"+pair[0]+".svg");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(42,38);group.add_child(icon)
		resource_labels[pair[0]]=label(group,pair[1]+" • —",17)
	gift_button=button(ui,"ของขวัญ",navigate.bind("jade"));gift_button.position=Vector2(24,112);gift_button.size=Vector2(128,76)
	gift_glow=VisualStyle.panel();gift_glow.bg_color=Color("376a63");gift_glow.border_color=Color("ffe39a");gift_glow.shadow_color=Color(1,0.76,0.28,0.5);gift_glow.shadow_size=12;gift_button.add_theme_stylebox_override("normal",gift_glow)
	gift_button.icon=load("res://assets/ui/gift.svg");gift_button.expand_icon=true;gift_button.add_theme_constant_override("icon_max_width",50);gift_button.visible=false
	var sidebar=panel(Vector2(960,92),Vector2(304,530));side_panel=sidebar
	var scroll=ScrollContainer.new();sidebar_scroll=scroll;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.scroll_deadzone=12;sidebar.add_child(scroll)
	side=VBoxContainer.new();side.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(side)
	var footer=panel(Vector2(16,634),Vector2(1248,70));var row=HBoxContainer.new();footer.add_child(row)
	for pair in [["สำนัก","home"],["ก่อสร้าง","build"],["ฝึกทหาร","train"],["บุกสำนัก","raid"],["ฝึกบุก","practice"],["จับคู่","match"],["ร้านค้า","jade"]]:
		button(row,pair[0],navigate.bind(pair[1]))
	button(row,"⚙",show_settings)
	button(row,"−",zoom.bind(5.0));button(row,"+",zoom.bind(-5.0))
	toast=Label.new();toast.position=Vector2(28,588);toast.size=Vector2(915,42);toast.add_theme_color_override("font_color",Color("ffe7a5"));toast.add_theme_color_override("font_shadow_color",Color.BLACK);toast.add_theme_constant_override("shadow_offset_x",2);toast.add_theme_constant_override("shadow_offset_y",2);ui.add_child(toast)
	draw_terrain("bamboo")
	show_login()
	if not api.refresh_token.is_empty(): api.resume()

func panel(pos: Vector2, extent: Vector2) -> PanelContainer:
	var p=PanelContainer.new();p.position=pos;p.size=extent
	var st=VisualStyle.panel()
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
	checkin_available=payload.get("checkin_available",false);gift_claiming=false
	for item in catalog:
		if item.id=="kitchen":item.name="โรงครัว"
		if item.id=="granary":item.name="ยุ้งฉาง"
		if item.id=="spring":item.name="โรงปรุงโอสถ"
		if item.id=="tank":item.name="อ่างเก็บน้ำ"
		if item.id=="crystal":item.name="คลังโอสถ"
		if item.id=="servant":item.name="เรือนช่าง"
		if item.id=="ward":item.name="หอค่ายกล"
		if item.id=="tower":item.name="หอหน้าไม้"
	if payload.get("needs_create",false):show_create();return
	var previous_selection=state.get("buildings",[])[selected].duplicate() if selected>=0 and selected<state.get("buildings",[]).size() else {}
	state=payload.get("state",{});caps=payload.get("capacity",{})
	if not previous_selection.is_empty() and (selected>=state.get("buildings",[]).size() or state.buildings[selected].id!=previous_selection.id or state.buildings[selected].x!=previous_selection.x or state.buildings[selected].y!=previous_selection.y):
		selected=-1;moving=false;clear_preview()
	if mode in ["login","create"]:close_modal();mode="home"
	if state.has("raid"):mode="raid"
	if map_drawn!=state.get("map","bamboo"):draw_terrain(state.get("map","bamboo"))
	var encoded=JSON.stringify(state.get("army",[]))+str(state.get("last_defense",{}).get("time",0))+JSON.stringify(state.get("buildings",[]))
	if encoded!=last_buildings and not battle_visual:
		last_buildings=encoded;draw_base()
	if mode=="raid" and state.has("raid") and not battle_visual:draw_battle()
	elif battle_visual and (mode!="raid" or not state.has("raid")):battle_visual=false;draw_base()
	update_storage_visuals()
	update_top()
	if menu_touch<0:show_side()
	else:side_refresh_pending=true
	if mode=="match":show_match()
	if mode=="jade" and is_instance_valid(modal):show_gifts()
	message("บันทึกแล้ว")
func now_time() -> float:return server_time+since_sync
func update_top():
	if state.is_empty():return
	top.text=str(state.get("name","สำนักของคุณ"))
	for pair in [["water","น้ำ"],["rice","ข้าว"],["stone","โอสถ"],["jade","หยก"]]:
		var value=int(state.get(pair[0],0))
		resource_labels[pair[0]].text=("%s\n%d" % [pair[1],value]) if pair[0]=="jade" else ("%s\n%d / %d" % [pair[1],value,int(caps.get(pair[0],1000))])
	gift_button.visible=not battle_visual

func open_practice():
	if is_instance_valid(practice):return
	clear_preview();fingers.clear();pinching=false;menu_touch=-1
	ui.hide();world.hide();terrain.hide()
	practice=load("res://scripts/offline_practice.gd").new();add_child(practice)
	practice.closed.connect(func():
		practice.queue_free();practice=null;ui.show();world.show();terrain.show();camera.make_current()
		if not state.is_empty() and not api.busy:api.action("sync")
	)
func navigate(target: String):
	if target=="practice":open_practice();return
	if state.is_empty():message("กรุณาเข้าสู่ระบบและตั้งสำนักก่อน");return
	if api.busy:return
	if battle_visual and target!="raid":battle_visual=false;draw_base()
	mode=target;chosen_build="";moving=false;wall_group.clear();clear_preview();close_modal()
	if target=="match":show_match()
	elif target=="jade":show_side();show_gifts()
	elif target=="raid" and not state.has("raid"):api.action("scout")
	elif target=="raid" and state.has("raid"):draw_battle();show_side()
	else:show_side()
func show_side():
	if is_instance_valid(side_panel):
		side_panel.visible=not state.is_empty() and (mode!="home" or selected>=0)
		camera.h_offset=6 if side_panel.visible else 0
	refresh_selection()
	build_cards.clear()
	clear(side)
	var title_row=HBoxContainer.new();side.add_child(title_row)
	label(title_row,{"build":"ก่อสร้าง","train":"กองทัพ","raid":"การต่อสู้"}.get(mode,"ข้อมูลสำนัก"),22)
	button(title_row,"ปิด",func():selected=-1;navigate("home"))
	if state.is_empty():label(side,"เริ่มต้นตำนานสำนักของคุณ");return
	label(side,"ช่างว่าง %d/%d • ศิษย์ %d/%d" % [int(caps.get("workers",1))-int(caps.get("busy",0)),int(caps.get("workers",1)),army_total(),int(caps.get("army",10))],16)
	match mode:
		"build":
			label(side,"เลื่อนขึ้นลงเพื่อเลือก\nลากรูปอาคารออกมาวางบนพื้น",20)
			button(side,"เลื่อนจอ / จบการวาง",end_placement)
			if chosen_build=="wall":
				label(side,"ลากบนพื้นเพื่อสร้างกำแพงเป็นแนว
เชื่อมมุมอัตโนมัติ • 5 น้ำ / 5 ข้าวต่อช่อง",16)
				button(side,"หมุนแนวลาก 90°",func():wall_axis=1 if wall_axis<=0 else 0;clear_preview();message("แนวตั้ง" if wall_axis==1 else "แนวนอน"))
				button(side,"ลากได้ทั้งสองแนว",func():wall_axis=-1;clear_preview())
			var filters=HBoxContainer.new();side.add_child(filters)
			for pair in [["ทั้งหมด","all"],["ผลิต","economy"],["ทหาร","army"],["ป้องกัน","defense"]]:
				var tab=button(filters,pair[0],func():build_category=pair[1];show_side());tab.add_theme_font_size_override("font_size",13);tab.add_theme_constant_override("outline_size",0)
			for c in catalog:
				if c.id=="recruit":continue
				var category="defense" if c.id in ["wall","tower","ward"] else "army" if c.id in ["training","barracks"] else "economy"
				if build_category!="all" and build_category!=category:continue
				var caption="%s\nน้ำ %d ข้าว %d\nโอสถ %d • %d วิ" % [c.name,c.water,c.rice,c.stone,c.seconds]
				if c.id=="servant":caption="เรือนช่าง • %d / 7 หลัง\n%s\nสร้างเสร็จทันที • ไม่อัปเกรด" % [builder_count(),"ครบแล้ว" if builder_count()>=7 else ("ฟรี" if builder_price()==0 else "%d หยก" % builder_price())]
				var card=button(side,caption,choose_build.bind(c.id))
				if c.id!="servant":card.disabled=float(state.get("water",0))<float(c.water) or float(state.get("rice",0))<float(c.rice) or float(state.get("stone",0))<float(c.stone)
				if c.id=="servant":card.disabled=builder_count()>=7 or int(state.get("jade",0))<builder_price()
				card.icon=building_icon(c.id);card.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT;card.expand_icon=true;card.add_theme_constant_override("icon_max_width",76);card.custom_minimum_size=Vector2(272,100)
				build_cards.append({"node":card,"kind":c.id})
		"train":
			label(side,"หอฝึกนักสู้",25)
			label(side,"ผลิตที่หอฝึก • เก็บที่ลานฝึกกระบี่
ลานจุ 20 หน่วยต่อระดับ สูงสุด 200",16)
			if building_level("barracks")==0:
				label(side,"สร้างหอฝึกนักสู้เพื่อเริ่มผลิต",17)
				button(side,"ไปสร้างหอฝึก",func():navigate("build");choose_build("barracks"))
			var names=Troops.NAMES
			for i in range(10):
				var sheet=load("res://assets/realistic/"+Troops.ASSETS[i]+".webp")
				var frame=AtlasTexture.new();frame.atlas=sheet;frame.region=Rect2(0,0,sheet.get_width()/4.0,sheet.get_height()/2.0)
				var portrait=TextureRect.new();portrait.texture=frame;portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(120,90);side.add_child(portrait)
				label(side,"ระดับ %d • "% (i+1)+Troops.SKILLS[i],15)
				label(side,Troops.DETAILS[i],14)
				label(side,"%s: %d คน" % [names[i],Troops.count(state.army,i)])
				var produce=button(side,"ผลิต • น้ำ %d ข้าว %d โอสถ %d" % [Troops.WATER[i],Troops.RICE[i],Troops.ELIXIR[i]],send.bind("train",{"type":i}))
				produce.disabled=building_level("barracks")<i+1 or building_level("training")<1 or army_total()+state.jobs.size()>=int(caps.get("army",10))
			label(side,"คิวผลิต: %d คน\nเวลาผลิต 10–100 วินาทีตามชนิด" % state.jobs.size())
			label(side,"ปลดล็อกนักรบใหม่ทุกระดับหอฝึก 1–10",15)
		"jade":
			label(side,"หยกเซียน",26)
			button(side,"เปิดของขวัญ / เช็คอิน",show_gifts)
			for pair in [["น้ำ 250","water"],["ข้าว 250","rice"],["โอสถเซียน 25","stone"]]:button(side,"5 หยก → "+pair[0],send.bind("exchange",{"resource":pair[1]}))
			label(side,"หยกถูกปล้นไม่ได้\nใช้สร้างเรือนช่างและเร่งงาน",16)
		"raid":show_raid()
		_:
			if selected>=0 and selected<state.buildings.size():
				var b=state.buildings[selected];var c=find_catalog(b.id)
				var portrait=TextureRect.new();portrait.texture=building_icon(b.id);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(180,140);side.add_child(portrait)
				label(side,c.get("name",b.id),26)
				label(side,"ระดับ %d" % int(b.level))
				if b.id=="training":
					label(side,"ลานเปิด 2×2 ช่อง
ความจุ %d → %d หน่วย" % [int(b.level)*20,mini(200,(int(b.level)+1)*20)])
					if int(b.get("size",2))==1:label(side,"พื้นที่แน่น: ย้ายลานไปช่องว่าง 2×2 เพื่อขยาย",16)
					label(side,"ป้องกันสำนัก 50% ของแต่ละชนิด (ปัดลง)",16)
					label(side,"พักและเก็บนักสู้เท่านั้น\nผลิตนักสู้ที่หอฝึกนักสู้",16)
				if b.id=="barracks":
					label(side,"ปลดล็อกนักรบใหม่ทุกระดับ 1–10",16)
					button(side,"ผลิตนักสู้",navigate.bind("train"))
				if b.id=="spring":label(side,"ผลิตโอสถเซียน → คลังโอสถ",16)
				if b.id=="crystal":label(side,"คลังเก็บโอสถสำหรับฝึกทหาร\nฝ่ายบุกมองเห็นปริมาณได้",16)
				clock_label=label(side,remaining(b.finish))
				if float(b.finish)>now_time():
					button(side,"เสร็จทันที • %d หยก" % ceili((float(b.finish)-now_time())/300),send.bind("boost",{"index":selected}))
				elif b.id=="servant":
					label(side,"ช่าง 1 คนต่อหลัง • ไม่อัปเกรด\nสร้างเพิ่มด้วยหยกได้สูงสุด 7 หลัง",16)
				else:
					var costs=[int(c.water*pow(2,b.level)),int(c.rice*pow(2,b.level)),int(c.stone*pow(2,b.level))]
					if b.id=="barracks" and int(b.level)<10:costs=[Troops.UPGRADE[int(b.level)],Troops.UPGRADE[int(b.level)],Troops.UPGRADE[int(b.level)]]
					label(side,"อัปเกรด: น้ำ %d / ข้าว %d / โอสถ %d" % costs,16)
					if b.id!="wall" and int(b.level)<10:
						var upgrade=button(side,"อัปเกรด",confirm_upgrade.bind(selected,costs))
						upgrade.disabled=float(state.get("water",0))<costs[0] or float(state.get("rice",0))<costs[1] or float(state.get("stone",0))<costs[2]
					elif int(b.level)>=10:label(side,"ระดับสูงสุด",18)
				if b.id=="wall":
					for choice in [["ชิ้นนี้","one"],["แถวนี้","row"],["ทั้งหมด","all"]]:
						button(side,"อัปเกรดกำแพง "+choice[0],wall_dialog.bind("upgrade",choice[1]))
						button(side,"ลบกำแพง "+choice[0],wall_dialog.bind("delete",choice[1]))
					button(side,"หมุนแนวกำแพง 90°",send.bind("wall_edit",{"index":selected,"operation":"rotate"}))
					button(side,"ย้ายทั้งแนวกำแพง",func():moving=true;wall_group=Walls.run_indices(state.buildings,selected);clear_preview();message("ลากแนวกำแพงไปยังพื้นที่สีเขียว"))
				button(side,"ย้ายอาคาร",func():moving=true;wall_group.clear();clear_preview();message("ลากบนพื้นไปยังช่องสีเขียว แล้วปล่อยเพื่อย้าย"))
			else:
				label(side,"สำนักของคุณ",27)
				label(side,"1. สร้างบ่อน้ำและโรงครัว\n2. สร้างโกดังเพิ่มความจุ\n3. ฝึกทหารและบุกสำนัก\n4. เล่นจับคู่ระหว่างรอ",20)
				label(side,"แตะอาคารเพื่อดู / อัปเกรด\nลากพื้นเพื่อเลื่อนมุมมอง",16)
			var refund=state.get("recruit_refund",{})
			if int(refund.get("water",0))+int(refund.get("rice",0))+int(refund.get("stone",0))>0:
				label(side,"ทรัพยากรคืนฐานรับศิษย์รอเข้าโกดัง: น้ำ %d / ข้าว %d / โอสถ %d" % [refund.get("water",0),refund.get("rice",0),refund.get("stone",0)],16)
			if state.has("last_defense"):
				var d=state.last_defense
				if d.has("garrison"):label(side,"นักรบป้องกัน: "+Troops.summary(d.garrison),16)
				label(side,"ถูกบุกโดย %s\nเสียน้ำ %d ข้าว %d โอสถ %d" % [d.attacker,d.water,d.rice,d.stone],16)
			button(side,"อัปเดตข้อมูล",send.bind("sync",{}))
			button(side,"เครดิตภาพ / โมเดล",show_credits)
func layout_signature() -> String:
	var parts=PackedStringArray()
	for b in state.get("buildings",[]):parts.append("%s:%d:%d" % [b.id,int(b.x),int(b.y)])
	return ",".join(parts)
func send(action: String,args: Dictionary):
	if api.busy:
		message("กำลังบันทึกคำสั่งก่อนหน้า กรุณารอสักครู่");return
	message("รับคำสั่งแล้ว กำลังบันทึก…")
	args=args.duplicate();args["layout"]=layout_signature()
	api.action(action,args)
func building_icon(kind: String) -> Texture2D:
	var icon_path="res://assets/ui/buildings/"+kind+".png"
	if ResourceLoader.exists(icon_path):return load(icon_path)
	if FileAccess.file_exists(icon_path):return ImageTexture.create_from_image(Image.load_from_file(icon_path))
	if icon_cache.has(kind):return icon_cache[kind]
	if kind=="granary":return load("res://assets/realistic/glass_tiffin.webp")
	if art.realistic_enabled and art.realistic.WIDTHS.has(kind):
		var model=art.realistic.building(kind,1);var texture=model.get_node("RealisticVisual").texture;model.free();icon_cache[kind]=texture;return texture
	return load("res://assets/buildings/"+kind+".png")
func choose_build(kind: String):
	chosen_build=kind;moving=false;wall_group.clear();clear_preview()
	if kind=="wall":show_side()
	message("ลากบนพื้นเพื่อวาง "+find_catalog(kind).get("name",kind)+" • เขียว: วางได้ / แดง: วางไม่ได้")
func find_catalog(kind: String) -> Dictionary:
	for c in catalog:
		if c.id==kind:return c
	return {}
func building_level(kind: String) -> int:
	var level=0
	for b in state.get("buildings",[]):
		if b.id==kind:level=maxi(level,int(b.level))
	return level
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
		if r.enemy.has("garrison"):label(side,"นักรบฝ่ายป้องกัน: "+Troops.summary(r.enemy.garrison),16)
		label(side,"ส่ง "+Troops.summary(r.army)+"\nผลคำนวณโดยเซิร์ฟเวอร์",16)
		button(side,"จบการบุก / รับของ",send.bind("raid_claim",{}))
	elif state.has("scout"):
		var s=state.scout
		label(side,s.name,22)
		label(side,("สำนักผู้เล่น" if s.has("player") else "สำนักบอท")+" • ระดับ %d\nพลังป้องกัน %d\nน้ำ %d ข้าว %d โอสถ %d" % [s.level,s.defense,s.water,s.rice,s.stone])
		if s.has("garrison"):label(side,"นักรบป้องกัน 50%: "+Troops.summary(s.garrison),16)
		label(side,"ส่งกองกำลังทั้งหมด\nหน่วยที่ส่งจะใช้ไปในการบุก",16)
		button(side,"เริ่มบุก (25 วินาที)",send.bind("raid_start",{}))
		button(side,"ค้นหาสำนักผู้เล่น",send.bind("scout",{"mode":"player"}))
		button(side,"ค้นหาสำนักบอท",send.bind("scout",{}))
		label(side,"เริ่มบุกแล้วโล่คุ้มครองจะหมด\nโกดังถูกปล้นได้บางส่วน หยกปลอดภัย",15)
	if state.has("last_raid"):
		label(side,"ผลล่าสุด: %d ดาว" % state.last_raid.stars,22)
func show_match():
	mode="home"
	if Engine.has_singleton("XianAuth"):
		Engine.get_singleton("XianAuth").open_ghost_match(api.user_id,api.token)
	else:
		var box=modal_box()
		label(box,"Ghost Match3",30)
		label(box,"เกมต้นฉบับ 120 ด่านรวมอยู่ใน APK Android\nกดปุ่มกลับสำนักเมื่อเล่นเสร็จ\nความคืบหน้าเกมจับคู่บันทึกในเครื่องแยกตามบัญชี")
		button(box,"กลับสำนัก",close_modal)
func show_credits():
	var box=modal_box()
	label(box,"เครดิตทรัพยากร",28)
	var logo=TextureRect.new();logo.texture=load("res://assets/donor/eep_logo.png");logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;logo.custom_minimum_size=Vector2(280,110);box.add_child(logo)
	label(box,"Godette / Adventure Mode / Dress Up\nEaster Egg Productions — CC BY 4.0 และเงื่อนไข Dress Up\nดัดแปลง: ถอดเป้ ปรับขนาด และใช้แอนิเมชันเดิน",17)
	label(box,"Quaternius Ultimate Monsters — CC0
มังกรและแอนิเมชันจาก The Gang",17)
	label(box,"Imperial China Palace and Garden — 3dassets.dev (CC0)\nโมเดลนำมาจาก The Gang\nGhostMatch3 — sunantongsan",17)
	button(box,"กลับสำนัก",close_modal)
func base_model(b: Dictionary, buildings: Array, fill=0.5) -> Node3D:
	if b.id=="wall":return art.wall(Walls.mask(buildings,Walls.cell(b)),int(b.get("rotation",0)),int(b.level))
	return art.building(b.id,int(b.level),fill)
func cell_pos(x: float,y: float) -> Vector3:return Vector3((x-7.5)*3,0,(y-7.5)*3)
func draw_terrain(kind: String):
	map_drawn=kind;clear(terrain)
	art.landscape(terrain,kind=="mountain")

func draw_base():
	# Preserve unchanged geometry/materials across build and upgrade responses.
	for cached in base_cache.values():
		if is_instance_valid(cached) and cached.get_parent()==world:world.remove_child(cached)
	clear(world);actors=[]
	var next_cache: Dictionary={}
	for b in state.get("buildings",[]):
		var resource={"tank":"water","granary":"rice","crystal":"stone"}.get(b.id,"")
		var fill=float(state.get(resource,0))/maxf(1,float(caps.get(resource,1000)))
		var key=JSON.stringify(b)+("/"+str(Walls.mask(state.buildings,Walls.cell(b))) if b.id=="wall" else "")
		var reused=base_cache.has(key) and is_instance_valid(base_cache[key])
		var model=base_cache[key] if reused else base_model(b,state.buildings,fill)
		next_cache[key]=model;model.position=building_position(b);world.add_child(model)
		if b.id=="training" and footprint(b)==1:model.scale=Vector3(0.49,1,0.49)
		if not reused:
			var body=StaticBody3D.new();body.set_meta("index",state.buildings.find(b));model.add_child(body)
			var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(footprint(b)*3-0.2,3.4,footprint(b)*3-0.2);collision.shape=shape;collision.position.y=1.7;body.add_child(collision)
			if float(b.finish)>now_time():
				var remaining_seconds=float(b.finish)-now_time();var spec=find_catalog(b.id)
				var total=minf(28800.0,float(spec.get("seconds",30))*pow(3.0,int(b.level)))
				var progress=clampf(1.0-remaining_seconds/maxf(1.0,total),0.0,1.0)
				art.construction_dressing(model,footprint(b),progress)
		else:
			for body in model.get_children():
				if body is StaticBody3D:body.set_meta("index",state.buildings.find(b))
		if b.id in ["well","kitchen","spring"] and int(b.level)>0:
			var target={"well":"tank","kitchen":"granary","spring":"crystal"}[b.id]
			for storage in state.buildings:
				if storage.id==target and int(storage.level)>0:
					var person=art.person(0,false);person.scale=Vector3.ONE;world.add_child(person)
					if not person.get_meta("realistic_art",false):art.box(person,Vector3(0.4,0.65,0),Vector3(0.35,0.4,0.35),"62b4c1" if b.id=="well" else "d2bb79")
					actors.append({"node":person,"from":model.position+Vector3(1,0,0),"to":cell_pos(storage.x,storage.y)+Vector3(1,0,0),"phase":actors.size(),"kind":0,"progress":0.0,"forward":true,"pause":0.0});person.position=actors[-1].from;break
	for key in base_cache:
		if not next_cache.has(key) and is_instance_valid(base_cache[key]):base_cache[key].queue_free()
	base_cache=next_cache
	var yard: Dictionary={}
	for b in state.buildings:
		if b.id=="training" and int(b.level)>0:yard=b;break
	home_units=[];defense_nodes=[]
	var grid=AStarGrid2D.new();grid.region=Rect2i(0,0,16,16);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update()
	for building in state.buildings:
		for x in range(int(building.x),int(building.x)+footprint(building)):
			for y in range(int(building.y),int(building.y)+footprint(building)):
				grid.set_point_solid(Vector2i(x,y))
	var open: Array=[]
	for x in range(16):
		for y in range(16):
			if not grid.is_point_solid(Vector2i(x,y)):open.append(Vector2i(x,y))
	for carrier in actors:
		if open.is_empty():continue
		var origin=Vector2i(roundi(carrier.from.x/3+7.5),roundi(carrier.from.z/3+7.5))
		var target=Vector2i(roundi(carrier.to.x/3+7.5),roundi(carrier.to.z/3+7.5))
		var start=open[0];var goal=open[0]
		for cell in open:
			if Vector2(cell-origin).length_squared()<Vector2(start-origin).length_squared():start=cell
			if Vector2(cell-target).length_squared()<Vector2(goal-target).length_squared():goal=cell
		carrier.path=grid.get_id_path(start,goal);carrier.path_index=1;carrier.forward=true
		carrier.node.position=cell_pos(start.x,start.y)
	var visible_unit=0
	for kind in range(10):
		for i in range(mini(2 if kind>1 else 6,Troops.count(state.army,kind))):
			if open.is_empty():break
			var person=art.person(kind);person.set_script(preload("res://scripts/sect_life.gd"));person.art=art;person.grid=grid;person.unit_kind=kind;person.serial=visible_unit
			var cell=open[(visible_unit*29+17)%open.size()]
			person.cell=cell;person.position=cell_pos(cell.x,cell.y);person.destination=person.position
			person.activity=["stroll","stroll","sleep","stroll","spar","spar"][visible_unit%6]
			if kind!=0 and person.activity=="sleep":person.activity="stroll"
			if visible_unit<2 and not yard.is_empty():
				person.activity="camp";person.position=building_position(yard)+Vector3(-0.8+visible_unit*1.6,0,0)
			elif person.activity=="sleep":
				# Pick a free cell next to an actual building, never inside its footprint.
				var beside=open.filter(func(c):return [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN].any(func(d):return grid.is_in_boundsv(c+d) and grid.is_point_solid(c+d)))
				if not beside.is_empty():
					var c=beside[visible_unit%beside.size()];person.cell=c;person.position=cell_pos(c.x,c.y)+Vector3(0.55,0,0.3)
			elif person.activity=="spar" and visible_unit%6==5 and not home_units.is_empty():
				person.position=home_units[-1].position+Vector3(1.1,0,-1.1)
				person.get_node("CharacterSprite").flip_h=true
			world.add_child(person);home_units.append(person);visible_unit+=1
	var report=state.get("last_defense",{})
	if report.has("finish") and now_time()<float(report.finish):start_home_defense(report)
func garrison_position(kind: int,index: int) -> Vector3:
	return cell_pos(4+(index%8)*0.8,10.3-(index/8)*0.65)+Vector3(0,1.7 if Troops.air(kind) else 0,-kind*0.7)
func start_home_defense(report: Dictionary):
	home_defense_time=float(report.finish)
	var guards=report.get("garrison",[0,0,0]);var used=[0,0,0,0,0,0,0,0,0,0]
	for person in home_units:
		var kind=int(person.unit_kind)
		if used[kind]<Troops.count(guards,kind):
			person.alarm(garrison_position(kind,used[kind]));used[kind]+=1
	for kind in range(10):
		# Every committed defender gets a visual; the calm village uses fewer extras.
		for i in range(used[kind],Troops.count(guards,kind)):
			var guard=art.person(kind);guard.set_script(preload("res://scripts/sect_life.gd"));guard.art=art;guard.unit_kind=kind;guard.position=cell_pos(6+i%4,6)
			world.add_child(guard);home_units.append(guard);guard.alarm(garrison_position(kind,i))
		for i in range(mini(20,Troops.count(report.get("army",[]),kind))):
			var node=art.person(kind);world.add_child(node)
			defense_nodes.append({"node":node,"start":cell_pos(4+i*0.5,14),"target":cell_pos(4+(i%8)*0.8,11.2+(i/8)*0.65+kind*0.3),"phase":i,"kind":kind})
	message("สำนักถูกบุกรุก! นักรบ 50% ออกป้องกันฐาน")
func position_camera():
	camera.position=pivot+Vector3(40,48,40);camera.look_at(pivot)
func zoom(amount: float):camera.size=clampf(camera.size+amount,18,80)
func world_area(pos: Vector2) -> bool:
	if is_instance_valid(gift_button) and gift_button.visible and gift_button.get_global_rect().has_point(pos):return false
	return Rect2(0,82,950 if is_instance_valid(side_panel) and side_panel.visible else 1280,550).has_point(pos)
func clear_preview():
	if is_instance_valid(preview):preview.queue_free()
	preview=null;preview_ok=false;placement_drag=false;wall_start=Vector2i(-1,-1);wall_cells.clear();wall_preview_key=""
func footprint(b: Dictionary) -> int:
	return int(b.get("size",2)) if b.id=="training" else 1
func building_position(b: Dictionary) -> Vector3:
	var offset=(footprint(b)-1)*1.5
	return cell_pos(b.x,b.y)+Vector3(offset,0,offset)
func placement_size() -> int:
	var kind=chosen_build
	if moving and selected>=0:kind=state.buildings[selected].id
	return 2 if kind=="training" else 1
func valid_cell(cell: Vector2i) -> bool:
	var size=placement_size()
	if cell.x<0 or cell.y<0 or cell.x+size>16 or cell.y+size>16:return false
	var rect=Rect2i(cell,Vector2i(size,size))
	for i in range(state.get("buildings",[]).size()):
		var b=state.buildings[i]
		if moving and (i==selected or i in wall_group):continue
		if rect.intersects(Rect2i(Vector2i(int(b.x),int(b.y)),Vector2i.ONE*footprint(b))):return false
	return true
func update_wall_preview():
	if wall_start.x<0:wall_start=preview_cell
	if not wall_group.is_empty():
		wall_cells=[]
		var delta=preview_cell-Walls.cell(state.buildings[selected])
		for i in wall_group:wall_cells.append(Walls.cell(state.buildings[i])+delta)
	else:wall_cells=Walls.line(wall_start,preview_cell,wall_axis)
	preview_ok=true
	for cell in wall_cells:
		if not valid_cell(cell):preview_ok=false
	var key=str(wall_cells)+str(preview_ok)
	if key==wall_preview_key and is_instance_valid(preview):preview.show();return
	wall_preview_key=key
	if is_instance_valid(preview):preview.queue_free()
	preview=Node3D.new();add_child(preview)
	var proposed=state.buildings.duplicate(true)
	for cell in wall_cells:proposed.append({"id":"wall","x":cell.x,"y":cell.y})
	for cell in wall_cells:
		art.box(preview,cell_pos(cell.x,cell.y)+Vector3(0,0.05,0),Vector3(2.98,0.1,2.98),"54dd7c" if preview_ok else "ed5555")
		var model=art.wall(Walls.mask(proposed,cell),maxi(0,wall_axis));preview.add_child(model);model.position=cell_pos(cell.x,cell.y)
	if wall_group.is_empty():message("กำแพง %d ช่อง • น้ำ %d / ข้าว %d • ปล่อยเพื่อสร้าง" % [wall_cells.size(),wall_cells.size()*5,wall_cells.size()*5])
func update_preview(pos: Vector2):
	if not world_area(pos):
		preview_ok=false
		if is_instance_valid(preview):preview.visible=false
		return
	var hit=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(pos),camera.project_ray_normal(pos))
	if hit==null:return
	preview_cell=Vector2i(roundi(hit.x/3+7.5),roundi(hit.z/3+7.5))
	if chosen_build=="wall" or not wall_group.is_empty():update_wall_preview();return
	preview_ok=valid_cell(preview_cell)
	if not is_instance_valid(preview):
		preview=Node3D.new();add_child(preview)
		preview_tile=art.box(preview,Vector3(0,0.06,0),Vector3(placement_size()*3-0.05,0.08,placement_size()*3-0.05),"54dd7c")
		var kind=chosen_build if not moving else str(state.buildings[selected].id)
		preview_model=art.building(kind,int(state.buildings[selected].level) if moving else 1);preview.add_child(preview_model);preview_model.position.y=0.12
	preview.visible=true;preview.position=cell_pos(preview_cell.x,preview_cell.y)+Vector3(1,0,1)*(placement_size()-1)*1.5
	preview_tile.material_override=art.material("54dd7c" if preview_ok else "ed5555")
func end_placement():
	chosen_build="";moving=false;wall_group.clear();card_drag=false;clear_preview()
	message("เลื่อนจอได้แล้ว • เลือกกำแพงอีกครั้งเพื่อสร้างแนวใหม่")
func drop_build(pos: Vector2):
	if chosen_build.is_empty() and not moving:return
	update_preview(pos)
	if not preview_ok or api.busy:
		message("วางไม่ได้: เลือกช่องว่างภายในสำนัก" if not preview_ok else "กำลังบันทึก กรุณารอสักครู่");return
	if not wall_group.is_empty():
		send("wall_edit",{"index":selected,"operation":"move","x":preview_cell.x,"y":preview_cell.y});moving=false;wall_group.clear()
	elif chosen_build=="wall":
		var end: Vector2i=wall_cells[-1]
		api.action("wall_line",{"x":wall_start.x,"y":wall_start.y,"end_x":end.x,"end_y":end.y,"rotation":maxi(0,wall_axis)})
	elif moving:
		send("move",{"index":selected,"x":preview_cell.x,"y":preview_cell.y});moving=false
	else:api.action("build",{"type":chosen_build,"x":preview_cell.x,"y":preview_cell.y})
	end_placement()
func pan_view(relative: Vector2):
	pivot+=Vector3(-relative.x-relative.y,0,relative.x-relative.y)*camera.size/1400.0
	pivot.x=clampf(pivot.x,-28,28);pivot.z=clampf(pivot.z,-28,28);position_camera()
func card_at(pos: Vector2) -> String:
	if not Rect2(960,92,304,530).has_point(pos):return ""
	for c in build_cards:
		if is_instance_valid(c.node) and c.node.get_global_rect().has_point(pos):return c.kind
	return ""
func menu_input(event) -> bool:
	if not is_instance_valid(side_panel) or not side_panel.visible:return false
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
	if is_instance_valid(practice):return
	if state.is_empty() or is_instance_valid(modal):return
	if menu_input(event):get_viewport().set_input_as_handled();return
	if event is InputEventScreenTouch:
		if event.pressed:
			if fingers.is_empty():
				card_kind=card_at(event.position);card_origin=event.position;card_drag=false
			if world_area(event.position) or not card_kind.is_empty():
				fingers[event.index]=event.position
				if fingers.size()==1:
					pan_start=event.position;dragging=false
					if chosen_build=="wall" and world_area(event.position):update_preview(event.position);placement_drag=true
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
	if is_instance_valid(practice):return
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
		if Rect2i(Vector2i(int(b.x),int(b.y)),Vector2i.ONE*footprint(b)).has_point(Vector2i(x,y)):selected=i;break
	mode="home";show_side()
func _process(delta):
	if is_instance_valid(practice):return
	if side_refresh_pending and menu_touch<0:
		side_refresh_pending=false;show_side()
	if menu_touch<0 and absf(menu_velocity)>5 and is_instance_valid(sidebar_scroll):
		menu_scroll_value=sidebar_scroll.scroll_vertical+menu_velocity*delta
		sidebar_scroll.scroll_vertical=roundi(menu_scroll_value);menu_velocity*=exp(-7*delta)
	since_sync+=delta;poll+=delta
	if poll>12 and not state.is_empty() and not api.busy and mode!="match":poll=0;api.action("sync")
	var time=Time.get_ticks_msec()/1000.0
	if gift_glow!=null:gift_glow.shadow_color=Color(1,0.76,0.28,0.4+0.2*sin(time*3) if checkin_available else 0.12)
	if is_instance_valid(gift_button):gift_button.self_modulate=Color(1,0.9+0.1*sin(time*3),0.73+0.27*sin(time*3),1) if checkin_available else Color.WHITE
	if battle_visual and state.has("raid"):
		var progress=clampf((now_time()-float(state.raid.start))/25.0,0,1)
		update_raid_destruction(progress,float(state.raid.get("ratio",0)))
		for defense in battle_buildings:
			if defense.kind in ["ward","tower"] and not defense.destroyed and progress>0.3 and progress<1 and time>defense.get("next_wave",0):
				if defense.kind=="ward":art.sound_wave(world,defense.node.position,12.6)
				elif not battle_nodes.is_empty():art.slingshot_fx(world,defense.node.position+Vector3(0,2.8,0),battle_nodes[0].node.position+Vector3(0,0.7,0))
				defense.next_wave=time+(1.8 if defense.kind=="ward" else 1.0)
		for unit in battle_nodes:
			var node=unit.node
			node.position=unit.start.lerp(unit.target,clampf(progress*3,0,1))
			node.position.y=(2.1 if Troops.air(unit.kind) else 0.0)
			var direction=unit.target-unit.start
			node.rotation.y=atan2(direction.x,direction.z)
			if progress>0.33:
				if not node.get_meta("next_strike",0.0)>time:
					art.pose(node,"attack",0.85);art.strike_fx(world,node.position,node.position+Vector3(0.4,0,-0.7),unit.kind);node.set_meta("next_strike",time+Troops.COOLDOWN[unit.kind])
			else:art.pose(node,"walk")
	if not battle_visual and not defense_nodes.is_empty():
		var progress=clampf(1.0-(home_defense_time-now_time())/25.0,0,1)
		for unit in defense_nodes:
			unit.node.position=unit.start.lerp(unit.target,minf(1,progress*3))
			if progress<0.33:art.pose(unit.node,"walk")
			elif time>unit.node.get_meta("next_strike",0.0):art.pose(unit.node,"attack",0.8);art.strike_fx(world,unit.node.position,unit.node.position+Vector3(0,0,-1),unit.kind);unit.node.set_meta("next_strike",time+Troops.COOLDOWN[unit.kind])
		if progress>=1:draw_base()
	for actor in actors:
		actor.pause=maxf(0.0,actor.pause-delta)
		if not actor.has("path") or actor.path.size()<2 or actor.pause>0:
			art.pose(actor.node,"idle");continue
		var cell=actor.path[actor.path_index];var goal=cell_pos(cell.x,cell.y)
		actor.node.position=actor.node.position.move_toward(goal,delta*0.85)
		art.pose(actor.node,"walk")
		if actor.node.position.distance_to(goal)<0.01:
			if actor.path_index==actor.path.size()-1:actor.forward=false;actor.pause=0.7
			elif actor.path_index==0:actor.forward=true;actor.pause=0.7
			actor.path_index+=1 if actor.forward else -1

	if is_instance_valid(clock_label) and not state.is_empty():
		if mode=="raid" and state.has("raid"):clock_label.text="การต่อสู้อัตโนมัติ • %d วิ" % maxi(0,int(state.raid.finish-now_time()))
		elif mode=="home" and selected>=0 and selected<state.buildings.size():clock_label.text=remaining(state.buildings[selected].finish)

func draw_battle():
	battle_visual=true;base_cache.clear();clear(world);actors=[];battle_nodes=[];battle_buildings=[];defense_nodes=[];home_units=[]
	pivot=Vector3.ZERO;position_camera()
	var enemy=state.raid.enemy
	var buildings=enemy.get("buildings",[
		{"id":"hall","x":7,"y":6,"level":1},{"id":"tower","x":5,"y":8,"level":1},
		{"id":"tower","x":9,"y":8,"level":1},{"id":"granary","x":6,"y":6,"level":1},
		{"id":"crystal","x":9,"y":6,"level":1},{"id":"tank","x":8,"y":6,"level":1}])
	for b in buildings:
		var model=base_model(b,buildings,float(enemy.get("pill_fill",0.65)));model.position=building_position(b);world.add_child(model)
		battle_buildings.append({"node":model,"kind":b.id,"width":footprint(b),"destroyed":false})
		if b.id=="training" and footprint(b)==1:model.scale=Vector3(0.49,1,0.49)
	for kind in range(10):
		for i in range(mini(20,Troops.count(state.raid.army,kind))):
			var node=art.person(kind);world.add_child(node)
			var start=cell_pos(4+i*0.45,13+kind*0.5)
			var target=cell_pos(4+(i%8)*0.8,8.4+(i/8)*0.65)
			battle_nodes.append({"node":node,"start":start,"target":target,"kind":kind,"phase":i})
	var guards=enemy.get("garrison",[0,0,0])
	for kind in range(10):
		for i in range(Troops.count(guards,kind)):
			var node=art.person(kind);world.add_child(node)
			battle_nodes.append({"node":node,"start":cell_pos(4+(i%8)*0.65,3+(i/8)*0.35+kind*0.15),"target":cell_pos(4+(i%8)*0.8,7.8-(i/8)*0.65),"kind":kind,"phase":i})
	message("กำลังบุก "+str(enemy.name)+" • การต่อสู้อัตโนมัติรุ่นทดลอง")

func _notification(what):
	if is_instance_valid(practice):return
	if what==NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(api) and not state.is_empty() and not api.busy:api.action("sync")

func update_raid_destruction(progress: float, ratio: float):
	var count=floori(battle_buildings.size()*clampf(ratio,0,1))
	for i in range(count):
		var target=battle_buildings[i]
		if target.destroyed or progress<0.36+0.63*float(i+1)/maxi(1,count):continue
		target.destroyed=true;target.node.hide()
		if target.kind!="wall":art.ruins(world,target.node.position,target.kind,target.width)
		art.impact_fx(world,target.node.position,7)

func builder_count() -> int:
	return state.get("buildings",[]).filter(func(b):return b.id=="servant").size()
func builder_price() -> int:
	var prices=find_catalog("servant").get("jade_prices",[0,250,500,1000,2000,3500,5000])
	return int(prices[mini(6,builder_count())])
func show_gifts():
	clear_preview();fingers.clear();menu_touch=-1
	var box=modal_box(Vector2(200,100),Vector2(850,480))
	var title=HBoxContainer.new();box.add_child(title)
	var picture=TextureRect.new();picture.texture=load("res://assets/ui/gift.svg");picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.custom_minimum_size=Vector2(56,56);title.add_child(picture)
	label(title,"ของขวัญประจำวัน",28)
	label(box,"เช็คอินวันละครั้ง • สะสมครบ 7 ครั้งรับรางวัลใหญ่",18)
	var grid=GridContainer.new();grid.columns=7;box.add_child(grid)
	var count=int(state.get("checkin_count",0));var completed=count%7
	if completed==0 and count>0 and not checkin_available:completed=7
	for day in range(7):
		var card=PanelContainer.new();card.custom_minimum_size=Vector2(110,124);grid.add_child(card)
		var style=VisualStyle.panel();style.set_content_margin_all(7);style.border_color=Color("f6d680" if day==completed and checkin_available else "729a83");card.add_theme_stylebox_override("panel",style)
		var column=VBoxContainer.new();card.add_child(column)
		label(column,"วันที่ %d" % (day+1),17)
		var icon=TextureRect.new();icon.texture=load("res://assets/ui/jade.svg");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(40,34);column.add_child(icon)
		label(column,"%d หยก" % (20 if day==6 else 5),18)
		label(column,"รับแล้ว ✓" if day<completed else ("วันนี้" if day==completed and checkin_available else "รอรับ"),14)
	var claim=button(box,"รับของขวัญวันนี้" if checkin_available else "รับแล้ว • กลับมาใหม่พรุ่งนี้",claim_daily)
	claim.disabled=not checkin_available or gift_claiming or api.busy
	button(box,"เล่นเกมจับคู่ • ผ่าน 1 ด่านรับ %d หยก" % int(state.get("match_reward_jade",2)),func():close_modal();show_match())
	label(box,"โฆษณาระหว่างด่านทุกครั้งที่ผ่านครบ 2 ด่าน",16)
	button(box,"ปิด",close_modal)

func claim_daily():
	if gift_claiming or not checkin_available or api.busy:return
	gift_claiming=true;send("checkin",{})

func wall_dialog(operation: String, scope: String):
	var indices=[selected] if scope=="one" else Walls.run_indices(state.buildings,selected)
	if scope=="all":
		indices=[]
		for i in range(state.buildings.size()):
			if state.buildings[i].id=="wall":indices.append(i)
	var eligible=[];var cost=0
	for i in indices:
		var b=state.buildings[i]
		if operation=="delete" or (int(b.level)<10 and int(b.level)<building_level("hall")+1):eligible.append(i);cost+=5*int(pow(2,b.level))
	var box=modal_box(Vector2(300,140),Vector2(650,370))
	label(box,("ลบ" if operation=="delete" else "อัปเกรด")+"กำแพง %d ชิ้น"%eligible.size(),25)
	label(box,"ลบถาวร ไม่คืนทรัพยากร" if operation=="delete" else "ใช้ น้ำ %d / ข้าว %d"%[cost,cost],19)
	var snapshot=wall_signature();var anchor=selected
	var confirm=button(box,"ยืนยัน",func():close_modal();selected=-1;send("wall_manage",{"index":anchor,"scope":scope,"operation":operation,"signature":snapshot}))
	confirm.disabled=eligible.is_empty()
	button(box,"ยกเลิก",close_modal)

func wall_signature() -> String:
	var parts=PackedStringArray()
	for i in range(state.buildings.size()):
		var b=state.buildings[i]
		if b.id=="wall":parts.append("%d:%d:%d:%d"%[i,b.x,b.y,b.level])
	return ",".join(parts)

func update_storage_visuals():
	for b in state.get("buildings",[]):
		var resource={"tank":"water","granary":"rice","crystal":"stone"}.get(b.id,"")
		if resource.is_empty():continue
		var key=JSON.stringify(b)
		if not base_cache.has(key) or not is_instance_valid(base_cache[key]):continue
		var model=base_cache[key]
		var fill=clampf(float(state.get(resource,0))/maxf(1,float(caps.get(resource,1000))),0,1)
		model.set_meta("storage_fill",fill)
		var amount=model.get_node_or_null("StorageAmount")
		if amount!=null:amount.text=str(roundi(fill*100))+"%"

func refresh_selection():
	if is_instance_valid(selection_marker):selection_marker.queue_free();selection_marker=null
	if state.is_empty() or selected<0 or selected>=state.get("buildings",[]).size() or mode!="home":return
	var b=state.buildings[selected]
	selection_marker=Node3D.new();world.add_child(selection_marker);selection_marker.position=building_position(b)
	var width=footprint(b)*3.0
	for side in [-1,1]:
		art.box(selection_marker,Vector3(side*width/2,0.09,0),Vector3(0.07,0.035,width),"7cd7ed")
		art.box(selection_marker,Vector3(0,0.09,side*width/2),Vector3(width,0.035,0.07),"7cd7ed")

func confirm_upgrade(index: int,costs: Array):
	if index<0 or index>=state.buildings.size():return
	var b=state.buildings[index];var signature=JSON.stringify(b)
	var box=modal_box(Vector2(350,180),Vector2(580,320))
	label(box,"อัปเกรด "+find_catalog(b.id).get("name",b.id),25)
	label(box,"ระดับ %d → %d" % [int(b.level),int(b.level)+1],22)
	label(box,"ใช้ น้ำ %d • ข้าว %d • โอสถ %d" % costs,19)
	button(box,"ยืนยันอัปเกรด",func():
		close_modal()
		if index>=state.buildings.size() or JSON.stringify(state.buildings[index])!=signature:message("ข้อมูลอาคารเปลี่ยนแล้ว กรุณาเลือกใหม่");return
		send("upgrade",{"index":index})
	)
	button(box,"ยกเลิก",close_modal)

func show_settings():
	var box=modal_box(Vector2(380,160),Vector2(520,380))
	label(box,"ตั้งค่าการแสดงผล",26)
	var toggle=button(box,"เอฟเฟกต์: "+("ประหยัด" if low_effects else "ปกติ"),func():
		low_effects=not low_effects;art.fx_limit=8 if low_effects else 28
		if is_instance_valid(practice):practice.art.fx_limit=art.fx_limit
		var config=ConfigFile.new();config.set_value("graphics","low_effects",low_effects);config.save("user://display.cfg")
		show_settings()
	)
	label(box,"โหมดประหยัดลดจำนวนประกายโจมตีที่แสดงพร้อมกัน",17)
	button(box,"จัดมุมมองกลางสำนัก",func():pivot=Vector3.ZERO;camera.size=29;position_camera();close_modal())
	button(box,"ปิด",close_modal)
