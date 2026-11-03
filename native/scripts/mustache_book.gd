extends RefCounted
class_name MustacheBook

# Big mustaches (user, November 3: the unfinished hat system becomes big
# mustaches, gifted only by the hardest achievements). The chosen mustache sits
# on the hero's face in every run, on the hero screen, and co-op friends see it
# (pose "mustache"). Nothing is stored apart from the choice: a mustache is
# owned while its achievement is.

const MUSTACHES=[
	{"id":"handlebar","name":"Noggin Handlebar","achievements":["WF_NOGGIN"],"how":"Noggin Knocker: defeat the Grand Noggin"},
	{"id":"horseshoe","name":"Lone Horseshoe","achievements":["WF_NOGGIN_ONE"],"how":"One And Only: defeat the Grand Noggin with a single weapon"},
	{"id":"chevron","name":"Flame Chevron","achievements":["WF_NOGGIN_DARE"],"how":"Daredevil: defeat the Grand Noggin with Dare at level 5"},
	{"id":"cloud","name":"Cloud Puff","achievements":["WF_SPOTLESS"],"how":"Spotless: clear a map without losing any health there"},
	{"id":"walrus","name":"Eclipse Walrus","achievements":["WF_ECLIPSE"],"how":"Lights Out, Still Standing: survive five minutes of the Endless Eclipse"},
	{"id":"imperial","name":"Golden Imperial","achievements":["WF_ROSTER"],"how":"Full Cast: defeat the Grand Noggin with ten different heroes"},
]

static func entry(id: String) -> Dictionary:
	for item in MUSTACHES:
		if item.id==id: return item
	return {}

static func owned(unlocked: Dictionary,id: String) -> bool:
	var item=entry(id)
	return not item.is_empty() and item.achievements.any(func(a):return unlocked.has(a))

# Mustaches unlocked by this achievement (for the unlock toast).
static func unlocked_by(achievement_id: String) -> Array:
	return MUSTACHES.filter(func(m):return m.achievements.has(achievement_id))

# Puts the mustache on a hero rig (or takes it off for ""). It sits on the
# upper lip: just under the front-most point of the head (the nose, beak or
# snout), against the face below it, sized to the head. A model without a Head
# joint is searched in its top part.
static func wear(rig: Node3D,id: String):
	if not is_instance_valid(rig): return
	var old=rig.find_child("Mustache",true,false)
	if old!=null: old.get_parent().remove_child(old);old.queue_free()
	if entry(id).is_empty(): return
	var head: Node3D=rig.find_child("Head",true,false)
	var mount: Node3D=head if head!=null else rig
	var box=bounds(mount)
	if box.size==Vector3.ZERO: box=AABB(Vector3(-.25,0,-.25),Vector3(.5,1.7,.5))
	var width=maxf(.2,minf(box.size.x,box.size.z))
	var points=face_points(mount,box.position.y+box.size.y*(.1 if head!=null else .6))
	var spot=Vector3(box.get_center().x,box.position.y+box.size.y*(.36 if head!=null else .62),box.position.z+width*.06)
	if not points.is_empty():
		# Models face -Z: the nose is the smallest z near the middle.
		var middle=box.get_center().x;var nose=points[0]
		for p in points:
			if absf(p.x-middle)<width*.3 and p.z<nose.z: nose=p
		# Not below the head (a visor or snout tip can sit at its bottom edge).
		var lip_y=maxf(nose.y-width*.14,box.position.y+box.size.y*.22);var lip_z=nose.z
		var found=false
		for p in points:
			if absf(p.x-middle)<width*.3 and absf(p.y-lip_y)<width*.08:
				if not found or p.z<lip_z: lip_z=p.z;found=true
		spot=Vector3(middle,lip_y,(lip_z if found else nose.z)+width*.02)
	var item=build(id);item.name="Mustache";mount.add_child(item)
	item.position=spot
	item.scale=Vector3.ONE*clampf(width/.5,.4,2.5)

# Surface points of the head (mount space) above a height, held weapons left out.
static func face_points(mount: Node3D,above: float) -> Array:
	var result=[]
	for node in mount.find_children("*","MeshInstance3D",true,false):
		if node.name=="GlassCore" or node.mesh==null or str(mount.get_path_to(node)).contains("HandSocket") or str(mount.get_path_to(node)).contains("Mustache"): continue
		var to_mount=mount.global_transform.affine_inverse()*node.global_transform
		var faces=node.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var p=to_mount*faces[i]
			if p.y>above: result.append(p)
	return result

