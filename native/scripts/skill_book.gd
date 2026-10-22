extends RefCounted
class_name SkillBook

# Screen-filling spell weapons. They take a weapon slot and fire on the weapon
# clock like any other weapon, but each spell is a large area effect that grows
# with the weapon's rank and the Size stat, and multiplies with extra shots:
#   tornado      wandering twisters that drag enemies in and shred them
#   blackhole    a vortex that pulls a crowd together, then collapses in a blast
#   thunderstorm a volley of sky lightning across many enemies
#   inferno      a ring of fire that sweeps outward and sets everything alight
# Active casts live in g.skills. A spell from a co-op teammate is visual only.
const KINDS=["tornado","blackhole","thunderstorm","inferno"]
const COLORS={"tornado":Color("b8ece0"),"blackhole":Color("a77cff"),"thunderstorm":Color("79c6ff"),"inferno":Color("ff7424")}
const SOUNDS={"tornado":"dash","blackhole":"gravity","thunderstorm":"lightning","inferno":"nova"}
const MAX_SCALE=4.0
static var funnel_mesh: CylinderMesh
static var wall_mesh: CylinderMesh
static var ground_quad: PlaneMesh

static func sound(kind: String) -> String:
	return SOUNDS.get(kind,kind)

# Rank and Size grow every skill: rank 1 is 1x, rank 9 about 2.3x.
static func growth(g,weapon: Dictionary) -> float:
	return clampf(g.stat("size")*(1.0+.16*(int(weapon.get("rank",1))-1)),.5,MAX_SCALE)

static func extra(g) -> int:
	return mini(4,int(g.stats.get("multishot",0)))

static func cast(g,weapon: Dictionary,kind: String,origin: Vector3,target: Dictionary,damage: float) -> bool:
	if not kind in KINDS: return false
	var scale=growth(g,weapon)
	g.coop.shot(weapon.id,origin,g.enemy_center(target),clampf(scale*.1,.07,.44))
	# Rank already widens the area, so damage only grows with the square root of weapon power.
	damage/=sqrt(maxf(1.0,float(weapon.get("power",1.0))))
	start(g,kind,origin,target.node.position,scale,damage,str(weapon.id),false,int(weapon.get("rank",1)))
	return true

# A teammate's spell: their scale arrives in the shot's duration field (scale/10).
static func cast_visual(g,kind: String,origin: Vector3,target: Vector3,duration: float):
	start(g,kind,origin,target,clampf(duration*10.0,1.0,MAX_SCALE),0.0,kind,true,1)

static func start(g,kind: String,origin: Vector3,target: Vector3,scale: float,damage: float,weapon_id: String,visual_only: bool,rank: int):
	var spell={"kind":kind,"age":0.0,"scale":scale,"damage":damage,"weapon_id":weapon_id,"visual_only":visual_only,"tick":0.0}
	match kind:
		"tornado":
			var count=mini(7,1+int((rank-1)/5)+(0 if visual_only else extra(g)))
			var heading=(target-origin)*Vector3(1,0,1)
			heading=heading.normalized() if heading.length_squared()>.01 else Vector3.FORWARD
			for i in range(count):
				var twist=(i-(count-1)*.5)*.7
				var entry=spell.duplicate();entry.life=3.6;entry.radius=1.7*scale
				entry.velocity=heading.rotated(Vector3.UP,twist)*6.5;entry.curl=1.1 if i%2==0 else -1.1
				entry.node=funnel(g,ground(g,origin+heading.rotated(Vector3.UP,twist)*(2.0+scale)),scale)
				g.skills.append(entry)
		"blackhole":
			var entry=spell.duplicate();entry.life=2.6;entry.radius=4.0*scale
			entry.node=vortex(g,ground(g,target),entry.radius)
			CombatInk.wave(g,ground(g,target),entry.radius*1.6,COLORS.blackhole)
			g.skills.append(entry)
		"thunderstorm":
			var count=mini(18,3+int(rank/3)+2*(0 if visual_only else extra(g)))
			var points=[]
			var near=g.enemies.filter(func(e):return not e.dead and e.node.position.distance_to(origin)<26.0)
			near.sort_custom(func(a,b):return a.node.position.distance_squared_to(target)<b.node.position.distance_squared_to(target))
			for i in range(count):
				if i<near.size() and not visual_only: points.append(near[i].node.position)
				else: points.append(target+Vector3.RIGHT.rotated(Vector3.UP,i*2.39996)*(2.0+i*.9)*scale)
			var entry=spell.duplicate();entry.life=count*.07+.3;entry.radius=2.2*scale;entry.points=points;entry.next=0
			entry.node=Node3D.new();g.add_child(entry.node)
			g.skills.append(entry)
		"inferno":
			var entry=spell.duplicate();entry.life=1.0;entry.radius=7.0*scale;entry.burned={}
			entry.node=nova(g,ground(g,origin))
			g.skills.append(entry)

