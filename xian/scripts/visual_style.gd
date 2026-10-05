extends RefCounted
# Shared visual language for the village and offline battles.
static func theme() -> Theme:
	var out=Theme.new()
	out.default_font=preload("res://assets/NotoSansThai.ttf")
	out.default_font_size=18
	out.set_color("font_color","Label",Color("fff0cf"))
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style=StyleBoxFlat.new()
		style.bg_color=Color({"normal":"365e87","hover":"4a7ea8","pressed":"233c60","disabled":"4a5354","focus":"365e87"}[state])
		style.border_color=Color("ebc680" if state=="focus" else "86adc3")
		style.set_border_width_all(2);style.border_width_bottom=4 if state!="pressed" else 1
		style.set_corner_radius_all(10);style.set_content_margin_all(10)
		style.shadow_color=Color(0.02,0.06,0.07,0.35);style.shadow_size=3;style.shadow_offset=Vector2(0,3)
		for control in ["Button","OptionButton"]:
			out.set_stylebox(state,control,style)
			out.set_color("font_color",control,Color("fff4d8"))
			out.set_color("font_disabled_color",control,Color("acb4ad"))
	out.set_constant("separation","VBoxContainer",8)
	return out
static func panel() -> StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=Color("162b40f2")
	style.set_corner_radius_all(14);style.set_content_margin_all(14)
	style.border_color=Color("819db1");style.set_border_width_all(2)
	style.shadow_color=Color(0,0.025,0.03,0.3);style.shadow_size=5;style.shadow_offset=Vector2(0,4)
	return style
