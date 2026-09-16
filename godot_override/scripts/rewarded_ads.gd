extends RefCounted
## Only a matching Google earned-reward callback can shorten the selected job.
const REWARD_SECONDS:=50.0
var host:Node3D
var bridge:Object
var pending:Dictionary={}
var sequence:=0
var status:="Watch an optional ad to remove 50 seconds from this job."
func _init(game:Node3D)->void:
	host=game
	if Engine.has_singleton("GalaxyAds"):
		bridge=Engine.get_singleton("GalaxyAds")
		bridge.connect("reward_earned",_earned)
		bridge.connect("ad_closed",_closed)
		bridge.connect("ad_status",_status)
func request_build(index:int)->void:
	if host.mode!="base" or index<0 or index>=host.buildings.size() or not pending.is_empty():return
	var b:Dictionary=host.buildings[index]
	if b.get("job","")=="" or float(b.finish)<=host.colony_time:host._toast("This job is already complete.");return
	if not bridge:host._toast("Ads are available in the Android build when online.");return
	if not bridge.is_ready():
		bridge.prepare();host._toast("Loading ad. Tap WATCH AD again when ready.");return
	sequence+=1
	pending={"token":str(sequence),"building":b,"started":float(b.started),"job":str(b.job),"level":int(b.level)}
	host._save_profile()
	bridge.show_rewarded(str(sequence))
func _earned(token:String)->void:
	if pending.is_empty() or token!=pending.token:return
	var claim:Dictionary=pending;pending={}
	# Wall-clock work still advances while Android displays the ad.
	host._advance_colony(maxf(host.colony_time,Time.get_unix_time_from_system()))
	var b:Dictionary=claim.building
	if b.get("job","")!=claim.job or int(b.level)!=claim.level or float(b.get("started",-1))!=claim.started:
		host._toast("Your selected job already finished while you watched.");return
	var saved:float=minf(REWARD_SECONDS,maxf(0,float(b.finish)-host.colony_time))
	b.finish=maxf(host.colony_time+.001,float(b.finish)-REWARD_SECONDS)
	host._advance_colony(host.colony_time+.002);host._save_profile()
	host._toast("Ad reward: −%ds from the selected job."%ceili(saved))
func _closed(token:String)->void:
	if not pending.is_empty() and pending.token==token:
		pending={};host._toast("Ad closed without a reward. Your construction continues.")
func _status(message:String)->void:
	status=message
	host._toast(message)
func privacy()->void:
	if bridge:bridge.privacy_options()
	else:host._toast("Ad privacy options are available on Android.")
func tick()->void:
	if not is_instance_valid(host.ad_button):return
	var index:int=host.selected_building
	var active:bool=index>=0 and index<host.buildings.size() and host.buildings[index].get("job","")!=""
	host.ad_button.visible=active
	host.ad_button.disabled=not pending.is_empty()
	host.ad_button.text="AD IN PROGRESS" if not pending.is_empty() else "WATCH AD • −50s"
