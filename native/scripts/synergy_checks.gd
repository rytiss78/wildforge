extends RefCounted

# Spell–mutation synergies through real casts: each spell is fired by the weapon
# path at a ring of tough dummies and ticked by update_combat, once with the
# matching strain carried and once without (the control).
static func dummies(game: Node3D):
	game.clear_entities();game.spawn_clock=1e9
	# Earlier checks leave the hero in the air; spells land on the ground around them.
	game.player.position=Vector3(0,game.world.height_at(0,0)+.1,0);game.player.velocity=Vector3.ZERO
	for i in range(8):
		game.spawn_enemy(6);var enemy=game.enemies[-1]
		var p=game.player.position+Vector3.FORWARD.rotated(Vector3.UP,TAU*i/8.0)*(2.5+i%2*1.5);p.y=game.world.height_at(p.x,p.z)
		enemy.node.position=p;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e6;enemy.maxHp=1e6;enemy.boss=false;enemy.behavior="chase";enemy.home=p

static func cast(game: Node3D,kind: String,mutations: Array,frames: int=150) -> Dictionary:
	dummies(game)
	for list in [game.pools,game.skills]:
		for item in list:
			if is_instance_valid(item.get("node")): item.node.queue_free()
		list.clear()
	game.equipped.clear();MutationBook.reset(game);game.owned.clear()
	for id in mutations: MutationBook.take(game,MutationBook.card(id,1))
	var item=game.rules.data.weapons.filter(func(w):return w.id==kind)[0].duplicate(true);item.kind="weapon";item.strength=1.0
	game.equip_weapon(item);var weapon=game.equipped[0];weapon.clock=-1e9
	game.events.announcement=""
	game.fire(weapon,game.player.position+Vector3.UP)
	# Exactly one cast: the weapon clock must not fire another during the frames below.
	game.equipped.clear()
	var frozen=0
	for i in range(frames):
		game.update_combat(1.0/60.0)
		frozen=maxi(frozen,game.enemies.filter(func(e):return float(e.freeze)>0).size())
	return {"burning":game.enemies.filter(func(e):return float(e.fire)>0).size(),"burn":game.enemies.reduce(func(sum,e):return sum+float(e.fire),0.0),"frozen":frozen,"pools":game.pools.size(),
		"seen":game.mutation_state.get("synergies",{}).duplicate(),"announcement":str(game.events.get("announcement","")),"cooldowns":game.mutation_state.cooldowns.duplicate()}

