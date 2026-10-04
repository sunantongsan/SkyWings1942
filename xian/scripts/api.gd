extends Node
signal updated(payload: Dictionary)
signal failed(message: String)
signal authenticated
const URL = "https://uzinxxeadejmzxqmqqtx.supabase.co"
const KEY = "sb_publishable_4R8VSfnmuFq6hAgWRtDX6Q_IcSVh82m"
var token = ""
var refresh_token = ""
var expires = 0.0
var busy = false
var pending: Dictionary = {}
var session_path = "user://xian_session.json"

func _ready():
	if FileAccess.file_exists(session_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(session_path))
		if data is Dictionary:
			refresh_token = data.get("refresh_token", "")
			pending = data.get("pending", {})

func uuid() -> String:
	var b = Crypto.new().generate_random_bytes(16)
	b[6] = (b[6] & 15) | 64
	b[8] = (b[8] & 63) | 128
	var h = b.hex_encode()
	return "%s-%s-%s-%s-%s" % [h.substr(0,8),h.substr(8,4),h.substr(12,4),h.substr(16,4),h.substr(20,12)]

func request(path: String, body: Dictionary, auth = false) -> Dictionary:
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = 25
	var headers = PackedStringArray(["Content-Type: application/json", "apikey: " + KEY])
	if auth: headers.append("Authorization: Bearer " + token)
	var err = http.request(URL + path, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		http.queue_free()
		return {"error": "เชื่อมต่อไม่ได้ กรุณาลองใหม่", "network":true}
	var response = await http.request_completed
	http.queue_free()
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	if response[0] != HTTPRequest.RESULT_SUCCESS:
		return {"error": "เครือข่ายขัดข้อง กรุณาตรวจอินเทอร์เน็ตแล้วลองใหม่", "network":true}
	if response[1] < 200 or response[1] >= 300:
		return {"error": data.get("message", data.get("msg", data.get("error_description", "เชื่อมต่อไม่สำเร็จ"))) if data is Dictionary else "เซิร์ฟเวอร์ไม่ตอบสนอง"}
	return data if data is Dictionary else {"error": "ข้อมูลไม่ถูกต้อง"}

func save_session(data: Dictionary):
	token = data.get("access_token", "")
	refresh_token = data.get("refresh_token", "")
	expires = Time.get_unix_time_from_system() + float(data.get("expires_in", 3600))
	persist()

func persist():
	var f = FileAccess.open(session_path, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"refresh_token": refresh_token,"pending":pending}))

func login(email: String, password: String, signup = false):
	if busy: return
	busy = true
	var data = await request("/auth/v1/signup" if signup else "/auth/v1/token?grant_type=password", {"email":email,"password":password})
	busy = false
	if data.has("error"): failed.emit(data.error); return
	if not data.has("access_token"):
		failed.emit("สมัครแล้ว กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ"); return
	pending={}
	save_session(data)
	authenticated.emit()
	await action("sync")

func resume():
	if refresh_token.is_empty(): return
	busy = true
	var data = await request("/auth/v1/token?grant_type=refresh_token", {"refresh_token":refresh_token})
	busy = false
	if data.has("error"):
		failed.emit("กรุณาเข้าสู่ระบบอีกครั้ง"); return
	save_session(data)
	authenticated.emit()
	await action("sync")

func action(kind: String, args: Dictionary = {}):
	if busy: return
	busy = true
	if Time.get_unix_time_from_system() > expires - 60:
		var data = await request("/auth/v1/token?grant_type=refresh_token", {"refresh_token":refresh_token})
		if data.has("error"):
			busy = false; failed.emit("เซสชันหมดอายุ กรุณาเปิดเกมและเข้าสู่ระบบใหม่"); return
		save_session(data)
	if pending.is_empty():
		pending={"p_action":kind,"p_args":args,"p_request":uuid()}
		persist()
	var payload = await request("/rest/v1/rpc/xian_action", pending, true)
	busy = false
	if payload.has("error"):
		if not payload.get("network",false):pending={};persist()
		failed.emit(payload.error)
	else:
		pending={};persist();updated.emit(payload)
