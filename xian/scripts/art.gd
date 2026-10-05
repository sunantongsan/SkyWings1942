extends RefCounted
var realistic_enabled=true
var stone_mat: StandardMaterial3D
var realistic=preload("res://scripts/realistic_art.gd").new()
var mats = {}
func stone_material() -> StandardMaterial3D:
	if stone_mat==null:
		stone_mat=StandardMaterial3D.new();stone_mat.albedo_texture=realistic.texture("stone");stone_mat.albedo_color=Color("9b9d90");stone_mat.roughness=1;stone_mat.uv1_triplanar=true;stone_mat.uv1_world_triplanar=true;stone_mat.uv1_scale=Vector3.ONE*0.5
	return stone_mat
func material(hex: String) -> StandardMaterial3D:
	if mats.has(hex): return mats[hex]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	# Stylized PBR: keep the broad readable shapes, but let sun/highlights sell depth.
	m.roughness = 0.72
	m.metallic = 0.0
	if realistic_enabled and hex in ["b8b19c","a9b091","b4bb87","c8c4a1"]:return stone_material()
	mats[hex] = m
	return m
func box(parent: Node3D, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	n.mesh = mesh; n.material_override = material(color); n.position = pos
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(n)
	return n
func cone(parent: Node3D, pos: Vector3, r: float, top: float, height: float, color: String, segments = 8) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.bottom_radius = r; mesh.top_radius = top; mesh.height = height; mesh.radial_segments = segments
	n.mesh = mesh; n.material_override = material(color); n.position = pos
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(n)
	return n
func roof(parent: Node3D, y: float, width: float, color: String):
	var n = cone(parent, Vector3(0,y,0),width,0.12,0.95,color,4)
	n.rotation_degrees.y = 45
	n.scale.z = 0.8
	box(parent,Vector3(0,y+0.48,0),Vector3(width*1.25,0.14,0.15),"d3b579")
	for x in [-1,1]:
		box(parent,Vector3(x*width*0.73,y-0.28,0),Vector3(0.18,0.3,width*1.2),color).rotation_degrees.z = x*20

func lantern(parent: Node3D, pos: Vector3, scale_value: float=1.0):
	var root=Node3D.new();root.position=pos;root.scale=Vector3.ONE*scale_value;parent.add_child(root)
	box(root,Vector3(0,0.7,0),Vector3(0.12,1.4,0.12),"513d31")
	box(root,Vector3(0,1.45,0),Vector3(0.5,0.58,0.5),"d98748")
	cone(root,Vector3(0,1.82,0),0.42,0.08,0.25,"385b51",4).rotation.y=PI/4
	return root
func rock(parent: Node3D, pos: Vector3, scale_value: float=1.0):
	var r=cone(parent,pos+Vector3(0,0.35*scale_value,0),0.7*scale_value,0.35*scale_value,0.7*scale_value,"747b72",7)
	r.rotation_degrees=Vector3(-8,17,6);return r
func bamboo_cluster(parent: Node3D, pos: Vector3, scale_value: float=1.0):
	var root=Node3D.new();root.position=pos;root.scale=Vector3.ONE*scale_value;parent.add_child(root)
	for i in range(3):
		var x=(i-1)*0.34
		cone(root,Vector3(x,1.45,i*0.12),0.075,0.06,2.9,"426a45",7)
		for y in [0.85,1.55,2.2]:
			var leaf=box(root,Vector3(x+0.28,y,i*0.12),Vector3(0.65,0.055,0.18),"5f8751");leaf.rotation_degrees.y=25+i*38
	return root
func training_banner(parent: Node3D, pos: Vector3, color="9c4152"):
	var root=Node3D.new();root.position=pos;parent.add_child(root)
	cone(root,Vector3(0,1.35,0),0.045,0.045,2.7,"6c4b35",7)
	var cloth=box(root,Vector3(0.38,1.9,0),Vector3(0.72,0.85,0.035),color);cloth.rotation_degrees.z=-4
	return root

var scene_cache: Dictionary = {}
var walk_library: AnimationLibrary
var combat_library: AnimationLibrary
var house_meshes: Dictionary = {}
func source_scene(path: String) -> PackedScene:
	if not scene_cache.has(path):scene_cache[path]=load("res://assets/donor/"+path)
	return scene_cache[path]
func mesh_transform(node: Node3D, root: Node3D) -> Transform3D:
	var result=node.transform;var parent=node.get_parent()
	while parent!=root and parent is Node3D:
		result=parent.transform*result;parent=parent.get_parent()
	return result
func model_bounds(root: Node3D) -> AABB:
	var bounds=AABB();var first=true
	for sprite in root.find_children("*","Sprite3D",true,false):
		var size=Vector2(sprite.texture.get_width()/float(sprite.hframes),sprite.texture.get_height()/float(sprite.vframes))
		var rect=AABB(Vector3((sprite.offset.x-size.x*0.5)*sprite.pixel_size,(sprite.offset.y-size.y*0.5)*sprite.pixel_size,0),Vector3(size.x*sprite.pixel_size,size.y*sprite.pixel_size,0.01));var value=mesh_transform(sprite,root)*rect
		if first:bounds=value;first=false
		else:bounds=bounds.merge(value)
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		var value=mesh_transform(mesh,root)*mesh.get_aabb()
		if first:bounds=value;first=false
		else:bounds=bounds.merge(value)
	return bounds
func donor(path: String, width: float, part="", height_limit=5.0) -> Node3D:
	var out=Node3D.new();var scene=source_scene(path).instantiate()
	if not part.is_empty():
		var piece=scene.get_node(part).duplicate();scene.free();scene=piece;scene.transform=Transform3D.IDENTITY
	out.add_child(scene)
	if path=="hitherton_buildings.glb" and scene is MeshInstance3D:
		if not house_meshes.has(part):
			var source=scene.mesh;var recolored=ArrayMesh.new();var bounds=source.get_aabb()
			var palette={"House Player":"65966f","House_2":"cfaa55","House_3":"429ca8","House_4":"638bae","shop":"cc7950","Arena":"708468"}
			for surface in range(source.get_surface_count()):
				var arrays=source.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL];var colors=PackedColorArray()
				for i in range(vertices.size()):
					var roof_face=normals[i].y>0.15 and vertices[i].y>bounds.position.y+bounds.size.y*0.35
					colors.append(Color(palette.get(part,"708468")) if roof_face else Color("e7d9bc"))
				arrays[Mesh.ARRAY_COLOR]=colors;recolored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=0.95;recolored.surface_set_material(surface,mat)
			house_meshes[part]=recolored
		scene.mesh=house_meshes[part]
	if path.ends_with(".gltf") and path!="Dragon_Evolved.gltf":
		for mesh in scene.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				var source_mat=mesh.mesh.surface_get_material(surface)
				if source_mat==null:continue
				var colors={"stone":"899587","plaster":"d7c8a3","glaze":"bd8c3e" if path=="hall.gltf" else "327a75","bronze":"b29657","timber":"644934","lacquer":"a8533d","paper":"e3cfa2","wood":"9b794f"}
				if colors.has(source_mat.resource_name):mesh.set_surface_override_material(surface,material(colors[source_mat.resource_name]))
	for collision in scene.find_children("*","CollisionObject3D",true,false):collision.free()
	var bounds=model_bounds(out)
	var size=minf(width/maxf(bounds.size.x,bounds.size.z),height_limit/maxf(bounds.size.y,0.01))
	scene.scale*=size
	scene.position-=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*size
	return out
