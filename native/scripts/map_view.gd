extends Control
class_name ExploreMap
var hero_position = Vector3.ZERO
var known_chests = []
var gate = Vector3.ZERO
var gate_open = false
var visited = {}
var camera_yaw=0.0
var party=[]
var pings=[]
var interactables=[]
var terrain: ImageTexture
var map_signature=""
var map_extent=400.0

func configure(seed_value: int,realm: int):
	var signature=str(seed_value)+":"+str(realm)
	if signature==map_signature: return
	map_signature=signature
	map_extent=85.0 if realm==3 else 400.0
	var image=Image.create(256,256,false,Image.FORMAT_RGBA8)
	var phase=float(seed_value%23)*.03+realm*.4
	for y in range(256):
		for x in range(256):
			var p=Vector2((x+.5)/256.0*map_extent*2-map_extent,(y+.5)/256.0*map_extent*2-map_extent)
			var biome=2 if realm==3 else 0 if p.length()<65 else int(floor(fposmod(atan2(p.y,p.x)+phase,TAU)/(TAU/6)))
			var coast=RealmWorld.coast_radius(atan2(p.y,p.x),seed_value,realm)
			var color=Color("0e1826") if p.length()>=coast else Color("806f53") if p.length()>coast-14 else [Color("294b42"),Color("37443f"),Color("3b465d"),Color("657179"),Color("63403c"),Color("443653")][biome]
			image.set_pixel(x,y,color)
	terrain=ImageTexture.create_from_image(image)

func point(p: Vector3,radius: float) -> Vector2:
	# Rotate the world around the player so their symbol always stays centered.
	var offset=Vector2(p.x-hero_position.x,p.z-hero_position.z)
	return size*.5+offset.rotated(-camera_yaw)*radius/map_extent

func _draw():
	var center = size*.5
	var radius = minf(size.x,size.y)*.46
	draw_rect(Rect2(Vector2.ZERO,size),Color("102027"))
	if terrain!=null:
		# Translate and rotate the already-cached world texture with the same
		# transform applied to landmarks, so the hero stays at the map center.
		var player_offset=Vector2(hero_position.x,hero_position.z)*radius/map_extent
		draw_set_transform(center-player_offset.rotated(-camera_yaw),-camera_yaw,Vector2.ONE)
		draw_texture_rect(terrain,Rect2(-Vector2.ONE*radius,Vector2.ONE*radius*2),false)
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	for entry in interactables:
		var p=point(entry.position,radius)
		match entry.kind:
			"hunt_target": draw_circle(p,4,Color("e17afa"));draw_circle(p,2,Color("fff2ff"))
			"hunt":
				draw_circle(p,6,Color("46235c"));draw_line(p-Vector2(3,3),p+Vector2(3,3),Color("efb5ff"),2);draw_line(p+Vector2(-3,3),p+Vector2(3,-3),Color("efb5ff"),2)
			"merchant":
				draw_circle(p,6,Color("654a30"));draw_circle(p,4,Color("ffd767"))
				draw_line(p+Vector2(-2,-2),p+Vector2(2,2),Color("654a30"),2)
			"supply":
				draw_colored_polygon(PackedVector2Array([p+Vector2(0,-6),p+Vector2(5,0),p+Vector2(0,6),p+Vector2(-5,0)]),Color("36d7e2"))
				draw_circle(p,2,Color("ffffff"))
			"landmark": draw_line(p+Vector2(0,4),p+Vector2(0,-4),Color("6b4d87"),2);draw_rect(Rect2(p+Vector2(0,-4),Vector2(5,3)),Color("a65ed4"))
			"pot": draw_circle(p,2,Color("a2693f"))
			"potion": draw_rect(Rect2(p-Vector2(2,3),Vector2(4,6)),Color("f04aa5"))
			"magnet":
				draw_circle(p,6,Color("4060e0"));draw_circle(p,3,Color("a0c0ff"))
				draw_line(p+Vector2(-3,0),p+Vector2(3,0),Color("a0c0ff"),2)
				draw_line(p+Vector2(0,-3),p+Vector2(0,3),Color("a0c0ff"),2)
	for chest in known_chests:
		var p = point(chest,radius)
		draw_rect(Rect2(p-Vector2(6,5),Vector2(12,10)),Color("574536"))
		draw_rect(Rect2(p-Vector2(4,3),Vector2(8,6)),Color("edbf56"))
		draw_line(p+Vector2(-4,-1),p+Vector2(4,-1),Color("574536"),1)
		draw_rect(Rect2(p-Vector2(1,1),Vector2(2,4)),Color("fff5da"))
	var hp = point(hero_position,radius)
	# Up now means the hero's current facing direction, not geographic north.
	draw_colored_polygon(PackedVector2Array([hp+Vector2(0,-7),hp+Vector2(-5,5),hp+Vector2(5,5)]),Color("fff0b5"))
	for member in party: draw_circle(point(member,radius),3,Color("398ace"))
	for ping in pings: draw_arc(point(ping,radius),5,0,TAU,12,Color("d55746"),2,true)

