extends RefCounted
class_name WeaponDetails

const MECHANICS = {
	"boomerang":"Throws a blade through enemies, then brings it back for another pass. Returning blades can hit the same enemy again.",
	"disc":"Fires a spinning disc that jumps between enemies. Extra bounces extend its route through the crowd.",
	"harpoon":"Launches a piercing hook. Normal enemies are pulled towards the impact; bosses resist the pull.",
	"gravity":"Creates a gravity well at the target. It pulls nearby enemies inward and damages them over time.",
	"horn":"Blasts a wide cone of sound. Enemies in front are pushed away and briefly stunned.",
	"bubble":"Traps an enemy in a floating bubble. The bubble slows it, then pops; bosses are slowed without being lifted.",
	"meteor":"Calls a falling meteor onto the target. A visible landing mark warns of the delayed explosion.",
	"bomb":"Rolls a bomb towards the target. It explodes when its fuse ends or it reaches an enemy.",
	"gun":"Automatically aims at the nearest enemy and fires a single bullet. A reliable base for extra shots and piercing powers.",
	"shotgun":"Fires three pellets in a wide fan. Get close to land the whole burst on one enemy.",
	"flame":"Fires burning shots. Enemies keep taking fire damage after the hit.",
	"poison":"Fires toxic shots that poison enemies. Poison keeps hurting them while you move away.",
	"ice":"Fires chilling shots that slow enemies and can freeze them in place.",
	"rail":"Fires a piercing shot through a long line of enemies. Line them up for the best result.",
	"lightning":"Hits an enemy and jumps electricity to nearby enemies. Best against groups.",
	"saw":"Your arm stretches out and sweeps the blade through enemies ahead. Hits halfway through the swing, with 8 m starting reach. Range bonuses stretch it farther.",
	"rocket":"Fires explosive shots. Each hit also hurts enemies around the target.",
	"ghost":"Automatically fires spirit shots at nearby enemies. Your collected shot powers also affect these spirits.",
	"flowers":"Walking plants flowers. Mature flowers root enemies, spread harmful pollen and heal you nearby. Blooms wake neighbouring flowers.",
	"turret":"Deploy one stationary gun turret. It automatically shoots nearby enemies; deploy again to move it.",
	"fire-turret":"Deploy one turret that shoots burning rounds. Move it by deploying again; fire keeps hurting enemies after a hit.",
	"ice-turret":"Deploy one turret that slows enemies and can freeze them. Deploy again to move it.",
	"poison-turret":"Deploy one turret that poisons enemies. Deploy again to move your toxic firing position.",
	"lightning-turret":"Deploy one turret whose shots jump electricity between enemies. Deploy again to move it.",
	"rocket-turret":"Deploy one turret that fires explosive rounds into crowds. Deploy again to move it."
}

static func describe(id: String) -> String:
	var item=ContentExpansion.weapon(id)
	if item.has("archetype"): return str(item.description)+" "+str(MECHANICS.get(item.archetype,""))
	return MECHANICS.get(id,"Automatically attacks nearby enemies with your collected shot powers.")
