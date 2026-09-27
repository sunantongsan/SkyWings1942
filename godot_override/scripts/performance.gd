extends RefCounted
## Device-only graphics preference. Never changes inventory, rewards or combat stats.
const PATH:="user://graphics_settings.cfg"
var host:Node3D
var low:=false
var button:Button
func _init(game:Node3D)->void:
	host=game
	var config:=ConfigFile.new()
	low=OS.has_feature("android")
	if config.load(PATH)==OK:low=bool(config.get_value("graphics","low",low))
	host.get_tree().node_added.connect(on_node_added)
	apply()
func on_node_added(node:Node)->void:
	if node is CPUParticles3D:prepare_particle.call_deferred(node)
func prepare_particle(node:Node)->void:
	if not is_instance_valid(node):return
	if not node.has_meta("full_amount"):node.set_meta("full_amount",node.amount)
	node.amount=maxi(3,int(node.get_meta("full_amount"))/3) if low else int(node.get_meta("full_amount"))
func apply()->void:
	host.sun.shadow_enabled=not low
	host.get_viewport().msaa_3d=Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	host.get_viewport().scaling_3d_scale=.75 if low else 1.0
	Engine.max_fps=30 if low else 60
	for node in host.world_root.find_children("*","CPUParticles3D",true,false):prepare_particle(node)
	if host.garrison:host.garrison.sync()
	refresh_button()
func refresh_button()->void:
	if is_instance_valid(button):button.text="GRAPHICS: LOW" if low else "GRAPHICS: STANDARD"
func toggle()->void:
	set_low(not low)
	host._toast("Low graphics: 30 FPS cap, fewer effects, shadows off." if low else "Standard graphics: 60 FPS cap, shadows on.")
func set_low(value:bool,persist:bool=true)->void:
	low=value;apply()
	if persist:
		var config:=ConfigFile.new();config.set_value("graphics","low",low);config.save(PATH)
