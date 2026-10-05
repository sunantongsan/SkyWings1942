extends Node3D
signal closed
const Sim=preload("res://scripts/practice_sim.gd")
const Walls=preload("res://scripts/wall_layout.gd")
const VisualStyle=preload("res://scripts/visual_style.gd")
const Art=preload("res://scripts/art.gd")
const SAVE="user://practice_stars.json"
var sim=Sim.new()
var art=Art.new()
var fingers: Dictionary={}
var gesture_start=Vector2.ZERO
var gesture_moved=false
var gesture_pinch=false
var pivot=Vector3.ZERO
var wall_revision=-1
var camera: Camera3D
var battlefield: Node3D
var hud: Control
var sidebar: VBoxContainer
var heading: Label
var hint: Label
var unit_buttons: Array = []
var level_picker: OptionButton
var models: Array = []
var unit_models: Array = []
var projectiles: Array = []
var records: Dictionary = {}
var level=1
var selected_kind=0
var result_shown=false
var accumulator=0.0
var test_mode=false
func _ready():
	if FileAccess.file_exists(SAVE):
		var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		if data is Dictionary:records=data
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=42;camera.far=250;camera.h_offset=6
	add_child(camera);position_camera();camera.make_current()
	battlefield=Node3D.new();add_child(battlefield)
	var layer=CanvasLayer.new();layer.layer=10;add_child(layer)
	hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(hud)
	hud.theme=VisualStyle.theme()
	var header=panel(Vector2(16,12),Vector2(1248,66));heading=text(header,"ประลองบอทออฟไลน์",24)
	var right=panel(Vector2(960,92),Vector2(304,530));sidebar=VBoxContainer.new();right.add_child(sidebar)
	level_picker=OptionButton.new();level_picker.custom_minimum_size.y=48;sidebar.add_child(level_picker)
	level_picker.item_selected.connect(func(i):start_level(i+1))
	text(sidebar,"แตะขอบเขียวเพื่อปล่อยศิษย์\nลากพื้นเลื่อน / จีบสองนิ้วซูม",17)
	for i in range(3):
		var b=button(sidebar,"",func():selected_kind=i;refresh_hud());unit_buttons.append(b)
	text(sidebar,"ขั้นต้น: เดิน / เจาะกำแพง\nฝึกปราณ: บิน / กระบี่ระยะไกล\nมังกร: ข้ามกำแพง / ตีป้อม",16)
	var zoom_row=HBoxContainer.new();sidebar.add_child(zoom_row)
	button(zoom_row,"− ซูมออก",func():camera.size=minf(72,camera.size+4))
	button(zoom_row,"+ ซูมเข้า",func():camera.size=maxf(24,camera.size-4))
	button(zoom_row,"ทั้งฐาน",func():camera.size=64;pivot=Vector3.ZERO;position_camera())
	button(sidebar,"จบการประลอง",func():sim.finished=true;finish())
	var footer=panel(Vector2(16,634),Vector2(1248,70));var row=HBoxContainer.new();footer.add_child(row)
	hint=text(row,"",17);hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(row,"เล่นใหม่",func():start_level(level));button(row,"กลับสำนัก",func():closed.emit())
	start_level(1)
func panel(pos: Vector2, extent: Vector2) -> PanelContainer:
	var p=PanelContainer.new();p.position=pos;p.size=extent
	p.add_theme_stylebox_override("panel",VisualStyle.panel());hud.add_child(p);return p
func text(parent: Node, value: String, size=18) -> Label:
	var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(l);return l
func button(parent: Node, value: String, callback: Callable) -> Button:
	var b=Button.new();b.text=value;b.custom_minimum_size.y=44;b.pressed.connect(callback);parent.add_child(b);return b
func world_pos(p: Vector2, height=0.0) -> Vector3:return Vector3((p.x-7.5)*3,height,(p.y-7.5)*3)
func start_level(value: int):
	level=value;result_shown=false;accumulator=0;sim.setup(level);wall_revision=-1;pivot=Vector3.ZERO;position_camera()
	for child in battlefield.get_children():child.queue_free()
	models.clear();unit_models.clear();projectiles.clear()
	art.landscape(battlefield,level%2==0,true)
	dress_battlefield()
	for b in sim.buildings:
		var model=art.wall(Walls.mask(sim.buildings,Vector2i(b.pos)),0,level) if b.kind=="wall" else art.building(b.kind,level);battlefield.add_child(model);model.position=world_pos(b.pos)
		var bar=health_bar(model,art.model_bounds(model).end.y+0.35);models.append({"node":model,"bar":bar})
	level_picker.clear()
	for i in range(1,13):
		level_picker.add_item("ฐาน %02d  %s" % [i,"★".repeat(int(records.get(str(i),0)))])
		# Earn one star to open the next challenge; replay any unlocked base.
		level_picker.set_item_disabled(i-1,i>1 and int(records.get(str(i-1),0))==0)
	level_picker.select(level-1);level_picker.disabled=false
	hint.text="ฝึกฟรี • ไม่เสียศิษย์ / ไม่ให้ทรัพยากรออนไลน์ • ดาวบันทึกในเครื่อง"
	refresh_hud()
