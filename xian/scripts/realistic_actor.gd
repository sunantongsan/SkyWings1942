extends Sprite3D
var troop_kind=0
var state="idle"
var elapsed=0.0
var flying=false
var attack_time=0.0
var attack_duration=0.8
var previous=Vector3.ZERO
var normal_texture: Texture2D
var normal_pixel=0.0
var normal_offset=Vector2.ZERO
var actions: Texture2D
var walk_material: ShaderMaterial
var gait_phase=0.0
var gait_target=0.0
func action_frame(index: int, sleeping: bool):
	if actions==null:actions=load("res://assets/realistic/fighter_actions.webp")
	var region=AtlasTexture.new();region.atlas=actions
	region.region=Rect2(index*actions.get_width()/4.0,550 if sleeping else 0,actions.get_width()/4.0,actions.get_height()-550 if sleeping else 550);region.filter_clip=true
	hframes=1;vframes=1;texture=region;pixel_size=1.8/550.0;offset=Vector2(0,region.get_height()*0.5-(65 if sleeping else 15))
func isolated_attack():
	var cell=Vector2(normal_texture.get_width()/4.0,normal_texture.get_height()/2.0)
	var cut=0.895 if troop_kind==7 else 0.86
	var region=AtlasTexture.new();region.atlas=normal_texture;region.region=Rect2(0,cell.y,cell.x*cut,cell.y);region.margin=Rect2(0,0,cell.x*(1-cut),0);region.filter_clip=true
	hframes=1;vframes=1;texture=region;pixel_size=normal_pixel;offset=normal_offset
func restore_walk():
	if normal_texture!=null:texture=normal_texture;hframes=4;vframes=2;pixel_size=normal_pixel;offset=normal_offset

func _ready():
	previous=get_parent().global_position;normal_texture=texture;normal_pixel=pixel_size;normal_offset=offset
	walk_material=ShaderMaterial.new();walk_material.shader=preload("res://scripts/walk_rig.gdshader");walk_material.set_shader_parameter("sheet",normal_texture);walk_material.set_shader_parameter("quadruped",1.0 if troop_kind in [4,6] else 0.0)
func _process(delta: float):
	elapsed+=delta
	var p=get_parent().global_position
	var movement=p-previous;previous=p
	if movement.length_squared()>0.000001 and attack_time<=0:
		# Screen horizontal at the fixed (40,48,40) camera is world X minus Z.
		var horizontal=movement.x-movement.z
		if abs(horizontal)>0.0001:flip_h=horizontal<0
	material_override=null
	if state=="sleep" and troop_kind==0:
		action_frame(int(elapsed*2)%4,true);position.y=0;return
	if attack_time>0:
		attack_time=maxf(0,attack_time-delta)
		if troop_kind==0:action_frame(mini(3,int((1.0-attack_time/attack_duration)*4)),false)
		elif troop_kind in [7,8]:isolated_attack()
		elif troop_kind>=3:restore_walk();frame=4 # Dedicated wind-up pose, with procedural lunge/impact.
		position.y=sin((1.0-attack_time/attack_duration)*PI)*0.09
	elif flying:
		restore_walk()
		frame=int(elapsed*7.0)%(4 if troop_kind>=3 else 8);position.y=0.12+sin(elapsed*2.0)*0.035
	elif state in ["walk","climb"]:
		restore_walk();frame=0
		gait_target+=Vector2(movement.x,movement.z).length()*TAU/(3.0 if troop_kind in [4,6] else 2.2)
		gait_phase=lerpf(gait_phase,gait_target,1.0-exp(-delta*22.0))
		material_override=walk_material;walk_material.set_shader_parameter("phase",gait_phase);walk_material.set_shader_parameter("climbing",1.0 if state=="climb" else 0.0)
		position.y=absf(sin(gait_phase*2))*0.022
	else:
		restore_walk()
		frame=0;position.y=0
func set_pose(value: String, duration: float):
	state=value
	if value=="attack":attack_duration=maxf(0.1,duration);attack_time=attack_duration

func face(direction: Vector3):
	var horizontal=direction.x-direction.z
	if absf(horizontal)>0.001:flip_h=horizontal<0
