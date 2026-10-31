extends SceneTree

# Rasterises res://icon.svg to PNGs for the Windows .ico (scripts/make-windows-icon.py).
func _initialize():
	var svg=FileAccess.get_file_as_string("res://icon.svg")
	for size in [256,128,64,48,32,24,16]:
		var image=Image.new()
		var error=image.load_svg_from_string(svg,float(size)/1024.0)
		if error!=OK: push_error("svg load failed");quit(1);return
		image.save_png(OS.get_environment("ICON_OUT")+"/icon-%d.png" % size)
	print("ICON_PNGS_DONE")
	quit()
