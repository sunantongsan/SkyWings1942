extends Node3D
const Iso=preload("res://scripts/iso_layout.gd")
const Troops=preload("res://scripts/troops.gd")
signal closed
const Sim=preload("res://scripts/practice_sim.gd")
const Walls=preload("res://scripts/wall_layout.gd")
const VisualStyle=preload("res://scripts/visual_style.gd")
const Art=preload("res://scripts/art.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Defenses=preload("res://scripts/campaign_defenses.gd")
var campaign_mode=false
var progress=preload("res://scripts/campaign_progress.gd").new()
var campaign_map: Control
var result_panel: Control
var visual_level=1
var trap_models: Array=[]
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
var troop_scroll: ScrollContainer
var scroll_touch=-1
var scroll_start=Vector2.ZERO
var scroll_origin=0.0
var scroll_dragged=false
var scroll_velocity=0.0
var scroll_button: Button
var hud_elapsed=0.0
var sidebar: VBoxContainer
var skill_label: Label
var heading: Label
var hint: Label
var unit_buttons: Array = []
var level_picker: OptionButton
var models: Array = []
var unit_models: Array = []
var guard_models: Array=[]
var projectiles: Array = []
var records: Dictionary = {}
var level=1
var selected_kind=0
var result_shown=false
var accumulator=0.0
var test_mode=false
func _ready():
	if campaign_mode:progress.load_progress();records=progress.stars
	if not campaign_mode and FileAccess.file_exists(SAVE):
		var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		if data is Dictionary:records=data
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=42;camera.far=250;camera.h_offset=6
	add_child(camera);position_camera();camera.make_current()
	battlefield=Node3D.new();add_child(battlefield)
	var layer=CanvasLayer.new();layer.layer=10;add_child(layer)
	hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(hud)
	hud.theme=VisualStyle.theme()
	var header=panel(Vector2(16,12),Vector2(1248,66));heading=text(header,"ประลองบอทออฟไลน์",24)
	var right=panel(Vector2(960,92),Vector2(304,530));var scroll=ScrollContainer.new();troop_scroll=scroll;right.add_child(scroll);sidebar=VBoxContainer.new();sidebar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(sidebar)
	level_picker=OptionButton.new();level_picker.custom_minimum_size.y=48;sidebar.add_child(level_picker)
	level_picker.item_selected.connect(func(i):start_level(i+1))
	if campaign_mode:
		level_picker.hide()
		button(sidebar,"แผนที่ 90 ด่าน",request_map)
		button(sidebar,"คู่มือป้อมป้องกัน",show_defense_guide)
	text(sidebar,"แตะขอบเขียวเพื่อปล่อยศิษย์\nลากพื้นเลื่อน / จีบสองนิ้วซูม",17)
	for i in range(10):
		var b=button(sidebar,"",func():selected_kind=i;refresh_hud());unit_buttons.append(b)
		var sheet=load("res://assets/realistic/"+Troops.ASSETS[i]+".webp")
		var portrait=AtlasTexture.new();portrait.atlas=sheet;portrait.region=Rect2(0,0,sheet.get_width()/4.0,sheet.get_height()/2.0)
		b.icon=portrait;b.expand_icon=true;b.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT;b.add_theme_constant_override("icon_max_width",44);b.custom_minimum_size.y=64
	text(sidebar,"นักรบแต่ละชนิดมีสกิลเฉพาะ\nโจรปีนกำแพง • เสือล่านักรบ\nคนหินทุบสิ่งกีดขวาง",16)
	skill_label=text(sidebar,"",16)
	var zoom_row=HBoxContainer.new();sidebar.add_child(zoom_row)
	button(zoom_row,"− ซูมออก",func():camera.size=minf(72,camera.size+4))
	button(zoom_row,"+ ซูมเข้า",func():camera.size=maxf(24,camera.size-4))
	button(zoom_row,"ทั้งฐาน",func():camera.size=64;pivot=Vector3.ZERO;position_camera())
	button(sidebar,"จบการบุก" if campaign_mode else "จบการประลอง",func():sim.finished=true;finish())
	var footer=panel(Vector2(16,634),Vector2(1248,70));var row=HBoxContainer.new();footer.add_child(row)
	hint=text(row,"",17);hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(row,"เล่นใหม่",func():request_restart() if campaign_mode and sim.started and not sim.finished else start_level(level));button(row,"แผนที่" if campaign_mode else "กลับสำนัก",func():request_map() if campaign_mode else closed.emit())
	start_level(progress.selected if campaign_mode else 1)
	if campaign_mode:show_campaign_map()
func panel(pos: Vector2, extent: Vector2) -> PanelContainer:
	var p=PanelContainer.new();p.position=pos;p.size=extent
	p.add_theme_stylebox_override("panel",VisualStyle.panel());hud.add_child(p);return p
func text(parent: Node, value: String, size=18) -> Label:
	var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(l);return l
func button(parent: Node, value: String, callback: Callable) -> Button:
	var b=Button.new();b.text=value;b.custom_minimum_size.y=44;b.pressed.connect(callback);parent.add_child(b);return b
func world_pos(p: Vector2, height=0.0) -> Vector3:return Iso.world_cell(p.x,p.y,height)
func start_level(value: int):
	if campaign_mode and (value<1 or value>progress.unlocked()):return
	if is_instance_valid(campaign_map):campaign_map.hide()
	if is_instance_valid(result_panel):result_panel.queue_free();result_panel=null
	fingers.clear();scroll_touch=-1;scroll_velocity=0
	level=value;result_shown=false;accumulator=0
	if campaign_mode:sim.setup_campaign(level)
	else:sim.setup(level)
	visual_level=sim.campaign_data.visual_level if campaign_mode else level
	wall_revision=-1;pivot=Vector3.ZERO
	if campaign_mode:camera.size=64
	position_camera()
	for child in battlefield.get_children():
		battlefield.remove_child(child);child.queue_free()
	models.clear();unit_models.clear();guard_models.clear();projectiles.clear();trap_models.clear()
	var terrain=Node3D.new();terrain.name="Terrain";battlefield.add_child(terrain)
	art.landscape(terrain,level%2==0,true)
	dress_battlefield()
	for b in sim.buildings:
		var model=art.wall(Walls.mask(sim.buildings,Vector2i(b.pos)),0,visual_level) if b.kind=="wall" else art.building(b.kind,visual_level);battlefield.add_child(model);model.position=world_pos(b.pos)
		var bar=health_bar(model,art.model_bounds(model).end.y+0.35);models.append({"node":model,"bar":bar})
	for trap in sim.traps:
		var marker=art.cone(battlefield,world_pos(trap.pos,0.13),0.65,0.60,0.16,"5d6258",12);marker.visible=false;trap_models.append(marker)
	for guard in sim.defenders:
		var actor=art.person(guard.kind);battlefield.add_child(actor);actor.position=world_pos(guard.pos,2.4 if Troops.air(guard.kind) else 0)
		guard_models.append({"node":actor,"bar":health_bar(actor,2.1)})
	level_picker.clear()
	for i in range(1,91 if campaign_mode else 13):
		level_picker.add_item("ฐาน %02d  %s" % [i,"★".repeat(int(records.get(str(i),0)))])
		# Earn one star to open the next challenge; replay any unlocked base.
		level_picker.set_item_disabled(i-1,i>1 and int(records.get(str(i-1),0))==0)
	level_picker.select(level-1);level_picker.disabled=false
	hint.text=sim.campaign_data.tip if campaign_mode else "ฝึกฟรี • ไม่เสียศิษย์ / ไม่ให้ทรัพยากรออนไลน์ • ดาวบันทึกในเครื่อง"
	refresh_hud()
func health_bar(parent: Node3D, height: float) -> MeshInstance3D:
	art.box(parent,Vector3(0,height,0),Vector3(1.7,0.13,0.13),"392f32")
	return art.box(parent,Vector3(0,height,0.08),Vector3(1.65,0.14,0.14),"86df8b")
func refresh_hud():
	if is_instance_valid(skill_label):skill_label.text=Troops.SKILLS[selected_kind]+"\n"+Troops.DETAILS[selected_kind]
	heading.text="ฐานบอท %02d  •  ทำลาย %d%%  •  %s  •  เวลา %d:%02d" % [level,sim.percent(),"★".repeat(sim.stars())+"☆".repeat(3-sim.stars()),int(maxf(0,180-sim.elapsed))/60,int(maxf(0,180-sim.elapsed))%60]
	if campaign_mode:heading.text="ด่าน %02d • %s • %d%% • %s • ไม่จำกัดเวลา"%[level,Campaign.CHAPTERS[int((level-1)/10)],sim.percent(),"★".repeat(sim.stars())+"☆".repeat(3-sim.stars())]
	for i in range(10):
		unit_buttons[i].visible=not campaign_mode or sim.campaign_data.reserve[i]>0
		unit_buttons[i].text=("▶ " if i==selected_kind else "")+Troops.NAMES[i]+" × %d" % sim.reserve[i]
		unit_buttons[i].disabled=sim.reserve[i]<=0 or sim.finished
func place_at(screen: Vector2):
	if overlay_open():return
	if not Rect2(0,82,950,540).has_point(screen) or sim.finished:return
	var hit=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(screen),camera.project_ray_normal(screen))
	if hit==null:return
	var cell=Vector2i(roundi(hit.x/3+7.5),roundi(hit.z/3+7.5))
	if not sim.deploy(selected_kind,cell):hint.text="แตะพื้นที่ขอบสีเขียวเพื่อปล่อยศิษย์";return
	level_picker.disabled=true
	var model=art.person(selected_kind);battlefield.add_child(model);model.position=world_pos(Vector2(cell),2.4 if Troops.air(selected_kind) else 0)
	unit_models.append({"node":model,"bar":health_bar(model,art.model_bounds(model).end.y+0.25)})
	hint.text="★ ทำลายสำนักหลัก  •  ★ ทำลาย 50%  •  ★ ทำลายทั้งหมด"
	refresh_hud()
