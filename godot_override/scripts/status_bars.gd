extends RefCounted
var host:Node3D
var layer:Control
var world_rows:Dictionary={}
var job_panel:PanelContainer
var job_list:VBoxContainer
var job_rows:Array=[]
var job_key:=""
var raid_bar:ProgressBar
var raid_text:Label
func _init(game:Node3D)->void:
	host=game
	layer=Control.new();layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.z_index=-1;host.ui_root.add_child(layer)
	job_panel=PanelContainer.new();job_panel.add_theme_stylebox_override("panel",host._style(Color("102832"),10,Color("365966"),1));host.ui_root.add_child(job_panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);job_panel.add_child(column)
	var heading:=Label.new();heading.text="ACTIVE JOBS";heading.add_theme_font_size_override("font_size",16);column.add_child(heading)
	var scroll:=preload("res://scripts/touch_scroll.gd").new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	job_list=VBoxContainer.new();job_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;job_list.add_theme_constant_override("separation",8);scroll.add_child(job_list)
	raid_bar=make_bar(300,22,Color("64dce7"));host.ui_root.add_child(raid_bar)
	raid_text=Label.new();raid_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;raid_text.add_theme_font_size_override("font_size",15);raid_text.mouse_filter=Control.MOUSE_FILTER_IGNORE;host.ui_root.add_child(raid_text)
	job_panel.hide();raid_bar.hide();raid_text.hide()
func make_bar(width:float,height:float,color:Color)->ProgressBar:
	var bar:=ProgressBar.new();bar.min_value=0;bar.max_value=100;bar.show_percentage=false;bar.add_theme_font_size_override("font_size",1);bar.custom_minimum_size=Vector2(width,height);bar.size=bar.custom_minimum_size;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var background:StyleBoxFlat=host._style(Color("08151e"),3,Color("456270"),1)
	var fill:StyleBoxFlat=host._style(color,2,Color("10232c"),1)
	for style in [background,fill]:
		style.content_margin_left=0;style.content_margin_right=0;style.content_margin_top=0;style.content_margin_bottom=0
	bar.add_theme_stylebox_override("background",background);bar.add_theme_stylebox_override("fill",fill)
	return bar
func progress(start:float,finish:float)->float:
	return clampf((host.colony_time-start)/maxf(.001,finish-start),0,1)*100.0
func blocked()->bool:
	return host.build_panel.visible or host.units_panel.visible or host.galaxy_panel.visible or host.victory_panel.visible or host.onboarding.screen.visible or (is_instance_valid(host.coin_system.panel) and host.coin_system.panel.visible)
func world_row(key:String,pos:Vector3,health:float,maximum:float,work:float=-1.0,title:String="",building:bool=false)->void:
	if not world_rows.has(key):
		var root:=Control.new();root.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root)
		var hp:=make_bar(104 if building else 36,8 if building else 6,Color("5de295"));root.add_child(hp)
		var label:=Label.new();label.add_theme_font_size_override("font_size",13);label.add_theme_color_override("font_outline_color",Color("07151c"));label.add_theme_constant_override("outline_size",4);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(label)
		var task:=make_bar(104,9,Color("62dcf1"));root.add_child(task)
		world_rows[key]={"root":root,"hp":hp,"label":label,"task":task}
	var row:Dictionary=world_rows[key]
	row.root.visible=not blocked() and not host.camera.is_position_behind(pos)
	var point:Vector2=host.camera.unproject_position(pos)
	var bounds:Rect2=host.get_viewport().get_visible_rect()
	if not bounds.grow(40).has_point(point):row.root.hide()
	var has_work:bool=work>=0
	row.root.position=point-Vector2(52 if building else 18,54 if has_work else 22)
	row.hp.visible=maximum>0
	row.hp.value=clampf(health/maxf(1,maximum),0,1)*100
	var color:=Color("5de295") if row.hp.value>50 else (Color("ffd36b") if row.hp.value>25 else Color("ff6575"))
	row.hp.get_theme_stylebox("fill").bg_color=color
	row.label.visible=has_work;row.task.visible=has_work
	if has_work:
		row.label.position=Vector2(0,12);row.label.text=title;row.task.position=Vector2(0,32);row.task.value=work
