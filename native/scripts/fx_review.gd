extends RefCounted

# Rendered weapon-effect review: every weapon archetype in flight and on impact,
# then enemy status effects. Writes three contact sheets (four columns, order in
# the printed JSON) for visual inspection; checks only prove the real fire/hit
# paths ran and that effects expire.

const KINDS=["gun","shotgun","rail","harpoon","flame","poison","ice","lightning","rocket","ghost","bubble","boomerang","disc","bomb","saw","horn","meteor","gravity"]
const CELL=Vector2i(480,270)

static func frame(g: Node3D,full: bool=false) -> Image:
	await RenderingServer.frame_post_draw
	var image=g.get_viewport().get_texture().get_image()
	# The action sits between the hero and the dummies, in the middle of the screen.
	var size=Vector2(image.get_size())
	if not full: image=image.get_region(Rect2i(Vector2i(size*Vector2(.36,.2)),Vector2i(size*.5)))
	image.resize(CELL.x,CELL.y,Image.INTERPOLATE_LANCZOS)
	return image

static func step(g: Node3D,frames: int):
	for i in range(frames):
		g.elapsed+=1.0/60.0;g.realm_time+=1.0/60.0;g.update_combat(1.0/60.0);g._process(1.0/60.0)
		await g.get_tree().process_frame

static func sheet(images: Array,name: String) -> bool:
	var columns=4;var rows=ceili(images.size()/float(columns))
	var board=Image.create(CELL.x*columns,CELL.y*rows,false,Image.FORMAT_RGBA8);board.fill(Color("101014"))
	for i in range(images.size()):
		var image: Image=images[i];image.convert(Image.FORMAT_RGBA8)
		board.blit_rect(image,Rect2i(Vector2i.ZERO,CELL),Vector2i(i%columns*CELL.x,i/columns*CELL.y))
	return board.save_png("user://fx-"+name+".png")==OK

static func clear_effects(g: Node3D):
	for list in [g.effects,g.projectiles,g.pools,g.hazards]:
		for item in list:
			if is_instance_valid(item.get("node")): item.node.queue_free()
		list.clear()
	g.melee_attacks.clear()

static func total_hp(g: Node3D) -> float:
	var sum=0.0
	for enemy in g.enemies: sum+=enemy.hp
	return sum