static func ground(g,p: Vector3) -> Vector3:
	return Vector3(p.x,g.world.height_at(p.x,p.z),p.z)

static func tick(g,delta: float):
	if g.skills.is_empty(): return
	var authority=not g.coop.active or g.coop.hosting
	for spell in g.skills:
		spell.age+=delta;spell.life-=delta;spell.tick-=delta
		# Damage ticks four times a second; visuals tick with them for debris.
		var fresh=spell.tick<=0
		var hits=fresh and not spell.visual_only
		if fresh: spell.tick=.25
		match spell.kind:
			"tornado":
				spell.velocity=spell.velocity.rotated(Vector3.UP,spell.curl*delta)
				var p: Vector3=spell.node.position+spell.velocity*delta;p.y=g.world.height_at(p.x,p.z);spell.node.position=p
				spell.node.rotation.y+=delta*7.0
				spell.node.get_child(0).material_override.set_shader_parameter("fade",clampf(minf(spell.age*4.0,spell.life*2.0),0,1))
				for enemy in g.enemies.duplicate():
					if enemy.dead: continue
					var offset: Vector3=(p-enemy.node.position)*Vector3(1,0,1)
					if offset.length()>spell.radius: continue
					if not spell.visual_only and authority and not enemy.boss and offset.length()>.4: enemy.node.move_and_collide(offset.normalized()*delta*5.0)
					if hits: g.hurt_enemy(enemy,spell.damage*.9,"hit",spell.weapon_id)
				if fresh:
					var debris=CombatInk.begin(g,p+Vector3.UP*spell.radius*.6,.4,"trail")
					if debris!=null: debris.shards(Color("d9cfb8"),3,spell.radius*1.6);debris.fall=-1.0
			"blackhole":
				var grow=clampf(spell.age/.45,0,1)*(1.0-clampf((.25-spell.life)/.25,0,1)*.8)
				var disk: Node3D=spell.node.get_child(0);disk.scale=Vector3.ONE*maxf(.05,grow);disk.rotation.y-=delta*3.0
				spell.node.get_child(1).scale=Vector3.ONE*(.4+.6*grow)*(1.0+sin(spell.age*14.0)*.06)
				var center: Vector3=spell.node.position
				for enemy in g.enemies.duplicate():
					if enemy.dead: continue
					var offset: Vector3=(center-enemy.node.position)*Vector3(1,0,1)
					if offset.length()>spell.radius*1.6: continue
					if not spell.visual_only and authority and not enemy.boss and offset.length()>.6: enemy.node.move_and_collide(offset.normalized()*delta*7.5)
					if hits and offset.length()<spell.radius: g.hurt_enemy(enemy,spell.damage*.04,"gravity",spell.weapon_id)
				if spell.life<=0:
					var burst=CombatInk.star(g,center+Vector3.UP*1.2,spell.radius*2.0,COLORS.blackhole,10.0,.5)
					if burst!=null: burst.shards(Color("e3d2ff"),12,spell.radius*1.8);burst.lamp(g,COLORS.blackhole,5.0,spell.radius*2.5,Vector3.UP)
					CombatInk.wave(g,center,spell.radius*1.5,COLORS.blackhole);g.sound.effect("blast",center)
					g.hit_shake=maxf(g.hit_shake,.25)
					if not spell.visual_only:
						for enemy in g.enemies.duplicate():
							if not enemy.dead and center.distance_to(g.melee_contact(enemy,center))<spell.radius*1.2: g.hurt_enemy(enemy,spell.damage*.45,"explosion",spell.weapon_id)
			"thunderstorm":
				while spell.next<spell.points.size() and spell.age>=spell.next*.07:
					var point: Vector3=spell.points[spell.next];point.y=g.world.height_at(point.x,point.z);spell.next+=1
					CombatInk.beam(g,point+Vector3(1.5,22,0),point+Vector3.UP*.3,COLORS.thunderstorm,true,1.8)
					CombatInk.star(g,point+Vector3.UP*.6,spell.radius*1.3,Color("d8f0ff"),8.0,.26)
					CombatInk.wave(g,point,spell.radius,COLORS.thunderstorm)
					if spell.next%3==1: g.sound.effect("lightning",point)
					if not spell.visual_only:
						for enemy in g.enemies.duplicate():
							if not enemy.dead and point.distance_to(g.melee_contact(enemy,point))<spell.radius: g.hurt_enemy(enemy,spell.damage*.6,"lightning",spell.weapon_id)
				if spell.next>0: g.hit_shake=maxf(g.hit_shake,.06)
			"inferno":
				var front=lerpf(.6,spell.radius,1.0-pow(1.0-clampf(spell.age/.85,0,1),2.0))
				spell.node.scale=Vector3(front,1.0+front*.04,front)
				for part in spell.node.get_children(): part.material_override.set_shader_parameter("fade",clampf(spell.life/.3,0,1))
				if not spell.visual_only:
					var center: Vector3=spell.node.position
					for enemy in g.enemies.duplicate():
						if enemy.dead or spell.burned.has(enemy.net_id): continue
						if (enemy.node.position-center).length()<front+float(enemy.get("radius",.7)):
							spell.burned[enemy.net_id]=true;g.hurt_enemy(enemy,spell.damage*.2,"fire",spell.weapon_id)
	for spell in g.skills:
		if spell.life<=0 and is_instance_valid(spell.node): spell.node.queue_free()
	g.skills=g.skills.filter(func(c):return c.life>0)