func jobs()->Array:
	var result:Array=[]
	for b in host.buildings:
		if b.get("job","")!="":result.append({"name":str(b.job).to_upper()+" • "+host.BUILDING_NAMES[b.type],"start":float(b.started),"finish":float(b.finish)})
	for job in host.clearing_jobs:result.append({"name":"CLEAR "+("ROCK" if int(job.id)%4==0 else "TREE"),"start":float(job.started),"finish":float(job.finish)})
	for job in host.training_queue:result.append({"name":host.UNIT_NAMES[int(job.type)],"start":float(job.finish)-5-int(job.type)*2,"finish":float(job.finish)})
	if host.drone_finish>0:result.append({"name":"CONSTRUCTION DRONE","start":host.drone_finish-15,"finish":host.drone_finish})
	if host.miner_finish>0:result.append({"name":"MINING VEHICLE","start":host.miner_finish-15,"finish":host.miner_finish})
	return result
func tick()->void:
	var active:Dictionary={}
	var entities:Array=[]
	if host.mode=="base":entities=host.buildings+host.home_attackers
	elif host.mode=="battle":entities=host.battle_targets+host.battle_units
	for entity in entities:
		if entity.get("hp",0)<=0 or not is_instance_valid(entity.node):continue
		var building:bool=entity.has("rank_label")
		var key:=str(entity.node.get_instance_id());active[key]=true
		var height:float=5.4*entity.node.scale.y if building else (1.1 if int(entity.get("type",0))<10 else 2.2)
		var job:String=entity.get("job","")
		var work:float=progress(entity.started,entity.finish) if job!="" else -1.0
		world_row(key,entity.node.global_position+Vector3(0,height,0),entity.hp,entity.get("max_hp",entity.hp),work,"%s %d%%"%[job.to_upper(),int(work)],building)
		if host.mode=="base" and building:
			var selected:bool=host.selected_building>=0 and host.selected_building<host.buildings.size() and host.buildings[host.selected_building].node==entity.node and host.info_panel.visible
			world_rows[key].hp.visible=selected or entity.hp<entity.get("max_hp",entity.hp)
	if host.mode=="base":
		for job in host.clearing_jobs:
			var key:="clear_"+str(int(job.id));active[key]=true
			world_row(key,Vector3(job.pos[0],5.0,job.pos[2]),0,0,progress(job.started,job.finish),"CLEAR %d%%"%int(progress(job.started,job.finish)),true)
	for key in world_rows.keys():
		if not active.has(key):world_rows[key].root.queue_free();world_rows.erase(key)
	var tasks:Array=jobs()
	var signature:=""
	for job in tasks:signature+=str([job.name,job.start,job.finish])
	if signature!=job_key:
		job_key=signature
		for child in job_list.get_children():job_list.remove_child(child);child.queue_free()
		job_rows.clear()
		for job in tasks:
			var title:=Label.new();title.add_theme_font_size_override("font_size",13);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;job_list.add_child(title)
			var bar:=make_bar(284,12,Color("62dcf1"));job_list.add_child(bar);job_rows.append({"title":title,"bar":bar})
	for i in tasks.size():
		var job:Dictionary=tasks[i];var queued:bool=host.colony_time<float(job.start)
		job_rows[i].bar.value=progress(job.start,job.finish)
		job_rows[i].title.text="%s • %s %ds"%[job.name,"QUEUED" if queued else str(int(job_rows[i].bar.value))+"%",maxi(0,ceili((job.start if queued else job.finish)-host.colony_time))]
	job_panel.visible=host.mode=="base" and not tasks.is_empty() and not blocked() and not host.onboarding.guide.visible
	var screen:Vector2=host.get_viewport().get_visible_rect().size
	job_panel.position=Vector2(24,108);job_panel.size=Vector2(320,minf(minf(270,screen.y-300),44+tasks.size()*48))
	raid_bar.visible=host.mode=="battle" and not host.awaiting_deployment;raid_text.visible=raid_bar.visible
	raid_bar.position=Vector2(24,108);raid_text.position=raid_bar.position;raid_text.size=Vector2(300,22)
	raid_bar.value=clampf((150-host.battle_elapsed)/150.0,0,1)*100
	raid_text.text="BATTLE TIME • %ds"%maxi(0,ceili(150-host.battle_elapsed))
