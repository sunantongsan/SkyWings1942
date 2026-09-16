extends RefCounted
## Native responsive UI over the live 3D world. No raster welcome poster.
var host:Node3D
var screen:Control
var panel:PanelContainer
var column:VBoxContainer
var selected_planet:=-1
var selection_label:Label
var confirm_button:Button
var planet_buttons:Array[Button]=[]
var page:=""
var help_return:=""
var guide:PanelContainer
var guide_title:Label
var guide_text:Label
var guide_action:Button
var guide_progress:ProgressBar
var guide_suppressed:=false
var settle_frames:=0
const BIOMES:=["Lush frontier","Volcanic plains","Frozen frontier","Desert dunes","Midnight world","Ocean frontier","Machine world","Alien wetlands","Nebula outpost","Asteroid colony","Ancient ruins","Orbital colony","Lunar frontier","Cloud outpost","Rift colony"]
const WHY:=["Your command center earns Credits and unlocks the colony. Place it on clear terrain. The glowing site is a suggestion.","Supply your colony with Power. Other facilities depend on this reactor.","Start producing Metal for construction and upgrades.","Establish a resource depot before expanding your industry.","Produce Oil to train your fleet and support future operations.","Mine Crystal for advanced colony development.","Build the Star Hangar. This is where your fleet is trained.","Establish your first defensive position with a Laser Tower.","Prepare a Research Lab for future technology upgrades.","Complete your defenses with a Shield Generator."]

func _init(game:Node3D)->void:
	host=game
	screen=Control.new();screen.mouse_filter=Control.MOUSE_FILTER_STOP;host.ui_root.add_child(screen)
	var shade:=ColorRect.new();shade.color=Color(0.015,0.04,0.075,0.84);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);screen.add_child(shade)
	panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",host._style(Color("102832"),20,Color("4f99a4"),1));screen.add_child(panel)
	column=VBoxContainer.new();column.add_theme_constant_override("separation",12);panel.add_child(column)
	guide=PanelContainer.new();guide.add_theme_stylebox_override("panel",host._style(Color("102832"),14,Color("7cd8ba"),1));host.ui_root.add_child(guide)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",10);guide.add_child(content)
	guide_title=_label("",20,Color("95edcc"));guide_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(guide_title)
	guide_progress=ProgressBar.new();guide_progress.max_value=13;guide_progress.show_percentage=false;guide_progress.custom_minimum_size.y=5;content.add_child(guide_progress)
	guide_text=_label("",17,Color("c2d7dc"));guide_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(guide_text)
	guide_action=host._button("",_guide_pressed,Vector2(0,52));guide_action.add_theme_font_size_override("font_size",17);content.add_child(guide_action)
	guide.hide()
	layout()

func _label(text:String,size:int,color:=Color("eef5f5"))->Label:
	var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",size);label.modulate=color
	return label

func _clear()->void:
	for child in column.get_children():column.remove_child(child);child.queue_free()
	planet_buttons.clear()
	column.alignment=BoxContainer.ALIGNMENT_CENTER if page=="welcome" else BoxContainer.ALIGNMENT_BEGIN
	screen.show();guide.hide();host.header.hide();host.dock.hide();host.info_panel.hide();host.toast.hide()
	for p in [host.build_panel,host.units_panel,host.galaxy_panel]:p.hide()

func welcome()->void:
	page="welcome";_clear();host.mode="welcome"
	column.add_child(_label("GALAXY 1942   /   COLONY COMMAND",17,Color("7ee1d4")))
	var spacer:=Control.new();spacer.custom_minimum_size.y=16;column.add_child(spacer)
	column.add_child(_label("YOUR WORLD.\nYOUR COMMAND.",48))
	var intro:=_label("Choose your homeworld. Build a colony. Lead your fleet.",21,Color("b4cbd4"));intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(intro)
	var description:=_label("A guided expedition teaches you one step at a time.\nDrag to explore your planet. Pinch to zoom.",18,Color("b4cbd4"));description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(description)
	if host.has_colony:
		column.add_child(_label("COLONY SAVED  /  "+host.MAP_NAMES[host.home_planet].to_upper(),18,Color("89dfb4")))
		column.add_child(host._button("CONTINUE EXPEDITION",enter_colony,Vector2(0,64)))
	else:
		column.add_child(_label("LANDING SUPPLIES  /  10K Metal · 3K Credits · 1K Oil · 500 Crystal",16,Color("d9c598")))
		column.add_child(host._button("BEGIN EXPEDITION",choose_world,Vector2(0,64)))
	column.add_child(host._button("HOW TO PLAY",show_help,Vector2(0,52)))
	layout()

