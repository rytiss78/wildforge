extends RefCounted
class_name CareerProfile

var data: Dictionary
var achievements: Array
var file = "user://career.json"
var on_unlock: Callable
var dirty = false

func _init(catalog: Dictionary, smoke: bool = false):
	achievements = catalog.achievements
	if smoke: file = "user://smoke-career.json"
	data = {"version":4,"feedback":[],"total":{},"best":{},"unlocked":{},"scores":[],"settings":{"sfx":0.65,"music":0.45,"voice":0.8,"rumble":true,"genre":"metal","name":"Local hero","lookSensitivity":1.0,"invertLook":false}}
	if FileAccess.file_exists(file):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(file))
		if saved is Dictionary:
			for key in data:
				if saved.has(key) and typeof(saved[key]) == typeof(data[key]): data[key] = saved[key]
	elif not smoke:
		# Copy, never overwrite, the prior desktop alpha's progress.
		var old = OS.get_environment("APPDATA").path_join("wildforge/profile.json")
		if FileAccess.file_exists(old):
			var saved = JSON.parse_string(FileAccess.get_file_as_string(old))
			if saved is Dictionary:
				for key in ["total","best","unlocked","scores"]:
					if saved.has(key) and typeof(saved[key]) == typeof(data[key]): data[key] = saved[key]
	var valid_ids = achievements.map(func(a):return a.id)
	for id in data.unlocked.keys():
		if not valid_ids.has(id): data.unlocked.erase(id)
	data.settings.merge({"sfx":0.65,"music":0.45,"voice":0.8,"rumble":true,"genre":"metal","name":"Local hero","lookSensitivity":1.0,"invertLook":false},false)
	data.version=4
	# Existing local achievements, scores and settings survive the standalone migration.
	dirty=not smoke

func bump(key: String, amount: float = 1.0):
	data.total[key] = float(data.total.get(key, 0.0)) + maxf(0, amount)
	check()
	dirty = true

func best(key: String, value: float):
	if value <= float(data.best.get(key, 0.0)): return
	data.best[key] = value
	check()
	dirty = true

func check():
	for achievement in achievements:
		if data.unlocked.has(achievement.id): continue
		if float(data[achievement.scope].get(achievement.key, 0.0)) >= achievement.target:
			data.unlocked[achievement.id] = Time.get_datetime_string_from_system()
			if on_unlock.is_valid(): on_unlock.call(achievement)

func save():
	if not dirty: return
	var temp = file + ".pending"
	var handle = FileAccess.open(temp, FileAccess.WRITE)
	if handle == null: return
	handle.store_string(JSON.stringify(data))
	handle.close()
	if DirAccess.rename_absolute(temp,file) == OK: dirty = false

func score(run: Dictionary):
	if data.scores.any(func(s): return s.id == run.id): return
	run.score = int(run.kills * 20 + run.seconds * 2 + run.level * 100 + run.bosses * 750 + run.chests * 150 + (10000 if run.win else 0))
	run.date = Time.get_datetime_string_from_system()
	run.player = data.settings.name
	data.scores.append(run)
	data.scores.sort_custom(func(a,b): return a.score > b.score)
	if data.scores.size() > 100: data.scores.resize(100)
	if run.win:
		bump("wins")
		bump("win_" + run.hero)
		if run.healthDamage == 0: bump("noHitWins")
		if run.seconds < 300: bump("fastWins")
	dirty = true
	save()
