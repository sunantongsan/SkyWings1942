extends RefCounted
## Durable earned receipts from Google; acknowledge only after the colony save succeeds.
const REWARD_SECONDS:=50
var host:Node3D
var bridge:Object
var pending:Dictionary={}
var requests:Dictionary={}
var processed:Array=[]
var inbox:Array=[]
var boost_seconds:=0
var poll_wait:=0.0
var result_panel:PanelContainer
var status:="Watch an optional ad for 50 seconds of construction speed-up."
func _init(game:Node3D)->void:
	host=game
	if Engine.has_singleton("GalaxyAds"):
		bridge=Engine.get_singleton("GalaxyAds")
		bridge.connect("reward_earned",_earned)
		bridge.connect("ad_closed",_closed)
		bridge.connect("ad_status",_status)
func save_state()->Dictionary:return {"pending":pending,"requests":requests,"processed":processed,"boost_seconds":boost_seconds}
func load_state(data:Dictionary)->void:
	pending=data.get("pending",{});requests=data.get("requests",{});processed=data.get("processed",[]);boost_seconds=int(data.get("boost_seconds",0))
	# A previous activity may have been destroyed; native receipts recover earned rewards.
	pending={}
func request_build(index:int)->void:
	if host.mode!="base" or index<0 or index>=host.buildings.size() or not pending.is_empty():return
	var b:Dictionary=host.buildings[index]
	if b.get("job","")=="" or float(b.finish)<=host.colony_time:host._toast("This job is already complete.");return
	if not bridge:host._toast("Ads are available in the Android build when online.");return
	if not bridge.is_ready():bridge.prepare();host._toast("Loading ad. Tap WATCH AD again when ready.");return
	var token:String=Crypto.new().generate_random_bytes(16).hex_encode()
	pending={"token":token,"index":index,"started":float(b.started),"job":str(b.job),"level":int(b.level)}
	requests[token]=pending.duplicate()
	if not host._save_profile():requests.erase(token);pending={};return
	host._dismiss_menus();bridge.show_rewarded(token)
func _earned(token:String)->void:
	# Queue delivery until the Android fullscreen activity has closed.
	if token not in inbox:inbox.append(token)
func _closed(token:String)->void:
	if not pending.is_empty() and pending.token==token:pending={}
	# Do not discard the request: an earned callback/receipt can arrive after dismissal.
func _status(message:String)->void:status=message;host._toast(message)
func _ack(token:String)->void:
	if bridge and bridge.has_method("ack_reward"):bridge.ack_reward(token)
func receive(token:String)->void:
	if token in processed:
		if host._save_profile():_ack(token)
		return
	if not requests.has(token):return
	var claim:Dictionary=requests[token]
	host._advance_colony(maxf(host.colony_time,Time.get_unix_time_from_system()))
	boost_seconds+=REWARD_SECONDS
	var used:=0
	var index:int=int(claim.index)
	if index>=0 and index<host.buildings.size():
		var b:Dictionary=host.buildings[index]
		if b.get("job","")==claim.job and int(b.level)==int(claim.level) and is_equal_approx(float(b.get("started",-1)),float(claim.started)):
			used=mini(REWARD_SECONDS,maxi(0,ceili(float(b.finish)-host.colony_time)))
			b.finish=maxf(host.colony_time+.001,float(b.finish)-used);boost_seconds-=used
	processed.append(token)
	# Keep request identities with receipt history. No callback can affect another job.
	if pending.get("token","")==token:pending={}
	host._advance_colony(host.colony_time+.002)
	if host._save_profile():_ack(token)
	show_result(used)
func use_saved(index:int)->void:
	if boost_seconds<=0 or host.mode!="base" or index<0 or index>=host.buildings.size():return
	var b:Dictionary=host.buildings[index]
	if b.get("job","")=="":return
	var used:int=mini(boost_seconds,mini(REWARD_SECONDS,maxi(0,ceili(float(b.finish)-host.colony_time))))
	boost_seconds-=used;b.finish=maxf(host.colony_time+.001,float(b.finish)-used)
	host._advance_colony(host.colony_time+.002);host._save_profile();host._dismiss_menus()
	host._toast("Saved boost applied: −%ds • %ds still saved"%[used,boost_seconds])
func show_result(used:int)->void:
	host._dismiss_menus()
	if is_instance_valid(result_panel):result_panel.queue_free()
	result_panel=host._panel("AD REWARD RECEIVED • 50 SECONDS")
	host.ui_root.add_child(result_panel)
	var label:=Label.new();label.add_theme_font_size_override("font_size",20)
	label.text="Construction reduced by %d seconds.\nSaved speed-up: %d seconds.\nUnused time is saved for your next construction."%[used,boost_seconds]
	result_panel.get_child(0).add_child(label)
	result_panel.get_child(0).add_child(host._button("CONTINUE",func():result_panel.hide(),Vector2(0,54)))
	var screen:Vector2=host.get_viewport().get_visible_rect().size
	result_panel.position=Vector2((screen.x-650)/2,160);result_panel.size=Vector2(650,280)
func privacy()->void:
	if bridge:bridge.privacy_options()
	else:host._toast("Ad privacy options are available on Android.")
func tick()->void:
	if host.app_paused:return
	if bridge and bridge.has_method("is_showing") and bridge.is_showing():return
	poll_wait-=host.get_process_delta_time()
	if poll_wait<=0:
		poll_wait=.5
		if bridge and bridge.has_method("get_reward_receipts"):
			var receipts:Variant=JSON.parse_string(bridge.get_reward_receipts())
			if receipts is Array:
				for token in receipts:_earned(str(token))
		for token in inbox.duplicate():receive(str(token));inbox.erase(token)
	if not is_instance_valid(host.ad_button):return
	var index:int=host.selected_building
	var active:bool=index>=0 and index<host.buildings.size() and host.buildings[index].get("job","")!=""
	host.ad_button.visible=active;host.ad_button.disabled=not pending.is_empty()
	host.ad_button.text="AD IN PROGRESS" if not pending.is_empty() else "WATCH AD • −50s"
	host.saved_boost_button.visible=active and boost_seconds>0
	host.saved_boost_button.text="USE SAVED BOOST • %ds"%boost_seconds
