extends RefCounted
class_name ClutchPlay

# Clutch (user, November 2: a counter-terrorist style shooter hero; the name and
# look are our own). First person with a wide shooter field of view, no auto-aim:
# hold the left mouse button to fire the active weapon where the crosshair points
# (hitscan; turrets still aim themselves). Number keys 1-3 pick the active weapon.
# Hits on a creature's glass health orb are weak-spot shots (double damage;
# a chime only in Lock-On); for Clutch only. V (Lock-On) is a
# full aimbot for a few seconds: the view swings onto the orb of the enemy
# nearest the hero (in view or not, through walls), fires by itself at five times
# the damage and moves on to the next enemy when one dies. Shift (instead of the dash) is a slow, quiet walk: enemies lose sight
# of him, stop where they are and do not attack (CoopSession.target "lost").
# No slam. His shots also hurt other heroes.

const EYE=1.55
const FOV=74.0          # vertical; about a 106° horizontal view at 16:9
const HEADSHOT=2.0      # damage on the glass orb (the weak spot)
const ORB_GRACE=1.25    # the orb counts a little bigger than drawn
const LOOK_SCALE=.6     # first-person look speed, of the third-person setting (user: .7 still too fast)
const LOCK_DAMAGE=5.0
const STEALTH=4.0
const LOCK_TIME=4.0
const LOCK_REACH=45.0
const LOCK_TURN=28.0     # how fast the aimbot swings the view
const LOCK_FIRE=.08     # radians off the head before it pulls the trigger
const STEALTH_COOLDOWN=6.0
const SNEAK_SPEED=.45
const FRIENDLY=.5       # share of the damage his shots deal to other heroes
# The AK-47 is fully automatic (user, November 3): 600 rounds a minute, 30 to a
# magazine, then a reload. Each round carries a share of the old one-a-second
# shot sized so that its damage over a whole magazine-and-reload cycle stays
# what it was (rate upgrades still raise it).
const AK_RATE=10.0
const MAG=30
const RELOAD=2.4
const AK_SHARE=(MAG/AK_RATE+RELOAD)/(MAG/AK_RATE)/AK_RATE

static var active_slot=0
static var lock_until=-1.0
static var stealth_left=STEALTH
static var stealth_cooldown=0.0
static var sneaking=false
static var lock_target={}
static var hit_flash=0.0
static var head_flash=0.0
static var headshot_kills=0
static var ammo=MAG
static var reload_left=0.0

static func is_clutch(g) -> bool: return str(g.hero.get("id",""))=="clutch"
static func first_person(g) -> bool: return is_clutch(g) and g.mode in ["playing","level_reveal"] and g.run_active and not g.update.downed

static func reset():
	if is_instance_valid(view): view.queue_free()
	view=null;view_id="";lock_target={}
	active_slot=0;lock_until=-1.0;ammo=MAG;reload_left=0.0;stealth_left=STEALTH;stealth_cooldown=0.0;sneaking=false;hit_flash=0.0;head_flash=0.0;headshot_kills=0

# The hand weapons he can switch between (turrets are not held).
# Weapons that work on their own (aura, orbiting lids, trails, mines) are not held.
static func held(g) -> Array: return g.equipped.filter(func(w):return not w.get("turret",false) and not WeaponActs.passive(w))

static func is_ak(weapon: Dictionary) -> bool: return str(weapon.get("id",""))=="gun"
static func reloading() -> bool: return reload_left>0

# Seconds between his shots with this weapon (game.gd's weapon clock).
static func interval(g,weapon: Dictionary) -> float:
	return 1.0/AK_RATE if is_ak(weapon) else 1.0/(float(weapon.rate)*g.stat("rate"))

static func active_weapon(g) -> Dictionary:
	var hands=held(g)
	if hands.is_empty(): return {}
	return hands[clampi(active_slot,0,hands.size()-1)]

static func place_camera(g,delta: float):
	var up=g.underside.camera_up()
	var eye=g.player.position+up*EYE
	var a=-g.pitch
	var forward=Vector3(-sin(g.yaw)*cos(a),sin(a)*up.y,-cos(g.yaw)*cos(a))
	g.camera.fov=FOV
	g.camera.global_position=eye
	if absf(forward.normalized().dot(up))<.99: g.camera.look_at(eye+forward,up)
	if g.hit_shake>0: g.hit_shake=maxf(0,g.hit_shake-delta)

