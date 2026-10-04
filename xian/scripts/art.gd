extends RefCounted
var mats = {}
func material(hex: String) -> StandardMaterial3D:
	if mats.has(hex): return mats[hex]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	# Stylized PBR: keep the broad readable shapes, but let sun/highlights sell depth.
	m.roughness = 0.72
	m.metallic = 0.0
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
			var palette={"House Player":"866f42","House_2":"ba8b46","House_3":"387e94","House_4":"596f9f","shop":"b45b43","Arena":"708468"}
			for surface in range(source.get_surface_count()):
				var arrays=source.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL];var colors=PackedColorArray()
				for i in range(vertices.size()):
					var roof_face=normals[i].y>0.15 and vertices[i].y>bounds.position.y+bounds.size.y*0.35
					colors.append(Color(palette.get(part,"708468")) if roof_face else Color("e7d9bc"))
				arrays[Mesh.ARRAY_COLOR]=colors;recolored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=0.95;recolored.surface_set_material(surface,mat)
			house_meshes[part]=recolored
		scene.mesh=house_meshes[part]
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
			box(root,Vector3(-2.42+x*0.97,0.065,-2.42+z*0.97),Vector3(0.91,0.03,0.91),"d0cbb7" if (x+z)%2==0 else "c1bea9")
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
	# Small props at the edges make the yard feel authored without blocking troop readability.
	lantern(root,Vector3(-2.35,0,-2.35),0.65);lantern(root,Vector3(2.35,0,-2.35),0.65)
	rock(root,Vector3(-2.25,0,1.45),0.55);rock(root,Vector3(2.2,0,1.5),0.45)
	cone(root,Vector3(0,0.092,0),1.05,1.05,0.018,"899c96",32)
	box(root,Vector3(0,0.11,0),Vector3(0.08,0.015,1.5),"ece4c9")
	box(root,Vector3(0,0.11,0.45),Vector3(0.55,0.015,0.08),"ece4c9")
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
	# Floating progress bar visible from the isometric camera.
	var bar=Node3D.new();bar.position=Vector3(0,h+0.65,0);parent.add_child(bar)
	box(bar,Vector3.ZERO,Vector3(2.5,0.22,0.12),"322f2c")
	var p=clampf(progress,0.04,1.0);var fill=box(bar,Vector3(-1.2+1.2*p,0,0.07),Vector3(2.4*p,0.16,0.08),"79d77b")
	fill.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in range(3):box(parent,Vector3(-0.7+i*0.65,0.13,span*0.5+0.35),Vector3(0.42,0.26,0.32),"b8a37a")

func building(kind: String, level: int, fill = 0.5) -> Node3D:
	if kind=="wall":return wall(0,0,level)
	if kind=="training":return courtyard(level)
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
	# Shared visual language: stone plinth, paired lanterns and banners make mixed donor assets feel like one sect.
	var plinth=box(root,Vector3(0,-0.055,0),Vector3(3.15,0.11,3.15),"8f8b79");plinth.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if kind in ["hall","recruit","tower","ward"]:
		lantern(root,Vector3(-1.15,0,-1.15),0.48);lantern(root,Vector3(1.15,0,-1.15),0.48)
	if kind in ["hall","recruit"]:
		training_banner(root,Vector3(-1.35,0,0.7),"a94438");training_banner(root,Vector3(1.35,0,0.7),"a94438")
	if level>=5:
		for p in [Vector3(-1.3,0,1.15),Vector3(1.3,0,1.15)]:rock(root,p,0.32)
	return root
func person(kind: int, armed: bool=true) -> Node3D:
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
		var bounds=model_bounds(root);var factor=2.15/maxf(bounds.size.y,0.01)
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
	if not root.has_meta("anim_player"):return
	var player: AnimationPlayer=root.get_meta("anim_player")
	if state!="attack" and root.get_meta("attacking",false) and player.is_playing():return
	var clip: String=root.get_meta(state+"_clip",root.get_meta("idle_clip"))
	if state=="attack":
		root.set_meta("attacking",true);player.play(clip,0.08,player.get_animation(clip).length/maxf(0.1,attack_duration));player.seek(0,true)
	elif player.current_animation!=clip or not player.is_playing():
		root.set_meta("attacking",false);player.play(clip,0.15,1.0)
