extends Control
signal launch(number: int)
signal leave
const Campaign=preload("res://scripts/campaign.gd")
const Defenses=preload("res://scripts/campaign_defenses.gd")
const Troops=preload("res://scripts/troops.gd")
const Style=preload("res://scripts/visual_style.gd")
var progress
var chapter=0
var selected=1
var node_buttons=[]
var title: Label
var details: Label
var deploy_button: Button
var chapter_buttons=[]
var stars_label: Label
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;theme=Style.theme()
	var backdrop=ColorRect.new();backdrop.color=Color("101e2bf5");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	label_at("เส้นทางพิชิต 90 ด่าน",Vector2(40,22),Vector2(700,44),32)
	stars_label=label_at("",Vector2(790,29),Vector2(250,38),23)
	button_at("กลับสำนัก",Vector2(1090,24),Vector2(150,48),func():leave.emit())
	label_at("ออฟไลน์ • กองทัพประจำด่าน • ไม่จำกัดเวลา • 1 ดาวเปิดด่านถัดไป",Vector2(40,72),Vector2(1100,34),19)
	for c in range(9):
		var b=button_at("เขต %d"%(c+1),Vector2(40+c*134,119),Vector2(126,50),func():chapter=c;selected=c*10+1;refresh())
		chapter_buttons.append(b)
	var panel=Panel.new();panel.position=Vector2(40,192);panel.size=Vector2(816,446);panel.add_theme_stylebox_override("panel",Style.panel());add_child(panel)
	var ground=TextureRect.new();ground.texture=load("res://assets/realistic/ground.webp");ground.position=Vector2(10,10);ground.size=Vector2(796,426);ground.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;ground.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;ground.modulate=Color(0.36,0.49,0.48,0.7);ground.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(ground)
	var route=Line2D.new();route.width=6;route.default_color=Color("688c9b");panel.add_child(route)
	for i in range(10):route.add_point(point(i)+Vector2(46,28))
	for i in range(10):
		var icon=TextureRect.new();var sheet=load("res://assets/realistic/hall_levels.webp");var atlas=AtlasTexture.new();atlas.atlas=sheet;var region=JSON.parse_string(FileAccess.get_file_as_string("res://assets/realistic/atlas.json")).hall_levels[i];atlas.region=Rect2(region[0],region[1],region[2],region[3]);icon.texture=atlas;icon.position=point(i)+Vector2(12,-57);icon.size=Vector2(85,76);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(icon)
		var b=Button.new();b.position=point(i);b.size=Vector2(110,94);b.pressed.connect(func():selected=chapter*10+i+1;refresh());panel.add_child(b);node_buttons.append(b)
	label_at("แตะหมายเลขเพื่อดูฐาน • ★ สำนักหลัก  ★ ทำลาย 50%  ★ ทำลายทั้งหมด",Vector2(60,650),Vector2(1160,36),18)
	var side=Panel.new();side.position=Vector2(880,192);side.size=Vector2(360,446);side.add_theme_stylebox_override("panel",Style.panel());add_child(side)
	title=label_at("",Vector2(904,208),Vector2(312,76),23)
	details=label_at("",Vector2(904,293),Vector2(312,256),17)
	deploy_button=button_at("เริ่มบุก",Vector2(904,564),Vector2(312,52),func():
		if selected<=progress.unlocked():launch.emit(selected))
	chapter=int((selected-1)/10);refresh()
func point(i: int) -> Vector2:
	var col=i if i<5 else 9-i
	return Vector2(32+col*150,75 if i<5 else 265)
func label_at(value: String,pos: Vector2,extent: Vector2,font_size: int) -> Label:
	var label=Label.new();label.text=value;label.position=pos;label.size=extent;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font_size);add_child(label);return label
func button_at(value: String,pos: Vector2,extent: Vector2,callback: Callable) -> Button:
	var button=Button.new();button.text=value;button.position=pos;button.size=extent;button.pressed.connect(callback);add_child(button);return button
func refresh():
	stars_label.text="★ %d / 270"%progress.total()
	for c in range(9):
		chapter_buttons[c].text=("▶ " if c==chapter else "")+"เขต %d"%(c+1)
	for i in range(10):
		var n=chapter*10+i+1;var score=int(progress.stars.get(str(n),0));var locked=n>progress.unlocked()
		node_buttons[i].text=("▶ " if n==selected else "")+"%02d"%n+"\n"+("ยังไม่เปิด" if locked else "★".repeat(score)+"☆".repeat(3-score))
		node_buttons[i].modulate=Color("758697") if locked else Color("ffd995") if n==selected else Color.WHITE
	var stage=Campaign.stage(selected);var kinds=[]
	for b in stage.buildings:
		if Defenses.NAMES.has(b.kind) and not b.kind in kinds:kinds.append(b.kind)
	var defenses=[]
	for kind in kinds:defenses.append(Defenses.NAMES[kind])
	var troops=0
	for count in stage.reserve:troops+=count
	title.text="ด่าน %02d\n%s"%[selected,stage.name]
	details.text="%s\n\nป้อม: %s\nกับดัก %d จุด • ทหารยาม %d\nกองทัพ %d หน่วย\n\n%s"%["เจ้าด่าน" if selected%10==0 else "ความยากเขต %d / 9"%(chapter+1)," • ".join(defenses),stage.traps.size(),stage.guards.size(),troops,stage.tip]
	deploy_button.disabled=selected>progress.unlocked()
	deploy_button.text="ผ่านด่าน %d ก่อน"%(selected-1) if deploy_button.disabled else "บุกด่าน %02d"%selected