# Late each physics frame: face the view, hide his own body, Shift and keys.
static func late(g,delta: float):
	hit_flash=maxf(0,hit_flash-delta);head_flash=maxf(0,head_flash-delta)
	if reload_left>0:
		reload_left-=delta
		if reload_left<=0: reload_left=0.0;ammo=MAG
	if not is_clutch(g): return
	if not g.update.downed: g.avatar.rotation.y=g.yaw
	# In first person his own body, hat and floating hand weapons would sit in
	# front of the lens.
	var fps=first_person(g) and not g.camera_locked
	if fps: g.avatar.visible=false
	for weapon in held(g):
		if is_instance_valid(weapon.get("node")): weapon.node.visible=not fps
	view_model(g,fps,delta)
	# Downed: watching a friend; the number keys are cheers, not weapons.
	if g.update.downed: sneaking=false;return
	if fps: aimbot(g,delta)
	for i in range(RunRules.WEAPON_CAP):
		if Input.is_physical_key_pressed(KEY_1+i) and i<held(g).size() and active_slot!=i:
			active_slot=i;g.sound.effect("switch");show_active(g)
	# Shift: sneak. Quiet and slow; enemies lose him while the stealth lasts.
	stealth_cooldown=maxf(0,stealth_cooldown-delta)
	var wants=Input.is_action_pressed("dash") and stealth_cooldown<=0 and stealth_left>0
	sneaking=wants
	if sneaking:
		stealth_left-=delta
		if stealth_left<=0: sneaking=false;stealth_cooldown=STEALTH_COOLDOWN
	elif stealth_left<STEALTH:
		stealth_left=minf(STEALTH,stealth_left+delta*.5)

# The active weapon held low on the right of the view, kicking back on shots.
static var view: Node3D
static var view_id=""
static var kick=0.0
# Where the weapon rests in view; the long rifle sits closer and more central.
static var rest=Vector3(.2,-.2,-.42)
static func view_model(g,fps: bool,delta: float):
	var weapon=active_weapon(g);var want=str(weapon.get("id","")) if fps else ""
	if want!=view_id:
		if is_instance_valid(view): view.queue_free()
		view=null;view_id=want
		if want!="":
			view=Node3D.new();view.name="ClutchView";g.camera.add_child(view)
			# His gun is an AK-47 (user, November 3).
			var model=WeaponModel.new();model.setup("ak47" if want=="gun" else want);view.add_child(model)
			# Every weapon is shown about the same size in the hands.
			var size=ClutchHands.bounds(view,model).size
			model.scale=Vector3.ONE*clampf((.58 if want=="gun" else .34)/maxf(.01,maxf(size.z,maxf(size.x,size.y))),.15,1.2)
			for mesh in model.find_children("*","GeometryInstance3D",true,false): mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rest=Vector3(.12,-.15,-.3) if want=="gun" else Vector3(.2,-.2,-.42)
			view.position=rest;view.rotation=Vector3.ZERO
			ClutchHands.build(view,model)
	if is_instance_valid(view):
		kick=maxf(0,kick-delta*6.0)
		var bob=sin(g.elapsed*9.0)*.012*clampf(Vector2(g.player.velocity.x,g.player.velocity.z).length()/6.0,0,1)
		# Reloading: the rifle dips and rolls toward him, then comes back up.
		var dip=sin(PI*clampf(1.0-reload_left/RELOAD,0,1)) if reload_left>0 and view_id=="gun" else 0.0
		view.position=rest+Vector3(0,bob-dip*.09,kick*.06);view.rotation=Vector3(kick*.12-dip*.55,.03 if view_id=="gun" else .06,dip*.5)

static func speed_scale(g) -> float: return SNEAK_SPEED if is_clutch(g) and sneaking else 1.0

# Enemies lose track of a sneaking Clutch (CoopSession.target).
static func hidden(g) -> bool: return is_clutch(g) and sneaking

# An enemy that has lost sight of every hero: it stops, looks around and does
# not attack (game.gd's enemy loop, target "lost").
static func lost(g,enemy: Dictionary,delta: float):
	var body: CharacterBody3D=enemy.node
	if not enemy.get("flying",false) and not body.is_on_floor():
		body.velocity=Vector3(0,body.velocity.y-20.0*delta,0);body.move_and_slide()
	else: body.velocity=Vector3.ZERO
	body.rotation.y+=sin(g.elapsed*1.3+float(enemy.get("net_id",0)))*delta*1.2
	if body.has_meta("rig"): body.get_meta("rig").animate(delta,Vector3.ZERO,true)

# Third person (hero screen, friends' view): only the active weapon is held.
static func show_active(g):
	var hands=held(g);var weapon=active_weapon(g)
	if weapon.is_empty(): return
	var ordered=[weapon]
	for other in g.equipped:
		if other!=weapon: ordered.append(other)
	g.avatar.sync_equipment(ordered)

# V: the aimbot. Picks the visible head nearest the crosshair, swings the view
# onto it and keeps it there; when that enemy dies it takes the next one.
static func locked(g) -> bool: return is_clutch(g) and g.elapsed<lock_until