func position_camera():
	Iso.place_camera(camera,pivot)
func pan(relative: Vector2):
	pivot+=Vector3(-relative.x-relative.y,0,relative.x-relative.y)*camera.size/1400.0
	pivot.x=clampf(pivot.x,-22,22);pivot.z=clampf(pivot.z,-22,22);position_camera()
func _unhandled_input(event):
	if overlay_open():return
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
	if campaign_mode:return # Layout-specific bases keep paths clear of structures.
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
	if test_mode or overlay_open():return
	if scroll_touch<0 and absf(scroll_velocity)>5:
		troop_scroll.scroll_vertical+=roundi(scroll_velocity*delta);scroll_velocity*=exp(-8*delta)
	accumulator+=minf(delta,0.25)
	while accumulator>=0.1:
		accumulator-=0.1;sim.step(0.1)
		for shot in sim.shots:
			if shot.has("unit") or shot.has("guard"):
				var actor=unit_models[shot.unit].node if shot.has("unit") else guard_models[shot.guard].node;var direction: Vector2=shot.to-shot.from
				actor.rotation.y=atan2(direction.x,direction.y);art.pose(actor,"attack",0.8,Vector3(direction.x,0,direction.y))
			if shot.get("trap",false):
				art.impact_fx(battlefield,world_pos(shot.from,0.3),8);continue
			if shot.get("weapon","")=="ward":
				art.sound_wave(battlefield,world_pos(shot.from),4.2*3);continue
			if not shot.has("weapon") and shot.has("to"):art.strike_fx(battlefield,world_pos(shot.from,shot.get("source_height",0.0)),world_pos(shot.to,shot.get("target_height",0.0)),int(shot.kind))
			if not shot.has("weapon"):continue
			var node=art.orb(battlefield,world_pos(shot.from,2.8),Vector3.ONE*0.2,"9d8d71") if shot.enemy else art.box(battlefield,world_pos(shot.from,2),Vector3(0.16,0.12,1.1),"adf0ff")
			projectiles.append({"node":node,"start":world_pos(shot.from,2.8 if shot.enemy else 2),"end":world_pos(shot.to,1+shot.get("target_height",0.0)),"age":0.0})
	if wall_revision!=sim.revision:
		wall_revision=sim.revision
		for i in range(sim.buildings.size()):
			var b=sim.buildings[i]
			if b.kind!="wall" or b.hp<=0:continue
			var mask=Walls.mask(sim.buildings,Vector2i(b.pos))
			if models[i].node.get_meta("wall_mask",-1)==mask:continue
			models[i].node.queue_free()
			var model=art.wall(mask,0,visual_level);battlefield.add_child(model);model.position=world_pos(b.pos)
			models[i]={"node":model,"bar":health_bar(model,2.5)}
	for i in range(sim.buildings.size()):
		var b=sim.buildings[i]
		if models[i].get("dead",false):continue
		models[i].bar.scale.x=maxf(0.001,b.hp/b.max_hp)
		if b.hp<=0 and models[i].node.visible:
			models[i].dead=true
			var dead=models[i].node;dead.hide();battlefield.remove_child(dead);dead.queue_free()
			if b.kind!="wall":art.ruins(battlefield,world_pos(b.pos),b.kind)
			art.impact_fx(battlefield,world_pos(b.pos,0.5),0)
	for i in range(sim.traps.size()):trap_models[i].visible=sim.traps[i].triggered
	for i in range(sim.units.size()):update_actor(sim.units[i],unit_models[i],delta)
	for i in range(sim.defenders.size()):update_actor(sim.defenders[i],guard_models[i],delta)
	for i in range(projectiles.size()-1,-1,-1):
		var p=projectiles[i];p.age+=delta;p.node.position=p.start.lerp(p.end,minf(1,p.age/0.25))
		if p.age>=0.25:p.node.queue_free();projectiles.remove_at(i)
	hud_elapsed+=delta
	if hud_elapsed>=0.15:
		hud_elapsed=0;refresh_hud()
	if sim.finished and not result_shown:finish()