func courtyard(level: int) -> Node3D:
	var root=Node3D.new();root.set_meta("courtyard",true)
	# Open, ground-level 2x2 courtyard. No roof obscures the training floor.
	box(root,Vector3(0,0.025,0),Vector3(5.85,0.05,5.85),"aba591")
	for x in range(6):
		for z in range(6):
			box(root,Vector3(-2.42+x*0.97,0.065,-2.42+z*0.97),Vector3(0.91,0.03,0.91),"d8d2b6" if (x+z)%2==0 else "d2ccb1")
	for z in [-2.72,2.72]:box(root,Vector3(0,0.09,z),Vector3(5.7,0.08,0.12),"b59a53" if level<5 else "e0b94d")
	for x in [-2.72,2.72]:box(root,Vector3(x,0.09,0),Vector3(0.12,0.08,5.7),"b59a53")
	# Wooden practice dummies and a sword rack keep the central arena clear.
	for x in [-1.9,0.0,1.9]:
		cone(root,Vector3(x,0.75,-2.1),0.12,0.12,1.4,"856044",8)
		box(root,Vector3(x,1,-2.1),Vector3(0.9,0.12,0.12),"987452")
		cone(root,Vector3(x,1.6,-2.1),0.19,0.19,0.28,"c6a679",8)
	for x in [-2.2,2.2]:
		training_banner(root,Vector3(x,0,2.2),"467f99" if level<5 else "9c4152")
	for i in range(mini(5,1+level/2)):
		box(root,Vector3(-1.1+i*0.4,0.65,2.3),Vector3(0.06,0.9,0.05),"becdd1")
		box(root,Vector3(-1.1+i*0.4,0.35,2.3),Vector3(0.25,0.05,0.08),"bb9a59")
	box(root,Vector3(0,0.3,2.35),Vector3(2.6,0.12,0.12),"785c43")
	rock(root,Vector3(-2.25,0,1.45),0.55);rock(root,Vector3(2.2,0,1.5),0.45)
	cone(root,Vector3(0,0.092,0),1.05,1.05,0.018,"689a99",32)
	box(root,Vector3(0,0.11,0),Vector3(0.08,0.015,1.5),"ece4c9")
	box(root,Vector3(0,0.11,0.45),Vector3(0.55,0.015,0.08),"ece4c9")
	for x in [-2.55,2.55]:
		box(root,Vector3(x,0.25,-2.5),Vector3(0.45,0.5,0.45),"b7b8a0")
		cone(root,Vector3(x,0.85,-2.5),0.2,0.2,0.8,"f0c77e",8)
		cone(root,Vector3(x,1.32,-2.5),0.42,0.08,0.24,"438a86",4).rotation.y=PI/4
	return root
func wall(mask: int=0, rotation: int=0, level: int=1) -> Node3D:
	var root=Node3D.new();root.set_meta("donor_building",true);root.set_meta("wall_mask",mask)
	if mask==0:mask=5 if rotation%2==0 else 10
	# Half spans meet exactly on the shared cell boundary, including corners/T junctions.
	for i in range(4):
		if not mask & (1<<i):continue
		var segment=donor("wall.gltf",3.04,"",2.3)
		segment.scale.x=0.5;segment.rotation.y=i*PI/2
		segment.position=Vector3.RIGHT.rotated(Vector3.UP,i*PI/2)*0.75;root.add_child(segment)
	box(root,Vector3(0,0.88,0),Vector3(0.6,1.76,0.6),"e4ddc5")
	box(root,Vector3(0,1.82,0),Vector3(0.76,0.15,0.76),"537c73" if level<5 else "b59753")
	cone(root,Vector3(0,2.0,0),0.52,0.08,0.24,"d1b970",4).rotation.y=PI/4
	evolve(root,"wall",level)
	if realistic_enabled:
		for mesh in root.find_children("*","MeshInstance3D",true,false):mesh.material_override=stone_material()
	batch_static(root)
	return root
func construction_dressing(parent: Node3D, footprint_size: int, progress: float):
	var span=maxf(2.7,float(footprint_size)*2.75);var h=3.1 if footprint_size<=1 else 4.2
	# Bamboo scaffold around the footprint: unmistakable construction silhouette.
	for x in [-span*0.46,span*0.46]:
		for z in [-span*0.46,span*0.46]:
			cone(parent,Vector3(x,h*0.5,z),0.045,0.045,h,"765535",6)
	for y in [0.9,1.8,2.7]:
		for z in [-span*0.46,span*0.46]:box(parent,Vector3(0,y,z),Vector3(span,0.07,0.07),"8c673d")
		for x in [-span*0.46,span*0.46]:box(parent,Vector3(x,y,0),Vector3(0.07,0.07,span),"8c673d")
	scaffold_worker(parent,span)
	# Floating progress bar visible from the isometric camera.
	var bar=Node3D.new();bar.position=Vector3(0,h+0.65,0);parent.add_child(bar)
	box(bar,Vector3.ZERO,Vector3(2.5,0.22,0.12),"322f2c")
	var p=clampf(progress,0.04,1.0);var fill=box(bar,Vector3(-1.2+1.2*p,0,0.07),Vector3(2.4*p,0.16,0.08),"79d77b")
	fill.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in range(3):box(parent,Vector3(-0.7+i*0.65,0.13,span*0.5+0.35),Vector3(0.42,0.26,0.32),"b8a37a")

func building(kind: String, level: int, fill = 0.5) -> Node3D:
	if realistic_enabled and realistic.WIDTHS.has(kind):
		var model=realistic.building(kind,level,fill)
		if kind=="spring":
			var smoke=motion(model,"black_smoke");smoke.position.y=2.0+level*0.025
			for i in range(5):
				realistic.puff(smoke,Color(0.10,0.10,0.11,0.4))
		return model
	if kind=="wall":return wall(0,0,level)
	var result=building_base(kind,level,fill)
	evolve(result,kind,level)
	batch_static(result)
	return result
func building_base(kind: String, level: int, fill = 0.5) -> Node3D:
	if kind=="wall":return wall(0,0,level)
	if kind=="training":return courtyard(level)
	if kind=="spring":return furnace(maxi(1,level))
	if kind=="crystal":return pill_pouch(level,fill)
	if kind=="barracks":return barracks(level)
	if kind=="kitchen":return inn(clampi(level,1,10))
	if kind=="granary":return takeaway_box(clampi(level,1,10),fill)
	if kind=="servant":return builder_shed()
	if kind=="well":return hand_pump(clampi(level,1,10))
	if kind=="tank":return water_bottle(clampi(level,1,10),fill)
	if kind=="tower":return slingshot_ladder(clampi(level,1,10))
	if kind=="ward":return speaker_tower(clampi(level,1,10))
	var mapping={"hall":["hall.gltf",""],"recruit":["gate.gltf",""],"dorm":["hitherton_buildings.glb","House_4"],"servant":["hitherton_buildings.glb","House Player"],"kitchen":["hitherton_buildings.glb","shop"],"granary":["hitherton_buildings.glb","House_2"],"well":["pavilion.gltf",""],"tank":["hitherton_buildings.glb","House_3"],"spring":["moon_gate.gltf",""],"crystal":["moon_gate.gltf",""],"tower":["gate.gltf",""],"ward":["pavilion.gltf",""],"wall":["wall.gltf",""]}
	var spec=mapping.get(kind,mapping.hall)
	var root=donor(spec[0],2.7,spec[1],4.2)
	root.set_meta("donor_building",true)
	if kind=="tower":root.scale=Vector3(0.8,1.4,0.8)
	if kind=="wall":root.scale.y=0.55
	if kind=="well" or kind=="spring" or kind=="tank":
		cone(root,Vector3(0,0.22,-0.9),0.65,0.65,0.42,"879ea4",12)
		cone(root,Vector3(0,0.45,-0.9),0.56,0.56,0.03,"57cde0" if kind!="spring" else "72e5b2",12)
		if kind=="spring":cone(root,Vector3(0,0.8,-0.9),0.13,0.04,0.7,"b2f7e5",8)
	if kind=="crystal" or kind=="ward":
		for i in range(3):cone(root,Vector3((i-1)*0.35,0.7,-0.9),0.24,0,0.9+fill,"87def5" if kind=="crystal" else "d2a1ef",5)
	if kind=="granary":
		for i in range(3):cone(root,Vector3(-0.6+i*0.5,0.27,-1),0.26,0.2,0.5,"d8c58e",8)
	if kind=="kitchen":cone(root,Vector3(0.8,0.3,-1),0.35,0.4,0.55,"535e64",10)
	building_trim(root,kind,level)
	if kind in ["hall","recruit","ward"]:
		lantern(root,Vector3(-1.15,0,-1.15),0.48);lantern(root,Vector3(1.15,0,-1.15),0.48)
	return root