func choose_world()->void:
	if host.has_colony:return
	page="planets";_clear();host.mode="planet_select"
	column.add_child(_label("CHOOSE YOUR HOMEWORLD",30))
	column.add_child(_label("15 frontiers. One colony. Every world starts with the same supplies.",17,Color("b4cbd4")))
	var scroll:=preload("res://scripts/touch_scroll.gd").new();scroll.custom_minimum_size.y=300;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	var grid:=GridContainer.new();grid.columns=5;grid.add_theme_constant_override("h_separation",9);grid.add_theme_constant_override("v_separation",9);grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(grid)
	for i in 15:
		var b:Button=host._button("",func(idx=i):select_world(idx),Vector2(195,88));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(b);planet_buttons.append(b)
		var row:=HBoxContainer.new();row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,8);row.add_theme_constant_override("separation",8);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(row)
		var badge:=ColorRect.new();badge.custom_minimum_size=Vector2(52,52);badge.size_flags_vertical=Control.SIZE_SHRINK_CENTER;badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var material:=ShaderMaterial.new();material.shader=load("res://shaders/planet_badge.gdshader");material.set_shader_parameter("planet_color",host.MAP_ACCENT[i]);material.set_shader_parameter("seed",float(i));badge.material=material;row.add_child(badge)
		var text:=VBoxContainer.new();text.alignment=BoxContainer.ALIGNMENT_CENTER;text.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(text)
		var name_label:=_label(host.MAP_NAMES[i],16);name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;text.add_child(name_label)
		var biome_label:=_label(BIOMES[i],12,Color("9ab6c2"));biome_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;text.add_child(biome_label)
	selection_label=_label("Select a world to establish your colony.",18,Color("93d6c7"));column.add_child(selection_label)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",12);column.add_child(footer)
	footer.add_child(host._button("BACK",welcome,Vector2(120,56)))
	confirm_button=host._button("ESTABLISH COLONY",_confirm_world,Vector2(0,56));confirm_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;confirm_button.disabled=true;footer.add_child(confirm_button)
	if selected_planet>=0:select_world(selected_planet)
	layout()

func select_world(index:int)->void:
	if index<0 or index>=15 or host.has_colony:return
	selected_planet=index
	host._apply_map_theme(index)
	selection_label.text=host.MAP_NAMES[index]+"  /  "+BIOMES[index]+" — your colony's homeworld."
	confirm_button.disabled=false
	for i in planet_buttons.size():
		planet_buttons[i].add_theme_stylebox_override("normal",host._style(Color("215361") if i==index else Color("183644"),12,Color("90efd1") if i==index else Color("4a6877"),2 if i==index else 1))

func _confirm_world()->void:
	if selected_planet<0:return
	host._found_colony(selected_planet)

func enter_colony()->void:
	if not host.has_colony:return
	page="";screen.hide();host.header.show();host.dock.show();host.mode="base"
	host._apply_map_theme(host.home_planet);host._center_camera();host._refresh_progress()