static func run(game: Node3D) -> Dictionary:
	var checks={}
	game.hud.close();game.mode="playing";game.invulnerable=1e9
	# Spell hits fire "on hit" mutations (20% chance, 0.3 s cooldown): five casts at eight enemies.
	var triggered=false
	for attempt in range(5):
		var result=cast(game,"inferno",["storm_hit"],70)
		triggered=triggered or result.cooldowns.has("storm_hit")
	checks.spell_hits_trigger_mutations=triggered
	var plain=cast(game,"inferno",[])
	var firestorm=cast(game,"inferno",["ember_dash"])
	# The halo alone already ignites; Firestorm doubles the burn and adds the ring of eruptions.
	checks.synergy_firestorm=plain.burning>=4 and firestorm.burn>plain.burn*1.8 and int(firestorm.seen.get("inferno:ember",0))>=2 and not plain.seen.has("inferno:ember")
	checks.synergy_announced=firestorm.announcement=="SPELL SYNERGY · FIRESTORM"
	# Healing beyond what an ordinary cast (regen) gives, capped at 3 per cast.
	game.hp=game.stats.maxHp*.5;var before=game.hp
	cast(game,"inferno",["bloom_dash"]);var phoenix_hp=game.hp-before
	game.hp=game.stats.maxHp*.5;before=game.hp
	cast(game,"inferno",[]);var control_hp=game.hp-before
	checks.synergy_phoenix_ring=phoenix_hp-control_hp>=1.0 and phoenix_hp-control_hp<=3.05
	var crown=cast(game,"thunderstorm",[],60)
	var hail=cast(game,"thunderstorm",["frost_dash"],60)
	checks.synergy_hailstorm=crown.frozen==0 and hail.frozen>=2 and hail.seen.has("thunderstorm:frost")
	var cell=cast(game,"thunderstorm",["storm_dash"],60)
	checks.synergy_supercell=cell.seen.has("thunderstorm:storm") and not crown.seen.has("thunderstorm:storm")
	var orb=cast(game,"blackhole",[],200)
	var well=cast(game,"blackhole",["venom_dash"],200)
	checks.synergy_plague_well=well.pools>orb.pools and well.seen.has("blackhole:venom")
	var collapsar=cast(game,"blackhole",["comet_dash"],200)
	checks.synergy_collapsar=collapsar.seen.has("blackhole:comet") and is_equal_approx(SpellSynergy.collapse_scale(game),1.5)
	var twister=cast(game,"tornado",[],120)
	var whirl=cast(game,"tornado",["ember_dash"],120)
	checks.synergy_fire_whirl=twister.burning==0 and whirl.burning>=1 and whirl.seen.has("tornado:ember")
	var cyclone=cast(game,"tornado",["venom_dash"],120)
	checks.synergy_toxic_cyclone=cyclone.pools>twister.pools and cyclone.seen.has("tornado:venom")
	# Cards name the synergy: a mutation card with a spell equipped, and a spell card
	# with the strain carried; the build menu lists the active ones.
	game.equipped.clear();MutationBook.reset(game)
	var inferno=game.rules.data.weapons.filter(func(w):return w.id=="inferno")[0].duplicate(true);inferno.kind="weapon";inferno.strength=1.0
	game.equip_weapon(inferno)
	checks.synergy_mutation_card=UpgradeFit.describe(game,MutationBook.card("ember_kill",1)).text.contains("SPELL SYNERGY · Firestorm with Inferno Halo")
	MutationBook.take(game,MutationBook.card("ember_kill",1));game.equipped.clear()
	var offers=[inferno.duplicate(true)];offers[0].tier=1
	game.offers=offers;game.mode="offer";game.offer_kind="weapon";game.offer_source="level";game.hud.show_offers(offers,"level",false)
	checks.synergy_spell_card=game.hud.cards[0].tooltip_text.contains("SPELL SYNERGY · Firestorm")
	game.hud.close();game.equip_weapon(inferno);game.hud.build_menu(true)
	checks.synergy_build_menu=game.hud.find_children("*","Label",true,false).any(func(l):return l.text.begins_with("Firestorm · Inferno Halo + Ember"))
	game.hud.close();game.mode="playing";game.equipped.clear();MutationBook.reset(game);game.clear_entities();game.invulnerable=0.0
	# Spell sounds: each spell casts its own sound (not a borrowed generic one),
	# every sound is audible without clipping, and the two loops loop.
	var audible=true
	for id in ["spell_tornado","spell_blackhole","spell_collapse","spell_thunderstorm","spell_strike","spell_inferno"]:
		var audio=SpellAudio.cast(id);var peak=0.0
		for i in range(0,audio.data.size()/2,7): peak=maxf(peak,absf(audio.data.decode_s16(i*2))/32767.0)
		audible=audible and audio.data.size()>RATE_BYTES*.3 and peak>.15 and peak<.96
	checks.spell_sounds_audible=audible
	checks.spell_sounds_own=SkillBook.KINDS.all(func(kind):return SkillBook.sound(kind)=="spell_"+kind)
	checks.spell_loops=["tornado","blackhole"].all(func(kind):return SpellAudio.loop(kind).loop_mode==AudioStreamWAV.LOOP_FORWARD and SpellAudio.loop(kind).loop_end>SpellAudio.RATE)
	return checks

const RATE_BYTES=SpellAudio.RATE*2