static func run(g: Node3D):
	if DisplayServer.get_name()=="headless": g.get_tree().quit(1);return
	AudioServer.set_bus_volume_db(0,-80);g.hud.menu_start.pressed.emit()
	g.start_run(407);g.invulnerable=1e9;g.spawn_clock=1e9;g.formation_clock=1e9;g.xp_target=1e9
	for i in range(120): await g.get_tree().process_frame
	g.set_physics_process(false);g.set_process(false)
	for enemy in g.enemies: enemy.node.queue_free()
	g.enemies.clear()
	var forward=-g.camera.global_basis.z;forward.y=0;forward=forward.normalized();var side=forward.cross(Vector3.UP)
	for i in range(5):
		g.spawn_enemy(12+i);var enemy=g.enemies[-1]
		# A group off to the side, so shots cross the screen instead of flying into it.
		var p=g.player.position+forward*(4.0+float(i%2)*1.6)+side*(6.5+(i-2)*1.5);p.y=g.world.height_at(p.x,p.z)
		enemy.node.position=p;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e6;enemy.maxHp=1e6
		enemy.node.look_at(Vector3(g.player.position.x,p.y,g.player.position.z))
	clear_effects(g);await step(g,30)
	var weapons={}
	for weapon in g.rules.data.weapons: weapons[weapon.id]=weapon
	var flights=[];var impacts=[];var checks={}
	for kind in KINDS:
		for weapon in g.equipped:
			if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
		g.equipped.clear()
		var item=weapons[kind].duplicate(true);item.kind="weapon";item.strength=1.0;g.equip_weapon(item)
		var weapon=g.equipped[-1];weapon.clock=1e9
		for enemy in g.enemies: enemy.fire=0.0;enemy.poison=0.0;enemy.freeze=0.0;enemy.slow=0.0;enemy.status_time=0.0;enemy.bubble=0.0
		clear_effects(g);await step(g,12)
		var before=total_hp(g)
		g.fire(weapon,g.player.position+Vector3.UP*.9)
		# Shots start behind the hero's body from this camera; capture them mid-way.
		var flown=0
		while flown<24 and total_hp(g)>=before and not g.projectiles.any(func(p):return Vector2(p.node.position.x-g.player.position.x,p.node.position.z-g.player.position.z).length()>3.6):
			await step(g,1);flown+=1
		if flown<3: await step(g,3)
		flights.append(await frame(g))
		var waited=0
		while total_hp(g)>=before and waited<90: await step(g,1);waited+=1
		await step(g,2);impacts.append(await frame(g))
		checks[kind+"_hit"]=total_hp(g)<before
	# Evolved shots beside the plain ones (pairs: plain, evolved), then the held
	# evolved weapon's halo up close.
	var evolved=[]
	for kind in ["gun","rail","flame","rocket"]:
		for evolve in [false,true]:
			for weapon in g.equipped:
				if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
			g.equipped.clear()
			var item=weapons[kind].duplicate(true);item.kind="weapon";item.strength=1.0;g.equip_weapon(item)
			var weapon=g.equipped[-1];weapon.clock=1e9
			if evolve: weapon.rank=WeaponEvolution.RANK;WeaponEvolution.apply(g,{"weapon_id":kind});g.events.announcement_until=0.0
			clear_effects(g);await step(g,12)
			g.fire(weapon,g.player.position+Vector3.UP*.9)
			var flown=0
			while flown<24 and not g.projectiles.any(func(p):return Vector2(p.node.position.x-g.player.position.x,p.node.position.z-g.player.position.z).length()>3.6):
				await step(g,1);flown+=1
			evolved.append(await frame(g))
			checks["evolved_"+kind]=not evolve or g.projectiles.all(func(p):return p.get("evolved",false))
	for i in range(40):
		for model in g.avatar.held: model.tick(1.0/60.0)
		await step(g,1)
	checks.evolved_halo=not g.avatar.held.is_empty() and g.avatar.held[0].halo!=null and g.avatar.held[0].halo.visible
	var close=g.get_viewport().get_texture().get_image();var size=Vector2(close.get_size())
	await RenderingServer.frame_post_draw;close=g.get_viewport().get_texture().get_image()
	close=close.get_region(Rect2i(Vector2i(size*Vector2(.40,.38)),Vector2i(size*Vector2(.2,.2))));close.resize(CELL.x,CELL.y,Image.INTERPOLATE_LANCZOS);evolved.append(close)
	checks.evolved_sheet=sheet(evolved,"evolved")
	# Weapons with their own projectile shape: the Ninja's Moon Shuriken throws stars.
	var shapes=[]
	for weapon in g.equipped:
		if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
	g.equipped.clear()
	var star_item=weapons["ninja-shuriken"].duplicate(true);star_item.kind="weapon";star_item.strength=1.0;g.equip_weapon(star_item)
	var star_weapon=g.equipped[-1];star_weapon.clock=1e9
	clear_effects(g);await step(g,12);g.fire(star_weapon,g.player.position+Vector3.UP*.9)
	for i in range(6): await step(g,1)
	shapes.append(await frame(g))
	checks.shuriken_shape=not g.projectiles.is_empty() and g.projectiles.all(func(p):return p.node.mesh==ShotShapes.mesh("ninja-shuriken"))
	await step(g,4);shapes.append(await frame(g))
	checks.shapes_sheet=sheet(shapes,"shapes")
	for weapon in g.equipped:
		if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
	g.equipped.clear()
	clear_effects(g)
	# Statuses: burning, poisoned, frozen, blinded, burning+poisoned; then an Ember burst
	# setting the whole group alight, the moment it lands and as it spreads.
	var statuses=[]
	var setups=[["fire"],["poison"],["freeze"],["blind"],["fire","poison"]]
	for i in range(g.enemies.size()):
		for key in setups[i]: g.enemies[i][key]=3.0 if key in ["freeze","blind"] else 6.0
		g.enemies[i].status_time=6.0
	await step(g,20);statuses.append(await frame(g))
	await step(g,30);statuses.append(await frame(g))
	for enemy in g.enemies: enemy.fire=0.0;enemy.poison=0.0;enemy.freeze=0.0;enemy.blind=0.0;enemy.status_time=0.0
	await step(g,20)
	var center=Vector3.ZERO
	for enemy in g.enemies: center+=enemy.node.position/g.enemies.size()
	g.damage_area(center,5.0,1.0,"fire");await step(g,2);statuses.append(await frame(g))
	await step(g,20);statuses.append(await frame(g))
	checks.ignited=g.enemies.all(func(e):return e.fire>0)
	for enemy in g.enemies: enemy.fire=0.0;enemy.status_time=0.0
	g.damage_area(center,5.0,1.0,"poison");await step(g,2);statuses.append(await frame(g))
	await step(g,20);statuses.append(await frame(g))
	checks.poisoned=g.enemies.all(func(e):return e.poison>0)
	for enemy in g.enemies: enemy.hp=1.0
	g.damage_area(center,5.0,10.0,"fire");await step(g,3);statuses.append(await frame(g))
	await step(g,20);statuses.append(await frame(g))
	# Skills: each mutation strain bursting on the group, the slam wave, and the hero
	# being struck on health and on a shield.
	var skills=[]
	await step(g,150)
	for enemy in g.enemies:
		if is_instance_valid(enemy.node): enemy.node.queue_free()
	g.enemies.clear()
	for i in range(5):
		g.spawn_enemy(12+i);var enemy=g.enemies[-1]
		var p=g.player.position+forward*(4.0+float(i%2)*1.6)+side*(6.5+(i-2)*1.5);p.y=g.world.height_at(p.x,p.z)
		enemy.node.position=p;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e6;enemy.maxHp=1e6
	center=Vector3.ZERO
	for enemy in g.enemies: center+=enemy.node.position/g.enemies.size()
	for strain in MutationBook.STRAIN_ORDER:
		clear_effects(g);await step(g,6)
		MutationBook.release(g,strain,center,1.0,g.enemies[2])
		await step(g,5);skills.append(await frame(g))
	clear_effects(g);await step(g,6)
	g.player.position=center-forward*1.5;g.slam_wave();await step(g,5);skills.append(await frame(g))
	g.player.position=center-side*6.5-forward*4.0
	for shielded in [false,true]:
		clear_effects(g);await step(g,30)
		g.invulnerable=0.0;g.shield_hp=1000.0 if shielded else 0.0
		g.take_damage(5.0,g.enemies[0].node.position);await step(g,4);skills.append(await frame(g))
		checks["hero_hit_shield" if shielded else "hero_hit"]=g.effects.any(func(e):return e.get("ink_fx",false))
		g.invulnerable=1e9;g.hp=g.stats.maxHp
	# Co-op combo effects as every player sees them.
	for kind in ["crossfire","overload"]:
		clear_effects(g);await step(g,20)
		PartyCombo.visual(g,kind,g.enemies[1].node.position);await step(g,4);skills.append(await frame(g))
	# Elite modifier badges (and the shield bubble) on four of the dummies.
	clear_effects(g)
	for i in range(EliteMods.ORDER.size()): EliteMods.assign(g,g.enemies[i],EliteMods.ORDER[i])
	await step(g,10);skills.append(await frame(g))
	# Spells (SkillBook): each cast through the real fire path at rank 1 and rank 9,
	# into a 24-enemy crowd around the hero, plus the Void Orb's collapse at rank 9.
	var spells=[]
	await step(g,150)
	for enemy in g.enemies:
		if is_instance_valid(enemy.node): enemy.node.queue_free()
	g.enemies.clear()
	g.player.position=center-side*6.5-forward*4.0
	for i in range(24):
		g.spawn_enemy(12+i%5);var enemy=g.enemies[-1]
		var p=g.player.position+forward.rotated(Vector3.UP,i*2.39996)*(4.0+float(i)*.45);p.y=g.world.height_at(p.x,p.z)
		enemy.node.position=p;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e6;enemy.maxHp=1e6
	var timing={"tornado":45,"blackhole":60,"thunderstorm":14,"inferno":28}
	for kind in SkillBook.KINDS:
		for rank in [1,9]:
			for weapon in g.equipped:
				if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
			g.equipped.clear();clear_effects(g)
			for spell in g.skills:
				if is_instance_valid(spell.node): spell.node.queue_free()
			g.skills.clear()
			var item=weapons[kind].duplicate(true);item.kind="weapon";item.strength=1.0
			for i in range(rank): g.equip_weapon(item)
			var weapon=g.equipped[-1];weapon.clock=1e9
			await step(g,10)
			var before=total_hp(g)
			g.fire(weapon,g.player.position+Vector3.UP*.9)
			checks[kind+"_cast_r"+str(rank)]=not g.skills.is_empty()
			await step(g,timing[kind]);spells.append(await frame(g,true))
			if kind=="blackhole" and rank==9:
				await step(g,160-timing[kind]);spells.append(await frame(g,true))
			await step(g,60)
			checks[kind+"_hurts_r"+str(rank)]=total_hp(g)<before
	# Spell synergies: each spell at rank 5 with the matching strain carried, captured
	# where its synergy shows (Firestorm's eruption ring, Collapsar's and Plague
	# Well's collapse, Supercell's forks and Hailstorm's frost, the twisters' trails).
	var synergies=[];var synergy_cells=[]
	var moments={"inferno":58,"blackhole":163,"thunderstorm":18,"tornado":80}
	for kind in SkillBook.KINDS:
		for strain in SpellSynergy.PAIRS[kind]:
			for weapon in g.equipped:
				if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
			g.equipped.clear();clear_effects(g)
			for spell in g.skills:
				if is_instance_valid(spell.node): spell.node.queue_free()
			g.skills.clear();MutationBook.reset(g);MutationBook.take(g,MutationBook.card(strain+"_dash",1))
			for enemy in g.enemies: enemy.fire=0.0;enemy.poison=0.0;enemy.freeze=0.0;enemy.status_time=0.0
			var item=weapons[kind].duplicate(true);item.kind="weapon";item.strength=1.0
			for i in range(5): g.equip_weapon(item)
			var weapon=g.equipped[-1];weapon.clock=1e9;g.events.announcement_until=0.0
			await step(g,10);g.fire(weapon,g.player.position+Vector3.UP*.9);g.equipped.clear()
			await step(g,moments[kind]);synergies.append(await frame(g,true));synergy_cells.append(SpellSynergy.PAIRS[kind][strain].name)
			checks["synergy_"+kind+"_"+strain]=g.mutation_state.get("synergies",{}).has(kind+":"+strain)
			await step(g,60)
	MutationBook.reset(g)
	checks.synergy_sheet=sheet(synergies,"synergies")
	# Deaths: creature styles (plain hit, poison; October 29, they replaced the ink
	# dissolve for creatures) and shatter (frost, crit), each early and late in the
	# effect; then everything must clean up.
	var deaths=[];var dissolving=false
	for enemy in g.enemies:
		if is_instance_valid(enemy.node): enemy.node.queue_free()
	g.enemies.clear();g.skills.clear();clear_effects(g);await step(g,20)
	var victims=[]
	for i in range(4):
		g.spawn_enemy(12);var enemy=g.enemies[-1]
		var p=g.player.position+forward*6.0+side*(float(i)-1.5)*2.6;p.y=g.world.height_at(p.x,p.z)
		enemy.node.position=p;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e6;enemy.maxHp=1e6;enemy.fire=0.0;enemy.poison=0.0;enemy.freeze=0.0;enemy.status_time=0.0
		enemy.node.look_at(Vector3(g.player.position.x,p.y,g.player.position.z));victims.append(enemy)
	await step(g,20)
	var causes=["hit","poison","ice","crit"]
	for i in range(4):
		var victim=victims[i];var cause=causes[i];var spot: Vector3=victim.node.position+Vector3.UP*.8
		g.kill_enemy(victim,cause)
		for moment in [8,16]:
			await step(g,moment)
			await RenderingServer.frame_post_draw
			var image=g.get_viewport().get_texture().get_image();var shot_size=Vector2(image.get_size())
			# The camera projects in viewport units; the captured image may be smaller.
			var at=g.camera.unproject_position(spot)*shot_size/g.get_viewport().get_visible_rect().size-Vector2(shot_size.x*.14,shot_size.y*.17)
			at=at.clamp(Vector2.ZERO,shot_size*.72);image=image.get_region(Rect2i(Vector2i(at),Vector2i(shot_size*Vector2(.28,.34))));image.resize(CELL.x,CELL.y,Image.INTERPOLATE_LANCZOS);deaths.append(image)
			if moment==8:
				checks["death_"+cause]=g.death_fx.any(func(e):return (e.kind=="shard") if cause in ["ice","crit"] else DeathFx.STYLE_LIFE.has(e.kind))
	await step(g,150)
	# The four creature styles side by side (pop, deflate, melt, splat), each
	# victim given a species whose voice has that style.
	var style_models={"pop":"creature_0_3","deflate":"creature_1_3","melt":"creature_1_9","splat":"creature_0_0"}
	var styled=[];var seen={}
	for style in style_models:
		g.spawn_enemy(12);var enemy=g.enemies[-1]
		var p=g.player.position+forward*6.0+side*(float(styled.size())-1.5)*2.6;p.y=g.world.height_at(p.x,p.z)
		enemy.node.position=p;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e6;enemy.maxHp=1e6;enemy.freeze=0.0;enemy.model=style_models[style]
		styled.append(enemy)
	await step(g,20)
	for enemy in styled: g.kill_enemy(enemy,"hit")
	for e in g.death_fx: seen[e.kind]=true
	for moment in [5,12,28]:
		await step(g,moment);deaths.append(await frame(g,true))
		for e in g.death_fx:
			if e.kind=="splat" and e.paint!=null and float(e.paint.get_shader_parameter("dissolve"))>0.1: dissolving=true
	checks.death_styles=style_models.keys().all(func(k):return seen.has(k))
	checks.death_dissolve_shader=dissolving
	await step(g,150)
	checks.death_cleanup=g.death_fx.is_empty()
	checks.death_sheet=sheet(deaths,"deaths")
	# Fight zoom: the same spot with a calm field, then with a 40-enemy crowd.
	var zoom_cells=[];g.fight_zoom=1.0;g.fight_zoom_target=1.0
	await step(g,30);zoom_cells.append(await frame(g,true))
	for i in range(40):
		g.spawn_enemy(8);var enemy=g.enemies[-1];var p=g.player.position+forward.rotated(Vector3.UP,i*.7)*(3.0+i*.22);p.y=g.world.height_at(p.x,p.z)
		enemy.node.position=p;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e6;enemy.maxHp=1e6
	await step(g,240);zoom_cells.append(await frame(g,true))
	checks.fight_zoom_out=g.fight_zoom>1.15
	checks.zoom_sheet=sheet(zoom_cells,"zoom")
	# Telegraphs: four attack styles share the danger red (their own colour stays as
	# the fill), mid-countdown and in the final flash; a charge lane; a bite windup.
	for enemy in g.enemies:
		if is_instance_valid(enemy.node): enemy.node.queue_free()
	g.enemies.clear();g.fight_zoom=1.0;g.fight_zoom_target=1.0;clear_effects(g);await step(g,40)
	var telegraphs=[]
	var styles=["toxic","lava","void","storm"]
	for i in range(4): g.warn_at(g.player.position+forward*6.0+side*(float(i)-1.5)*3.2,1.4,1.6,0.0,styles[i],true)
	await step(g,40);telegraphs.append(await frame(g,true))
	await step(g,44);telegraphs.append(await frame(g,true))
	checks.telegraph_flash=g.hazards.all(func(h):return float(h.node.material_override.get_shader_parameter("progress"))>float(h.node.material_override.get_shader_parameter("flash_from")))
	checks.telegraph_danger_ink=g.hazards.all(func(h):return h.node.material_override.get_shader_parameter("ink").is_equal_approx(DangerMark.DANGER))
	await step(g,30)
	g.spawn_enemy(8);var charger=g.enemies[-1];var c=g.player.position+forward*9.0;c.y=g.world.height_at(c.x,c.z)
	charger.node.position=c;charger.speed=0.0;charger.hp=1e6;charger.maxHp=1e6;charger.windup=.8;charger.charge_direction=(g.player.position-c).normalized();charger.charge_length=10.0;charger.attack=99.0
	for i in range(20): preload("res://scripts/combat_tactics.gd").charge_movement(g,charger,charger.charge_direction,9.0,1.0/60.0);await step(g,1)
	telegraphs.append(await frame(g,true))
	checks.telegraph_charge_lane=is_instance_valid(charger.get("charge_lane"))
	charger.windup=0.0;preload("res://scripts/combat_tactics.gd").charge_movement(g,charger,charger.charge_direction,9.0,1.0/60.0)
	checks.telegraph_lane_cleared=not charger.has("charge_lane")
	charger.contact_windup=.4;preload("res://scripts/combat_tactics.gd").contact_warning(charger);charger.node.position=g.player.position+forward*3.0
	await step(g,2);telegraphs.append(await frame(g,true))
	checks.telegraph_sheet=sheet(telegraphs,"telegraphs")
	# Rift Dash (October 26) through the real dash: a portal ring at each end of the
	# jump, seen just after and a moment later.
	for enemy in g.enemies:
		if is_instance_valid(enemy.node): enemy.node.queue_free()
	g.enemies.clear();clear_effects(g);await step(g,20)
	var rifts=[];var rift_start=g.player.position
	g.stats.riftDash=1.0;g.dash_cooldown=0.0;g.direction=side;g.dash()
	var rings=g.effects.filter(func(e):return e.node is MeshInstance3D and e.node.mesh is TorusMesh).size()
	await step(g,2);rifts.append(await frame(g,true))
	await step(g,14);rifts.append(await frame(g,true))
	checks.rift_portals=rings==2 and Vector2(g.player.position.x-rift_start.x,g.player.position.z-rift_start.z).length()>=4.0
	await step(g,40)
	checks.rift_portals_fade=not g.effects.any(func(e):return is_instance_valid(e.node) and e.node is MeshInstance3D and e.node.mesh is TorusMesh)
	checks.rift_sheet=sheet(rifts,"rift");g.stats.riftDash=0.0
	# Red barrels (October 29): a pair in view, then the shot one and its chain.
	if g.barrels.size()<2: ExplosiveBarrels.setup(g)
	var keg=g.barrels[0];var keg_two=g.barrels[1]
	var keg_at=g.player.position+forward*7.0;keg_at.y=g.world.height_at(keg_at.x,keg_at.z)
	keg.node.position=keg_at;keg_two.node.position=keg_at+side*2.4;keg_two.node.position.y=g.world.height_at(keg_two.node.position.x,keg_two.node.position.z)
	await step(g,6);var kegs=[await frame(g,true)]
	g.invulnerable=1e9;ExplosiveBarrels.shot(g,keg_at+Vector3(-2,.6,0),keg_at+Vector3(2,.6,0))
	await step(g,8);kegs.append(await frame(g,true))
	await step(g,8);kegs.append(await frame(g,true))
	await step(g,10);kegs.append(await frame(g,true))
	checks.barrel_chain=not g.barrels.has(keg) and not g.barrels.has(keg_two)
	checks.barrel_sheet=sheet(kegs,"barrels")
	# The co-op rescue code (October 29) beside a downed friend, two arrows in.
	var friend=990;g.coop.members[friend]={"position":CoopSession.array(g.player.position+side*1.5),"hp":0.0}
	g.update.downed_ids[friend]=true;g.update.rescue_interrupt_until=-1.0;g.update.rescue_tick(1.0/60.0)
	for i in range(2): g.hud.rescue_code.press(g.hud.rescue_code.code[i])
	await step(g,2);checks.rescue_code_shown=g.hud.rescue_code.visible;checks.rescue_sheet=sheet([await frame(g,true)],"rescue")
	g.coop.members.erase(friend);g.update.downed_ids.erase(friend);g.update.rescue_tick(1.0/60.0)
	# Pets (October 29): the three species at stages 1-3, in rows, plus the hero's own.
	clear_effects(g);await step(g,90)
	var lineup=Node3D.new();g.add_child(lineup)
	for k in range(3):
		for st in range(3):
			var pet_model=Pet.build(Pet.KINDS[k],st);lineup.add_child(pet_model)
			var at=g.player.position+forward*(2.5+k*1.5)+side*((st-1)*1.5);at.y=g.world.height_at(at.x,at.z);pet_model.scale*=1.6
			pet_model.position=at;pet_model.look_at(Vector3(g.camera.global_position.x,at.y,g.camera.global_position.z),Vector3.UP)
	await step(g,4);checks.pet_sheet=sheet([await frame(g,true)],"pets");lineup.queue_free()
	checks.pet_follows=is_instance_valid(g.pet) and g.pet.position.distance_to(g.player.position)<6.0
	# Hats (October 29): thirteen heroes in a row, each wearing one of the hats.
	var hatters=Node3D.new();g.add_child(hatters)
	for i in range(HatBook.HATS.size()):
		var hero_def=g.rules.data.heroes[i%g.rules.data.heroes.size()]
		var hero_model=g.world.model(hero_def.model,float(hero_def.get("height",1.65)));hatters.add_child(hero_model)
		var at=g.player.position+forward*(3.2+(i/7)*1.8)+side*((i%7-3)*1.0+(i/7)*.5);at.y=g.world.height_at(at.x,at.z)
		hero_model.position=at;hero_model.look_at(Vector3(g.camera.global_position.x,at.y,g.camera.global_position.z),Vector3.UP);hero_model.rotate_y(PI)
		HatBook.wear(hero_model,HatBook.HATS[i].id)
	await step(g,4);await RenderingServer.frame_post_draw;g.get_viewport().get_texture().get_image().save_png("user://fx-hats-full.png")
	checks.hat_sheet=sheet([await frame(g,true)],"hats")
	checks.hats_worn=hatters.find_children("Hat","",true,false).size()==HatBook.HATS.size()
	hatters.queue_free()
	# Hero tricks (October 29): Count Duck's QUACK! and Stone Granny's Handbag Quake.
	var own_hero=g.hero;var tricks=[]
	for id in ["duck","grandma"]:
		g.hero=g.rules.data.heroes.filter(func(h):return h.id==id)[0];g.trick_cooldown=0.0
		checks["trick_"+id]=HeroTricks.use(g)
		await step(g,6);tricks.append(await frame(g,true))
	g.hero=own_hero;g.trick_cooldown=0.0
	checks.trick_sheet=sheet(tricks,"tricks")
	for weapon in g.equipped:
		if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
	g.equipped.clear()
	await step(g,150)
	checks.spells_expired=g.skills.is_empty()
	checks.effects_expired=not g.effects.any(func(e):return e.get("ink_fx",false))
	checks.sheets=sheet(flights,"flight") and sheet(impacts,"impact") and sheet(statuses,"status") and sheet(skills,"skills") and sheet(spells,"spells")
	var result={"checks":checks,"kinds":KINDS,"spell_cells":["tornado r1","tornado r9","blackhole r1","blackhole r9","blackhole r9 collapse","thunderstorm r1","thunderstorm r9","inferno r1","inferno r9"],"skill_cells":MutationBook.STRAIN_ORDER+["slam","hero hit","hero hit on shield","co-op crossfire","co-op overload","elite badges"],"status_cells":["statuses","statuses later","ember burst","burning","poison burst","poisoned","burning deaths","after deaths"]}
	print("FX_REVIEW "+JSON.stringify(result));g.get_tree().quit(0 if not checks.values().has(false) else 1)
