extends Node
class_name AuthManager

signal user_registered(username: String)
signal user_authenticated(username: String)
signal auth_error(message: String)

const USER_DB_PATH := "user://skillpath_users.json"
const HASH_ALGO := HashingContext.HASH_SHA256

var users: Dictionary = {}

func _ready() -> void:
	_load_db()

func register_user(username: String, password: String) -> bool:
	username = username.strip_edges()
	if username.is_empty() or password.is_empty():
		emit_signal("auth_error", "Username and password required.")
		return false
	if users.has(username):
		emit_signal("auth_error", "User already exists.")
		return false
	var salt := _generate_salt()
	users[username] = {
		"salt": salt,
		"hash": _hash_password(password, salt),
		"progress": {
			"B1": {},
			"B2": {},
			"C1": {}
		}
	}
	_save_db()
	emit_signal("user_registered", username)
	return true

func authenticate(username: String, password: String) -> bool:
	username = username.strip_edges()
	if not users.has(username):
		emit_signal("auth_error", "User not found.")
		return false
	var record: Dictionary = users[username]
	var password_hash := _hash_password(password, record["salt"])
	if password_hash != record["hash"]:
		emit_signal("auth_error", "Incorrect password.")
		return false
	emit_signal("user_authenticated", username)
	return true

func user_exists(username: String) -> bool:
	return users.has(username.strip_edges())

func _hash_password(password: String, salt: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HASH_ALGO)
	ctx.update((salt + password).to_utf8_buffer())
	var digest := ctx.finish()
	return digest.hex_encode()

func _generate_salt() -> String:
	var bytes := Crypto.new().generate_random_bytes(32)
	return bytes.hex_encode()

func _load_db() -> void:
	if not FileAccess.file_exists(USER_DB_PATH):
		users = {}
		return
	var file := FileAccess.open(USER_DB_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	if text.is_empty():
		users = {}
		return
	var json := JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		users = json.data
	else:
		users = {}

func _save_db() -> void:
	var file := FileAccess.open(USER_DB_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(users, "  "))
	file.close()

func get_progress(username: String) -> Dictionary:
	if not users.has(username):
		return {}
	return users[username].get("progress", {})

func update_progress(username: String, level: String, skill: String, correct: int, attempted: int) -> void:
	if not users.has(username):
		return
	var progress: Dictionary = users[username].get("progress", {})
	if not progress.has(level):
		progress[level] = {}
	if not progress[level].has(skill):
		progress[level][skill] = {"correct": 0, "attempted": 0}
	progress[level][skill]["correct"] += correct
	progress[level][skill]["attempted"] += attempted
	users[username]["progress"] = progress
	_save_db()
