extends RefCounted
class_name IllustratedIcons

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
	"speed":15,"jumpPower":15,"jumpHeight":15,"airJumps":15,"bounceJump":15,"slamRecovery":15,"airControl":15,"airDamage":15,"fallThreshold":15
}
const WEAPONS = {"gun":0,"shotgun":1,"flame":2,"poison":3,"ice":4,"rail":5,"lightning":6,"saw":7,"rocket":8,"ghost":9,"flowers":10,"turret":11,"fire-turret":11,"poison-turret":11,"ice-turret":11,"lightning-turret":11,"rocket-turret":11}
const POWERS = {
	"burn":12,"splash":12,"explosion":12,"dashBlast":12,
	"poison":13,"pools":13,"freeze":14,"slow":14,
	"lifesteal":15,"maxHp":15,"regen":15,"salvage":15,"repair":15,"revive":15,
	"armor":16,"shield":16,"dodge":16,
	"goldGain":17,"discount":17,"walkGold":17,"hurtGold":17,"interest":17,"coinRadius":17,"potGold":17,
	"keyPower":18,"speed":19,"dashCooldown":19,"jumpPower":19,"jumpHeight":19,"airJumps":19,"fallGuard":16,"slamPower":7,"slamRadius":12,"bounceJump":19,"slamRecovery":19,"burrow":19,
	"pickup":20,"magnetPulse":20,"thorns":21,"blind":22,
	"ghost":9,"nova":23,"chain":6,"storm":6,"rate":6,"damage":7,"crit":7,"critPower":7,
	"multishot":1,"pierce":5,"projectileSpeed":5,"range":5,"size":8,"ricochet":6,"boomerang":7,"luck":23
}

static func texture(key: String, weapon: bool=false) -> Texture2D:
	var path="res://assets/illustrated/weapon-icons/"+key+".png" if weapon else "res://assets/illustrated/content/"+key+".svg"
	if not ResourceLoader.exists(path): path="res://assets/illustrated/effects/"+key+".svg"
	if not ResourceLoader.exists(path):
		push_error("Missing required icon: "+key)
		return null
	if not textures.has(path): textures[path]=load(path)
	return textures[path]
