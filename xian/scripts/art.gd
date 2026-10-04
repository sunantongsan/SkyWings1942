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
	# Floating progress bar visible from the isometric camera.
	var bar=Node3D.new();bar.position=Vector3(0,h+0.65,0);parent.add_child(bar)
	box(bar,Vector3.ZERO,Vector3(2.5,0.22,0.12),"322f2c")
	var p=clampf(progress,0.04,1.0);var fill=box(bar,Vector3(-1.2+1.2*p,0,0.07),Vector3(2.4*p,0.16,0.08),"79d77b")
	fill.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in range(3):box(parent,Vector3(-0.7+i*0.65,0.13,span*0.5+0.35),Vector3(0.42,0.26,0.32),"b8a37a")

func building(kind: String, level: int, fill = 0.5) -> Node3D:
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
	if kind in ["tank","tower"]:return resource_building(kind,level,fill)
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
	# A thin stone boundary frames the buildable area without a chessboard.
	for axis in range(2):
		for side in [-1,1]:
			var pos=Vector3(side*24,0.015,0) if axis==0 else Vector3(0,0.015,side*24)
			box(parent,pos,Vector3(0.2,0.08,48) if axis==0 else Vector3(48,0.08,0.2),"b4bb87")
	if deployment:
		for axis in range(2):
			for side in [-1,1]:
				var pos=Vector3(side*21,0.022,0) if axis==0 else Vector3(0,0.022,side*21)
				box(parent,pos,Vector3(5.8,0.035,47.8) if axis==0 else Vector3(35.8,0.035,5.8),"82ba72")
	var rng=RandomNumberGenerator.new();rng.seed=894 if mountain else 421
	for i in range(42):
		var angle=i*TAU/42;var radius=rng.randf_range(30,38)
		var at=Vector3(cos(angle)*radius,0,sin(angle)*radius)
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
	var root=Node3D.new();root.set_meta("original_building",true)
	building_trim(root,"spring",level)
	var bronze=["836047","966949","9b734c","a8814d","b28b4f"][mini(4,(level-1)/2)]
	cone(root,Vector3(0,0.24,0),1.18,1.18,0.3,"5a676a",8)
	for i in range(3):
		var a=i*TAU/3;var p=Vector3(cos(a)*0.68,0.58,sin(a)*0.68)
		cone(root,p,0.18,0.12,0.7,bronze,7)
	orb(root,Vector3(0,0.52,0),Vector3(0.75,0.65,0.75),"e99942")
	orb(root,Vector3(0,1.22,0),Vector3(1.85,1.55,1.85),bronze)
	ring(root,Vector3(0,1.14,0),0.91,0.055,"d2ad68")
	cone(root,Vector3(0,2.02,0),0.9,0.2,0.38,"537c73",12)
	ring(root,Vector3(0,1.85,0),0.82,0.075,"dfbe76")
	cone(root,Vector3(0,2.29,0),0.19,0.12,0.28,bronze,8)
	for x in [-1,1]:
		var handle=ring(root,Vector3(x*0.91,1.6,0),0.29,0.065,"d2ad68");handle.rotation.z=PI/2
		box(root,Vector3(x*0.3,0.4,1.04),Vector3(0.3,0.35,0.12),"efb654")
	# White wisps and herbs are bounded decoration, not particle emitters.
	for i in range(3):orb(root,Vector3(sin(i)*0.12,2.58+i*0.19,0),Vector3(0.21+i*0.04,0.17,0.21),"c0d2b6")
	return root
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
	return root
func evolve(root: Node3D, kind: String, level: int):
	# Every level changes silhouette, masonry height and an additive detail;
	# higher tiers add buttresses, gables, lanterns and a jade/gold crown.
	var lv=clampi(level,1,10);root.set_meta("visual_level",lv)
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
