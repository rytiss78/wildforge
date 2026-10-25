extends RefCounted
class_name CareerProfile

var data: Dictionary
var achievements: Array
var file = "user://career.json"
var on_unlock: Callable
var dirty = false
const COSMETIC_REWARDS={"WF_WEAPON_MASTERY":"mastery_crown","WF_FORMATION_BREAKER":"formation_gold","WF_BIOME_COLLECTOR":"biome_prism","WF_PARTY_PINGS":"ping_star","WF_READY_PARTY":"party_banner"}

func _init(catalog: Dictionary, smoke: bool = false):
	achievements = catalog.achievements
	if smoke: file = "user://smoke-career.json"
	data = {"version":6,"feedback":[],"total":{},"best":{},"unlocked":{},"cosmetics":[],"weaponMastery":{},"recentWeapons":[],"blockDrop":{},"scores":[],"lastRun":{},"settings":{"sfx":0.65,"music":0.45,"voice":0.8,"rumble":true,"genre":"metal","name":"Local hero","lookSensitivity":1.0,"invertLook":false}}
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
	data.settings.merge({"sfx":0.65,"music":0.45,"voice":0.8,"rumble":true,"genre":"metal","name":"Local hero","lookSensitivity":1.0,"invertLook":false,"cosmetic":"","shake":1.0,"flashes":1.0,"particles":1.0},false)
	if str(data.settings.get("coopToken","")).is_empty():
		var token_rng=RandomNumberGenerator.new();token_rng.randomize()
		data.settings.coopToken="%08x-%08x-%08x-%08x" % [token_rng.randi(),token_rng.randi(),token_rng.randi(),token_rng.randi()]
	if not data.cosmetics is Array: data.cosmetics=[]
	if not data.weaponMastery is Dictionary: data.weaponMastery={}
	for achievement_id in COSMETIC_REWARDS:
		if data.unlocked.has(achievement_id): award_cosmetic(COSMETIC_REWARDS[achievement_id])
	data.total["achievement_cosmetics"]=float(data.cosmetics.size())
	if data.lastRun.is_empty():
		for entry in data.scores:
			if str(entry.get("date","")) > str(data.lastRun.get("date","")): data.lastRun=entry.duplicate(true)
	data.version=6
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

func record_weapon_mastery(weapon_id: String,rank: int):
	if weapon_id.is_empty() or rank<3: return
	if int(data.weaponMastery.get(weapon_id,0))>=rank: return
	data.weaponMastery[weapon_id]=rank
	best("weapon_mastery_count",float(data.weaponMastery.size()))
	dirty=true

func discover_biome(index: int):
	if index<0 or index>=6: return
	var key="biome_"+str(index)
	if float(data.best.get(key,0))>=1: return
	best(key,1)
	var found=data.best.keys().filter(func(value):return str(value).trim_prefix("biome_").is_valid_int()).size()
	best("biomes_discovered",float(found))

func award_cosmetic(id: String):
	if id.is_empty() or data.cosmetics.has(id): return
	data.cosmetics.append(id)
	data.total["achievement_cosmetics"]=float(data.cosmetics.size())
	dirty=true

func check():
	for achievement in achievements:
		if data.unlocked.has(achievement.id): continue
		if float(data[achievement.scope].get(achievement.key, 0.0)) >= achievement.target:
			data.unlocked[achievement.id] = Time.get_datetime_string_from_system()
			var reward=str(COSMETIC_REWARDS.get(achievement.id,""))
			if not reward.is_empty(): award_cosmetic(reward)
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
	if data.lastRun.get("id","") == run.id or data.scores.any(func(s): return s.id == run.id): return
	run.score = int(run.kills * 20 + int(run.get("gold",0)) + run.seconds * 2 + run.level * 100 + run.bosses * 750 + run.chests * 150 + (10000 if run.win else 0))
	run.date = Time.get_datetime_string_from_system()
	run.player = data.settings.name
	data.lastRun=run.duplicate(true)
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
