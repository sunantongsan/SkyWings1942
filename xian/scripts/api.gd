extends Node
signal updated(payload: Dictionary)
signal failed(message: String)
signal auth_notice(message: String)
signal auth_working(active: bool)
signal authenticated
const URL = "https://uzinxxeadejmzxqmqqtx.supabase.co"
const KEY = "sb_publishable_4R8VSfnmuFq6hAgWRtDX6Q_IcSVh82m"
var user_id = ""
var token = ""
var refresh_token = ""
var expires = 0.0
var busy = false
var pending: Dictionary = {}
var oauth_verifier = ""
var oauth_started = 0.0
var session_path = "user://xian_session.json"

func _ready():
	if Engine.has_singleton("XianAuth"):
		Engine.get_singleton("XianAuth").oauth_callback.connect(oauth_callback)
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
	user_id = str(data.get("user",{}).get("id",user_id))
	token = data.get("access_token", "")
	refresh_token = data.get("refresh_token", "")
	expires = Time.get_unix_time_from_system() + float(data.get("expires_in", 3600))
	persist()

func persist():
	var f = FileAccess.open(session_path, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"refresh_token": refresh_token,"pending":pending}))

func valid_email(email: String) -> bool:
	var re = RegEx.new()
	re.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")
	return re.search(email) != null

func auth_error(data: Dictionary) -> String:
	var error = str(data.get("error", "เชื่อมต่อไม่สำเร็จ"))
	if "Invalid login credentials" in error: return "อีเมลหรือรหัสผ่านไม่ถูกต้อง หากเคยใช้วิถีเซียน ให้ใช้บัญชีอีเมลเดิม"
	if "Email not confirmed" in error: return "กรุณายืนยันอีเมลก่อน แล้วกดเข้าสู่ระบบอีกครั้ง"
	if "rate limit" in error.to_lower() or "security purposes" in error.to_lower(): return "ส่งคำขอบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่"
	if "already registered" in error.to_lower(): return "อีเมลนี้มีบัญชีแล้ว กรุณากดเข้าสู่ระบบ"
	return error

func resend_confirmation(email: String):
	if busy: return
	email = email.strip_edges()
	if not valid_email(email): failed.emit("กรุณากรอกอีเมลให้ครบ เช่น name@example.com"); return
	busy = true; auth_working.emit(true)
	var data = await request("/auth/v1/resend", {"type":"signup", "email":email})
	busy = false; auth_working.emit(false)
	if data.has("error"): failed.emit(auth_error(data))
	else: auth_notice.emit("ส่งคำขอยืนยันแล้ว ตรวจกล่องจดหมายและสแปม จากนั้นกลับมากดเข้าสู่ระบบ")

func login(email: String, password: String, signup = false):
	if busy: return
	email = email.strip_edges()
	if not valid_email(email): failed.emit("กรุณากรอกอีเมลให้ครบ เช่น name@example.com"); return
	if password.is_empty(): failed.emit("กรุณากรอกรหัสผ่าน"); return
	if signup and password.length() < 8: failed.emit("ตั้งรหัสผ่านอย่างน้อย 8 ตัวอักษร"); return
	busy = true; auth_working.emit(true)
	var data = await request("/auth/v1/signup" if signup else "/auth/v1/token?grant_type=password", {"email":email,"password":password})
	busy = false; auth_working.emit(false)
	if data.has("error"): failed.emit(auth_error(data)); return
	if not data.has("access_token"):
		auth_notice.emit("รับคำขอสมัครแล้ว กรุณาเปิดอีเมลเพื่อยืนยัน (ตรวจสแปมด้วย) แล้วกลับมากดเข้าสู่ระบบ หากมีบัญชีเดิมให้เข้าสู่ระบบได้เลย"); return
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

func google_login():
	if busy: return
	if not Engine.has_singleton("XianAuth"):
		failed.emit("Google ต้องใช้ APK รุ่นที่รองรับการเข้าสู่ระบบ Google"); return
	oauth_verifier = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(32)).replace("+","-").replace("/","_").replace("=","")
	oauth_started = Time.get_unix_time_from_system()
	var challenge = Marshalls.raw_to_base64(oauth_verifier.sha256_buffer()).replace("+","-").replace("/","_").replace("=","")
	# Reuse the old game's registered redirect. PKCE binds the callback to this request.
	var url = URL+"/auth/v1/authorize?provider=google&redirect_to="+"com.sunantongsan.thegang://auth-callback".uri_encode()+"&code_challenge_method=s256&code_challenge="+challenge
	if OS.shell_open(url)!=OK:
		oauth_verifier=""; failed.emit("เปิดเบราว์เซอร์ไม่ได้ กรุณาติดตั้งหรือเปิดใช้งานเบราว์เซอร์"); return
	auth_notice.emit("เลือกบัญชี Google ในเบราว์เซอร์ แล้วเลือกกลับมาที่ Xian of Clans หากยกเลิกให้กด Google ใหม่")

func oauth_callback(url: String):
	if not url.begins_with("com.sunantongsan.thegang://auth-callback?"): return
	if oauth_verifier.is_empty() or Time.get_unix_time_from_system()-oauth_started>600:
		failed.emit("คำขอ Google หมดอายุ กรุณากดเข้าสู่ระบบด้วย Google ใหม่"); return
	if busy: return
	var query: Dictionary = {}
	for item in url.get_slice("?",1).get_slice("#",0).split("&"):
		query[item.get_slice("=",0)]=item.get_slice("=",1).uri_decode()
	var verifier=oauth_verifier; oauth_verifier=""
	if not query.has("code"):
		failed.emit("ยกเลิกหรือยืนยันบัญชี Google ไม่สำเร็จ กรุณาลองใหม่"); return
	busy=true;auth_working.emit(true)
	var data=await request("/auth/v1/token?grant_type=pkce",{"auth_code":query.code,"code_verifier":verifier})
	busy=false;auth_working.emit(false)
	if data.has("error"):failed.emit(auth_error(data));return
	if str(data.get("access_token","")).is_empty():failed.emit("ไม่ได้รับบัญชีจาก Google กรุณาลองใหม่");return
	pending={};save_session(data);authenticated.emit();await action("sync")
