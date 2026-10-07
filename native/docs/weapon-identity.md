# Weapon visual identity

Every weapon card/menu/HUD icon uses assets/illustrated/weapon-icons/<weapon-id>.png before any legacy illustrated content lookup. All 65 catalog IDs are rendered from WeaponModel, the same constructor used by ActorRig in player hands and by hero previews. Variant attachments are included. Gameplay archetypes, ranks and saved IDs are unchanged.

weapon_identity.gd supplies visible elemental colors/hardware to the existing 3D models: ice crystal muzzle, flame tanks/nozzle, poison canister, electrical electrodes/coils, rail rails/scope, ghost vessel and rocket fins. Elemental sentries share those identifiers. This is mesh/material refinement, not a claim that all models are new sculptures.

After changing held weapon geometry/materials/catalog variants, run:
1. node scripts/agent-workflow.mjs check
2. node scripts/agent-workflow.mjs weapon-icons
3. node scripts/agent-workflow.mjs check (imports generated images)
4. node scripts/agent-workflow.mjs capture-ui and inspect ice-match/weapon cards
5. node scripts/agent-workflow.mjs build

The renderer processes the entire catalog, frames each visible mesh assembly, writes 256px PNGs and fails on image-save errors. Exported smoke verifies every weapon ID resolves to its matching rendered image, protecting against legacy content artwork taking precedence. Higher weapon ranks retain the base silhouette while adding rank plates in play.