static func aimbot(g,delta: float):
	if not locked(g): lock_target={};return
	var eye=g.camera.global_position
	var nearest=pick(g)
	# Keep the current target until it dies or leaves reach, unless another
	# enemy comes clearly nearer to the hero.
	if lock_target.is_empty() or lock_target.dead or g.player.position.distance_to(lock_target.node.position)>LOCK_REACH: lock_target=nearest
	elif not nearest.is_empty() and nearest!=lock_target and g.player.position.distance_to(nearest.node.position)<g.player.position.distance_to(lock_target.node.position)*.7: lock_target=nearest
	if lock_target.is_empty(): return
	var to=(head_point(g,lock_target)-eye).normalized()
	var want_yaw=atan2(-to.x,-to.z);var want_pitch=-asin(clampf(to.y,-1,1))
	var t=1.0-exp(-delta*LOCK_TURN)
	g.yaw=lerp_angle(g.yaw,want_yaw,t);g.pitch=clampf(lerpf(g.pitch,want_pitch,t),-1.45,1.45)

# The living enemy nearest the hero, wherever it is.
static func pick(g) -> Dictionary:
	var best={};var best_d=LOCK_REACH
	for enemy in g.enemies:
		if enemy.dead: continue
		var d=g.player.position.distance_to(enemy.node.position)
		if d<best_d: best_d=d;best=enemy
	return best

# Is the crosshair on the locked head (close enough to pull the trigger)?
static func on_target(g) -> bool:
	if lock_target.is_empty() or lock_target.dead: return false
	var eye=g.camera.global_position
	var to=(head_point(g,lock_target)-eye).normalized()
	return to.angle_to(-g.camera.global_basis.z)<LOCK_FIRE

# Fire the active weapon if the trigger is held (or the aimbot is on a head).
static func trigger(g,weapon: Dictionary) -> bool:
	if weapon!=active_weapon(g) or not first_person(g): return false
	if is_ak(weapon) and reloading(): return false
	if locked(g):
		if not on_target(g): return false
		shoot(g,weapon);return true
	if not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(maxi(0,g.controller_id),JOY_BUTTON_RIGHT_SHOULDER) or g.get_meta("test_trigger",false)): return false
	shoot(g,weapon)
	return true

# One hitscan shot (or a spread of pellets) from the eye along the crosshair.
static func shoot(g,weapon: Dictionary):
	var kind=ContentExpansion.kind(weapon.id);var mods=weapon.get("modifiers",{})
	var origin=g.camera.global_position;var aim=-g.camera.global_basis.z
	var reach=maxf(30.0,float(weapon.range)*g.stat("range")*1.6)
	if locked(g): reach=maxf(reach,LOCK_REACH+5.0)
	var locked=locked(g)
	if locked and not lock_target.is_empty() and not lock_target.dead: aim=(head_point(g,lock_target)-origin).normalized()
	var pellets=(3 if kind=="shotgun" else 1)+int(mods.get("extraShots",0))+mini(4,int(g.stats.multishot))
	var base=g.stat("damage")*weapon.damage*float(weapon.get("power",1.0))*float(g.stats.get(kind+"Power",1.0))
	if locked: base*=LOCK_DAMAGE
	if is_ak(weapon): base*=float(weapon.rate)*g.stat("rate")*AK_SHARE
	g.sound.effect(SkillBook.sound(kind),origin)
	var muzzle=g.player.position+Vector3.UP*(EYE-.25)+(-g.camera.global_basis.z)*.6+g.camera.global_basis.x*.25
	# The flash is small in first person: it sits a hand's length from the lens.
	ShotFx.muzzle(g,muzzle,aim,kind,.2)
	g.hit_shake=maxf(g.hit_shake,.03);kick=1.0
	for i in range(pellets):
		var dir=aim.rotated(Vector3.UP,(i-(pellets-1)*.5)*float(mods.get("spread",.05)))
		var hit=cast(g,origin,dir,reach,locked)
		var end: Vector3=hit.get("point",origin+dir*reach)
		# The AK leaves no tracer line (user: they looked like lasers), only a
		# puff where the round lands; other weapons keep their beams.
		if is_ak(weapon):
			if not hit.has("enemy"): CombatInk.star(g,end,.3,Color("d8c9a6"),4.0,.1)
		else: g.beam(muzzle,end,PowerIcon.color_for(kind))
		# Explosive barrels are solid (layer 1), so the ray stops on them: light
		# the one it struck (any barrel along the line up to the hit point).
		if not g.barrels.is_empty(): ExplosiveBarrels.shot(g,origin,end+dir*.3)
		if hit.has("enemy"):
			var head=bool(hit.head) or locked
			var damage=base*(HEADSHOT if head else 1.0)
			g.hurt_enemy(hit.enemy,damage,"crit" if head else "hit",weapon.id)
			hit_flash=.18
			if head:
				# The chime only rings in Lock-On (aimbot) mode (user, November 2).
				head_flash=.35
				if locked: g.sound.effect("headshot",g.player.position+Vector3.UP*EYE)
				if hit.enemy.dead: headshot_kills+=1
		elif hit.has("hero"):
			friendly_hit(g,int(hit.hero),base*FRIENDLY)
	if is_ak(weapon):
		ammo-=1
		if ammo<=0: ammo=0;reload_left=RELOAD;g.sound.effect("ak-reload",g.player.position+Vector3.UP*EYE)