func person(kind: int, armed: bool=true) -> Node3D:
	if realistic_enabled:return realistic.character(kind,armed)
	var root=Node3D.new()
	if kind==2:
		var model=source_scene("Dragon_Evolved.gltf").instantiate();root.add_child(model)
		var bounds=model_bounds(root);var factor=3.5/maxf(bounds.size.x,0.01)
		model.scale=Vector3.ONE*factor;model.position.y=-bounds.position.y*factor
		var player=model.find_child("AnimationPlayer",true,false)
		root.set_meta("anim_player",player);root.set_meta("idle_clip","Flying_Idle");root.set_meta("walk_clip","Fast_Flying");root.set_meta("attack_clip","Headbutt");root.set_meta("donor_beast",true)
		for name in ["Flying_Idle","Fast_Flying"]:player.get_animation(name).loop_mode=Animation.LOOP_LINEAR
	else:
		var model=source_scene("godette.glb").instantiate();root.add_child(model)
		var bounds=model_bounds(root);var factor=2.5/maxf(bounds.size.y,0.01)
		model.scale=Vector3.ONE*factor;model.position.y=-bounds.position.y*factor
		var player=model.get_node("AnimationPlayer")
		if walk_library==null:
			var animations=source_scene("animset_walk_jog_run.glb").instantiate();walk_library=AnimationLibrary.new()
			for name in ["walk_fwd","idle"]:
				var anim=animations.get_node("AnimationPlayer").get_animation(name).duplicate();anim.loop_mode=Animation.LOOP_LINEAR
				for track in range(anim.get_track_count()-1,-1,-1):
					if str(anim.track_get_path(track)).ends_with(":Root"):anim.remove_track(track)
				walk_library.add_animation(name,anim)
			animations.free()
		if combat_library==null:
			combat_library=AnimationLibrary.new()
			for name in ["combat_attack_light_01","combat_idle_sword_1h"]:
				var anim=load("res://assets/donor/"+name+".tres").duplicate()
				for i in range(anim.get_track_count()-1,-1,-1):
					if str(anim.track_get_path(i)).ends_with(":Root"):anim.remove_track(i)
				anim.loop_mode=Animation.LOOP_NONE if name=="combat_attack_light_01" else Animation.LOOP_LINEAR
				combat_library.add_animation(name,anim)
		player.add_animation_library("movement",walk_library);player.add_animation_library("combat",combat_library)
		root.set_meta("donor_character",true);root.set_meta("anim_player",player)
		root.set_meta("idle_clip","combat/combat_idle_sword_1h" if armed else "movement/idle")
		root.set_meta("walk_clip","combat/combat_idle_sword_1h" if kind==1 else "movement/walk_fwd");root.set_meta("attack_clip","combat/combat_attack_light_01")
		if armed:
			var skeleton=model.get_node("char/Skeleton3D")
			var hand=BoneAttachment3D.new();hand.name="SwordHand";hand.bone_name="prop.R";skeleton.add_child(hand)
			var sword=source_scene("godette_sword.glb").instantiate();sword.name="HeldSword";sword.scale=Vector3(0.62,0.29,0.55);sword.rotation.x=PI/2;sword.position=Vector3.ZERO;hand.add_child(sword)
			for mesh in sword.find_children("*","MeshInstance3D",true,false):
				for surface in range(mesh.mesh.get_surface_count()):mesh.set_surface_override_material(surface,material(["738fa9","b99444","4d3a30"][mini(surface,2)]))
		if kind==1:
			var sword=source_scene("godette_sword.glb").instantiate();root.add_child(sword);sword.scale=Vector3(1.6,0.48,0.9);sword.rotation.x=PI/2;sword.position=Vector3(0,0.04,-0.8)
			for mesh in sword.find_children("*","MeshInstance3D",true,false):mesh.material_override=material("8ba9bb")
	pose(root,"idle")
	return root

func impact_fx(parent: Node3D, pos: Vector3, kind: int=0):
	var root=Node3D.new();root.position=pos;parent.add_child(root)
	var flash=cone(root,Vector3.ZERO,0.5,0.08,0.08,"ffd47b" if kind!=1 else "82ddff",12)
	flash.rotation.x=PI/2
	for i in range(5):
		var shard=box(root,Vector3.ZERO,Vector3(0.05,0.05,0.7),"fff0b0" if kind==0 else "9beaff")
		shard.rotation.y=i*TAU/5.0
		shard.position=Vector3(sin(i*TAU/5.0)*0.55,0.12,cos(i*TAU/5.0)*0.55)
	var tween=root.create_tween();tween.set_parallel(true);tween.tween_property(root,"scale",Vector3.ONE*1.8,0.16);tween.tween_property(root,"position:y",root.position.y+0.2,0.18)
	tween.chain().tween_callback(root.queue_free)
func rubble(parent: Node3D, pos: Vector3):
	for i in range(5):
		var angle=i*TAU/5.0;var r=rock(parent,pos+Vector3(cos(angle)*0.65,0,sin(angle)*0.65),0.22+0.04*(i%2));r.rotation.y=angle

func pose(root: Node3D, state: String, attack_duration: float=0.8):
	if root.has_node("CharacterSprite"):
		root.get_node("CharacterSprite").set_pose(state,attack_duration);return
	if not root.has_meta("anim_player"):return
	var player: AnimationPlayer=root.get_meta("anim_player")
	if state!="attack" and root.get_meta("attacking",false) and player.is_playing():return
	var clip: String=root.get_meta(state+"_clip",root.get_meta("idle_clip"))
	if state=="attack":
		root.set_meta("attacking",true);player.play(clip,0.08,player.get_animation(clip).length/maxf(0.1,attack_duration));player.seek(0,true)
	elif player.current_animation!=clip or not player.is_playing():
		root.set_meta("attacking",false);player.play(clip,0.15,1.0)

var ground_materials: Dictionary={}
func landscape(parent: Node3D, mountain: bool=false, deployment: bool=false):
	# One textured ground plane replaces 256 separate checkerboard tiles.
	var ground=box(parent,Vector3(0,-0.16,0),Vector3(160,0.3,160),"769456")
	if not ground_materials.has(mountain):
		var noise=FastNoiseLite.new();noise.seed=421;noise.frequency=0.075;noise.fractal_octaves=3
		var pixels=Image.create(128,128,false,Image.FORMAT_RGB8)
		var dark=Color("8d9a84" if mountain else "68934d");var bright=Color("b3baa0" if mountain else "96b76a")
		for x in range(128):
			for y in range(128):pixels.set_pixel(x,y,dark.lerp(bright,(noise.get_noise_2d(x,y)+1)*0.5))
		pixels.generate_mipmaps()
		var mat=StandardMaterial3D.new();mat.albedo_texture=ImageTexture.create_from_image(pixels);mat.uv1_scale=Vector3(10,10,10);mat.roughness=1
		ground_materials[mountain]=mat
	ground.material_override=ground_materials[mountain]
	if realistic_enabled:
		ground.material_override.albedo_texture=realistic.texture("ground");ground.material_override.uv1_scale=Vector3(18,18,18);ground.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ground.material_override.albedo_color=Color("b8c3a5")
	# A thin stone boundary frames the buildable area without a chessboard.
	for axis in range(2):
		for side in [-1,1]:
			var pos=Vector3(side*24,0.015,0) if axis==0 else Vector3(0,0.015,side*24)
			box(parent,pos,Vector3(0.2,0.08,48) if axis==0 else Vector3(48,0.08,0.2),"b4bb87")
	if deployment:
		for axis in range(2):
			for side in [-1,1]:
				var pos=Vector3(side*21,0.022,0) if axis==0 else Vector3(0,0.022,side*21)
				box(parent,pos,Vector3(5.8,0.035,47.8) if axis==0 else Vector3(35.8,0.035,5.8),"54775c")
	var rng=RandomNumberGenerator.new();rng.seed=894 if mountain else 421
	for i in range(42):
		var angle=i*TAU/42;var radius=rng.randf_range(30,38)
		var at=Vector3(cos(angle)*radius,0,sin(angle)*radius)
		if realistic_enabled:
			if i%2==0:
				var tree=realistic.sprite("tree",rng.randf_range(5.0,7.0),0.05);tree.position=at;parent.add_child(tree)
			continue
		if i%4==0:
			var rock=orb(parent,at+Vector3(0,0.6,0),Vector3(2.4,1.6,1.9),"8b9c90" if mountain else "9ba586")
			rock.rotation.y=angle
		else:
			var height=rng.randf_range(3.5,5.5)
			cone(parent,at+Vector3(0,height*0.35,0),0.3,0.19,height*0.7,"78684d",7)
			for j in range(3):
				var offset=Vector3(cos(j*2.1)*0.65,height*0.68+j*0.42,sin(j*2.1)*0.65)
				orb(parent,at+offset,Vector3(3.3,2.5,3.1),["40765a","588b58","78a35f"][j])
		if i%3==0:
			for j in range(3):orb(parent,at+Vector3(j*0.6,0.25,2),Vector3(0.65,0.5,0.65),"dbc187" if mountain else "afc975")
	# Small flagstones lead into the village; they never affect placement or AI.
	for i in range(9):
		var stone=box(parent,Vector3(0,0.02,25+i*0.85),Vector3(2.5,0.09,0.7),"c8c4a1")
		stone.rotation.y=sin(i*2.0)*0.08
	batch_static(parent)