func update_actor(u: Dictionary, visual: Dictionary,delta: float):
	var node=visual.node;node.visible=u.hp>0;visual.bar.scale.x=maxf(0.001,u.hp/u.max_hp)
	var height=2.4 if Troops.air(u.kind) else u.get("climbing",0.0)*2.3
	if u.kind==6 and u.windup>0 and u.pending_target.get("entity","")=="unit" and Troops.air(u.pending_target.kind):height+=sin(clampf(1-u.windup/0.35,0,1)*PI)*2.4
	var target=world_pos(u.pos,height);var diff=target-node.position
	if Vector2(diff.x,diff.z).length()>0.01 and u.moving:node.rotation.y=atan2(diff.x,diff.z)
	art.pose(node,"climb" if u.get("climbing",0.0)>0.05 else "walk" if u.moving else "idle")
	node.position=node.position.lerp(target,1.0-exp(-delta*18))
func finish():
	if result_shown:return
	result_shown=true;sim.finished=true
	if campaign_mode:
		var error=progress.record(level,sim.stars());records=progress.stars;refresh_hud();show_campaign_result(error);return
	var stars=sim.stars();records[str(level)]=maxi(stars,int(records.get(str(level),0)))
	var file=FileAccess.open(SAVE,FileAccess.WRITE)
	if file:file.store_string(JSON.stringify(records))
	level_picker.disabled=false
	if level<12 and stars>0:level_picker.set_item_disabled(level,false)
	hint.text="จบการประลอง: %s • ทำลาย %d%% • %s" % ["★".repeat(stars)+"☆".repeat(3-stars),sim.percent(),"เปิดฐานถัดไปแล้ว" if stars>0 and level<12 else "ลองจัดแนวโจมตีใหม่"]

	if sim.stolen.water+sim.stolen.rice+sim.stolen.stone>0:hint.text+=" • โจรขโมยได้ในสนามฝึก: น้ำ %d ข้าว %d โอสถ %d (ไม่เข้าออนไลน์)"%[sim.stolen.water,sim.stolen.rice,sim.stolen.stone]
