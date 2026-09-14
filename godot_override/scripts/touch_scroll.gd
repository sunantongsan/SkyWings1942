extends ScrollContainer
var finger:=-1
var start:=Vector2.ZERO
var dragged:=false
var chosen:Button
var velocity:=0.0
func _ready()->void:
	vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
func _input(event:InputEvent)->void:
	if not is_visible_in_tree():finger=-1;velocity=0;return
	if event is InputEventMouse and event.device==-1:
		if get_global_rect().has_point(event.position):get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger<0 and get_global_rect().has_point(event.position):
			finger=event.index;start=event.position;dragged=false;velocity=0;chosen=null
			for child in find_children("*","Button",true,false):
				if child.is_visible_in_tree() and child.get_global_rect().has_point(event.position):chosen=child;break
			get_viewport().set_input_as_handled()
		elif event.index==finger and not event.pressed:
			finger=-1;get_viewport().set_input_as_handled()
			if not dragged and is_instance_valid(chosen) and not chosen.disabled and chosen.get_global_rect().has_point(event.position):chosen.pressed.emit()
			chosen=null
	elif event is InputEventScreenDrag and event.index==finger:
		if event.position.distance_to(start)>12:dragged=true
		if dragged:
			scroll_vertical-=int(event.relative.y)
			velocity=-event.relative.y/maxf(get_process_delta_time(),.008)
		get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	if finger<0 and is_visible_in_tree() and absf(velocity)>1:
		scroll_vertical+=int(velocity*delta);velocity*=exp(-9*delta)