func orb(parent: Node3D, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var node=MeshInstance3D.new();var mesh=SphereMesh.new()
	mesh.radial_segments=10;mesh.rings=5;mesh.radius=0.5;mesh.height=1
	node.mesh=mesh;node.material_override=material(color);node.position=pos;node.scale=size;parent.add_child(node)
	return node
func batch_static(root: Node3D):
	# Merge only immutable decoration. Actors, health bars and selectable buildings stay independent.
	var groups: Dictionary={}
	for node in root.find_children("*","MeshInstance3D",true,false):
		if node.mesh==null:continue
		var ancestor: Node=node;var moving=false
		while ancestor!=root:
			if ancestor.get_meta("dynamic_visual",false):moving=true;break
			ancestor=ancestor.get_parent()
		if moving:continue
		# Transparent fabric must retain its separate sorted draw and identity.
		var transparent=false
		for surface in range(node.mesh.get_surface_count()):
			var active=node.get_active_material(surface)
			if active is BaseMaterial3D and active.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:transparent=true
		if transparent:continue
		for surface in range(node.mesh.get_surface_count()):
			var mat=node.get_active_material(surface)
			if mat==null:continue
			var key=mat.get_instance_id()
			if not groups.has(key):
				var builder=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES);builder.set_material(mat);groups[key]=builder
			groups[key].append_from(node.mesh,surface,mesh_transform(node,root))
		# All callers supply freshly generated decoration without collision or animation.
		node.free()
	for builder in groups.values():
		var combined=MeshInstance3D.new();combined.mesh=builder.commit();root.add_child(combined)
func building_trim(root: Node3D, kind: String, level: int):
	# Consistent pale stone footing, warm gold trim and readable resource accents.
	box(root,Vector3(0,0.045,0),Vector3(2.84,0.09,2.84),"b7b8a0")
	box(root,Vector3(0,0.105,0),Vector3(2.64,0.04,2.64),"d3cfac")
	for i in range(2):box(root,Vector3(0,0.04+i*0.045,1.35-i*0.16),Vector3(0.95,0.08,0.24),"e0d4b3")
	var color={"hall":"cd7654","recruit":"d79b4e","dorm":"6288af","servant":"78a576","kitchen":"d18a55","granary":"e5bd61","well":"65bfd0","tank":"65bfd0","spring":"70cead","crystal":"a08cdb","tower":"c8785c","ward":"a58cd3"}.get(kind,"80aaa0")
	if kind in ["hall","recruit","dorm","servant","tower"]:
		for side in [-1,1]:
			box(root,Vector3(side*0.95,0.78,1.1),Vector3(0.09,1.45,0.09),"8b6b48")
			box(root,Vector3(side*0.95,1.13,1.12),Vector3(0.34,0.59,0.055),color)
			box(root,Vector3(side*0.95,1.15,1.155),Vector3(0.065,0.31,0.02),"f7daa0")
	if kind=="kitchen":
		orb(root,Vector3(0.8,0.7,-1),Vector3(0.65,0.22,0.65),"ecdab5")
	if kind=="tank":
		cone(root,Vector3(0,0.62,-0.85),0.75,0.75,0.18,"5b8790",12)
		cone(root,Vector3(0,0.73,-0.85),0.64,0.64,0.025,"7ed9df",16)

	if level>=5:
		for side in [-1,1]:orb(root,Vector3(side*1.12,0.32,1.12),Vector3(0.23,0.38,0.23),"efc76d")
func idle_flair(actor: Node3D, time: float, phase: float, kind: int):
	# Occasional anticipation + wobble for waiting disciples; no extra skeletons or particles.
	var beat=fposmod(time+phase*1.7,12.0)
	actor.rotation.z=sin(beat*9)*0.055*sin((beat-8)*PI/2) if beat>8 and beat<10 and kind==0 else 0.0
func resource_building(kind: String, level: int, fill: float) -> Node3D:
	var root=Node3D.new();root.set_meta("original_building",true)
	building_trim(root,kind,level)
	if kind=="tank":
		cone(root,Vector3(0,0.57,0),1.13,1.13,1.08,"597d87",16)
		for y in [0.16,0.95]:cone(root,Vector3(0,y,0),1.2,1.2,0.13,"c6b27a",16)
		cone(root,Vector3(0,1.12,0),1.15,1.15,0.18,"d9cdab",16)
		cone(root,Vector3(0,1.22,0),0.98,0.98,0.025,"43aabc",24)
		for x in [-0.46,0.46]:box(root,Vector3(x,1.245,0),Vector3(0.08,0.012,1.15),"91d6d2")
		box(root,Vector3(1.08,0.8,0),Vector3(0.23,0.22,0.7),"b8a071")
	elif kind=="crystal":
		cone(root,Vector3(0,0.25,0),1.18,1.18,0.35,"6f7e89",8)
		cone(root,Vector3(0,0.46,0),1.2,1.2,0.09,"d6b971",8)
		for i in range(5):
			var at=Vector3(cos(i*2.4)*0.55,0.47,sin(i*2.4)*0.55)
			var height=0.8+clampf(fill,0,1)*0.6+(0.6 if i==0 else 0)
			cone(root,at+Vector3(0,height*0.4,0),0.27,0.27,height*0.8,["589fb9","8a82bb","77bac4"][i%3],5)
			cone(root,at+Vector3(0,height,0),0.27,0,0.4,["82c6d2","b1a1d4","9dd9dc"][i%3],5)
	elif kind=="tower":
		cone(root,Vector3(0,1.12,0),1.0,0.76,2.1,"a8ab97",8)
		for y in [0.25,1.1,2.1]:cone(root,Vector3(0,y,0),1.04 if y<2 else 1.22,1.04 if y<2 else 1.22,0.15,"778d83",8)
		cone(root,Vector3(0,2.29,0),1.24,1.24,0.25,"c7bd9b",8)
		for i in range(8):
			var angle=i*TAU/8
			box(root,Vector3(cos(angle)*1.1,2.55,sin(angle)*1.1),Vector3(0.28,0.4,0.28),"a2a48d")
		box(root,Vector3(0,2.65,0),Vector3(0.35,0.65,0.4),"74523c")
		box(root,Vector3(0,2.94,0),Vector3(1.65,0.16,0.2),"bd8d53")
		box(root,Vector3(0,2.97,0.2),Vector3(0.12,0.12,1.5),"5d655f")
		cone(root,Vector3(0,3.2,0),0.26,0.04,0.35,"cc865d",4)
	return root

func ring(parent: Node3D, pos: Vector3, radius: float, thickness: float, color: String):
	var node=MeshInstance3D.new();var mesh=TorusMesh.new()
	mesh.inner_radius=radius-thickness;mesh.outer_radius=radius+thickness;mesh.rings=16;mesh.ring_segments=6
	node.mesh=mesh;node.material_override=material(color);node.position=pos;parent.add_child(node)
	return node