func show_help()->void:
	help_return=page
	page="help";_clear()
	column.add_child(_label("COMMANDER'S FIELD GUIDE",30))
	var text:=_label("1   CHOOSE A WORLD — settle a permanent home for this colony.\n\n2   BUILD — follow the mission card and tap clear terrain (the glowing site is a suggestion).\n\n3   GATHER — production begins when the matching facility is built.\n\n4   UPGRADE — tap a building, then use UPGRADE to improve it.\n\n5   TRAIN — Star Hangar builds aircraft and drones; Vehicle Factory builds vehicles; Barracks trains troops. Upgrade each facility to unlock higher-tier units. Training uses Credits and Oil. Mining vehicles require a Vehicle Factory and Gold Refinery.\n\n6   RAID — open the Galaxy Map, choose a rival outpost and return with rewards.\n\nDRAG to move the camera. PINCH or use + / − to zoom. Progress saves on this device. Construction and training continue while away. Offline resource production is capped at 8 hours. Raids are against AI. Select portraits on the right and tap an outer edge to send reinforcements during combat. Deployed troops are consumed; unused reserves stay home.\n\nGODOT COIN — tap the GODOT COIN card in the top resource bar for daily rewards, resource exchange and speed-ups. BUILD → CLEAR ROCKS / TREES lets you assign a free construction drone to an obstacle: 100 Metal + 50 Oil, 20 seconds. Clearing may reward coins and continues while away.",18,Color("bed3da"));text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var scroll:=preload("res://scripts/touch_scroll.gd").new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.custom_minimum_size.y=345;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.add_child(text);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
	column.add_child(host._button("BACK TO EXPEDITION",func():
		if help_return=="welcome":welcome()
		else:
			page="";screen.hide();host.header.show();host.dock.show();refresh_guide()
	,Vector2(0,56)))
	layout()

func refresh_guide()->void:
	var step:int=host.tutorial_step
	guide.visible=page.is_empty() and host.mode=="base" and not guide_suppressed and not host.build_panel.visible and not host.units_panel.visible and not host.galaxy_panel.visible and (step<13 or not host.tutorial_dismissed)
	guide_action.disabled=host._builder_busy() and step<=10
	guide_progress.value=step
	if step<10:
		var kind:int=host.BUILD_ORDER[step]
		guide_title.text="%02d / 13  ·  %s"%[step+1,host.BUILDING_NAMES[kind]]
		guide_text.text=WHY[step]+"\nCost: %s Metal"%host._fmt(host.BUILDING_COST[kind])
		guide_action.text="PLACE "+host.BUILDING_NAMES[kind].to_upper()
	elif step==10:
		guide_title.text="11 / 13  ·  UPGRADE YOUR CORE"
		guide_text.text="Tap the Galactic Core and upgrade it to Level 2. Upgrades improve your colony."
		guide_action.text="SELECT GALACTIC CORE"
	elif step==11:
		guide_title.text="12 / 13  ·  TRAIN YOUR FLEET"
		guide_text.text="Open FLEET and train 8 Fighters. Each costs 180 Credits and 72 Oil.\nFighters ready: %d / 8"%host.unit_stock[0]
		guide_action.text="OPEN STAR HANGAR"
	elif step==12:
		guide_title.text="13 / 13  ·  YOUR FIRST RAID"
		guide_text.text="Open GALAXY MAP and choose a rival outpost. Scout the enemy base, then tap an outer edge to deploy your fleet. Win to earn resources."
		guide_action.text="OPEN GALAXY MAP"
	else:
		guide_title.text="COLONY ESTABLISHED"
		guide_text.text="Training complete, Commander. Expand your base, upgrade facilities and explore the galaxy."
		guide_action.text="CONTINUE BUILDING"
	if host._builder_busy() and step<=10:guide_action.text="CONSTRUCTION IN PROGRESS"
	layout()

func _guide_pressed()->void:
	var step:int=host.tutorial_step
	if step<10:host._begin_build(host.BUILD_ORDER[step])
	elif step==10:
		for b in host.buildings:
			if b.type==0:host._select_building_at(b.pos);break
	elif step==11:host._toggle_units()
	elif step==12:host._toggle_galaxy()
	else:host.tutorial_dismissed=true;host._save_profile();refresh_guide()

func layout()->void:
	var size:Vector2=host.get_viewport().get_visible_rect().size
	screen.position=Vector2.ZERO;screen.size=size
	var width:float=minf(size.x-80,1120 if page=="planets" else 900)
	panel.position=Vector2((size.x-width)/2,32);panel.size=Vector2(width,size.y-64)
	guide.position=Vector2(maxf(24.0,host.header.position.x),110);guide.size=Vector2(302,0)
	settle_frames=3

func tick()->void:
	# Autowrapped labels settle their minimum height after container sorting.
	# Reapply the intended size, rather than retaining a transient tall minimum.
	if settle_frames<=0:return
	settle_frames-=1
	var size:Vector2=host.get_viewport().get_visible_rect().size
	panel.size=Vector2(minf(size.x-80,1120 if page=="planets" else 900),size.y-64)
	guide.size=Vector2(302,guide.get_combined_minimum_size().y)
