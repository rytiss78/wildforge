extends RefCounted
class_name PortalFx

# Travel between islands: a rising teleport sweep, a white-gold screen flash
# that fades as the new island appears, and a beam of light coming down on the
# hero with a ring and sparks in the island's own colour. Plays on every island
# arrival (run start, portal, co-op realm changes, rejoin).
const COLORS=[Color("ffe7a8"),Color("d9a2ff"),Color("ff9a4a"),Color("ff5a4a")]
static var overlay: ColorRect

static func arrive(g):
	var color: Color=COLORS[clampi(g.realm,0,3)]
	g.sound.effect("teleport",g.player.position)
	flash(g,color.lightened(.55))
	var at: Vector3=g.player.position
	CombatInk.beam(g,at+Vector3.UP*45,at+Vector3.UP*.2,color,false,9.0)
	CombatInk.beam(g,at+Vector3.UP*45,at+Vector3.UP*.2,Color("fffbe8"),false,3.0)
	CombatInk.wave(g,at,6.5,color)
	var star=CombatInk.star(g,at+Vector3.UP*1.2,5.0,color,10.0,.6)
	if star!=null: star.shards(color.lightened(.3),12,5.0);star.fall=-2.0;star.lamp(g,color,5.0,14.0,Vector3.UP*2)

static func flash(g,color: Color):
	# Automated runs (any command-line review or check) capture right after island
	# changes; the flash would wash out their screenshots unless one asks for it.
	if not OS.get_cmdline_user_args().is_empty() and not g.has_meta("review_flash"): return
	if not is_instance_valid(overlay):
		overlay=ColorRect.new();overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);g.hud.add_child(overlay)
	overlay.color=Color(color,.85*clampf(EffectDetail.flashes,.25,1.0));overlay.visible=true
	# A tree tween keeps fading even while the game node itself is paused.
	var fade=g.get_tree().create_tween();fade.tween_property(overlay,"color:a",0.0,.9).set_ease(Tween.EASE_OUT)
