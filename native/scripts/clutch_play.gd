extends RefCounted
class_name ClutchPlay

# Clutch (user, November 2: a counter-terrorist style shooter hero; the name and
# look are our own). First person with a wide shooter field of view, no auto-aim:
# hold the left mouse button to fire the active weapon where the crosshair points
# (hitscan; turrets still aim themselves). Number keys 1-3 pick the active weapon.
# Hits high on a body are headshots (double damage, a chime). V (Lock-On) snaps
# shots to the nearest enemy's head for a few seconds at five times the damage.
# Shift (instead of the dash) is a slow, quiet walk: enemies lose track of him
# for up to STEALTH seconds and go to where they last saw him. No slam. His shots
# also hurt other heroes.

const EYE=1.55
const FOV=74.0          # vertical; about a 106° horizontal view at 16:9
const HEAD=.78          # hits above this share of the body height are headshots
const HEADSHOT=2.0
const LOCK_DAMAGE=5.0
const STEALTH=3.0
const STEALTH_COOLDOWN=6.0
const SNEAK_SPEED=.45
const FRIENDLY=.5       # share of the damage his shots deal to other heroes

static var active_slot=0
static var lock_until=-1.0
static var stealth_left=STEALTH
static var stealth_cooldown=0.0
static var sneaking=false
static var last_seen=Vector3.ZERO
static var hit_flash=0.0
static var head_flash=0.0
static var kill_times=[]
static var last_kills=0
static var headshot_kills=0

static func is_clutch(g) -> bool: return str(g.hero.get("id",""))=="clutch"
static func first_person(g) -> bool: return is_clutch(g) and g.mode in ["playing","level_reveal"] and g.run_active and not g.update.downed

static func reset():
	if is_instance_valid(view): view.queue_free()
	view=null;view_id=""
	active_slot=0;lock_until=-1.0;stealth_left=STEALTH;stealth_cooldown=0.0;sneaking=false;hit_flash=0.0;head_flash=0.0;kill_times.clear();last_kills=0;headshot_kills=0

# The hand weapons he can switch between (turrets are not held).
static func held(g) -> Array: return g.equipped.filter(func(w):return not w.get("turret",false))

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
	if not is_clutch(g): return
	g.avatar.rotation.y=g.yaw
	# In first person his own body, hat and floating hand weapons would sit in
	# front of the lens.
	var fps=first_person(g)
	if fps: g.avatar.visible=false
	for weapon in held(g):
		if is_instance_valid(weapon.get("node")): weapon.node.visible=not fps
	view_model(g,fps,delta)
	for i in range(3):
		if Input.is_physical_key_pressed(KEY_1+i) and i<held(g).size() and active_slot!=i:
			active_slot=i;g.sound.effect("switch")
	# Shift: sneak. Quiet and slow; enemies lose him while the stealth lasts.
	stealth_cooldown=maxf(0,stealth_cooldown-delta)
	var wants=Input.is_action_pressed("dash") and stealth_cooldown<=0 and stealth_left>0
	if wants and not sneaking: last_seen=g.player.position
	sneaking=wants
	if sneaking:
		stealth_left-=delta
		if stealth_left<=0: sneaking=false;stealth_cooldown=STEALTH_COOLDOWN
	elif stealth_left<STEALTH:
		stealth_left=minf(STEALTH,stealth_left+delta*.5)
	# Kills for the combo counter.
	if g.kills>last_kills:
		for i in range(g.kills-last_kills): kill_times.append(g.elapsed)
	last_kills=g.kills
	kill_times=kill_times.filter(func(t):return g.elapsed-t<5.0)

# The active weapon held low on the right of the view, kicking back on shots.
static var view: Node3D
static var view_id=""
static var kick=0.0
static func view_model(g,fps: bool,delta: float):
	var weapon=active_weapon(g);var want=str(weapon.get("id","")) if fps else ""
	if want!=view_id:
		if is_instance_valid(view): view.queue_free()
		view=null;view_id=want
		if want!="":
			view=Node3D.new();view.name="ClutchView";g.camera.add_child(view)
			var model=WeaponModel.new();model.setup(want);model.scale=Vector3.ONE*.42;view.add_child(model)
			for mesh in model.find_children("*","GeometryInstance3D",true,false): mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if is_instance_valid(view):
		kick=maxf(0,kick-delta*6.0)
		var bob=sin(g.elapsed*9.0)*.012*clampf(Vector2(g.player.velocity.x,g.player.velocity.z).length()/6.0,0,1)
		view.position=Vector3(.24,-.22+bob,-.5+kick*.12);view.rotation=Vector3(kick*.25,.08,0)