static func funnel(g,point: Vector3,scale: float) -> Node3D:
	if funnel_mesh==null:
		funnel_mesh=CylinderMesh.new();funnel_mesh.top_radius=1.0;funnel_mesh.bottom_radius=.22;funnel_mesh.height=1.0;funnel_mesh.cap_top=false;funnel_mesh.cap_bottom=false;funnel_mesh.radial_segments=20;funnel_mesh.rings=1
	var root=Node3D.new();g.add_child(root);root.position=point
	var cone=MeshInstance3D.new();cone.mesh=funnel_mesh;cone.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/ink_funnel.gdshader");paint.set_shader_parameter("pigment",COLORS.tornado);paint.set_shader_parameter("fade",0.0)
	cone.material_override=paint;cone.scale=Vector3(1.7*scale,3.4*scale,1.7*scale);cone.position.y=1.7*scale;root.add_child(cone)
	return root

# Swirling disk at full size (scaled in as it opens) plus a small black core that
# stays a fixed size, so a large hole does not become a black dome.
static func vortex(g,point: Vector3,radius: float) -> Node3D:
	var root=Node3D.new();g.add_child(root);root.position=point+Vector3.UP*.15
	var disk=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2.ONE*radius*2.0;disk.mesh=plane
	var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/area_vortex.gdshader");disk.material_override=paint
	disk.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;disk.scale=Vector3.ONE*.05;root.add_child(disk)
	var core=MeshInstance3D.new();var ball=SphereMesh.new();ball.radius=.75;ball.height=1.5;ball.radial_segments=16;ball.rings=8;core.mesh=ball;core.position.y=.9
	var black=StandardMaterial3D.new();black.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;black.albedo_color=Color("05030a")
	black.rim_enabled=false;core.material_override=black;core.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(core)
	var halo=MeshInstance3D.new();var hoop=TorusMesh.new();hoop.inner_radius=.85;hoop.outer_radius=1.0;halo.mesh=hoop
	var glow=StandardMaterial3D.new();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow.albedo_color=COLORS.blackhole.lightened(.25)
	halo.material_override=glow;halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;halo.rotation.x=PI*.5;core.add_child(halo)
	return root