func furnace(level: int) -> Node3D:
	var lv=clampi(level,1,10);var root=new_original();var tint=level_color(lv);var k=0.8+lv*0.035
	box(root,Vector3(0,0.1,0),Vector3(2.75,0.2,2.75),"a5aaa0")
	var pot=Node3D.new();root.add_child(pot);pot.scale=Vector3.ONE*k
	for x in [-0.65,0.65]:box(pot,Vector3(x,0.3,0),Vector3(0.26,0.3,0.8),"424f50")
	cone(pot,Vector3(0,1.03,0),0.9,0.95,1.2,"e5e8d9",24)
	cone(pot,Vector3(0,0.5,0),0.92,0.92,0.2,tint,24)
	cone(pot,Vector3(0,1.69,0),1.0,0.8,0.18,tint,24)
	box(pot,Vector3(0,1.9,0),Vector3(0.65,0.15,0.22),"384d4e")
	for x in [-1,1]:box(pot,Vector3(x*0.99,1.36,0),Vector3(0.38,0.18,0.35),"45595a")
	box(pot,Vector3(0,0.92,0.92),Vector3(0.58,0.5,0.07),"405557")
	box(pot,Vector3(0,0.91,0.99),Vector3(0.16,0.27,0.1),"e87753").rotation.x=-0.25
	for x in [-0.16,0.16]:orb(pot,Vector3(x,1.08,0.99),Vector3(0.075,0.075,0.04),"ee6655" if x<0 else "96d886")
	for i in range(lv):orb(pot,Vector3(-0.7+i*0.15,1.43,0.91),Vector3(0.06,0.09,0.04),tint)
	beam(pot,Vector3(0.85,0.6,-0.3),Vector3(1.1,0.25,-0.65),0.04,"393f3d")
	beam(pot,Vector3(1.1,0.25,-0.65),Vector3(0.65,0.22,-1),0.04,"393f3d")
	box(pot,Vector3(0.6,0.23,-1),Vector3(0.18,0.1,0.16),"393f3d")
	var smoke=motion(pot,"black_smoke");smoke.position=Vector3(0.3,1.83,0)
	for i in range(6):
		var puff=orb(smoke,Vector3.ZERO,Vector3.ONE*0.3,"343735");puff.material_override=clear_material("343735",0.55);puff.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.set_meta("rice_cooker",true);return root
func pill_pouch(level: int, fill: float) -> Node3D:
	var root=Node3D.new();root.set_meta("original_building",true);root.set_meta("pill_fill",clampf(fill,0,1))
	building_trim(root,"crystal",level)
	cone(root,Vector3(0,0.22,0),1.1,1.1,0.22,"857154",12)
	var count=ceili(clampf(fill,0,1)*24);root.set_meta("pill_count",count)
	for i in range(count):
		var layer=i/8;var a=(i%8)*TAU/8+layer*0.45
		var p=Vector3(cos(a)*0.5,0.56+layer*0.38,sin(a)*0.5)
		orb(root,p,Vector3(0.39,0.34,0.39),["e5b761","77cda5","c19adc"][i%3])
	var cloth=orb(root,Vector3(0,1.04,0),Vector3(1.94,1.68,1.94),"d2e1c8")
	var mat=StandardMaterial3D.new();mat.albedo_color=Color(0.8,0.92,0.83,0.30)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.roughness=1;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	cloth.material_override=mat;cloth.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;cloth.name="SheerCloth"
	for y in [0.71,1.08,1.43]:ring(root,Vector3(0,y,0),0.94 if y<1.2 else 0.82,0.012,"a3b69b")
	# Woven seams remain opaque enough to read the bag silhouette at mobile size.
	for i in range(6):
		var a=i*TAU/6
		for j in range(4):
			var y=0.43+j*0.36;var radius=0.72+sin(j*PI/3)*0.22
			cone(root,Vector3(cos(a)*radius,y,sin(a)*radius),0.017,0.017,0.38,"a3b69b",5)
	cone(root,Vector3(0,1.94,0),0.33,0.48,0.4,"afc2ad",10)
	ring(root,Vector3(0,1.81,0),0.34,0.045,"dcba74")
	for x in [-1,1]:
		var tie=ring(root,Vector3(x*0.24,1.89,0.4),0.2,0.028,"dcba74");tie.rotation.x=PI/2
		cone(root,Vector3(x*0.32,1.56,0.47),0.025,0.025,0.4,"dcba74",6)
	return root
func barracks(level: int) -> Node3D:
	var root=Node3D.new();root.set_meta("original_building",true)
	building_trim(root,"barracks",level)
	box(root,Vector3(0,0.83,-0.18),Vector3(1.9,1.4,1.65),"c7bc99")
	for x in [-0.98,0.98]:
		for z in [-1.0,0.65]:box(root,Vector3(x,1.02,z),Vector3(0.15,1.8,0.15),"694e3c")
	box(root,Vector3(0,0.72,0.68),Vector3(0.7,1.15,0.1),"394d52")
	roof(root,2.0,1.65,"376d87")
	box(root,Vector3(0,1.45,0.78),Vector3(0.96,0.26,0.08),"ceab67")
	for side in [-1,1]:
		box(root,Vector3(side*0.94,0.54,0.98),Vector3(0.45,0.1,0.3),"7a583b")
		for j in range(2):
			var blade=box(root,Vector3(side*(0.79+j*0.24),0.94,0.99),Vector3(0.07,0.94,0.055),"b5d3d6");blade.rotation.z=side*0.16
			box(root,Vector3(side*(0.79+j*0.24),0.64,1.0),Vector3(0.25,0.06,0.08),"d5ab61")
		training_banner(root,Vector3(side*1.17,0,-0.67),"476f9e")
	boxer_statue(root,level)
	return root
func evolve(root: Node3D, kind: String, level: int):
	# Every level changes silhouette, masonry height and an additive detail;
	# higher tiers add buttresses, gables, lanterns and a jade/gold crown.
	var lv=clampi(level,1,10);root.set_meta("visual_level",lv)
	if kind in ["kitchen","granary","well","tank","spring","servant","tower","ward"]:return
	if lv==1:return
	var colors=["836d50","9d7956","a58758","547c72","3f898a","447f98","596ea8","896baf","ae814f","d4b269"]
	var accent=colors[lv-1];var span=5.7 if kind=="training" else 2.68
	if kind=="wall":
		# No widened ground pad: adjacency and corners remain exactly on their cells.
		for y in range(lv-1):box(root,Vector3(0,0.24+y*0.13,0.33),Vector3(0.4,0.055,0.07),accent)
		if lv>=4:cone(root,Vector3(0,2.2,0),0.33,0.15,0.32,accent,4).rotation.y=PI/4
		root.scale.y=1.0+(lv-1)*0.025
		return
	box(root,Vector3(0,0.08,0),Vector3(span,0.14,span),accent)
	var frame=Node3D.new();root.add_child(frame)
	for i in range(lv-1):
		var x=-span*0.36+i*(span*0.72/8)
		box(frame,Vector3(x,0.26,span*0.46),Vector3(0.12,0.14+0.015*lv,0.12),"e1c789")
	if lv>=3:
		for x in [-1,1]:
			box(frame,Vector3(x*span*0.44,0.42,-span*0.43),Vector3(0.23,0.65,0.23),"84958d")
			cone(frame,Vector3(x*span*0.44,0.82,-span*0.43),0.22,0.05,0.2,accent,4)
	if lv>=5:
		for x in [-1,1]:lantern(frame,Vector3(x*span*0.43,0,span*0.4),0.5+lv*0.018)
	if kind in ["hall","recruit","dorm","servant","kitchen","granary","well","ward","barracks"]:
		if lv>=4:
			for x in [-1,1]:
				box(frame,Vector3(x*1.05,0.7,0),Vector3(0.36,1.1,1.1),"acb4a0")
				roof_node(frame,Vector3(x*1.02,1.44,0),0.66,accent)
		if lv>=7:
			var y=minf(model_bounds(root).end.y,3.4)
			cone(frame,Vector3(0,y+0.12,0),0.18,0.12,0.45,"d4b269",8)
			orb(frame,Vector3(0,y+0.45,0),Vector3(0.29,0.37,0.29),accent)
	if lv>=9:
		for x in [-1,1]:training_banner(frame,Vector3(x*span*0.43,0,0),accent)
	root.scale.y=1.0+(lv-1)*0.025
func roof_node(parent: Node3D, pos: Vector3, width: float, color: String):
	var holder=Node3D.new();holder.position=pos;parent.add_child(holder)
	roof(holder,0,width,color)

# Resource buildings use compact, level-specific silhouettes within their grid cell.
func new_original() -> Node3D:
	var root=Node3D.new();root.set_meta("original_building",true);return root
func level_color(level: int) -> String:
	return ["a57c50","bc8d58","75ae94","61b3b6","7bb1d9","859ddd","ab92d6","d699bc","e1b372","edd493"][clampi(level-1,0,9)]
func clear_material(color: String, alpha: float) -> StandardMaterial3D:
	var mat=StandardMaterial3D.new();mat.albedo_color=Color(color);mat.albedo_color.a=alpha
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.roughness=0.2;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat
func motion(parent: Node3D, kind: String) -> Node3D:
	var node=Node3D.new();node.set_script(preload("res://scripts/visual_motion.gd"));node.kind=kind
	node.set_meta("dynamic_visual",true);node.name=kind.to_pascal_case()+"Motion";parent.add_child(node);return node
