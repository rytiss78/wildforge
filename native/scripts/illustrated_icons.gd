extends RefCounted
class_name IllustratedIcons

static var atlas: Texture2D
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
	var matching={"discBounces":"disc","boomerangPierce":"boomerang","harpoonPull":"harpoon","gravitySize":"gravity","hornStun":"horn","bubbleTime":"bubble","meteorCount":"meteor","bombSize":"bomb"}
	if matching.has(key): return texture(matching[key],true)
	if key.ends_with("Power") and key.trim_suffix("Power") in ["boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb"]: return texture(key.trim_suffix("Power"),true)
	var rendered="res://assets/illustrated/weapon-icons/"+key+".png"
	if weapon and ResourceLoader.exists(rendered): return load(rendered)
	if atlas==null: atlas=load("res://assets/illustrated/icons.png")
	var index=int(WEAPONS.get(key,0) if weapon else POWERS.get(key,10 if key.begins_with("flower") else 11 if key.begins_with("turret") else 23))
	var result=AtlasTexture.new()
	result.atlas=atlas
	result.region=Rect2((index%6)*128+5,(index/6)*128+5,118,118)
	if index==4: result.region=Rect2(4*128+4,5,110,118)
	result.filter_clip=true
	return result
