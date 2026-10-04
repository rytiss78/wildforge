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

static func value(key: String, base: float, buffs: Dictionary, power: float=1.0) -> float:
	var result=base
	for id in buffs:
		if not TYPES.has(id) or TYPES[id].key!=key: continue
		var bonus=TYPES[id].bonus*power
		result=result+bonus if key in ["armor","crit","regen","fallGuard"] else result*(1+bonus)
	return minf(.95,result) if key=="fallGuard" else minf(.95,result) if key=="crit" else result