func beam(parent: Node3D, start: Vector3, end: Vector3, width: float, color: String):
	var node=box(parent,(start+end)*0.5,Vector3(width,start.distance_to(end),width),color)
	node.quaternion=Quaternion(Vector3.UP,(end-start).normalized());return node
func inn(level: int) -> Node3D:
	var root=new_original();var accent=level_color(level)
	box(root,Vector3(0,0.11,0),Vector3(2.85,0.22,2.8),"969e90")
	# One readable floor per level; compact upper floors keep the mobile map visible.
	for i in range(level):
		var y=0.23+i*0.48;var w=2.3-i*0.055
		box(root,Vector3(0,y+0.22,0),Vector3(w,0.44,1.9),"e1cda4")
		for x in [-1,1]:
			box(root,Vector3(x*(w*0.5-0.05),y+0.24,0.99),Vector3(0.1,0.48,0.1),"794b37")
			box(root,Vector3(x*w*0.26,y+0.24,0.968),Vector3(0.48,0.26,0.035),"77523d")
			for dx in [-0.14,0,0.14]:box(root,Vector3(x*w*0.26+dx,y+0.24,0.997),Vector3(0.025,0.26,0.025),"f3d394")
		box(root,Vector3(0,y+0.46,0),Vector3(w+0.24,0.08,2.17),accent)
		for x in [-1,1]:box(root,Vector3(x*(w*0.5+0.08),y+0.51,0),Vector3(0.11,0.13,2.18),accent).rotation.z=x*0.3
	roof(root,0.65+level*0.48,1.66-level*0.024,"456e69" if level<5 else "52678c")
	box(root,Vector3(0,0.45,1),Vector3(0.48,0.55,0.1),"493a2e")
	box(root,Vector3(0,0.89,1.16),Vector3(0.83,0.26,0.08),"814e33")
	var sign=Label3D.new();sign.text="เตี๊ยม";sign.font=load("res://assets/NotoSansThai.ttf");sign.font_size=36;sign.pixel_size=0.005;sign.position=Vector3(0,0.9,1.22);sign.modulate=Color("f3d394");root.add_child(sign)
	for x in [-1,1]:lantern(root,Vector3(x*1.17,0,1.05),0.45)
	roast_chicken(root,1.23+level*0.48)
	root.set_meta("floors",level);return root
func rice_tiffin(level: int, fill: float) -> Node3D:
	var root=new_original();var tint=level_color(level);var amount=clampf(fill,0,1)
	box(root,Vector3(0,0.08,0),Vector3(2.7,0.16,2.7),"98a999")
	var glass=clear_material("d9f0e5",0.25)
	var portions=ceili(amount*level*18);root.set_meta("food_count",portions);root.set_meta("storage_fill",amount);root.set_meta("tiers",level)
	for i in range(level):
		var y=0.25+i*0.38
		cone(root,Vector3(0,y,0),0.85,0.85,0.065,tint,20)
		var bowl=cone(root,Vector3(0,y+0.17,0),0.83,0.85,0.29,"d9f0e5",20)
		bowl.name="ClearRiceTier"+str(i);bowl.material_override=glass;bowl.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring(root,Vector3(0,y+0.31,0),0.85,0.03,tint)
		var layer_fill=clampf(amount*level-i,0,1)
		if layer_fill>0:
			cone(root,Vector3(0,y+0.045+layer_fill*0.1,0),0.75,0.75,layer_fill*0.2,"fff1ce",20)
			for grain in range(ceili(layer_fill*18)):
				var a=grain*2.4;var radius=0.14+0.55*sqrt(float(grain)/18)
				orb(root,Vector3(cos(a)*radius,y+0.08+layer_fill*0.2,sin(a)*radius),Vector3(0.16,0.045,0.065),"fff9df").rotation.y=a
		for ornament in range(2+level):
			var a=ornament*TAU/(2+level)
			orb(root,Vector3(cos(a)*0.854,y+0.14,sin(a)*0.854),Vector3(0.045,0.08,0.045),"efd798")
	var top=0.25+level*0.38
	cone(root,Vector3(0,top,0),0.88,0.7,0.12,tint,20)
	for side in [-1,1]:
		beam(root,Vector3(side*0.92,0.24,0),Vector3(side*0.92,top+0.43,0),0.075,tint)
	beam(root,Vector3(-0.92,top+0.43,0),Vector3(0.92,top+0.43,0),0.1,"d5b779")
	if amount>0:
		var steam=motion(root,"smoke");steam.position=Vector3(0.23,top+0.1,0.2)
		for i in range(4):
			var puff=orb(steam,Vector3.ZERO,Vector3.ONE*0.13,"f2f1dd");puff.material_override=clear_material("f2f1dd",0.24);puff.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root
func builder_shed() -> Node3D:
	var root=new_original();root.set_meta("fixed_level",true)
	box(root,Vector3(0,0.08,0),Vector3(2.7,0.16,2.7),"928b74")
	for x in [-1.02,1.02]:
		for z in [-0.8,0.82]:box(root,Vector3(x,0.91,z),Vector3(0.1,1.7,0.1),"856344")
	box(root,Vector3(0,0.9,-0.87),Vector3(2.1,1.55,0.045),"9aa7a6")
	box(root,Vector3(-1.07,0.9,0),Vector3(0.04,1.55,1.72),"879795")
	for i in range(13):
		var x=-1.22+i*0.2
		box(root,Vector3(x,1.91,0),Vector3(0.19,0.06,2.15),"9ea9a7" if i%3 else "a78869").rotation.x=-0.13
		box(root,Vector3(x,1.95,0),Vector3(0.035,0.06,2.15),"bcc6bb").rotation.x=-0.13
	for i in range(11):box(root,Vector3(-1+i*0.2,0.9,-0.82),Vector3(0.035,1.5,0.04),"bdc1ad")
	box(root,Vector3(0.15,0.69,0.54),Vector3(1.6,0.12,0.58),"b2915a")
	for x in [-0.48,0.72]:box(root,Vector3(x,0.37,0.54),Vector3(0.1,0.63,0.45),"795d3d")
	for i in range(3):box(root,Vector3(0.38+i*0.1,0.81,0.58),Vector3(0.065,0.07,0.55),"dcc18a")
	box(root,Vector3(-0.5,0.85,0.56),Vector3(0.09,0.08,0.47),"825535")
	box(root,Vector3(-0.5,0.89,0.36),Vector3(0.35,0.13,0.13),"697575")
	cone(root,Vector3(0.76,0.3,-0.45),0.23,0.28,0.45,"a57d52",10)
	return root
func water_bottle(level: int, fill: float) -> Node3D:
	var root=new_original();var k=0.76+level*0.045;var tint=level_color(level)
	box(root,Vector3(0,0.08,0),Vector3(2.75,0.16,2.75),"91aaa7")
	var bottle=Node3D.new();root.add_child(bottle);bottle.scale=Vector3.ONE*k
	var shell=cone(bottle,Vector3(0,1.27,0),0.79,0.79,2.15,"c7edf4",24)
	shell.name="ClearBottle";shell.material_override=clear_material("c7edf4",0.14);shell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shoulder=cone(bottle,Vector3(0,2.5,0),0.79,0.32,0.32,"c7edf4",24);shoulder.material_override=shell.material_override
	cone(bottle,Vector3(0,2.79,0),0.32,0.32,0.27,tint,16)
	ring(bottle,Vector3(0,2.68,0),0.34,0.04,"e4d5ab")
	var amount=clampf(fill,0,1);root.set_meta("storage_fill",amount)
	if amount>0:
		var water=cone(bottle,Vector3(0,0.23+amount*1.04,0),0.73,0.73,amount*2.08,"4bbcdf",24)
		water.name="StoredWater";water.material_override=clear_material("43b9dc",0.72)
	for i in range(3+level):ring(bottle,Vector3(0,0.33+i*1.9/(2+level),0),0.794,0.018,tint)
	for i in range(level):
		var a=i*TAU/level
		orb(bottle,Vector3(cos(a)*0.797,1.22,sin(a)*0.797),Vector3(0.09,0.21,0.09),"eee0b3")
	return root
