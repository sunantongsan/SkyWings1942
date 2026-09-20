extends RefCounted
var host:Node3D
var tiles:MultiMeshInstance3D
var footprint:MeshInstance3D
var caption:Label3D
var pointer:=Vector3.ZERO
var has_pointer:=false
var cache_key:=""
const GREEN:=Color(.15,1.0,.4,.22)
const RED:=Color(1.0,.12,.15,.28)
func _init(game:Node3D)->void:
	host=game
	tiles=MultiMeshInstance3D.new();tiles.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh:=PlaneMesh.new();mesh.size=Vector2(1.9,1.9)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.vertex_color_use_as_albedo=true
	tiles.material_override=material
	var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true;multi.mesh=mesh;tiles.multimesh=multi;host.world_root.add_child(tiles)
	footprint=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(6,6);footprint.mesh=plane
	var pad:=StandardMaterial3D.new();pad.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;pad.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;footprint.material_override=pad;footprint.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;host.world_root.add_child(footprint)
	caption=Label3D.new();caption.font_size=38;caption.pixel_size=.018;caption.outline_size=8;caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED;caption.no_depth_test=true;host.world_root.add_child(caption)
	tiles.hide();footprint.hide();caption.hide()
func point_at(screen:Vector2)->void:
	var hit=host._ground_hit(screen)
	if hit!=null:pointer=hit;has_pointer=true;update_cursor()
func reason(pos:Vector3)->String:
	return host._deployment_reason(pos) if host.mode=="battle" else host._placement_reason(Vector3(snappedf(pos.x,1),0,snappedf(pos.z,1)))
func update_cursor()->void:
	var pos:Vector3=pointer if has_pointer else host.camera_focus
	if host.mode!="battle":pos=Vector3(snappedf(pos.x,1),0,snappedf(pos.z,1))
	footprint.rotation.y=float(host.buildings[host.moving_building].get("yaw",0)) if host.moving_building>=0 else 0.0
	var kind:int=host.buildings[host.moving_building].type if host.moving_building>=0 else host.build_type
	if host.mode=="base" and kind==24:
		var connection:Dictionary=host.layout.wall_snap(pos,host.moving_building);pos=connection.pos;footprint.rotation.y=connection.yaw
	var error:=reason(pos)
	footprint.position=pos+Vector3(0,.16,0);footprint.scale=Vector3.ONE*(.4 if host.mode=="battle" else 1.0)
	if host.mode=="base":
		if kind in [24,25]:footprint.scale=Vector3(1,1,1.4/6.0)
		if kind in [18,19,20]:footprint.scale=Vector3(13.0/6.0,1,10.0/6.0)
	footprint.material_override.albedo_color=Color(.1,1,.3,.5) if error.is_empty() else Color(1,.1,.1,.55)
	caption.position=pos+Vector3(0,2,0);caption.text="CAN PLACE" if error.is_empty() else error.to_upper()
func tick()->void:
	var visible:bool=((host.mode=="battle" and host._reserve_count()>0) or (host.mode=="base" and (host.build_type>=0 or host.moving_building>=0))) and not host.build_panel.visible and not host.units_panel.visible and not host.galaxy_panel.visible and not host.victory_panel.visible
	if host.onboarding and host.onboarding.screen.visible:visible=false
	if host.coin_system and is_instance_valid(host.coin_system.panel) and host.coin_system.panel.visible:visible=false
	host.terrain_material.set_shader_parameter("deployment_active",visible and host.mode=="battle")
	host.terrain_material.set_shader_parameter("deployment_available",host.mode=="battle" and reason(Vector3(30,0,0)).is_empty())
	tiles.visible=visible and host.mode!="battle";footprint.visible=visible and has_pointer;caption.visible=visible and has_pointer
	if not visible:cache_key="";has_pointer=false;return
	update_cursor()
	var center:=Vector3.ZERO if host.mode=="battle" else Vector3(snappedf(host.camera_focus.x,2),0,snappedf(host.camera_focus.z,2))
	var reserves:int=host._reserve_count() if host.mode=="battle" else 0
	var key:String=str([host.mode,center,host.build_type,host.moving_building,host.buildings.size(),host.deploy_kind,reserves,host._builder_busy(),int(host.metal),int(host.oil)])
	if key==cache_key:return
	cache_key=key
	if host.mode=="battle":
		# Exact outer deployment bands; no green cells extend into forbidden terrain.
		var regions:=[Vector4(-19,0,6,40),Vector4(19,0,6,40),Vector4(0,-16.5,32,7),Vector4(0,16.5,32,7),Vector4(0,0,32,26),Vector4(-23,0,2,40),Vector4(23,0,2,40),Vector4(0,-21,48,2),Vector4(0,21,48,2)]
		tiles.multimesh.instance_count=regions.size()
		for i in regions.size():
			var region:Vector4=regions[i]
			var basis:=Basis.IDENTITY.scaled(Vector3(region.z/1.9,1,region.w/1.9))
			tiles.multimesh.set_instance_transform(i,Transform3D(basis,Vector3(region.x,.07,region.y)))
			tiles.multimesh.set_instance_color(i,GREEN if reason(Vector3(region.x,0,region.y)).is_empty() else RED)
		return
	var positions:Array[Vector3]=[]
	for x in range(-24,25,2):
		for z in range(-22,23,2):positions.append(center+Vector3(x,.12,z))
	tiles.multimesh.instance_count=positions.size()
	for i in positions.size():
		var pos:Vector3=positions[i]
		tiles.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,pos))
		tiles.multimesh.set_instance_color(i,GREEN if reason(Vector3(pos.x,0,pos.z)).is_empty() else RED)
