extends RefCounted
class_name Underside

# The island's underside (user request, October 31: "remove the water under the
# map, it is not a death sea. When you walk over the edge you start walking upside
# down under the map. Monsters and drops can't cross the edge, only the hero. The
# camera still shows the ground at the bottom").
#
# The island is a floating slab: its top ends in a rounded rocky rim (RealmWorld.
# compute_height_at) and a hanging rock belly below (RealmWorld.under_height).
# Walking over the rim flips the hero over it in FLIP seconds; underneath, the hero
# walks upside down on the belly, kinematically (there is nothing to collide with),
# and the camera is rolled half a turn so the belly is at the bottom of the screen.
# Walking back out over the rim flips the hero back on top.
#
# Underneath, the hero is out of the fight: enemies cannot reach or target them,
# they take no damage, their weapons rest, drops do not fly to them and the pet
# waits on top. The Red Moon arena (realm 3) has no underside; its void still kills.

const THICK=14.0  # rock from the shore down to the belly's lip
const RIM=4.0  # the rim's width, curving from the shore down to the lip
const FLIP=.7
const INSET=2.0  # how far inside the rim the hero lands, top or bottom
const TRIGGER=.5  # how close to the rim a move starts the flip

var state="top"  # top, down (flipping under), under, up (flipping back)
var clock=0.0
var pivot=Vector3.ZERO
var outward=Vector3.RIGHT
var axis=Vector3.FORWARD
var from=Vector3.ZERO
var to=Vector3.ZERO
var realm=-1
var flips=0
var face=0.0

# Anything but plain walking on top: the hero is unreachable and out of the fight.
func active() -> bool: return state!="top"
# Underneath or most of the way there: the view and the controls are turned over.
func flipped() -> bool: return state=="under" or (state=="down" and clock>=FLIP*.5) or (state=="up" and clock<FLIP*.5)

# A new island or run: back on top, nothing turned over.
func clear(game: Node3D):
	state="top";clock=0.0;realm=game.world.realm
	game.avatar.rotation.x=0.0;game.avatar.rotation.z=0.0
	light(game,false)

func reset(game: Node3D):
	if state=="top": return
	state="top";clock=0.0
	var p: Vector3=game.player.position;var coast=game.world.shore_radius(p)
	var flat=Vector2(p.x,p.z)
	if flat.length()>coast-INSET: flat=flat.normalized()*(coast-INSET)
	game.player.position=Vector3(flat.x,game.world.height_at(flat.x,flat.y)+.3,flat.y);game.player.velocity=Vector3.ZERO
	game.player.reset_physics_interpolation()
	game.avatar.rotation.x=0.0;game.avatar.rotation.z=0.0
	light(game,false)

# Called every physics frame after the hero's horizontal velocity is set. Returns
# true when this frame's movement was handled here (flipping or underneath).
func tick(game: Node3D,delta: float) -> bool:
	if realm!=game.world.realm: realm=game.world.realm;reset(game)
	if game.world.realm==3: return false
	var p: Vector3=game.player.position;var flat=Vector2(p.x,p.z)
	var coast=game.world.shore_radius(p)
	match state:
		"top":
			var moving_out=Vector2(game.player.velocity.x,game.player.velocity.z).dot(flat.normalized())>.5
			if flat.length()>coast-TRIGGER and (moving_out or flat.length()>coast+.5): begin(game,"down",flat,coast)
			return state!="top"
		"down","up":
			clock+=delta
			var t=clampf(clock/FLIP,0,1);var eased=t*t*(3-2*t)
			# Round the rim: swing about the pivot, blending into the landing spot.
			var swung=pivot+(from-pivot).rotated(axis,eased*PI)
			var mirror=pivot+(from-pivot).rotated(axis,PI)
			game.player.position=swung+(to-mirror)*eased
			game.player.velocity=Vector3.ZERO
			# The body turns with the swing: going under, forward runs out, down, in;
			# coming back, out, up, in. Up is the camera's up.
			var angle=eased*PI
			var forward=outward*cos(angle)+(Vector3.DOWN if state=="down" else Vector3.UP)*sin(angle)
			pose(game,forward,camera_up())
			if t>=1.0:
				state="under" if state=="down" else "top"
				face=atan2(outward.x,outward.z)  # facing inward
				if state=="top":
					game.avatar.rotation=Vector3(0,face,0)
					game.last_safe=game.player.position;light(game,false)
				else: game.avatar.rotation=Vector3(0,face,PI)
				# Keep walking the same way round the rim: the view turns with you.
				game.yaw+=PI;flips+=1
			return true
		"under":
			var step=Vector3(game.player.velocity.x,0,game.player.velocity.z)*delta
			var next=p+step;var next_flat=Vector2(next.x,next.z)
			var next_coast=game.world.shore_radius(next)
			if next_flat.length()>next_coast-TRIGGER and step.length()>0.0 and Vector2(step.x,step.z).dot(next_flat.normalized())>0.0:
				begin(game,"up",next_flat,next_coast);return true
			game.player.position=Vector3(next.x,game.world.under_height(next.x,next.z),next.z)
			# Upside down, turning toward the way the hero walks.
			if step.length()>.001: face=lerp_angle(face,atan2(-step.x,-step.z),minf(1.0,delta*9))
			game.avatar.rotation=Vector3(0,face,PI)
			return true
	return false

func begin(game: Node3D,kind: String,flat: Vector2,coast: float):
	state=kind;clock=0.0
	var direction=flat.normalized() if flat.length()>.01 else Vector2.RIGHT
	outward=Vector3(direction.x,0,direction.y);axis=Vector3.UP.cross(outward).normalized()
	var top_y=game.world.height_at(direction.x*coast,direction.y*coast)
	pivot=Vector3(direction.x*coast,top_y-THICK*.5,direction.y*coast)
	var inner=direction*(coast-INSET)
	var top=Vector3(inner.x,game.world.height_at(inner.x,inner.y),inner.y)
	var bottom=Vector3(inner.x,game.world.under_height(inner.x,inner.y),inner.y)
	from=game.player.position
	if kind=="up": axis=-axis
	to=bottom if kind=="down" else top
	game.slamming=false;game.landing_ready=false;game.air_jumps=0
	game.sound.effect("dash",game.player.position)
	light(game,true)

# Sets the avatar's turn from where its front and its head point (model front is -Z).
func pose(game: Node3D,forward: Vector3,up: Vector3):
	var size=game.avatar.scale
	var back=-forward.normalized();var head=up.normalized();var side=head.cross(back).normalized()
	head=back.cross(side)
	game.avatar.basis=Basis(side*size.x,head*size.y,back*size.z)

# Which way is "up" for the camera: the sky on top, the belly's downward face below,
# turning over the rim in between.
func camera_up() -> Vector3:
	match state:
		"under": return Vector3.DOWN
		"down": return Vector3.UP.rotated(axis,ease_angle())
		"up": return Vector3.DOWN.rotated(axis,ease_angle())
	return Vector3.UP

func ease_angle() -> float:
	var t=clampf(clock/FLIP,0,1)
	return t*t*(3-2*t)*PI

# A soft light from below while the hero is under the island, so the belly reads.
func light(game: Node3D,on: bool):
	var lamp: DirectionalLight3D=game.world.get_node_or_null("UnderLight")
	if lamp!=null: lamp.visible=on
