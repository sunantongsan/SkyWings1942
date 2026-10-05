extends RefCounted
const Iso=preload("res://scripts/iso_layout.gd")
const Troops=preload("res://scripts/troops.gd")
# Prerendered artwork uses the game's fixed isometric view. Gameplay, collision,
# storage amounts and targeting remain independent of these visual nodes.
const ROOT = "res://assets/realistic/"
const WIDTHS = {"hall":3.7,"recruit":3.5,"training":6.4,"barracks":3.6,"kitchen":3.6,"spring":3.2,"granary":3.3,"crystal":2.8,"servant":3.7,"well":3.5,"tank":2.3,"ward":2.8,"tower":2.6,"carpenter":2.1}
var textures: Dictionary = {}
var ground_anchors: Dictionary = {}
var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"atlas.json"))
var soft_texture: GradientTexture2D
func soft_material(color: Color, billboard: bool=false) -> StandardMaterial3D:
	if soft_texture==null:
		soft_texture=GradientTexture2D.new();soft_texture.width=64;soft_texture.height=64;soft_texture.fill=GradientTexture2D.FILL_RADIAL;soft_texture.fill_from=Vector2(0.5,0.5);soft_texture.fill_to=Vector2(0.5,1)
		var gradient=Gradient.new();gradient.colors=PackedColorArray([Color.WHITE,Color(1,1,1,0)]);soft_texture.gradient=gradient
	var mat=StandardMaterial3D.new();mat.albedo_texture=soft_texture;mat.albedo_color=color;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	if billboard:mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	return mat
func puff(parent: Node3D, color: Color) -> MeshInstance3D:
	var n=MeshInstance3D.new();var q=QuadMesh.new();q.size=Vector2(2.5,2.5);n.mesh=q;n.material_override=soft_material(color,true);n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(n);return n
func shadow(parent: Node3D, width: float):
	var n=MeshInstance3D.new();var q=QuadMesh.new();q.size=Vector2(width,width*0.72);n.name="ContactShadow";n.mesh=q;n.rotation.x=-PI/2;n.position.y=0.065;n.material_override=soft_material(Color(0.08,0.07,0.04,0.38));n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(n)
func texture(kind: String) -> Texture2D:
	if not textures.has(kind):textures[kind] = load(ROOT + kind + ".webp")
	return textures[kind]
func sprite(kind: String, width: float, ground_inset: float=0.12) -> Sprite3D:
	var s=Sprite3D.new();s.name="RealisticVisual";s.texture=texture(kind)
	s.billboard=BaseMaterial3D.BILLBOARD_ENABLED;s.shaded=false;s.double_sided=true
	s.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.pixel_size=width/s.texture.get_width()
	s.offset.y=s.texture.get_height()*(0.5-ground_inset)
	s.alpha_cut=SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	s.alpha_scissor_threshold=0.15
	s.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return s
func building(kind: String, level: int, fill: float=0.5) -> Node3D:
	var root=Node3D.new();root.set_meta("realistic_art",true)
	var width=minf(2.45,float(WIDTHS[kind])) if kind!="training" else 5.5
	if kind!="servant":width*=1.0
	shadow(root,width*1.05)
	var visual=sprite(kind+"_levels" if regions.has(kind+"_levels") else kind,width,0.16 if kind in ["training","well","granary"] else 0.1)
	if regions.has(kind+"_levels"):
		var region=regions[kind+"_levels"][clampi(level,1,10)-1]
		var frame=AtlasTexture.new();frame.atlas=texture(kind+"_levels");frame.region=Rect2(region[0],region[1],region[2],region[3]);frame.filter_clip=true
		visual.texture=frame;visual.pixel_size=minf(width/frame.get_width(),4.2/frame.get_height());visual.offset.y=frame.get_height()*0.5-frame.get_width()*0.22

	ground_sprite(visual,kind+":"+str(level))
	root.add_child(visual)
	if kind in ["tank","granary","crystal"]:
		var label=Label3D.new();label.name="StorageAmount";label.text=str(roundi(clampf(fill,0,1)*100))+"%";label.font_size=40;label.pixel_size=0.012;label.outline_size=8;label.font=load("res://assets/NotoSansThai.ttf");label.position.y=0.4;label.render_priority=10;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true;root.add_child(label)
	root.set_meta("visual_level",clampi(level,1,10));root.set_meta("storage_fill",clampf(fill,0,1))
	return root

func ground_sprite(visual: Sprite3D, key: String, depth: float=0.22):
	# Only placement changes: the source pixels and aspect ratio remain intact.
	if not ground_anchors.has(key):
		var used=visual.texture.get_image().get_used_rect()
		ground_anchors[key]=float(used.end.y)-visual.texture.get_height()*0.5-used.size.x*depth
	visual.offset.y=ground_anchors[key]
	visual.position.y=0.025
	visual.material_override=Iso.sprite_depth_material(visual)

func character(kind: int, armed: bool) -> Node3D:
	var root=Node3D.new();root.set_meta("realistic_art",true)
	shadow(root,1.4 if armed and kind in [2,4,6,7,8] else 0.7)
	var id="collector" if not armed else Troops.ASSETS[clampi(kind,0,9)]
	var s=sprite(id,1.0,0.02);s.name="CharacterSprite";s.hframes=4;s.vframes=2
	# Sheet cells retain their generated transparent padding; never crop each frame
	# independently, which would make the feet jump between animation frames.
	s.pixel_size=(3.6 if kind==9 and armed else 2.6 if kind in [2,4,6,7,8] and armed else 1.35)/(s.texture.get_height()/2.0)
	var feet={"fighter":431,"collector":480,"thief":482,"turtle":418,"sword_sage_red":490,"tiger":440,"stone_warrior":476}
	s.offset.y=float(feet.get(id,s.texture.get_height()*0.49))-s.texture.get_height()/4.0
	s.set_script(preload("res://scripts/realistic_actor.gd"));s.flying=armed and Troops.air(kind);s.troop_kind=kind if armed else -1
	root.add_child(s)
	if armed and kind in [5,9]:
		var aura=puff(root,Color(1,0.33,0.13,0.14) if kind==5 else Color(0.45,0.75,1,0.15));aura.name="Aura";aura.position.y=1.0 if kind==5 else 1.9;aura.scale=Vector3.ONE*(0.75 if kind==5 else 1.35)
	return root
