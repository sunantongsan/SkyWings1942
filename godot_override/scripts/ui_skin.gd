extends RefCounted
static var cache:Dictionary={}
static func style(state:String)->StyleBoxTexture:
	if cache.has(state):return cache[state]
	var box:=StyleBoxTexture.new();box.texture=load("res://assets/ui/"+state+".svg")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:box.set_texture_margin(side,20)
	box.content_margin_left=14;box.content_margin_right=14;box.content_margin_top=10;box.content_margin_bottom=14
	cache[state]=box;return box
static func button(b:Button)->void:
	for state in ["normal","hover","pressed","disabled"]:b.add_theme_stylebox_override(state,style(state))
	b.add_theme_stylebox_override("hover_pressed",style("pressed"))
	b.add_theme_color_override("font_color",Color("f2ffe7"));b.add_theme_color_override("font_hover_color",Color.WHITE)
	b.add_theme_color_override("font_pressed_color",Color.WHITE);b.add_theme_color_override("font_disabled_color",Color("96a3a9"))
	b.add_theme_color_override("font_outline_color",Color("163b28"));b.add_theme_constant_override("outline_size",3)
static func theme()->Theme:
	var result:=Theme.new()
	for kind in ["Button","OptionButton"]:
		for state in ["normal","hover","pressed","disabled"]:result.set_stylebox(state,kind,style(state))
		result.set_color("font_color",kind,Color("f2ffe7"));result.set_color("font_disabled_color",kind,Color("96a3a9"))
	return result
