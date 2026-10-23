extends RefCounted
class_name EliteMods

# Every elite carries one modifier, shown by a coloured badge above it:
#   shielded  a bubble absorbs damage up to 60% of its health and regrows after
#             4 s without being hit
#   splitting bursts into two smaller enemies when it dies
#   blinking  every 5-7 s it vanishes and reappears behind the hero, with a
#             warning puff where it will land
#   berserk   below half health it turns red, moves 60% faster, hits 50% harder
# The host decides everything; clients get the modifier with the actor's
# identity and the shield level in the world snapshot.
const MODS={
	"shielded":{"label":"◇ SHIELDED","color":Color("8fe9ff")},
	"splitting":{"label":"⧉ SPLITTING","color":Color("b6f06a")},
	"blinking":{"label":"↯ BLINKING","color":Color("c49bff")},
	"berserk":{"label":"‼ BERSERK","color":Color("ff5a3c")},
}
const ORDER=["shielded","splitting","blinking","berserk"]

static func assign(g,enemy: Dictionary,forced: String=""):
	var id=forced if MODS.has(forced) else ORDER[g.rules.rng.randi_range(0,ORDER.size()-1)]
	enemy.modifier=id
	match id:
		"shielded": enemy.shield_max=enemy.maxHp*.6;enemy.shield=enemy.shield_max;enemy.shield_clock=0.0;enemy.elite_shield=1.0
		"blinking": enemy.blink_clock=g.rules.rng.randf_range(4.0,6.0)
	badge(g,enemy)

# The badge and, for shielded elites, the bubble. Used by the host and clients.
static func badge(g,enemy: Dictionary):
	var id=str(enemy.get("modifier",""))
	if not MODS.has(id) or not is_instance_valid(enemy.get("node")): return
	var height=float(enemy.get("height",1.7))
	var label=Label3D.new();label.text=MODS[id].label;label.modulate=MODS[id].color;label.outline_modulate=Color("120c10");label.outline_size=8
	label.font_size=30;label.pixel_size=.011;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true
	label.position=Vector3(0,height*1.25+.6,0);enemy.node.add_child(label);enemy.node.set_meta("elite_badge",label)
	if id=="shielded":
		var bubble=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=1.0;sphere.height=2.0;sphere.radial_segments=16;sphere.rings=8;bubble.mesh=sphere
		var radius=float(enemy.get("radius",.7))
		bubble.scale=Vector3(radius*1.5,height*.72,radius*1.5);bubble.position.y=height*.5
		var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		paint.albedo_color=Color(.56,.91,1,.22);paint.cull_mode=BaseMaterial3D.CULL_BACK
		bubble.material_override=paint;bubble.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;enemy.node.add_child(bubble);enemy.node.set_meta("elite_bubble",bubble)

# Host: the shield takes damage first. Returns what gets through.
static func absorb(g,enemy: Dictionary,damage: float) -> float:
	if str(enemy.get("modifier",""))!="shielded": return damage
	enemy.shield_clock=4.0
	var shield=float(enemy.get("shield",0))
	if shield<=0: return damage
	var taken=minf(shield,damage);enemy.shield=shield-taken
	enemy.elite_shield=enemy.shield/maxf(1,float(enemy.shield_max))
	if enemy.shield<=0:
		var pop=CombatInk.star(g,g.enemy_center(enemy),3.0,MODS.shielded.color,12.0,.35)
		if pop!=null: pop.shards(Color("eafcff"),8,3.0)
	return damage-taken

# Host, once per enemy update.
static func tick(g,enemy: Dictionary,delta: float):
	match str(enemy.get("modifier","")):
		"shielded":
			enemy.shield_clock=float(enemy.get("shield_clock",0))-delta
			if enemy.shield_clock<=0 and float(enemy.shield)<float(enemy.shield_max):
				enemy.shield=minf(float(enemy.shield_max),float(enemy.shield)+float(enemy.shield_max)*.25*delta)
				enemy.elite_shield=enemy.shield/maxf(1,float(enemy.shield_max))
			replicate(enemy)
		"blinking":
			enemy.blink_clock=float(enemy.get("blink_clock",5))-delta
			var target: Vector3=g.coop.target(enemy.node.position).position
			if enemy.blink_clock<=.7 and not enemy.has("blink_to"):
				var behind=-(g.camera.global_basis.z*Vector3(1,0,1)).normalized()
				var spot=target-behind*3.5;spot.y=g.world.height_at(spot.x,spot.z)
				enemy.blink_to=spot;puff(g,spot,true)
			if enemy.blink_clock<=0 and enemy.has("blink_to"):
				puff(g,enemy.node.position,false);enemy.node.position=enemy.blink_to;enemy.erase("blink_to")
				enemy.blink_clock=g.rules.rng.randf_range(5.0,7.0);enemy.contact=maxf(float(enemy.get("contact",0)),.6)
		"berserk":
			if not enemy.get("enraged",false) and enemy.hp<enemy.maxHp*.5:
				enemy.enraged=true;enemy.speed*=1.6;enemy.damage=float(enemy.get("damage",1))*1.5
				var flare=CombatInk.star(g,g.enemy_center(enemy),3.2,MODS.berserk.color,7.0,.4)
				if flare!=null: flare.shards(Color("ffb38a"),8,3.0)
				if enemy.node.has_meta("elite_badge"): enemy.node.get_meta("elite_badge").font_size=38

# Host: a splitting elite leaves two smaller enemies behind.
static func died(g,enemy: Dictionary):
	if str(enemy.get("modifier",""))!="splitting": return
	var at: Vector3=enemy.node.position
	var burst=CombatInk.star(g,g.enemy_center(enemy),3.0,MODS.splitting.color,9.0,.4)
	if burst!=null: burst.shards(Color("d9ffb0"),10,3.5)
	for i in range(2):
		var before=g.enemies.size()
		g.spawn_enemy(1.5,false,at)
		if g.enemies.size()==before: continue
		var child=g.enemies[-1];child.maxHp=enemy.maxHp/2.5*.45;child.hp=child.maxHp;child.xp_reward=float(child.get("xp_reward",2))*.5
		child.node.position=at+Vector3.RIGHT.rotated(Vector3.UP,i*PI+at.x)*1.2;child.node.position.y=g.world.height_at(child.node.position.x,child.node.position.z)

# Clients: the bubble follows the shield level from the snapshot.
static func replicate(enemy: Dictionary):
	if is_instance_valid(enemy.get("node")) and enemy.node.has_meta("elite_bubble"):
		enemy.node.get_meta("elite_bubble").visible=float(enemy.get("elite_shield",0))>.02

static func puff(g,point: Vector3,warning: bool):
	var mark=CombatInk.star(g,point+Vector3.UP*.9,2.6 if warning else 2.0,MODS.blinking.color,6.0,.7 if warning else .3,1.0,"status")
	if mark!=null: mark.shards(Color("e3d2ff"),6,2.0)
	if warning: CombatInk.wave(g,point,1.8,MODS.blinking.color)
