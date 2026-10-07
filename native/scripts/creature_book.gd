extends RefCounted
class_name CreatureBook

const NAMES=[
 ["Briar Beetle","Leaf Ray","Antler Snail","Thorn Flower","Four-Eye Moth","Pine Spider"],
 ["Balloon Toad","Tentacle Cap","Bite Lily","Umbrella Jelly","Winged Axolotl","Moss Turtle"],
 ["Crater Crab","Moon Octopus","Crescent Grub","Meteor Eye","Crystal Star","Moon Snail"],
 ["Cloud Puffer","Six-Wing Owl","Frost Slug","Snow Jelly","Kite Dragon","Frost Worm"],
 ["Lava Lobster","Coal Crawler","Fire Clam","Volcano Turtle","Ember Bat","Bloom Hydra"],
 ["Galaxy Nautilus","Orbit Jelly","Ring Squid","Prism Mantis","Starfly","Coral Crab"]]
# Common 58%, unusual 24%, rare 14%, mythic 4%; every region has six species.
const WEIGHTS=[34,24,14,10,14,4]
const HEALTH=[1.0,.75,1.8,1.25,.65,3.1]
const SPEED=[1.0,1.4,.7,1.0,1.65,.65]
const DAMAGE=[1.0,.75,1.4,1.25,.7,1.8]
const BEHAVIORS=["chase","swoop","armored","spit","skitter","charge"]
const SOUNDS=["shell_bump","wing_bump","stone_bump","wet_bump","buzz_bump","roar_bump"]
const HEIGHTS=[1.45,1.3,1.85,1.6,1.2,2.5]
const RADII=[.65,.48,.9,.7,.46,1.2]
const FLYING=[[1,4],[3,4],[1,3,4],[0,1,3,4],[4],[1,2,4]]

static func pick(biome: int,rng: RandomNumberGenerator) -> Dictionary:
	# One tenth of the original absolute flying-spawn probability.
	var fly_weight=0
	for i in range(6):
		if i in FLYING[biome]: fly_weight+=WEIGHTS[i]
	var choose_flying=rng.randf()<float(fly_weight)/1000.0
	var pool=[];var weight=0
	for i in range(6):
		if (i in FLYING[biome])==choose_flying: pool.append(i);weight+=WEIGHTS[i]
	var roll=rng.randi_range(1,weight)
	for i in pool:
		roll-=WEIGHTS[i]
		if roll<=0: return entry(biome,i)
	return entry(biome,pool[0])

static func entry(biome: int,index: int) -> Dictionary:
	return {"species":index,"name":NAMES[biome][index],"model":"creature_%d_%d" % [biome,index],"health":HEALTH[index],"speed":SPEED[index],"damage":DAMAGE[index],"height":HEIGHTS[index],"radius":RADII[index],"flying":index in FLYING[biome],"altitude":3.5+index*.35,"behavior":BEHAVIORS[index],"sound":SOUNDS[index],"rarity":0 if index<2 else 1 if index<4 else 2 if index==4 else 3}
