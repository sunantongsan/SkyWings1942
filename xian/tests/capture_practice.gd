extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.api.busy=true
 # Open from login without needing a player state or network.
 game.navigate("practice");await process_frame;await process_frame
 assert(is_instance_valid(game.practice));assert(not game.ui.visible)
 var practice=game.practice
 DirAccess.make_dir_recursive_absolute("res://build/review")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/practice.png")
 practice.start_level(8);practice.camera.size=64
 for kind in range(3):
  practice.selected_kind=kind
  for i in range(3):practice.place_at(practice.camera.unproject_position(practice.world_pos(Vector2(1,6+i))))
 practice.camera.size=38
 for i in range(90):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/practice-battle.png")
 assert(practice.sim.units.size()==9)
 practice.closed.emit();await process_frame
 assert(game.ui.visible and not is_instance_valid(game.practice))
 game.close_modal();game.mode="home"
 game.state={"name":"สำนักเมฆาคราม","map":"bamboo","water":650,"rice":650,"stone":60,"jade":20,"army":[6,2,0],"jobs":[],"buildings":[{"id":"training","x":7,"y":7,"size":2,"level":3,"finish":0},{"id":"hall","x":5,"y":6,"level":3,"finish":0}]}
 game.caps={"army":60,"workers":1,"busy":0}
 game.catalog=[{"id":"training","name":"ลานฝึกกระบี่","water":100,"rice":100,"stone":10,"seconds":30}]
 game.selected=0;game.camera.size=26;game.draw_base();game.show_side();game.update_top()
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/courtyard.png")
 print("XIAN_PRACTICE_UI_PASSED");quit()
