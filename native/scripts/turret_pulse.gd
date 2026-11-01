extends RefCounted
class_name TurretPulse

# Two turrets that pulse instead of shooting (user request, November 1: "too many
# similar turrets; make one a healing turret, another push enemies away in pulses;
# turret upgrade cards should work on them too"):
#   heal-turret   Mender Turret: each pulse heals the hero standing in its ring
#   pulse-turret  Thumper Turret: each pulse knocks enemies in its ring away and
#                 hurts them a little
# Turret cards apply as to any turret: Stronger turret (turretDamage) heals more or
# pushes and hurts harder, Faster turret (turretRate) pulses more often, and
# Turret reaches farther (turretRange) widens the ring. Weapon ranks add power
# like any weapon. The ring is drawn on the ground so the area reads at a glance.

const KINDS=["heal-turret","pulse-turret"]
const COLORS={"heal-turret":Color("65f8bd"),"pulse-turret":Color("8fd0ff")}

static func pulses(id: String) -> bool: return id in KINDS

static func radius(g,weapon: Dictionary) -> float:
	return float(weapon.range)*g.stat("turretRange")

static func power(g,weapon: Dictionary) -> float:
	return float(weapon.get("power",1.0))*g.stat("turretDamage")

static func fire(g,weapon: Dictionary):
	if not is_instance_valid(weapon.get("node")): return
	var at: Vector3=weapon.node.global_position;var r=radius(g,weapon)
	var model=weapon.node.get_meta("model") if weapon.node.has_meta("model") else null
	if weapon.id=="heal-turret":
		var near=Vector2(g.player.position.x-at.x,g.player.position.z-at.z).length()<r and absf(g.player.position.y-at.y)<4.0
		if not near or g.hp<=0 or g.hp>=g.stats.maxHp: return
		var amount=1.5+1.5*power(g,weapon)
		g.heal(amount);weapon.healed=float(weapon.get("healed",0.0))+amount
		g.burst(g.player.position+Vector3.UP,COLORS[weapon.id],6)
	else:
		var authority=not g.coop.active or g.coop.hosting
		var damage=g.stat("damage")*float(weapon.damage)*power(g,weapon)*g.TURRET_POWER
		var push=3.0+1.2*power(g,weapon);var hit=0
		for enemy in g.enemies.duplicate():
			if enemy.dead: continue
			var away: Vector3=(enemy.node.position-at)*Vector3(1,0,1)
			if away.length()>r+float(enemy.get("radius",.5)) or absf(enemy.node.position.y-at.y)>4.0: continue
			hit+=1
			g.hurt_enemy(enemy,damage,"sonic",weapon.id)
			if authority and not enemy.dead and not enemy.boss:
				var dir=away.normalized() if away.length()>.05 else Vector3.RIGHT.rotated(Vector3.UP,randf()*TAU)
				enemy.node.move_and_collide(dir*push*clampf(1.0-away.length()/(r*1.6),.35,1.0))
				enemy.freeze=maxf(float(enemy.freeze),.15)
		if hit==0: return
		weapon.pushed=int(weapon.get("pushed",0))+hit
	if model!=null: model.shoot()
	CombatInk.wave(g,at,r,COLORS[weapon.id])
	g.sound.effect("heal" if weapon.id=="heal-turret" else "nova",at,-8.0)

# The ring is resized each frame to the current reach (turret cards may change it).
static func tick(g,weapon: Dictionary):
	if not is_instance_valid(weapon.get("node")): return
	var ring=weapon.node.get_node_or_null("Ring")
	if ring!=null:
		var scale_value=radius(g,weapon)/maxf(.1,float(ring.get_meta("radius",1.0)))
		ring.scale=Vector3(scale_value,1,scale_value)

static func add_ring(g,weapon: Dictionary,flipped: bool):
	var r=radius(g,weapon)
	var ring=GroundRing.make(g,weapon.node.global_position,r,COLORS[weapon.id],.12,not flipped)
	ring.name="Ring";ring.set_meta("radius",r)
	weapon.node.add_child(ring)