func _exit_tree():
	sim.clear_targets()

func _input(event):
	if overlay_open():return
	if not is_instance_valid(troop_scroll):return
	var area=troop_scroll.get_global_rect()
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION and area.has_point(event.position):
		get_viewport().set_input_as_handled();return
	if event is InputEventScreenTouch:
		if event.pressed and area.has_point(event.position) and scroll_touch<0:
			# Let the native level dropdown handle its own taps.
			if level_picker.get_global_rect().has_point(event.position):return
			scroll_touch=event.index;scroll_start=event.position;scroll_origin=troop_scroll.scroll_vertical;scroll_dragged=false;scroll_velocity=0;scroll_button=null
			for child in sidebar.find_children("*","Button",true,false):
				if child.get_global_rect().has_point(event.position):scroll_button=child;break
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index==scroll_touch:
			var tapped=scroll_button
			scroll_touch=-1;scroll_button=null
			if not scroll_dragged and event.position.distance_to(scroll_start)<10 and is_instance_valid(tapped) and not tapped.disabled and tapped.get_global_rect().has_point(event.position):tapped.pressed.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==scroll_touch:
		var diff=event.position-scroll_start
		if absf(diff.y)>8 or scroll_dragged:
			scroll_dragged=true;troop_scroll.scroll_vertical=roundi(scroll_origin-diff.y)
			scroll_velocity=clampf(event.velocity.y*-1,-1200,1200)
		get_viewport().set_input_as_handled()

func overlay_open() -> bool:
	return (is_instance_valid(campaign_map) and campaign_map.visible) or is_instance_valid(result_panel)
