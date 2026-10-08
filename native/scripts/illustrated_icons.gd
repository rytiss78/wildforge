extends RefCounted
class_name IllustratedIcons

static var atlas: Texture2D
static var skill_atlas: Texture2D
static var textures={}
const SKILLS={
	"damage":0,"bossDamage":0,"berserk":0,"orbitDamage":0,"auraDamage":0,"slamPower":0,
	"rate":1,"dashCooldown":1,"turretRate":1,"turretLife":1,"potionDuration":1,"bubbleTime":1,
	"range":2,"turretRange":2,"pickup":2,"coinRadius":2,"gravitySize":2,"slamRadius":2,
	"multishot":3,"pierce":3,"ricochet":3,"boomerang":3,"discBounces":3,"boomerangPierce":3,"meteorCount":3,"projectileSpeed":3,"size":3,
	"crit":4,"critPower":4,"execute":4,"luck":4,"chestBonus":4,"potionChance":4,
	"chain":5,"storm":5,"nova":5,"stun":5,"hornStun":5,
	"turretDamage":6,"turretCount":6,"drones":6,"harpoonPull":6,
	"ghost":7,"burrow":7,
	"flowerPower":8,"flowerRoots":8,"flowerPollen":8,"flowerHeal":8,"flowerSeeds":8,
	"maxHp":9,"regen":9,"lifesteal":9,"salvage":9,"repair":9,"revive":9,"landingHeal":9,"slamHeal":9,"coinHeal":9,"chestHeal":9,
	"armor":10,"shield":10,"dodge":10,"fallGuard":10,"jumpShield":10,
	"goldGain":11,"discount":11,"walkGold":11,"hurtGold":11,"interest":11,"potGold":11,
	"poison":12,"pools":12,"slamPoison":12,"potionPower":12,
	"burn":13,"splash":13,"explosion":13,"dashBlast":13,"jumpBlast":13,"slamFire":13,"bombSize":13,
	"freeze":14,"slow":14,
	"speed":15,"jumpPower":15,"jumpHeight":15,"airJumps":15,"bounceJump":15,"airControl":15,"airDamage":15,"fallThreshold":15
}
const WEAPONS = {"gun":0,"shotgun":1,"flame":2,"poison":3,"ice":4,"rail":5,"lightning":6,"saw":7,"rocket":8,"ghost":9,"flowers":10,"turret":11,"fire-turret":11,"poison-turret":11,"ice-turret":11,"lightning-turret":11,"rocket-turret":11}
const POWERS = {
	"burn":12,"splash":12,"explosion":12,"dashBlast":12,
	"poison":13,"pools":13,"freeze":14,"slow":14,
	"lifesteal":15,"maxHp":15,"regen":15,"salvage":15,"repair":15,"revive":15,
	"armor":16,"shield":16,"dodge":16,
	"goldGain":17,"discount":17,"walkGold":17,"hurtGold":17,"interest":17,"coinRadius":17,"potGold":17,
	"keyPower":18,"speed":19,"dashCooldown":19,"jumpPower":19,"jumpHeight":19,"airJumps":19,"fallGuard":16,"slamPower":7,"slamRadius":12,"bounceJump":19,"burrow":19,
	"pickup":20,"magnetPulse":20,"thorns":21,"blind":22,
	"ghost":9,"nova":23,"chain":6,"storm":6,"rate":6,"damage":7,"crit":7,"critPower":7,
	"multishot":1,"pierce":5,"projectileSpeed":5,"range":5,"size":8,"ricochet":6,"boomerang":7,"luck":23
}

static func texture(key: String, weapon: bool=false) -> Texture2D:
	# Weapon images are rendered from the very same WeaponModel used by ActorRig.
	var matching="res://assets/illustrated/weapon-icons/"+key+".png"
	if weapon and ResourceLoader.exists(matching):
		if not textures.has(matching): textures[matching]=load(matching)
		return textures[matching]
	var vector_art="res://assets/illustrated/content/"+key+".svg"
	if ResourceLoader.exists(vector_art):
		if not textures.has(vector_art): textures[vector_art]=load(vector_art)
		return textures[vector_art]
	var content="res://assets/illustrated/content/"+key+".png"
	if ResourceLoader.exists(content):
		if not textures.has(content): textures[content]=load(content)
		return textures[content]
	var cache_key=("weapon:" if weapon else "power:")+key
	if textures.has(cache_key): return textures[cache_key]
	if not weapon and ResourceLoader.exists("res://assets/illustrated/skills.png"):
		if skill_atlas==null: skill_atlas=load("res://assets/illustrated/skills.png")
		var tile=int(SKILLS.get(key,0 if key.ends_with("Power") else -1))
		if tile>=0:
			var result=AtlasTexture.new();result.atlas=skill_atlas
			var side=skill_atlas.get_width()/4.0
			var inset=side*.04
			result.region=Rect2((tile%4)*side+inset,int(tile/4)*side+inset,side-2*inset,side-2*inset);result.filter_clip=true
			textures[cache_key]=result;return result
	var rendered="res://assets/illustrated/weapon-icons/"+key+".png"
	if weapon and ResourceLoader.exists(rendered):
		textures[cache_key]=load(rendered);return textures[cache_key]
	if atlas==null: atlas=load("res://assets/illustrated/icons.png")
	# A missing skill illustration must never fall back to a gun or turret.
	var index=int(WEAPONS.get(key,0) if weapon else 20 if key=="magnetPulse" else 21 if key=="thorns" else 22 if key=="blind" else 18 if key=="keyPower" else 23)
	var result=AtlasTexture.new()
	result.atlas=atlas
	result.region=Rect2((index%6)*128+5,(index/6)*128+5,118,118)
	if index==4: result.region=Rect2(4*128+4,5,110,118)
	result.filter_clip=true
	textures[cache_key]=result
	return result