# The glass orbs of an enemy (most have one; the Grand Noggin's eyes are two),
# as world centres and radii. Found once per enemy and kept on it.
static func orbs(enemy: Dictionary) -> Array:
	if not enemy.has("orb_nodes"):
		var found=[]
		if is_instance_valid(enemy.get("node")):
			for node in enemy.node.find_children("GlassCore*","MeshInstance3D",true,false): found.append(node)
		enemy.orb_nodes=found
	var out=[]
	for node in enemy.orb_nodes:
		if not is_instance_valid(node) or not node.is_visible_in_tree(): continue
		var box: AABB=node.get_aabb()
		var radius=maxf(box.size.x,maxf(box.size.y,box.size.z))*.5*node.global_basis.get_scale().x
		out.append({"center":node.global_transform*box.get_center(),"radius":maxf(.08,radius)})
	return out

# Where the aimbot aims: the nearest orb, or high on the body when it has none.
static func head_point(g,enemy: Dictionary) -> Vector3:
	var list=orbs(enemy)
	if not list.is_empty(): return list[0].center
	return enemy.node.position+Vector3.UP*float(enemy.get("height",1.7))*.6

# Ray against sphere: the distance to the first hit, or INF.
static func sphere_hit(origin: Vector3,dir: Vector3,center: Vector3,radius: float) -> float:
	var to=center-origin;var t=to.dot(dir)
	var miss=to.length_squared()-t*t
	if miss>radius*radius: return INF
	var entry=t-sqrt(radius*radius-miss)
	return entry if entry>=0 else (t if t>=0 else INF)

# The first enemy, hero or wall along the ray.
static func cast(g,origin: Vector3,dir: Vector3,reach: float,through_walls: bool=false) -> Dictionary:
	var result={};var nearest=reach
	if not through_walls:
		var ray=PhysicsRayQueryParameters3D.create(origin,origin+dir*reach,1,[g.player.get_rid()])
		var wall=g.get_world_3d().direct_space_state.intersect_ray(ray)
		if not wall.is_empty(): nearest=origin.distance_to(wall.position);result={"point":wall.position}
	for enemy in g.enemies:
		if enemy.dead: continue
		var base: Vector3=enemy.node.position;var height=float(enemy.get("height",1.7));var radius=float(enemy.get("radius",.5))*1.15
		var center=base+Vector3.UP*height*.5
		var t=(center-origin).dot(dir)
		# The orb: hit when it is on the near side of the body (not through it).
		var orb_t=INF
		for orb in orbs(enemy):
			var hit_t=sphere_hit(origin,dir,orb.center,float(orb.radius)*ORB_GRACE)
			if hit_t<orb_t: orb_t=hit_t
		if orb_t<nearest and orb_t<=t+radius*.5:
			nearest=orb_t;result={"point":origin+dir*orb_t,"enemy":enemy,"head":true};continue
		if t<0 or t>nearest: continue
		var q=origin+dir*t
		if Vector2(q.x-center.x,q.z-center.z).length()>radius or q.y<base.y-.1 or q.y>base.y+height+.1: continue
		nearest=t;result={"point":q,"enemy":enemy,"head":false}
	for id in g.coop.avatars:
		var body=g.coop.avatars[id]
		if not is_instance_valid(body) or float(g.coop.members.get(id,{}).get("hp",0))<=0: continue
		var center=body.position+Vector3.UP*.85;var t=(center-origin).dot(dir)
		if t<0 or t>nearest: continue
		var q=origin+dir*t
		if q.distance_to(center)<.6: nearest=t;result={"point":q,"hero":id}
	return result

static func friendly_hit(g,id: int,amount: float):
	if g.coop.hosting: g.coop.damage_player(id,amount,g.player.position,"hit")
	else: g.coop.send_to(g.coop.owner_id,{"type":"clutch_hit","id":id,"amount":amount})

static func receive(g,sender: int,message) -> bool:
	if not message is Dictionary or message.get("type","")!="clutch_hit": return false
	if g.coop.hosting and g.coop.members.has(sender):
		g.coop.damage_player(int(message.get("id",-1)),clampf(float(message.get("amount",0)),0,500),CoopSession.vector(g.coop.members[sender].get("position",[0,0,0])) if g.coop.members[sender].has("position") else Vector3.ZERO,"hit")
	return true
