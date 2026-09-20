extends RefCounted
## Only Google's earned callback creates a durable receipt. Delivery never waits on activity flags.
const REWARD_SECONDS:=3000
const REWARD_COINS:=5
var host:Node3D
var bridge:Object
var pending:Dictionary={}
var requests:Dictionary={}
var processed:Array=[]
var inbox:Array=[]
var poll_wait:=0.0
var result_panel:PanelContainer
var status:="Optional ad: reduce one construction by 50 minutes, or choose 5 GODOT Coin."
func _init(game:Node3D)->void:
	host=game
	if Engine.has_singleton("GalaxyAds"):
		bridge=Engine.get_singleton("GalaxyAds")
		bridge.connect("reward_earned",_earned)
		bridge.connect("ad_closed",_closed)
		bridge.connect("ad_status",_status)
func save_state()->Dictionary:return {"pending":pending,"requests":requests,"processed":processed}
func load_state(data:Dictionary)->void:
	requests=data.get("requests",{});processed=data.get("processed",[]);pending={}
	# Preserve already-earned v19 credit once as ordinary in-game currency; new boosts never bank.
	var legacy:int=int(data.get("boost_seconds",0))
	if legacy>0:host.godot_coins+=ceili(legacy/600.0)
func offer_build(index:int)->void:
	if host.mode!="base" or index<0 or index>=host.buildings.size():return
	var b:Dictionary=host.buildings[index]
	if b.get("job","")=="":host._toast("This job is already complete.");return
	confirmation("REDUCE CONSTRUCTION • 50 MIN", "Complete one optional ad to reduce this job by 50 minutes.\nIf less time remains, the job finishes. No time is stored.\nReward applies only to this construction.",func():request_build(index))
func offer_coins()->void:
	if host.mode!="base" or not host.has_colony:return
	confirmation("EARN 5 GODOT COIN", "Complete one optional ad to receive 5 GODOT Coin.\n1 Coin = 10 minutes of construction time.\nIn-game only. No transfers or cash redemption.",request_coins)
func confirmation(title:String,message:String,action:Callable)->void:
	show_panel(title,message)
	var p:PanelContainer=result_panel
	p.get_child(0).add_child(host._button("WATCH AD",func():p.hide();action.call(),Vector2(0,54)))
	p.get_child(0).add_child(host._button("CANCEL",func():p.hide(),Vector2(0,48)))
func request_build(index:int)->void:
	if host.mode!="base" or index<0 or index>=host.buildings.size():return
	host._advance_colony(maxf(host.colony_time,Time.get_unix_time_from_system()))
	var b:Dictionary=host.buildings[index]
	if b.get("job","")=="" or float(b.finish)<=host.colony_time:host._toast("This job is already complete.");return
	request({"kind":"build","index":index,"started":float(b.started),"job":str(b.job),"level":int(b.level)})
func request_coins()->void:
	if host.mode=="base" and host.has_colony:request({"kind":"coins"})
func request(claim:Dictionary)->void:
	if not pending.is_empty():host._toast("Please finish the current ad first.");return
	if not bridge:host._toast("Ads are available in the Android build when online.");return
	if not bridge.is_ready():bridge.prepare();host._toast("Loading ad. Tap WATCH AD again when ready.");return
	var token:String=Crypto.new().generate_random_bytes(16).hex_encode()
	pending=claim.duplicate();pending.token=token;requests[token]=pending.duplicate()
	if not host._save_profile():requests.erase(token);pending={};return
	host._dismiss_menus();bridge.show_rewarded(token)
func _earned(token:String)->void:
	if token not in inbox:inbox.append(token)
func _closed(token:String)->void:
	if pending.get("token","")==token:pending={}
	poll_wait=0
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
	var message:String
	if claim.get("kind","build")=="coins":
		host.godot_coins+=REWARD_COINS
		message="+5 GODOT Coin added.\nBalance: %d GODOT Coin.\n1 Coin = 10 minutes of construction time."%host.godot_coins
	else:
		var index:int=int(claim.index)
		var used:=0
		if index>=0 and index<host.buildings.size():
			var b:Dictionary=host.buildings[index]
			if b.get("job","")==claim.job and int(b.level)==int(claim.level) and absf(float(b.get("started",-1))-float(claim.started))<.01:
				used=mini(REWARD_SECONDS,maxi(0,ceili(float(b.finish)-host.colony_time)))
				b.finish=maxf(host.colony_time+.001,float(b.finish)-REWARD_SECONDS)
		message="50-minute boost applied to the selected construction.\nTime removed: %dm %ds. No time stored."%[used/60,used%60] if used>0 else "The selected construction is already complete.\nNo time stored and no Coins spent."
	processed.append(token)
	if pending.get("token","")==token:pending={}
	host._advance_colony(host.colony_time+.002)
	if host._save_profile():_ack(token)
	host._refresh_progress();host._update_top_bar();host._update_work_display()
	show_panel("AD REWARD RECEIVED",message)
	result_panel.get_child(0).add_child(host._button("CONTINUE",func():result_panel.hide(),Vector2(0,54)))
func show_panel(title:String,message:String)->void:
	host._dismiss_menus()
	if is_instance_valid(result_panel):result_panel.queue_free()
	result_panel=host._panel(title);host.ui_root.add_child(result_panel)
	var label:=Label.new();label.add_theme_font_size_override("font_size",18);label.text=message
	result_panel.get_child(0).add_child(label)
	var screen:Vector2=host.get_viewport().get_visible_rect().size
	result_panel.position=Vector2((screen.x-720)/2,150);result_panel.size=Vector2(720,330)
func privacy()->void:
	if bridge:bridge.privacy_options()
	else:host._toast("Ad privacy options are available on Android.")
func tick()->void:
	# Receipt delivery is safe even if an Android lifecycle callback is delayed or missing.
	# Do not gate it on app_paused/is_showing: the receipt proves the reward was earned.
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
	var active:bool=host.mode=="base" and index>=0 and index<host.buildings.size() and host.buildings[index].get("job","")!="" and host.buildings[index].type!=24
	host.ad_button.visible=active;host.ad_button.disabled=not pending.is_empty()
	host.ad_button.text="AD IN PROGRESS" if not pending.is_empty() else "WATCH AD • −50 MIN"
