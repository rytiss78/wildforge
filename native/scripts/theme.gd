# Theme system — centralized tokens for all UI surfaces.
# All scripts should reference this file instead of hard-coding colors,
# spacing, or typography values.  See art-direction.md §2–§4.
class_name ThemeTokens

# ── Core palette (verified in code, art-direction.md §2) ────────────
const INK = Color("#17293D")
const PAPER = Color("#FFF8DE")
const WARM_LIGHT = Color("#FFF2DE")
const STAR_GOLD = Color("#FFF1C8")
const EARTH_TERRACOTTA = Color("#B67552")

# Runtime-derived aliases (used by hud.gd for ink/paper constants)
const INK_RUNTIME = INK
const PAPER_RUNTIME = PAPER

# Supporting tones
const SKY_AMBIENT = Color("#E6EFFF")
const SUN_LIGHT = Color("#FFF8EF")
const STONE_COOL_1 = Color("#847D70")
const STONE_COOL_2 = Color("#849EB1")
const STONE_COOL_3 = Color("#9BB4B9")
const PARCHMENT_STEAM = Color(0.91, 0.89, 0.83, 0.12)

# ── Biome accents (art-direction.md §2) ─────────────────────────────
const BIOME_ACCENTS = {
	"verdant": {"leaf": Color("#9FBE8C"), "pine": Color("#51B899"), "island_orange": Color("#ECAB8A"), "petal": Color("#E8C4A0"), "blossom": Color("#F0D8B8")},
	"rose_dunes": {"petal": Color("#BB8CA7"), "blossom": Color("#F5E9C9"), "sand_trunk": Color("#E6D7BA")},
	"meadow": {"sage": Color("#9CAF76"), "fruit": Color("#E5AC95")},
	"snow": {"ice": Color("#8AB5B6"), "snow": Color("#E9F0E2"), "moon_glow": Color("#FFF2DB")},
	"ember_dusk": {"rock": Color("#947F7D"), "ember": Color("#E5A578"), "bark": Color("#B9886B")},
}

# ── Rarity colors ───────────────────────────────────────────────────
const RARITY_COLORS = {
	"Common": Color("#9E9E9E"),
	"Uncommon": Color("#4CAF50"),
	"Rare": Color("#2196F3"),
	"Epic": Color("#9C27B0"),
	"Legendary": Color("#FFC107"),
}

# Also expose the hex strings used by RunRules.COLORS array
const RARITY_HEX = ["#9E9E9E", "#4CAF50", "#2196F3", "#9C27B0", "#FFC107"]

# ── Typography ──────────────────────────────────────────────────────
const FONT_FAMILY_TITLE = "Baloo 2"
const FONT_FAMILY_BODY = "Nunito"
const FONT_FAMILY_FALLBACK = "sans-serif"

const TITLE_SIZES = {
	"mega": 52,    # main title (WILDFORGE)
	"large": 28,   # menu headers
	"medium": 21,  # section headers
	"small": 16,   # body text
	"tiny": 12,    # secondary detail
}

const BODY_SIZES = {
	"large": 20,   # numbers (gold, HP)
	"medium": 16,  # body text minimum
	"small": 14,   # captions
	"tiny": 12,    # footnotes
}

const FONT_WEIGHTS = {
	"regular": 0,
	"bold": 1,
}

# ── Spacing ─────────────────────────────────────────────────────────
const SPACING = {
	"xs": 4,
	"sm": 8,
	"md": 12,
	"lg": 22,
	"xl": 40,
}

# ── Border radii (art-direction.md §4, proposed) ────────────────────
const RADIUS = {
	"small": 3,   # existing buttons
	"medium": 8,  # cards
	"large": 12,  # panels
	"full": 22,   # modal panels
}

# ── Shadows ─────────────────────────────────────────────────────────
const SHADOW = {
	"color": Color(0.18, 0.12, 0.08, 0.24),
	"size": 4,
	"offset": Vector2(1, 2),
}

# ── Content margins (existing hud.gd defaults) ──────────────────────
const MARGINS = {
	"left": 12,
	"right": 12,
	"top": 7,
	"bottom": 7,
}

# ── Helper: build a StyleBoxFlat from tokens ────────────────────────
static func make_style(
	background: Color = PAPER_RUNTIME,
	border: Color = Color("b9a58a"),
	radius_key: String = "small"
) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	# Every UI surface is opaque; only the surface colour conveys selection.
	if background.get_luminance() < 0.3:
		box.bg_color = PAPER_RUNTIME
	else:
		box.bg_color = Color(background.r, background.g, background.b, 1)
	if border.a < 0.7:
		box.border_color = Color("b9a58a")
	else:
		box.border_color = Color(border.r, border.g, border.b, 1)
	box.set_border_width_all(1)
	box.border_width_bottom = 2
	box.shadow_color = SHADOW.color
	box.shadow_size = SHADOW.size
	box.shadow_offset = SHADOW.offset
	box.set_corner_radius_all(mini(radius_key if radius_key in RADIUS else RADIUS.small, 4))
	box.content_margin_left = MARGINS.left
	box.content_margin_right = MARGINS.right
	box.content_margin_top = MARGINS.top
	box.content_margin_bottom = MARGINS.bottom
	return box

# ── Helper: build a themed Label ────────────────────────────────────
static func make_label(
	text: String,
	size: int = 18,
	color: Color = INK_RUNTIME,
	font_family: String = FONT_FAMILY_BODY,
	weight: int = 0
) -> Label:
	var item = Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color.lerp(INK_RUNTIME, 0.65) if color.get_luminance() > 0.45 else color)
	item.add_theme_color_override("font_outline_color", Color("10272de0"))
	item.add_theme_constant_override("outline_size", 0)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

# ── Helper: build a themed Button ───────────────────────────────────
static func make_button(
	text: String,
	action: Callable,
	accent: bool = false,
	radius_key: String = "small"
) -> Button:
	var item = Button.new()
	item.text = text
	item.custom_minimum_size.y = 32
	item.add_theme_font_size_override("font_size", 16)
	var bg = Color("e3ba86") if accent else PAPER_RUNTIME
	item.add_theme_stylebox_override("normal", make_style(bg, Color("c8d9c23c"), radius_key))
	item.add_theme_stylebox_override("hover", make_style(Color("efd3a7"), Color("977657"), radius_key))
	item.add_theme_stylebox_override("pressed", make_style(Color("dcb48a"), Color("70543b"), radius_key))
	item.add_theme_stylebox_override("focus", make_style(Color("f4dfbf"), Color("c56c50"), radius_key))
	item.add_theme_color_override("font_color", INK_RUNTIME)
	item.add_theme_color_override("font_hover_color", INK_RUNTIME)
	item.add_theme_color_override("font_focus_color", INK_RUNTIME)
	item.add_theme_color_override("font_pressed_color", INK_RUNTIME)
	item.pressed.connect(action)
	return item
