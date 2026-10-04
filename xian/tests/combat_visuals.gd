extends SceneTree
const Art=preload("res://scripts/art.gd")
func _initialize():call_deferred("run")
func run():
 var art=Art.new();var stage=Node3D.new();root.add_child(stage)
 var camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=10;camera.position=Vector3(5,5,10);camera.look_at(Vector3(0,1,0))
 var light=DirectionalLight3D.new();stage.add_child(light);light.rotation_degrees=Vector3(-50,-30,0);light.light_energy=1.0;light.shadow_enabled=true
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=0.55;stage.add_child(env)
 art.box(stage,Vector3(0,-0.1,0),Vector3(30,0.2,30),"71826b")
 var models=[]
 for i in range(3):
  var model=art.person(i);stage.add_child(model);model.position=Vector3((i-1)*3.5,0,0);models.append(model)
  assert(model.has_meta("anim_player"))
  var player=model.get_meta("anim_player");assert(player.has_animation(model.get_meta("attack_clip")))
  if i<2:assert(model.find_child("SwordHand",true,false).bone_name=="prop.R")
  else:assert(model.get_meta("donor_beast",false))
 await process_frame;await process_frame
 DirAccess.make_dir_recursive_absolute("res://build/review")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/units37-idle.png")
 var hand=models[0].find_child("SwordHand",true,false);var start=hand.global_transform
 for model in models:art.pose(model,"attack",1.0)
 for model in models:model.get_meta("anim_player").advance(0.45)
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 assert(not hand.global_transform.is_equal_approx(start),"Attack does not animate sword hand")
 root.get_texture().get_image().save_png("res://build/review/units37-attack.png")
 print("XIAN_COMBAT_VISUALS_PASSED");quit()
