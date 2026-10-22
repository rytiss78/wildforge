extends RefCounted
class_name EffectDetail

# Player effect settings plus automatic thinning for big crowds, read by every
# effect builder. Settings (0..1, saved in the profile):
#   shake      camera shake strength
#   flashes    scene light flashes and white-hot cores of impact stars
#   particles  shards, shot puffs and status particles
# Crowd scaling: status particles thin out once many enemies carry a status, so
# a burning crowd of 100 costs about as much as a burning group of 24.
static var shake=1.0
static var flashes=1.0
static var particles=1.0
static var status_ratio=1.0
static var clock=0.0

static func load_settings(settings: Dictionary):
	shake=clampf(float(settings.get("shake",1.0)),0,1)
	flashes=clampf(float(settings.get("flashes",1.0)),0,1)
	particles=clampf(float(settings.get("particles",1.0)),.25,1)

static func tick(g,delta: float):
	clock-=delta
	if clock>0: return
	clock=.5
	var burning=0
	for enemy in g.enemies:
		if not enemy.dead and (enemy.fire>0 or enemy.poison>0 or enemy.freeze>.5 or enemy.blind>0): burning+=1
	status_ratio=clampf(24.0/maxf(1,burning),.2,1.0)*particles

static func count(base: int) -> int:
	return maxi(1,roundi(base*particles))
