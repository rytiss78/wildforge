extends RefCounted
class_name RunState

# Static state that belongs to one run, and the single place a new run clears it.
#
# Scripts keep run state in `static var`s (a carry off a launch pad, the time of
# the last trick shout, who is being spectated). A new run starts its clock at 0
# again, so anything left over from the last run misbehaves: a stale timestamp
# keeps a shout silent for minutes, an old carry keeps pushing the hero. Each of
# those was once forgotten in start_run()'s hand-written list.
#
# Every script with a `static var` is named in exactly one of the two tables
# below; run_state_checks.gd fails when one is missing, so a new static cannot
# be added without deciding which kind it is.

# Run state: cleared by reset_all(), or where the note says.
const RESET={
	"hero_play":"reset_all",
	"wrench_tune":"reset_all",
	"dropai":"reset_all",
	"clutch_play":"reset_all",
	"carry_rescue":"reset_all",
	"lasso":"reset_all",
	"climb_map":"reset_all",
	"hero_tricks":"reset_all",
	"spectate":"reset_all",
	"weapon_acts":"game.clear_entities() (WeaponActs.clear)",
	"mutation_book":"game.start_run() (MutationBook.reset, before the first weapon)",
}

# Not run state: caches of meshes, paints, sounds and data that stay valid for
# the whole session, settings, wall-clock timers and measurement counters.
const SHARED=[
	"actor_rig","biome_mechanics","cartoon_alien_rig","cartoon_book","cartoon_creature_rig","cartoon_mesh",
	"colossus_rig","combat_ink","combat_tactics","content_expansion","coop","creature_voice","crowd_mover",
	"death_fx","eclipse_corruption","effect_detail","event_loot","ground_cover","ground_ring","illustrated_icons",
	"labyrinth","lava","nature_scenery","painted_batch","pet","portal_fx","shot_fx","shot_shapes","skill_book",
	"spell_audio","stat_glyphs","status_fx","style_model","toon_art","treasure_chest","world",
]

static func reset_all(g):
	HeroPlay.start(g);WrenchTune.reset();Dropai.reset();ClutchPlay.reset();CarryRescue.reset();Lasso.reset()
	ClimbMap.reset();HeroTricks.reset();Spectate.reset()