func health_bar(parent: Node3D, height: float) -> MeshInstance3D:
	art.box(parent,Vector3(0,height,0),Vector3(1.7,0.13,0.13),"392f32")
	return art.box(parent,Vector3(0,height,0.08),Vector3(1.65,0.14,0.14),"86df8b")
func refresh_hud():
	heading.text="ฐานบอท %02d  •  ทำลาย %d%%  •  %s  •  เวลา %d:%02d" % [level,sim.percent(),"★".repeat(sim.stars())+"☆".repeat(3-sim.stars()),int(maxf(0,180-sim.elapsed))/60,int(maxf(0,180-sim.elapsed))%60]
	for i in range(3):
		unit_buttons[i].text=("▶ " if i==selected_kind else "")+["ศิษย์ชั้นต้น","ศิษย์ฝึกปราณ","มังกรเทวะ"][i]+" × %d" % sim.reserve[i]
		unit_buttons[i].disabled=sim.reserve[i]<=0 or sim.finished
func place_at(screen: Vector2):
	if not Rect2(0,82,950,540).has_point(screen) or sim.finished:return
	var hit=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(screen),camera.project_ray_normal(screen))
	if hit==null:return
	var cell=Vector2i(roundi(hit.x/3+7.5),roundi(hit.z/3+7.5))
	if not sim.deploy(selected_kind,cell):hint.text="แตะพื้นที่ขอบสีเขียวเพื่อปล่อยศิษย์";return
	level_picker.disabled=true
	var model=art.person(selected_kind);battlefield.add_child(model);model.position=world_pos(Vector2(cell),2.4 if selected_kind==1 else 0)
	unit_models.append({"node":model,"bar":health_bar(model,2.0)})
	hint.text="★ ทำลายสำนักหลัก  •  ★ ทำลาย 50%  •  ★ ทำลายทั้งหมด"
	refresh_hud()
func position_camera():
	camera.position=pivot+Vector3(42,58,42);camera.look_at(pivot)
func pan(relative: Vector2):
	pivot+=Vector3(-relative.x-relative.y,0,relative.x-relative.y)*camera.size/1400.0
	pivot.x=clampf(pivot.x,-22,22);pivot.z=clampf(pivot.z,-22,22);position_camera()