func show_campaign_map():
	fingers.clear();scroll_touch=-1;scroll_velocity=0
	if is_instance_valid(result_panel):result_panel.queue_free();result_panel=null
	if not is_instance_valid(campaign_map):
		campaign_map=preload("res://scripts/campaign_map.gd").new();campaign_map.progress=progress;campaign_map.selected=level
		hud.add_child(campaign_map);campaign_map.launch.connect(start_level);campaign_map.leave.connect(func():closed.emit())
	campaign_map.selected=level;campaign_map.chapter=int((level-1)/10);campaign_map.refresh();campaign_map.show()
func make_dialog() -> VBoxContainer:
	fingers.clear();scroll_touch=-1;scroll_velocity=0
	if is_instance_valid(result_panel):result_panel.queue_free()
	result_panel=Control.new();result_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.add_child(result_panel)
	var shade=ColorRect.new();shade.color=Color(0.02,0.05,0.08,0.88);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_panel.add_child(shade)
	var box=PanelContainer.new();box.position=Vector2(350,170);box.custom_minimum_size=Vector2(580,360);box.add_theme_stylebox_override("panel",VisualStyle.panel());result_panel.add_child(box)
	var column=VBoxContainer.new();column.add_theme_constant_override("separation",16);box.add_child(column);return column
func request_restart():
	var column=make_dialog();text(column,"เริ่มด่านนี้ใหม่?",28);text(column,"การบุกครั้งนี้จะไม่บันทึกดาว",20)
	button(column,"เริ่มใหม่",func():start_level(level));button(column,"บุกต่อ",dismiss_dialog)
func request_map():
	if not sim.started or sim.finished:show_campaign_map();return
	var column=make_dialog();text(column,"กลับไปแผนที่?",28);text(column,"การบุกครั้งนี้จะไม่บันทึกดาว
เลือก ‘จบการบุก’ หากต้องการเก็บดาวที่ทำได้",20)
	button(column,"กลับแผนที่",show_campaign_map);button(column,"บุกต่อ",dismiss_dialog)
func dismiss_dialog():
	if is_instance_valid(result_panel):result_panel.queue_free();result_panel=null
func show_campaign_result(save_error: Error):
	var column=make_dialog();var score=sim.stars()
	text(column,"ด่าน %02d • %s"%[level,"ชนะแล้ว" if score>0 else "ลองใหม่อีกครั้ง"],28)
	var star_label=text(column,"★".repeat(score)+"☆".repeat(3-score),48);star_label.modulate=Color("ffd184")
	text(column,"ทำลาย %d%% • ดาวรวม %d / 270
%s"%[sim.percent(),progress.total(),"บันทึกในเครื่องแล้ว • เล่นซ้ำเก็บดาวเพิ่มได้" if save_error==OK else "บันทึกไม่สำเร็จ กรุณาตรวจพื้นที่ว่างในเครื่อง"],20)
	if score>0 and level<90:button(column,"บุกด่านถัดไป →",func():start_level(level+1))
	if score==3 and progress.total()==270:text(column,"พิชิตครบ 90 ด่าน • 270 ดาว!",24)
	button(column,"ลองด่านนี้อีกครั้ง",func():start_level(level));button(column,"แผนที่แคมเปญ",show_campaign_map)

func show_defense_guide():
	var column=make_dialog();text(column,"รู้จักป้อมป้องกัน",26)
	var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(550,255);column.add_child(scroll)
	var content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content)
	var notes={"cannon":"ยิงเป้าหมายพื้นดินทีละตัว • ใช้หน่วยบินเข้าทางนี้ได้","tower":"ยิงได้ทั้งพื้นดินและอากาศ • ระยะคุ้มกันกว้าง","mortar":"ยิงพื้นดินเป็นหมู่ • ยิงใกล้กว่า 2 ช่องไม่ได้","air_defense":"โจมตีเฉพาะหน่วยบิน • ใช้ทหารพื้นดินเข้าทำลาย","ward":"โจมตีหมู่รอบหอ • อย่ารวมทหารในรัศมีเดียวกัน","flame":"ยิงต่อเนื่องเป้าเดิมแรงขึ้น • ใช้หลายหน่วยเข้ากดดัน","storm":"สายฟ้าชิ่งใส่เป้าหมายใกล้กัน • แยกแนวโจมตี","bomb":"ระเบิดหน่วยพื้นดินที่เข้าใกล้ • ทำงานครั้งเดียว","air_mine":"ระเบิดหน่วยบินที่เข้าใกล้ • ทำงานครั้งเดียว"}
	for kind in notes:text(content,Defenses.NAMES[kind]+" — "+notes[kind],17)
	button(column,"กลับไปบุกต่อ",dismiss_dialog)
