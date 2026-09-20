extends RefCounted
## Runtime GLB paint variants. Original resources are never modified.
const COLORS:=[Color("ffffff"),Color("2275e8"),Color("d82e35"),Color("20252e"),Color("eab43b"),Color("c72032")]
static var paint_cache:Dictionary={}
static func apply(root:Node3D,level:int,kind:int)->void:
	if not is_instance_valid(root) or int(root.get_meta("paint_rank",0))==level:return
	root.set_meta("paint_rank",level)
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		if not mesh.has_meta("rank_originals"):
			var originals:Array=[]
			for surface in mesh.mesh.get_surface_count():originals.append(mesh.get_active_material(surface))
			mesh.set_meta("rank_originals",originals)
		var originals:Array=mesh.get_meta("rank_originals")
		for surface in originals.size():
			var source:Material=originals[surface]
			if not source is StandardMaterial3D:continue
			if level==1:mesh.set_surface_override_material(surface,source);continue
			var name:String=source.resource_name.to_lower()
			if "recess" in name or "glass" in name or "rust" in name:continue
			# Keep bamboo/earth/concrete/steel/fire recognizable; color the fittings.
			if kind==24 and name in ["wall_material","bamboo_joints"]:continue
			var key:String=str(source.get_instance_id())+":"+str(mini(level,6))
			if not paint_cache.has(key):
				var paint:StandardMaterial3D=source.duplicate()
				var trim:bool="edge" in name or "gold" in name or "ochre" in name or "titanium" in name
				var color:Color=Color("ffcc52") if level>=6 and (trim or source.emission_enabled) else COLORS[mini(level,6)-1]
				paint.albedo_color=color.lightened(.12) if trim and level<5 else color
				paint.metallic=.65 if level>=5 else .32;paint.roughness=.38 if level>=5 else .57
				if source.emission_enabled:paint.emission=Color("ffd667") if level>=5 else color;paint.emission_energy_multiplier=1.15
				paint_cache[key]=paint
			mesh.set_surface_override_material(surface,paint_cache[key])
	var sparkles:CPUParticles3D=root.get_node_or_null("RankSparkles")
	if level>=6 and not sparkles:
		sparkles=CPUParticles3D.new();sparkles.name="RankSparkles";root.add_child(sparkles)
		sparkles.amount=10;sparkles.lifetime=2.4;sparkles.preprocess=2.4
		sparkles.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;sparkles.emission_box_extents=Vector3(2.7,2.2,2.7);sparkles.position.y=2.5
		sparkles.gravity=Vector3.ZERO;sparkles.direction=Vector3.UP;sparkles.spread=25;sparkles.initial_velocity_min=.15;sparkles.initial_velocity_max=.45
		var shape:=SphereMesh.new();shape.radius=.1;shape.height=.2;shape.radial_segments=6;shape.rings=3;sparkles.mesh=shape
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color("fff0a0");mat.emission_enabled=true;mat.emission=Color("ffcf57");sparkles.material_override=mat
		var pulse:=Curve.new()
		for point in [Vector2(0,0),Vector2(.15,1),Vector2(.3,.05),Vector2(.48,1.4),Vector2(.65,.1),Vector2(.8,1),Vector2(1,0)]:pulse.add_point(point)
		sparkles.scale_amount_curve=pulse
	if sparkles:sparkles.emitting=level>=6;sparkles.visible=level>=6
