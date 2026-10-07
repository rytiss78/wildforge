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
	var image=Image.create(256,256,false,Image.FORMAT_RGBA8)
	var phase=float(seed_value%23)*.03+realm*.4
	for y in range(256):
		for x in range(256):
			var p=Vector2((x+.5)/256.0*800-400,(y+.5)/256.0*800-400)
			var biome=0 if p.length()<65 else int(floor(fposmod(atan2(p.y,p.x)+phase,TAU)/(TAU/6)))
			var coast=RealmWorld.coast_radius(atan2(p.y,p.x),seed_value,realm)
			var color=Color("245b6c") if p.length()>=coast else Color("ddc995") if p.length()>coast-14 else RealmWorld.COLORS[biome]
			image.set_pixel(x,y,color)
	terrain=ImageTexture.create_from_image(image)

func point(p: Vector3,radius: float) -> Vector2:
	return size*.5+Vector2(p.x,p.z)*radius/RealmWorld.EXTENT

func _draw():
	var center = size*.5
	var radius = minf(size.x,size.y)*.46
	var frame=StyleBoxFlat.new();frame.bg_color=Color("17293d");frame.border_color=Color("b8a16e");frame.set_border_width_all(2);frame.set_corner_radius_all(10)
	draw_style_box(frame,Rect2(Vector2.ZERO,size))
	if terrain!=null: draw_texture_rect(terrain,Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),false)
	draw_string(ThemeDB.fallback_font,Vector2(8,18),"N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff8de"))
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
	for chest in known_chests:
		var p = point(chest,radius)
		draw_rect(Rect2(p-Vector2(6,5),Vector2(12,10)),Color("574536"))
		draw_rect(Rect2(p-Vector2(4,3),Vector2(8,6)),Color("edbf56"))
		draw_line(p+Vector2(-4,-1),p+Vector2(4,-1),Color("574536"),1)
		draw_rect(Rect2(p-Vector2(1,1),Vector2(2,4)),Color("fff5da"))
	var gp = point(gate,radius)
	draw_circle(gp,9,Color("17293d"));draw_arc(gp,7,0,TAU,24,Color("ffd767") if gate_open else Color("e1c8f4"),3,true)
	draw_line(gp+Vector2(0,-10),gp+Vector2(0,10),Color("ffd767"),1.5)
	var hp = point(hero_position,radius)
	draw_colored_polygon(PackedVector2Array([hp+Vector2(0,-6).rotated(-camera_yaw),hp+Vector2(-4,4).rotated(-camera_yaw),hp+Vector2(4,4).rotated(-camera_yaw)]),Color("574536"))
	for member in party: draw_circle(point(member,radius),3,Color("398ace"))
	for ping in pings: draw_arc(point(ping,radius),5,0,TAU,12,Color("d55746"),2,true)

	draw_rect(Rect2(0,size.y+2,size.x,19),Color("17293d"))
	draw_string(ThemeDB.fallback_font,Vector2(4,size.y+15),"Ring: portal · Gold: shop · Violet: hunt",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f4e9cc"))