# The head's meshes in the mount's own space (hats/glass orbs excluded).
static func bounds(mount: Node3D) -> AABB:
	var box=AABB();var first=true
	for node in mount.find_children("*","MeshInstance3D",true,false):
		if node.name=="GlassCore" or node.get_parent().name=="Mustache": continue
		var local=mount.global_transform.affine_inverse()*node.global_transform*node.get_aabb()
		box=local if first else box.merge(local);first=false
	return box

# A thick strand along points (one side, x>=0), mirrored to the other side;
# the face curves back, so the ends sit further back (+z).
static func strand(m,points: Array,radii: Array,color: Color,steps:=4):
	for side in [-1.0,1.0]:
		for i in range(points.size()-1):
			for s in range(steps):
				var t=float(s)/steps
				var p: Vector2=points[i].lerp(points[i+1],t);var r=lerpf(float(radii[i]),float(radii[i+1]),t)
				m.ball(Vector3(side*p.x,p.y,p.x*p.x*1.3),Vector3(r,r*.85,r)*2.0,color)
		var last: Vector2=points[-1];var r_last=float(radii[-1])
		m.ball(Vector3(side*last.x,last.y,last.x*last.x*1.3),Vector3(r_last,r_last,r_last)*2.0,color)

# Each mustache sized for a head about 0.5 m wide, centred on the upper lip.
# Big on purpose: wider than the mouth and readable from the run camera.
static func build(id: String) -> Node3D:
	var scene=CartoonScene.new();var m=scene.paint(scene.body)
	match id:
		"handlebar":
			var brown=Color("4a2a16")
			strand(m,[Vector2(0,0),Vector2(.08,-.012),Vector2(.16,0),Vector2(.23,.03),Vector2(.27,.085),Vector2(.255,.13),Vector2(.215,.125)],[.06,.058,.048,.036,.028,.022,.02],brown)
		"horseshoe":
			var black=Color("1d1a1c")
			strand(m,[Vector2(0,0),Vector2(.09,-.004),Vector2(.15,-.04),Vector2(.165,-.12),Vector2(.165,-.23)],[.05,.05,.048,.045,.042],black)
		"chevron":
			var red=Color("e8452c")
			strand(m,[Vector2(0,.01),Vector2(.11,-.015),Vector2(.2,-.05),Vector2(.25,-.075)],[.08,.074,.055,.03],red)
			strand(m,[Vector2(.2,-.05),Vector2(.25,-.075)],[.04,.022],Color("ffc34a"),3)
		"cloud":
			var white=Color("f6f4ef")
			for p in [Vector2(0,.0),Vector2(.085,-.012),Vector2(.165,-.01),Vector2(.235,.01)]:
				for side in [-1.0,1.0]:
					var r=.075 if p.x<.2 else .06
					m.ball(Vector3(side*p.x,p.y,p.x*p.x*1.3),Vector3(r,r,r)*2.0,white)
			for side in [-1.0,1.0]: m.ball(Vector3(side*.05,-.06,.0),Vector3(.11,.09,.11),white)
		"walrus":
			var grey=Color("c9c4bc")
			strand(m,[Vector2(0,.01),Vector2(.1,-.025),Vector2(.18,-.08),Vector2(.22,-.15)],[.085,.085,.075,.06],grey)
			for i in range(7):
				var x=-.18+i*.06
				m.ball(Vector3(x,-.07-absf(x)*.4,x*x*1.3-.02),Vector3(.05,.1,.05),grey.darkened(.08))
		"imperial":
			var gold=Color("f2c230")
			strand(m,[Vector2(0,0),Vector2(.1,-.005),Vector2(.19,.03),Vector2(.26,.11),Vector2(.28,.2),Vector2(.25,.25)],[.052,.048,.038,.028,.02,.016],gold)
			for side in [-1.0,1.0]: m.ball(Vector3(side*.25,.25,.08),Vector3(.045,.045,.045),Color("fff2a8"))
	return scene.finish()
