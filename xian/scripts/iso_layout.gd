extends RefCounted
# Shared projection and placement contract for village, combat and asset previews.
const CELL_SIZE=3.0
const GRID_CENTER=7.5
const CAMERA_OFFSET=Vector3(40,32.66,40)
const SURFACE_Y=0.075
static func world_cell(x: float,y: float,height: float=0.0) -> Vector3:
 return Vector3((x-GRID_CENTER)*CELL_SIZE,height,(y-GRID_CENTER)*CELL_SIZE)
static func place_camera(camera: Camera3D,pivot: Vector3):
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.position=pivot+CAMERA_OFFSET
 camera.look_at(pivot)
static func sprite_depth_material(visual: Sprite3D) -> ShaderMaterial:
 var material=ShaderMaterial.new()
 material.shader=preload("res://scripts/grounded_sprite.gdshader")
 var source=visual.texture
 if source is AtlasTexture:source=source.atlas
 material.set_shader_parameter("artwork",source)
 material.set_shader_parameter("surface_y",SURFACE_Y)
 return material
