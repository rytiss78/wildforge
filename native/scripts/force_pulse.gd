extends RefCounted
class_name ForcePulse

const PERIODS={"enemyPull":3.5,"enemyPush":4.5}
static func tick(game,delta: float):
	if game.hp<=0: return
	for key in PERIODS:
		game.force_clocks[key]=float(game.force_clocks.get(key,1.0 if key=="enemyPull" else 2.5))-delta
		if game.force_clocks[key]>0 or game.stat(key)<=0: continue
		game.force_clocks[key]=PERIODS[key]
		if game.coop.active and not game.coop.hosting:
			game.coop.send_to(game.coop.owner_id,{"type":"force_pulse","key":key,"realm":game.realm})
		else: apply(game,game.player.position,key,game.stat(key))

static func apply(game,origin: Vector3,key: String,power: float):
	if not PERIODS.has(key) or power<=0: return
	for enemy in game.enemies:
		if enemy.dead: continue
		var offset=enemy.node.position-origin;offset.y=0
		var distance=offset.length()
		if distance>.1 and distance<8 and absf(enemy.node.position.y-origin.y)<3:
			var amount=minf(8,power)*(.2 if enemy.boss else 1.)
			if key=="enemyPull": amount=minf(amount,maxf(0,distance-enemy.radius-.9))
			enemy.node.move_and_collide(offset.normalized()*amount*(-1 if key=="enemyPull" else 1))
	visual(game,origin,key)
	if game.coop.active and game.coop.hosting: game.coop.broadcast({"type":"force_pulse_fx","position":CoopSession.array(origin),"key":key,"realm":game.realm})

static func visual(game,origin: Vector3,key: String):
	var mesh=TorusMesh.new();mesh.inner_radius=.94;mesh.outer_radius=1.;mesh.rings=24;mesh.ring_segments=6
	var node=game.shape(mesh,Color("68c8db") if key=="enemyPull" else Color("efa569"),game,origin+Vector3.UP*.15,.5)
	node.scale=Vector3(8,.15,8) if key=="enemyPull" else Vector3(.4,.15,.4)
	var target=Vector3(.4,.15,.4) if key=="enemyPull" else Vector3(8,.15,8)
	var tween=game.create_tween();tween.tween_property(node,"scale",target,.4);tween.tween_callback(node.queue_free)
