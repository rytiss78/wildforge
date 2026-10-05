extends SceneTree

func _initialize():
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var atlas=load("res://assets/illustrated/content/painted-atlas.png").get_image()
	var skills=load("res://assets/illustrated/skills.png").get_image()
	var originals=load("res://assets/illustrated/icons.png").get_image()
	var variants=data.weapons.filter(func(w):return w.has("art"))
	var manifest=[]
	for item in data.loot+data.weapons:
		var image: Image
		if item.has("art"):
			var tile=int(item.art.shape) if item.has("effects") else 20+variants.find(item)
			image=atlas.get_region(Rect2i(tile%8*atlas.get_width()/8,tile/8*atlas.get_height()/8,atlas.get_width()/8,atlas.get_height()/8))
		elif item.has("effects"):
			var tile=int(IllustratedIcons.SKILLS.get(item.effects[0].key,4))
			if item.effects[0].key=="jumpHeight": image=atlas.get_region(Rect2i(2*atlas.get_width()/8,0,atlas.get_width()/8,atlas.get_height()/8))
			elif item.effects[0].key=="airJumps": image=atlas.get_region(Rect2i(4*atlas.get_width()/8,7*atlas.get_height()/8,atlas.get_width()/8,atlas.get_height()/8))
			else: image=skills.get_region(Rect2i(tile%4*skills.get_width()/4,tile/4*skills.get_height()/4,skills.get_width()/4,skills.get_height()/4))
		else:
			var rendered="res://assets/illustrated/weapon-icons/"+item.id+".png"
			if ResourceLoader.exists(rendered): image=load(rendered).get_image()
			else:
				var tile=int(IllustratedIcons.WEAPONS.get(item.id,0))
				image=originals.get_region(Rect2i(tile%6*128+5,tile/6*128+5,118,118))
		image.convert(Image.FORMAT_RGBA8);image.resize(128,128,Image.INTERPOLATE_LANCZOS)
		# Painted object art with individual condition seals and engraved identity marks.
		var seal=load("res://assets/illustrated/content/"+item.id+".svg").get_image()
		seal.convert(Image.FORMAT_RGBA8)
		image.blend_rect(seal,Rect2i(3,3,38,38),Vector2i(3,3))
		image.blend_rect(seal,Rect2i(32,112,65,10),Vector2i(32,115))
		var target="res://assets/illustrated/content/"+item.id+".png"
		if image.save_png(target)!=OK: push_error("Icon save failed: "+target);quit(1);return
		manifest.append({"id":item.id,"path":target,"source":"Painted atlas with distinct condition seal and identity engraving","sha256":FileAccess.get_sha256(target)})
	var file=FileAccess.open("res://assets/illustrated/content/painted-manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("Baked "+str(manifest.size())+" painted collectible icons")
	quit()
