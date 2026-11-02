extends RefCounted
class_name PotionBook

const TYPES={
	"poison":{"name":"Poison Guard","color":"8bb773","mark":"P","key":"","bonus":0.0},
	"fire":{"name":"Fire Guard","color":"e59b73","mark":"F","key":"","bonus":0.0},
	"speed":{"name":"Speed Juice","color":"99cbce","mark":">>","key":"speed","bonus":.4},
	"xp":{"name":"XP Juice","color":"ccacd7","mark":"XP","key":"xpGain","bonus":.5},
	"stone":{"name":"Stone Skin","color":"a0a8b8","mark":"SH","key":"armor","bonus":15.0},
	"bite":{"name":"Big Bite","color":"e89793","mark":"POW","key":"damage","bonus":.4},
	"hands":{"name":"Fast Hands","color":"e6c685","mark":"FAST","key":"rate","bonus":.35},
	"lucky":{"name":"Lucky Shot","color":"a8ce84","mark":"!","key":"crit","bonus":.2},
	"reach":{"name":"Long Reach","color":"a6b7dc","mark":"FAR","key":"range","bonus":.4},
	"coins":{"name":"Coin Rush","color":"e6bc61","mark":"$","key":"goldGain","bonus":.5},
	"magnet":{"name":"Big Magnet","color":"89c3db","mark":"M","key":"pickup","bonus":.65},
	"jump":{"name":"High Jump","color":"c5a4e0","mark":"UP","key":"jumpHeight","bonus":.5},
	"feather":{"name":"Soft Landing","color":"e6d8bd","mark":"SOFT","key":"fallGuard","bonus":.75},
	"blood":{"name":"Fresh Blood","color":"d791a7","mark":"HP","key":"regen","bonus":6.0}}

# What a potion does, in plain numbers (user, November 2: "potion benefits are
# not clear"): shown over the bottle, on drinking and under its buff icon.
const BENEFITS={"poison":"poison-proof","fire":"fire-proof","speed":"+%d%% speed","xp":"+%d%% XP","stone":"+%d armour",
	"bite":"+%d%% damage","hands":"+%d%% fire rate","lucky":"+%d%% crit","reach":"+%d%% range","coins":"+%d%% coins",
	"magnet":"+%d%% pickup reach","jump":"+%d%% jump","feather":"-%d%% fall damage","blood":"+%d ♥/s"}

static func benefit(id: String,power: float=1.0) -> String:
	if not TYPES.has(id): return ""
	var text: String=BENEFITS.get(id,"")
	if not text.contains("%d"): return text
	var bonus=float(TYPES[id].bonus)*power
	return text % roundi(bonus if TYPES[id].key in ["armor","regen"] else bonus*100.0)

# A floating label over a bottle or plant, seen only from close by.
static func tag(parent: Node3D,text: String,color: Color,height: float=.75):
	var label=Label3D.new();label.name="Benefit";label.text=text;label.font_size=40;label.pixel_size=.006
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=color.lightened(.45);label.outline_modulate=Color("1b1a24");label.outline_size=10
	label.position=Vector3(0,height,0);label.visibility_range_end=16.0;label.visibility_range_end_margin=3.0
	label.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF;parent.add_child(label)

static func value(key: String, base: float, buffs: Dictionary, power: float=1.0) -> float:
	var result=base
	for id in buffs:
		if not TYPES.has(id) or TYPES[id].key!=key: continue
		var bonus=TYPES[id].bonus*power
		result=result+bonus if key in ["armor","crit","regen","fallGuard"] else result*(1+bonus)
	return minf(.95,result) if key=="fallGuard" else minf(.95,result) if key=="crit" else result
