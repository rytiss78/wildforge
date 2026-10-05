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

func configure(seed_value: int,realm: int):
	var signature=str(seed_value)+":"+str(realm)
	if signature==map_signature: return
	map_signature=signature
	var image=Image.create(128,128,false,Image.FORMAT_RGBA8)
	var phase=float(seed_value%23)*.03+realm*.4
	for y in range(128):
		for x in range(128):
			var p=Vector2((x+.5)/128.0*800-400,(y+.5)/128.0*800-400)
			var biome=0 if p.length()<65 else int(floor(fposmod(atan2(p.y,p.x)+phase,TAU)/(TAU/6)))
			var color=Color("176579") if maxf(absf(p.x),absf(p.y))>=375 else Color("ddc995") if maxf(absf(p.x),absf(p.y))>350 else RealmWorld.COLORS[biome]
			image.set_pixel(x,y,color)
	terrain=ImageTexture.create_from_image(image)

func point(p: Vector3,radius: float) -> Vector2:
	return size*.5+Vector2(p.x,p.z).rotated(camera_yaw)*radius/(RealmWorld.EXTENT*sqrt(2.0)+10)

func _draw():
	var center = size*.5
	var radius = minf(size.x,size.y)*.46
	draw_circle(center,radius,Color("123f55"))
	if terrain!=null:
		var side=2*RealmWorld.EXTENT*radius/(RealmWorld.EXTENT*sqrt(2.0)+10)
		draw_set_transform(center,camera_yaw)
		draw_texture_rect(terrain,Rect2(Vector2.ONE*(-side*.5),Vector2.ONE*side),false)
		draw_set_transform(Vector2.ZERO)
	draw_arc(center,radius,0,TAU,60,Color("947956"),2,true)
	for entry in interactables:
		var p=point(entry.position,radius)
		match entry.kind:
			"merchant":
				draw_circle(p,6,Color("654a30"));draw_circle(p,4,Color("ffd767"))
				draw_line(p+Vector2(-2,-2),p+Vector2(2,2),Color("654a30"),2)
			"supply":
				draw_colored_polygon(PackedVector2Array([p+Vector2(0,-6),p+Vector2(5,0),p+Vector2(0,6),p+Vector2(-5,0)]),Color("36d7e2"))
				draw_circle(p,2,Color("ffffff"))
			"landmark": draw_line(p+Vector2(0,4),p+Vector2(0,-4),Color("6b4d87"),2);draw_rect(Rect2(p+Vector2(0,-4),Vector2(5,3)),Color("a65ed4"))
			"pot": draw_circle(p,2,Color("a2693f"))
			"potion": draw_rect(Rect2(p-Vector2(2,3),Vector2(4,6)),Color("f04aa5"))
	for chest in known_chests:
		var p = point(chest,radius)
		if p.distance_to(center)>radius-9: p=center+(p-center).normalized()*(radius-9)
		draw_rect(Rect2(p-Vector2(6,5),Vector2(12,10)),Color("574536"))
		draw_rect(Rect2(p-Vector2(4,3),Vector2(8,6)),Color("edbf56"))
		draw_line(p+Vector2(-4,-1),p+Vector2(4,-1),Color("574536"),1)
		draw_rect(Rect2(p-Vector2(1,1),Vector2(2,4)),Color("fff5da"))
	var gp = point(gate,radius)
	draw_arc(gp,5,0,TAU,12,Color("9bdcb9") if gate_open else Color("967cac"),2,true)
	var hp = point(hero_position,radius)
	draw_colored_polygon(PackedVector2Array([hp+Vector2(0,-6),hp+Vector2(-4,4),hp+Vector2(4,4)]),Color("574536"))
	for member in party: draw_circle(point(member,radius),3,Color("398ace"))
	for ping in pings: draw_arc(point(ping,radius),5,0,TAU,12,Color("d55746"),2,true)

	draw_string(ThemeDB.fallback_font,Vector2(6,size.y-6),"Gold: merchant  Cyan: supply  Pink: potion",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f4e9cc"))
