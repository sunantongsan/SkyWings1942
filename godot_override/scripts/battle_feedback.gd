extends RefCounted
var host:Node3D
var player:AudioStreamPlayer
var fireworks:Node3D
var enabled:=true
var elapsed:=0.0
var next_burst:=0.0
var active:=false
var bursts:=0
var last_cue:=""
var sound_button:Button
func _init(game:Node3D)->void:
	host=game
	player=AudioStreamPlayer.new();player.volume_db=-10;host.add_child(player)
	fireworks=Node3D.new();fireworks.name="VictoryFireworks";host.world_root.add_child(fireworks)
	var settings:=ConfigFile.new()
	if settings.load("user://audio_settings.cfg")==OK:enabled=bool(settings.get_value("audio","enabled",true))
func set_enabled(value:bool,persist:bool=true)->void:
	enabled=value
	if not enabled:player.stop()
	if is_instance_valid(sound_button):sound_button.text="SFX ON" if enabled else "SFX OFF"
	if persist:
		var settings:=ConfigFile.new();settings.set_value("audio","enabled",enabled);settings.save("user://audio_settings.cfg")
func play(name:String)->void:
	last_cue=name
	if enabled:player.stream=load("res://assets/audio/"+name+".wav");player.play()
func victory()->void:
	clear();active=true;elapsed=0;next_burst=0;bursts=0;play("victory_bugle")
func defeat()->void:
	clear();play("defeat_brass")
func clear()->void:
	active=false;player.stop()
	for child in fireworks.get_children():fireworks.remove_child(child);child.queue_free()
func tick(delta:float)->void:
	if not active:return
	if host.mode!="victory":clear();return
	elapsed+=delta
	if elapsed>=6:active=false;return
	if elapsed<next_burst:return
	next_burst=elapsed+.42
	var screen:Vector2=host.get_viewport().get_visible_rect().size
	# Launch at the screen edges so the reward card cannot cover the celebration.
	var point:=Vector2(screen.x*(.13 if bursts%2==0 else .87),screen.y*(.3+.13*(bursts%3)))
	var ground=host._ground_hit(point)
	var pos:Vector3=Vector3.ZERO if ground==null else ground
	pos.y=4.5+float(bursts%3)
	var colors:=[Color("ffce57"),Color("60e5ff"),Color("ff6aa8"),Color("93ffad")]
	var burst:CPUParticles3D=host.art.particles(fireworks,pos,colors[bursts%4],false,true)
	burst.amount=36;burst.lifetime=1.4;burst.initial_velocity_min=3.5;burst.initial_velocity_max=7;burst.gravity=Vector3(0,-3,0);burst.scale_amount_min=.07;burst.scale_amount_max=.15
	burst.restart();bursts+=1
