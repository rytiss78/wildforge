extends RefCounted
class_name CartoonCast

# Which StyleModel assets are generated in the cartoon style, and their ink width.
static func scene(asset: String) -> Node3D:
	if CartoonHeroes.has(asset): return CartoonHeroes.scene(asset)
	if CartoonWeapons.has(asset): return CartoonWeapons.scene(asset)
	if CartoonBosses.has(asset): return CartoonBosses.scene(asset)
	return null

static func outline_width(asset: String) -> float:
	return .02 if CartoonHeroes.has(asset) else .008 if CartoonWeapons.has(asset) else .012
