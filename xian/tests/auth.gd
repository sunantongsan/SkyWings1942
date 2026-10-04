extends SceneTree
class FakeAPI:
	extends "res://scripts/api.gd"
	var calls = 0
	var reply: Dictionary = {}
	func request(_path: String, _body: Dictionary, _auth = false) -> Dictionary:
		calls += 1
		await get_tree().process_frame
		return reply
	func persist(): pass
	func action(_kind: String, _args: Dictionary = {}): pass
var errors: Array[String] = []
var notices: Array[String] = []
var working: Array[bool] = []
func _initialize(): call_deferred("run")
func run():
	var api=FakeAPI.new();root.add_child(api)
	api.failed.connect(func(value): errors.append(value))
	api.auth_notice.connect(func(value): notices.append(value))
	api.auth_working.connect(func(value): working.append(value))
	await api.login("", "password123", true)
	await api.login("bad@", "password123", true)
	await api.login("valid@example.com", "", false)
	assert(api.calls==0 and errors.size()==3)
	api.reply={"user":{"id":"test"}}
	await api.login(" valid@example.com ", "password123", true)
	assert(notices.size()==1 and not api.busy and working==[true,false])
	api.reply={"error":"Email not confirmed"}
	await api.login("valid@example.com", "password123")
	assert("ยืนยันอีเมล" in errors.back() and not api.busy)
	api.reply={"error":"network unavailable", "network":true}
	await api.login("valid@example.com", "password123")
	assert(not api.busy)
	api.reply={}
	await api.resend_confirmation("valid@example.com")
	assert(notices.size()==2)
	api.oauth_verifier="request-bound-secret";api.oauth_started=Time.get_unix_time_from_system()
	api.reply={"access_token":"test", "refresh_token":"test", "expires_in":3600}
	await api.oauth_callback("com.sunantongsan.thegang://auth-callback?code=test-code")
	assert(api.token=="test" and api.oauth_verifier.is_empty())
	var used_calls=api.calls
	await api.oauth_callback("com.sunantongsan.thegang://auth-callback?code=test-code")
	assert(api.calls==used_calls)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.message("visible auth error")
	assert(game.auth_status.text=="visible auth error")
	game.auth_loading(true)
	for c in game.auth_controls:
		if c is Button: assert(c.disabled)
	game.auth_loading(false)
	game.auth_signup=true;game.show_login("saved@example.com")
	assert(game.auth_controls[0].text=="saved@example.com")
	assert(game.auth_controls[2].visible)
	game.queue_free();api.queue_free()
	await process_frame
	print("XIAN_AUTH_PASSED")
	quit()