static func nova(g,point: Vector3) -> Node3D:
	if ground_quad==null:
		ground_quad=PlaneMesh.new();ground_quad.size=Vector2(2.1,2.1)
		wall_mesh=CylinderMesh.new();wall_mesh.top_radius=1.0;wall_mesh.bottom_radius=1.0;wall_mesh.height=1.0;wall_mesh.cap_top=false;wall_mesh.cap_bottom=false;wall_mesh.radial_segments=48;wall_mesh.rings=1
	var root=Node3D.new();g.add_child(root);root.position=point+Vector3.UP*.12
	for wall in [0.0,1.0]:
		var part=MeshInstance3D.new();part.mesh=wall_mesh if wall>0 else ground_quad;part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/ink_fire_ring.gdshader");paint.set_shader_parameter("wall",wall);paint.set_shader_parameter("pigment",COLORS.inferno)
		part.material_override=paint
		if wall>0: part.scale=Vector3(.94,1.5,.94);part.position.y=.75
		root.add_child(part)
	return root

# Held focus for each spell, built from the shared toon primitives so it can be
# rendered into the weapon icon like every other weapon.
static func build_model(model: WeaponModel) -> bool:
	if not model.id in KINDS: return false
	var gold=Color("dab377");var root=model.base;var tip=Vector3(0,.42,-.2)
	ToonArt.tube(root,Color("6b4a35"),Vector3(0,.08,-.1),.04,.05,.5)
	ToonArt.tube(root,gold,Vector3(0,.32,-.15),.07,.07,.05)
	match model.id:
		"tornado":
			# A funnel of thin, offset layers widening upward.
			for i in range(6): ToonArt.tube(root,Color("e4fbf5").darkened(.05+(i%2)*.14),tip+Vector3(sin(i*1.3)*.035,i*.065-.1,cos(i*1.3)*.02),.035+i*.04,.028+i*.04,.055)
		"blackhole":
			ToonArt.ball(root,Color("17121f"),tip,Vector3(.24,.24,.24))
			var hoop=TorusMesh.new();hoop.inner_radius=.19;hoop.outer_radius=.24
			var ring=ToonArt.part(root,hoop,COLORS.blackhole,tip);ring.rotation=Vector3(.5,0,.3)
		"thunderstorm":
			ToonArt.ball(root,Color("bfe8ff"),tip,Vector3(.16,.16,.16))
			for i in range(3): ToonArt.ball(root,Color("8d97a8"),tip+Vector3((i-1)*.13,.13,0),Vector3(.13,.1,.12))
			var bolt=BoxMesh.new();bolt.size=Vector3(.035,.2,.035)
			var spark=ToonArt.part(root,bolt,Color("ffe36a"),tip+Vector3(.05,-.14,0));spark.rotation.z=.4
		"inferno":
			ToonArt.ball(root,Color("ffb347"),tip,Vector3(.18,.18,.18))
			for i in range(6):
				var flame=CylinderMesh.new();flame.top_radius=0;flame.bottom_radius=.05;flame.height=.16;flame.radial_segments=6
				var ray=ToonArt.part(root,flame,Color("ff6a1c"),tip+Vector3(cos(i*TAU/6),sin(i*TAU/6),0)*.2);ray.rotation.z=i*TAU/6-PI/2
	model.muzzle.position=tip;root.add_child(model.muzzle)
	model.flash=ToonArt.ball(model.muzzle,COLORS[model.id].lightened(.2),Vector3.ZERO,Vector3(.16,.16,.16));model.flash.visible=false
	return true
