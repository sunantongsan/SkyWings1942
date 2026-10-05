extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.api.refresh_token="";game.api.busy=true;game.set_process(false);game.close_modal();game.mode="home"
 game.state={"name":"สำนักเมฆาคราม","map":"bamboo","water":1350,"rice":1950,"stone":150,"jade":3500,"army":[3,0,0],"jobs":[],"checkin_count":3,"buildings":[]}
 game.caps={"water":3000,"rice":5000,"stone":600,"workers":2,"busy":0,"army":30}
 var kinds=["hall","well","kitchen","tank","granary","spring","crystal","servant","barracks","training"]
 var positions=[[7,6],[4,5],[9,5],[4,7],[9,7],[6,4],[8,4],[5,9],[7,9],[9,9]]
 for i in range(kinds.size()):game.state.buildings.append({"id":kinds[i],"x":positions[i][0],"y":positions[i][1],"level":3 if kinds[i] in ["kitchen","granary"] else 1,"finish":0})
 game.catalog=[{"id":"servant","name":"เพิงช่าง","water":0,"rice":0,"stone":0,"seconds":0}]
 game.draw_base();game.update_top();game.show_side();game.checkin_available=true
 DirAccess.make_dir_recursive_absolute("res://build/review")
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/home41.png")
 game.api.busy=false;game.show_gifts()
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/review/gifts41.png")
 print("XIAN_GIFTS_CAPTURE_PASSED");quit()
