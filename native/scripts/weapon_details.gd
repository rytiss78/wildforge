extends RefCounted
class_name WeaponDetails

const MECHANICS = {
	"boomerang":"Throws a blade through enemies, then brings it back for another pass. Returning blades can hit the same enemy again.",
	"disc":"Fires a spinning disc that jumps between enemies. Extra bounces extend its route through the crowd.",
	"harpoon":"Launches a long, fast spear that runs through five more enemies. Normal enemies are pulled towards the impact; bosses resist the pull.",
	"gravity":"Creates a gravity well at the target. It pulls nearby enemies inward and damages them over time.",
	"horn":"Blasts a wide cone of sound. Enemies in front are pushed away and briefly stunned.",
	"bubble":"Traps an enemy in a floating bubble. The bubble slows it, then pops; bosses are slowed without being lifted.",
	"meteor":"Calls a falling meteor onto the target. A visible landing mark warns of the delayed explosion.",
	"bomb":"Drops mines behind you as you go. They arm, then blow up when an enemy comes close. Works best on the move.",
	"tornado":"Releases twisters that wander outward, drag enemies in and shred them. Ranks and Size make them bigger; extra shots add more twisters.",
	"blackhole":"Opens a black hole on the target that pulls everything nearby inward, then collapses in a big blast. Ranks and Size widen it.",
	"thunderstorm":"Calls lightning down on many nearby enemies in quick succession. Ranks and extra shots add strikes; Size widens each strike.",
	"inferno":"Sends a ring of fire sweeping outward from you, burning every enemy it passes. Ranks and Size push the ring much farther.",
	"gun":"Fires fast bullets at the nearest enemy. Extra shots fire more bullets; piercing cards carry them through enemies.",
	"shotgun":"Fires a fan of pellets, each a little weaker and stopped by the first enemy. Get close to land the whole burst on one enemy.",
	"flame":"A flamethrower: a short cone of fire in front of you, ticking fast. Enemies in it keep burning.",
	"poison":"Throws flasks that shatter into lingering poison clouds. Poison keeps hurting enemies while you move away.",
	"ice":"Fires chilling shots that slow enemies and can freeze them in place.",
	"rail":"A sniper shot: instant, across the whole reach, through every enemy in line. Line them up for the best result.",
	"lightning":"Bolts fall from the sky on enemies in reach and splash around them. Extra shots add bolts.",
	"saw":"Your arm stretches out and sweeps the blade through enemies ahead. Hits halfway through the swing, with 8 m starting reach. Range bonuses stretch it farther.",
	"rocket":"Fires homing rockets that turn after their target, find a new one if it dies, and explode.",
	"ghost":"Sends a ghost that blinks from enemy to enemy, through walls. Extra shots and piercing add hops.",
	"flowers":"Walking plants flowers. Mature flowers root enemies, spread harmful pollen and heal you nearby. Blooms wake neighbouring flowers.",
	"turret":"Deploy one stationary gun turret. It automatically shoots nearby enemies; deploy again to move it.",
	"fire-turret":"Deploy one turret that shoots burning rounds. Move it by deploying again; fire keeps hurting enemies after a hit.",
	"pulse-turret":"Deploy one turret that thumps out a pulse, knocking enemies in its ring away and hurting them a little. Deploy again to move it.",
	"heal-turret":"Deploy one turret that heals you while you stand in its green ring. Turret cards make it heal more, more often and wider.",
	"lightning-turret":"Deploy one turret whose shots jump electricity between enemies. Deploy again to move it.",
	"rocket-turret":"Deploy one turret that fires explosive rounds into crowds. Deploy again to move it.",
	"halo":"A constant damage field around you. Size widens it.",
	"orbit-lids":"Pot lids circle you and knock back what they touch. Extra shots add lids.",
	"fire-trail":"You leave burning footprints as you move. Enemies in them catch fire.",
	"frost-trail":"You leave icy footprints as you move. Enemies in them slow down, then freeze.",
	"dice":"Throws a die: damage times the roll, and a six explodes.",
	"blood-pump":"Pulses out blasts that spend a little of your health for big damage.",
	"whip":"A long noodle whip across a wide cone. The tip hits harder.",
	"snip-knife":"Very fast short slashes that finish off weak enemies.",
	"katana":"A long narrow slash with extra critical hit chance.",
	"scythe":"A sweep almost all the way around you.",
	"hero-blade":"A slash that also throws a flying wave of light.",
	"grudge-blade":"Slashes in front and behind, stronger with every kill this run."
}

static func describe(id: String) -> String:
	var item=ContentExpansion.weapon(id)
	if item.has("archetype"): return str(item.description)+" "+str(MECHANICS.get(item.archetype,""))
	return MECHANICS.get(id,"Automatically attacks nearby enemies with your collected shot powers.")