func small_worker(parent: Node3D, seated: bool) -> Node3D:
	var node=Node3D.new();parent.add_child(node);node.set_meta("worker_height",1.25)
	var hip=0.46 if seated else 0.52
	box(node,Vector3(0,hip+0.22,0),Vector3(0.38,0.4,0.26),"6b9898")
	orb(node,Vector3(0,hip+0.6,0),Vector3(0.35,0.38,0.34),"e7bd91")
	cone(node,Vector3(0,hip+0.8,0),0.29,0.02,0.15,"c9ae70",10)
	for x in [-0.12,0.12]:
		var knee=Vector3(x,0.38,0.31) if seated else Vector3(x,0.25,0)
		beam(node,Vector3(x,hip,0),knee,0.14,"475e70")
		beam(node,knee,Vector3(x,0.08,knee.z),0.13,"475e70")
		box(node,Vector3(x,0.055,knee.z+0.06),Vector3(0.17,0.11,0.25),"58493d")
	return node
func hand_pump(level: int) -> Node3D:
	var root=new_original();var tint=level_color(level);var radius=0.11+level*0.012
	box(root,Vector3(0,0.1,0),Vector3(2.8,0.2,2.8),"899b96")
	for i in range(level+2):box(root,Vector3(-1.2+i*2.4/(level+1),0.22,0.65),Vector3(0.12,0.04,1.2),tint)
	cone(root,Vector3(-0.48,0.4,0),0.36,0.3,0.4,tint,12)
	cone(root,Vector3(-0.48,0.91,0),radius,radius,1.0,tint,12)
	beam(root,Vector3(-0.48,1.15,0),Vector3(-0.48,1.15,0.6),radius*1.1,tint)
	cone(root,Vector3(-0.48,1.06,0.6),radius*0.55,radius*0.55,0.23,tint)
	cone(root,Vector3(-0.48,0.43,0.65),0.28,0.34,0.42,"ae9274",12)
	cone(root,Vector3(-0.48,0.65,0.65),0.29,0.29,0.025,"55bdd5",12)
	var group=motion(root,"pump")
	var handle=Node3D.new();handle.name="Handle";handle.position=Vector3(-0.48,1.39,0);group.add_child(handle)
	beam(handle,Vector3(-0.15,0,0),Vector3(0.98,0,0),0.075,"506d70")
	var worker=small_worker(group,false);worker.position=Vector3(0.83,0.2,0);worker.rotation.y=-PI/2
	for z in [-0.16,0.16]:
		var arm=beam(group,Vector3(0.83,1.02,z),Vector3(0.48,1.39,z),0.11,"e7bd91");arm.name="ArmLeft" if z<0 else "ArmRight"
	var stream=cone(group,Vector3(-0.48,0.87,0.65),0.027,0.027,0.42,"89dce6",6);stream.name="Stream"
	root.set_meta("pipe_radius",radius);return root
func scaffold_worker(parent: Node3D, span: float):
	if realistic_enabled:
		var worker=realistic.sprite("carpenter_motion",2.1*4,0.07);worker.hframes=4;worker.vframes=2;worker.offset.y=worker.texture.get_height()*0.215;worker.set_script(preload("res://scripts/realistic_loop.gd"));worker.position=Vector3(0,0,span*0.46);parent.add_child(worker);return
	box(parent,Vector3(0,1.78,span*0.46),Vector3(2.3,0.1,0.73),"b8925c")
	var group=motion(parent,"saw");group.position=Vector3(-0.58,1.84,span*0.46)
	small_worker(group,true)
	box(group,Vector3(0,0.28,0),Vector3(0.46,0.1,0.38),"82613e")
	for x in [-0.48,0.48]:box(group,Vector3(x,0.32,0.49),Vector3(0.1,0.64,0.34),"84613e")
	box(group,Vector3(0.12,0.66,0.49),Vector3(1.16,0.16,0.2),"d4b07b")
	var tool=Node3D.new();tool.name="Saw";group.add_child(tool)
	box(tool,Vector3(0.12,0.79,0.49),Vector3(0.65,0.12,0.025),"c8d6d8")
	for i in range(9):cone(tool,Vector3(-0.15+i*0.066,0.7,0.49),0.035,0,0.07,"c8d6d8",3).rotation.z=PI
	box(tool,Vector3(-0.25,0.83,0.49),Vector3(0.16,0.18,0.07),"825131")
	for x in [-0.18,0.18]:beam(tool,Vector3(x,0.74,0.05),Vector3(x-0.1,0.84,0.49),0.1,"e7bd91")

func ruins(parent: Node3D, pos: Vector3, kind: String="hall", width: int=1) -> Node3D:
	var root=new_original();root.name="Ruins";root.set_meta("ruins",true);root.position=pos;parent.add_child(root)
	if realistic_enabled:
		root.add_child(realistic.sprite("ruins",2.8 if width==1 else 5.3,0.22))
		var smoke=motion(root,"embers");smoke.name="EmbersMotion"
		for i in range(5):
			realistic.puff(smoke,Color(0.23,0.23,0.23,0.3))
		return root
	var span=2.4 if width==1 else 5.3
	box(root,Vector3(0,0.08,0),Vector3(span,0.16,span),"4b4b43")
	for i in range(9 if kind!="wall" else 5):
		var a=i*2.4;var radius=span*(0.13+0.025*i)
		var chunk=box(root,Vector3(cos(a)*radius,0.21+(i%3)*0.08,sin(a)*radius),Vector3(0.32+(i%2)*0.3,0.3,0.35),"8c8b7c" if i%2 else "605d50")
		chunk.rotation=Vector3(0.12*i,a,0.16*(i%3))
	if kind!="wall":
		for side in [-1,1]:
			beam(root,Vector3(side*span*0.34,0.1,-0.5),Vector3(side*0.2,0.45,0.7),0.15,"483e31")
			box(root,Vector3(side*0.5,0.3,-0.35),Vector3(0.85,0.08,0.6),"526c62").rotation.z=side*0.35
	var smoke=motion(root,"embers");smoke.position.y=0.3
	for i in range(2 if kind=="wall" else 5):
		var puff=orb(smoke,Vector3.ZERO,Vector3.ONE*0.3,"7d817b");puff.material_override=clear_material("7d817b",0.24);puff.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fire=motion(root,"fire")
	for i in range(2):cone(fire,Vector3(-0.3+i*0.6,0.25,0.1),0.09,0.01,0.24,"d99a50",6)
	batch_static(root);return root

func takeaway_box(level: int, fill: float) -> Node3D:
	var root=new_original();var amount=clampf(fill,0,1);var k=0.86+level*0.025;var tint=level_color(level)
	box(root,Vector3(0,0.09,0),Vector3(2.8,0.18,2.75),"929f8b")
	var tray=Node3D.new();root.add_child(tray);tray.scale=Vector3.ONE*k
	box(tray,Vector3(0,0.26,0),Vector3(2.2,0.18,1.65),"eeeeda")
	var plastic=clear_material("e9f4e6",0.24)
	for x in [-1.08,1.08]:
		var side=box(tray,Vector3(x,0.59,0),Vector3(0.075,0.66,1.7),"e9f4e6");side.material_override=plastic
	for z in [-0.82,0.82]:
		var side=box(tray,Vector3(0,0.59,z),Vector3(2.18,0.66,0.065),"e9f4e6");side.material_override=plastic
	var lid=Node3D.new();tray.add_child(lid);lid.position=Vector3(0,0.91,-0.8);lid.rotation.x=0.68
	var cover=box(lid,Vector3(0,0,-0.8),Vector3(2.25,0.075,1.65),"e9f4e6");cover.material_override=plastic
	for x in [-1.1,1.1]:box(lid,Vector3(x,0,-0.8),Vector3(0.07,0.09,1.65),"f5f0d8")
	for z in [0,-1.6]:box(lid,Vector3(0,0,z),Vector3(2.25,0.09,0.07),"f5f0d8")
	var count=ceili(amount*24);root.set_meta("food_count",count);root.set_meta("storage_fill",amount)
	for i in range(count):
		var pos=Vector3(-0.8+(i%6)*0.31,0.4+floori(i/12.0)*0.19,-0.47+((i/6)%2)*0.64)
		if i%6<3:orb(tray,pos,Vector3(0.35,0.25,0.32),"fff3cf")
		else:
			orb(tray,pos,Vector3(0.28,0.16,0.3),"92633d" if i%2 else "6d9e46")
			box(tray,pos+Vector3(0,0.1,0),Vector3(0.12,0.04,0.05),"d75b3e")
	if count>6:
		orb(tray,Vector3(-0.42,0.79,0.15),Vector3(0.66,0.075,0.5),"fff9dd")
		orb(tray,Vector3(-0.42,0.85,0.15),Vector3(0.26,0.1,0.26),"edb742")
	for i in range(level):box(tray,Vector3(-0.9+i*0.2,0.31,0.88),Vector3(0.09,0.06,0.03),tint)
	root.set_meta("takeaway",true);return root