static func speed_scale(g) -> float: return SNEAK_SPEED if is_clutch(g) and sneaking else 1.0

# Enemies lose track of a sneaking Clutch (CoopSession.target).
static func hidden(g) -> bool: return is_clutch(g) and sneaking

# Fire the active weapon if the trigger is held. Returns true if it fired.
static func trigger(g,weapon: Dictionary) -> bool:
	if weapon!=active_weapon(g) or not first_person(g): return false
	if not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(maxi(0,g.controller_id),JOY_BUTTON_RIGHT_SHOULDER) or g.get_meta("test_trigger",false)): return false
	shoot(g,weapon)
	return true

# One hitscan shot (or a spread of pellets) from the eye along the crosshair.
static func shoot(g,weapon: Dictionary):
	var kind=ContentExpansion.kind(weapon.id);var mods=weapon.get("modifiers",{})
	var origin=g.camera.global_position;var aim=-g.camera.global_basis.z
	var reach=maxf(30.0,float(weapon.range)*g.stat("range")*1.6)
	var locked=g.elapsed<lock_until
	if locked:
		var best={};var best_dot=-2.0  # the nearest to the crosshair, wherever it is
		for enemy in g.enemies:
			if enemy.dead: continue
			var to=(head_point(g,enemy)-origin);if to.length()>reach: continue
			var d=to.normalized().dot(aim)
			if d>best_dot: best_dot=d;best=enemy
		if not best.is_empty(): aim=(head_point(g,best)-origin).normalized()
	var pellets=(3 if kind=="shotgun" else 1)+int(mods.get("extraShots",0))+mini(4,int(g.stats.multishot))
	var base=g.stat("damage")*weapon.damage*float(weapon.get("power",1.0))*float(g.stats.get(kind+"Power",1.0))
	if locked: base*=LOCK_DAMAGE
	g.sound.effect(SkillBook.sound(kind),origin)
	var muzzle=g.player.position+Vector3.UP*(EYE-.25)+(-g.camera.global_basis.z)*.6+g.camera.global_basis.x*.25
	ShotFx.muzzle(g,muzzle,aim,kind)
	g.hit_shake=maxf(g.hit_shake,.03);kick=1.0
	for i in range(pellets):
		var dir=aim.rotated(Vector3.UP,(i-(pellets-1)*.5)*float(mods.get("spread",.05)))
		var hit=cast(g,origin,dir,reach)
		var end: Vector3=hit.get("point",origin+dir*reach)
		g.beam(muzzle,end,PowerIcon.color_for(kind))
		if hit.has("enemy"):
			var head=bool(hit.head) or locked
			var damage=base*(HEADSHOT if head else 1.0)
			g.hurt_enemy(hit.enemy,damage,"crit" if head else "hit",weapon.id)
			hit_flash=.18
			if head:
				head_flash=.35;g.sound.effect("headshot",end)
				if hit.enemy.dead: headshot_kills+=1
		elif hit.has("hero"):
			friendly_hit(g,int(hit.hero),base*FRIENDLY)

static func head_point(g,enemy: Dictionary) -> Vector3:
	return enemy.node.position+Vector3.UP*float(enemy.get("height",1.7))*.88

# The first enemy, hero or wall along the ray.
static func cast(g,origin: Vector3,dir: Vector3,reach: float) -> Dictionary:
	var result={};var nearest=reach
	var ray=PhysicsRayQueryParameters3D.create(origin,origin+dir*reach,1,[g.player.get_rid()])
	var wall=g.get_world_3d().direct_space_state.intersect_ray(ray)
	if not wall.is_empty(): nearest=origin.distance_to(wall.position);result={"point":wall.position}
	for enemy in g.enemies:
		if enemy.dead: continue
		var base: Vector3=enemy.node.position;var height=float(enemy.get("height",1.7));var radius=float(enemy.get("radius",.5))*1.15
		var center=base+Vector3.UP*height*.5
		var t=(center-origin).dot(dir)
		if t<0 or t>nearest: continue
		var q=origin+dir*t
		if Vector2(q.x-center.x,q.z-center.z).length()>radius or q.y<base.y-.1 or q.y>base.y+height+.1: continue
		nearest=t;result={"point":q,"enemy":enemy,"head":q.y>base.y+height*HEAD}
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