func _unhandled_input(event):
	var area=Rect2(0,82,950,540)
	if event is InputEventScreenTouch:
		if event.pressed and area.has_point(event.position):
			if fingers.is_empty():gesture_start=event.position;gesture_moved=false;gesture_pinch=false
			fingers[event.index]=event.position
			if fingers.size()>1:gesture_pinch=true
		elif not event.pressed and fingers.has(event.index):
			if fingers.size()==1 and not gesture_moved and not gesture_pinch:place_at(event.position)
			fingers.erase(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		if fingers.size()>1:
			var points=fingers.values();var before=points[0].distance_to(points[1]);fingers[event.index]=event.position;points=fingers.values()
			var after=points[0].distance_to(points[1]);if after>1:camera.size=clampf(camera.size*before/after,24,72)
		else:
			fingers[event.index]=event.position
			if event.position.distance_to(gesture_start)>10:gesture_moved=true
			if gesture_moved and not gesture_pinch:pan(event.relative)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION and area.has_point(event.position):
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:camera.size=maxf(24,camera.size-3)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:camera.size=minf(72,camera.size+3)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:gesture_start=event.position;gesture_moved=false
			elif not gesture_moved:place_at(event.position)
	elif event is InputEventMouseMotion and event.device!=InputEvent.DEVICE_ID_EMULATION and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		if event.position.distance_to(gesture_start)>10:gesture_moved=true
		if gesture_moved:pan(event.relative)
func dress_battlefield():
	# Wide approach paths, central paving, bamboo/rock framing and paired lanterns.
	for i in range(3,13):
		for pos in [Vector2(i,7),Vector2(8,i)]:art.box(battlefield,world_pos(pos,0.03),Vector3(2.9,0.03,2.9),"b8b19c")
	for x in range(5,11):
		for y in range(5,11):
			if (x+y)%2==0:art.box(battlefield,world_pos(Vector2(x,y),0.04),Vector3(2.75,0.02,2.75),"a9b091")
	for p in [Vector2(3,4),Vector2(12,4),Vector2(3,11),Vector2(12,11)]:
		art.lantern(battlefield,world_pos(p),1.0)
	# Foreground framing gives each base depth while keeping the deploy border readable.
	for p in [Vector2(1,3),Vector2(14,4),Vector2(2,12),Vector2(13,12)]:
		art.bamboo_cluster(battlefield,world_pos(p),0.85)
	for p in [Vector2(2,5),Vector2(13,6),Vector2(4,13),Vector2(11,2)]:art.rock(battlefield,world_pos(p),0.75)
func _process(delta):
	if test_mode:return
	accumulator+=minf(delta,0.25)
	while accumulator>=0.1:
		accumulator-=0.1;sim.step(0.1)
		for shot in sim.shots:
			if shot.has("unit"):
				var actor=unit_models[shot.unit].node;var direction: Vector2=shot.to-shot.from
				actor.rotation.y=atan2(direction.x,direction.y);art.pose(actor,"attack",[0.7,1.0,1.1][shot.kind])
			if shot.has("to"):art.impact_fx(battlefield,world_pos(shot.to,1.0),int(shot.kind))
			if not shot.enemy and shot.kind!=1:continue
			var node=art.box(battlefield,world_pos(shot.from,2),Vector3(0.16,0.12,1.1),"ee8868" if shot.enemy else "adf0ff")
			projectiles.append({"node":node,"start":world_pos(shot.from,2),"end":world_pos(shot.to,1),"age":0.0})
	if wall_revision!=sim.revision:
		wall_revision=sim.revision
		for i in range(sim.buildings.size()):
			var b=sim.buildings[i]
			if b.kind!="wall" or b.hp<=0:continue
			var mask=Walls.mask(sim.buildings,Vector2i(b.pos))
			if models[i].node.get_meta("wall_mask",-1)==mask:continue
			models[i].node.queue_free()
			var model=art.wall(mask,0,level);battlefield.add_child(model);model.position=world_pos(b.pos)
			models[i]={"node":model,"bar":health_bar(model,2.5)}
	for i in range(sim.buildings.size()):
		var b=sim.buildings[i];models[i].bar.scale.x=maxf(0.001,b.hp/b.max_hp)
		if b.hp<=0 and models[i].node.visible:
			models[i].node.hide();art.ruins(battlefield,world_pos(b.pos),b.kind);art.impact_fx(battlefield,world_pos(b.pos,0.5),0)
	for i in range(sim.units.size()):
		var u=sim.units[i];var node=unit_models[i].node
		node.visible=u.hp>0;unit_models[i].bar.scale.x=maxf(0.001,u.hp/u.max_hp)
		var target=world_pos(u.pos,2.4 if u.kind==1 else absf(sin(sim.elapsed*5))*0.16 if u.kind==2 else 0)
		var diff=target-node.position
		if Vector2(diff.x,diff.z).length()>0.01 and u.moving:node.rotation.y=atan2(diff.x,diff.z)
		art.pose(node,"walk" if u.moving else "idle")
		node.position=target
	for i in range(projectiles.size()-1,-1,-1):
		var p=projectiles[i];p.age+=delta;p.node.position=p.start.lerp(p.end,minf(1,p.age/0.25))
		if p.age>=0.25:p.node.queue_free();projectiles.remove_at(i)
	refresh_hud()
	if sim.finished and not result_shown:finish()
func finish():
	if result_shown:return
	result_shown=true;sim.finished=true
	var stars=sim.stars();records[str(level)]=maxi(stars,int(records.get(str(level),0)))
	var file=FileAccess.open(SAVE,FileAccess.WRITE)
	if file:file.store_string(JSON.stringify(records))
	level_picker.disabled=false
	if level<12 and stars>0:level_picker.set_item_disabled(level,false)
	hint.text="จบการประลอง: %s • ทำลาย %d%% • %s" % ["★".repeat(stars)+"☆".repeat(3-stars),sim.percent(),"เปิดฐานถัดไปแล้ว" if stars>0 and level<12 else "ลองจัดแนวโจมตีใหม่"]