func roast_chicken(parent: Node3D, y: float):
	var chicken=Node3D.new();parent.add_child(chicken);chicken.position.y=y;chicken.name="RoofChicken"
	orb(chicken,Vector3(0,0.35,0),Vector3(1.1,0.65,0.75),"c57a36")
	for side in [-1,1]:
		orb(chicken,Vector3(side*0.49,0.24,0.38),Vector3(0.4,0.33,0.48),"d99444")
		beam(chicken,Vector3(side*0.54,0.24,0.43),Vector3(side*0.7,0.34,0.74),0.09,"f2ddae")
		orb(chicken,Vector3(side*0.7,0.34,0.76),Vector3(0.18,0.12,0.12),"fff0c8")
	for x in [-0.25,0,0.25]:box(chicken,Vector3(x,0.67,0),Vector3(0.045,0.025,0.38),"87502d")
	beam(chicken,Vector3(-0.8,0.2,0),Vector3(0.8,0.2,0),0.06,"806246")
func boxer_statue(parent: Node3D, level: int):
	var lv=clampi(level,1,10);var boxer=Node3D.new();parent.add_child(boxer);boxer.name="RoofBoxer";boxer.position=Vector3(0,2.58,0)
	boxer.scale=Vector3.ONE*(0.55+lv*0.07);boxer.set_meta("muscle",lv)
	var muscle=0.28+lv*0.018
	box(boxer,Vector3(0,0.23,0),Vector3(0.9,0.15,0.7),"d3b77a")
	for side in [-1,1]:
		beam(boxer,Vector3(side*0.21,0.28,0),Vector3(side*0.19,0.94,0),0.2,"c9936c")
		box(boxer,Vector3(side*0.2,0.95,0),Vector3(0.31,0.4,0.38),"cc5453")
		orb(boxer,Vector3(side*0.3,1.53,0),Vector3(muscle,muscle,0.3),"d8a47c")
		beam(boxer,Vector3(side*0.38,1.54,0),Vector3(side*0.55,1.25,0.1),muscle*0.75,"d8a47c")
		beam(boxer,Vector3(side*0.55,1.25,0.1),Vector3(side*0.35,1.65,0.28),0.18,"d8a47c")
		orb(boxer,Vector3(side*0.35,1.66,0.28),Vector3(0.25,0.27,0.25),"e06452")
	orb(boxer,Vector3(0,1.35,0),Vector3(0.53+lv*0.016,0.68,0.36),"d8a47c")
	orb(boxer,Vector3(0,1.97,0),Vector3(0.38,0.43,0.36),"d8a47c")
	cone(boxer,Vector3(0,2.16,0),0.21,0.2,0.11,"384746",10)
	ring(boxer,Vector3(0,2.12,0),0.205,0.035,"e3c86b")
	for x in [-0.08,0.08]:orb(boxer,Vector3(x,2.0,0.172),Vector3(0.045,0.045,0.035),"343c39")
	if lv==10:
		var fire=motion(boxer,"fire");fire.name="ChampionFire"
		for i in range(8):
			var a=i*TAU/8;var flame=cone(fire,Vector3(cos(a)*0.55,0.6,sin(a)*0.46),0.12,0,0.8,"ef973e",6)
			var mat=material("ef973e").duplicate();mat.emission_enabled=true;mat.emission=Color("e87529");flame.material_override=mat
func speaker_tower(level: int) -> Node3D:
	var root=new_original();var h=2.5+level*0.17;var spread=0.65+level*0.025;var tint=level_color(level)
	box(root,Vector3(0,0.12,0),Vector3(2.7,0.24,2.7),"929e96")
	for side in [-1,1]:
		for z in [-1,1]:beam(root,Vector3(side*spread,0.2,z*spread),Vector3(side*0.35,h,z*0.35),0.1+level*0.005,"708f94")
	for i in range(1,5):
		var y=i*h/5
		beam(root,Vector3(-spread,y,-spread),Vector3(spread,y+h/5,-spread),0.055,tint)
		beam(root,Vector3(-spread,y,spread),Vector3(spread,y+h/5,spread),0.055,tint)
	box(root,Vector3(0,h,0),Vector3(1.4+level*0.025,0.16,1.4+level*0.025),tint)
	for i in range(4):
		var a=i*TAU/4;var horn=Node3D.new();root.add_child(horn);horn.position=Vector3(0,h+0.34,0);horn.rotation.y=a
		cone(horn,Vector3(0,0,0.51),0.17,0.38+level*0.006,0.7,"d5d9bd",12).rotation.x=PI/2
		cone(horn,Vector3(0,0,0.88),0.32+level*0.006,0.32+level*0.006,0.025,"45585a",12).rotation.x=PI/2
	cone(root,Vector3(0,h+0.64,0),0.045,0.02,0.7,"d7bd78",6)
	root.set_meta("sound_radius",4.2);return root
func slingshot_ladder(level: int) -> Node3D:
	var root=new_original();var h=1.8+level*0.08;var w=0.78+level*0.035
	var timber="987043" if level<4 else "627f7f" if level<8 else "a39a77"
	box(root,Vector3(0,0.1,0),Vector3(2.8,0.2,2.8),"9b9e87")
	for side in [-1,1]:
		for z in [-1,1]:beam(root,Vector3(side*w,0.2,z*0.85),Vector3(side*w,h,z*0.25),0.11+level*0.007,timber)
	for step in range(1,5+level/2):
		var y=float(step)*h/(5+level/2);var z=0.85-0.6*y/h
		beam(root,Vector3(-w,y,z),Vector3(w,y,z),0.1,timber)
	box(root,Vector3(0,h,0),Vector3(w*2+0.2,0.15,1.15),timber)
	# One more seated shooter per level; two staggered rows keep the ladder readable.
	for i in range(level):
		var holder=Node3D.new();root.add_child(holder);holder.position=Vector3((i%5-(mini(level,5)-1)*0.5)*0.4 if level>2 else (i-(level-1)*0.5)*0.55,h+0.08,-0.3+(i/5)*0.6)
		holder.scale=Vector3.ONE*(0.48 if level>2 else 0.68)
		small_worker(holder,true)
		box(holder,Vector3(0,0.39,0),Vector3(0.45,0.09,0.35),timber)
		for side in [-1,1]:box(holder,Vector3(side*0.17,0.19,0),Vector3(0.07,0.38,0.3),timber)
		var hand=motion(holder,"slinger");hand.name="Sling"
		beam(hand,Vector3(-0.16,0.73,0),Vector3(0.16,0.81,0.38),0.1,"e3b58c")
		for side in [-1,1]:beam(hand,Vector3(0.16,0.83,0.4),Vector3(0.16+side*0.14,1.15,0.4),0.055,"805a39")
		beam(hand,Vector3(0.02,1.15,0.4),Vector3(0.16,1.03,0.15),0.025,"d7c99e")
		beam(hand,Vector3(0.3,1.15,0.4),Vector3(0.16,1.03,0.15),0.025,"d7c99e")
		batch_static(hand)
	root.set_meta("shooters",level);return root
func sound_wave(parent: Node3D, pos: Vector3, radius: float):
	var root=Node3D.new();parent.add_child(root);root.position=pos
	for i in range(3):
		var wave=ring(root,Vector3(0,0.2+i*0.17,0),1.0,0.025,"e2d891")
		wave.material_override=clear_material("f5e5a2",0.65);wave.scale=Vector3.ONE*0.2
		var tween=wave.create_tween();tween.set_parallel(true)
		tween.tween_property(wave,"scale",Vector3(radius,1,radius),0.65+i*0.12)
		tween.tween_property(wave.material_override,"albedo_color:a",0.0,0.65+i*0.12)
	var timer=root.get_tree().create_timer(1.0);timer.timeout.connect(root.queue_free)

func slingshot_fx(parent: Node3D, start: Vector3, end: Vector3):
	var pebble=orb(parent,start,Vector3.ONE*0.18,"a39880")
	var tween=pebble.create_tween();tween.tween_property(pebble,"position",end,0.3)
	tween.tween_callback(pebble.queue_free)
