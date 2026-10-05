# Megabonk Wildforge Mod: full content merge

The goal is the complete Wildforge content catalog inside Megabonk, retaining Megabonk's native content alongside it. The earlier Duck-only milestone is superseded by the user's full-merge instruction.

## Current implementation batch

- All 21 Wildforge heroes and their 21 named perks.
- All 694 cards: 352 items and 342 skills, including conditional augments.
- All 65 weapon definitions and their source damage/rate/variant data.
- All 36 enemy species plus 18 biome forms of World Maw, Sun Breaker and Star Eater.
- All 875 original PNG icon/illustration assets.
- All 57 distinct original hero/enemy GLB models and the source weapon GLBs.
- Native reward pools plus Wildforge skill-card slots in level-up offers.
- Mixed enemy waves and boss selection, retaining native Megabonk enemies.
- Wildforge actors use HP fill in their original GlassCore/RearGlass orbs. Native Megabonk actors retain their original indicators.

The shared effect engine applies native stat modifiers, conditional augments, healing, damage procs, status effects, turrets, flowers, mobility and economy effects. Native stats and AI/weapon archetypes are used where Unity differs from Godot. Importing content does not imply exact mechanical parity: projectile spread/fuses, some status semantics and boss attack patterns need further adaptation and gameplay validation.

## Workflow

Implement the whole merge batch first. Build once after the batch, fix compile errors together, then run the automated full-catalog smoke. Repeat runtime checks only for concrete failures. No per-change screen-check loop. Visual/gameplay acceptance comes after integration works.

## Verification after implementation

The 0.3.0 compatibility batch is implemented, installed and passes the full runtime smoke. All 342 skills acquire, stack, resolve and remove; a native hero accepts a Wildforge skill. The build audit checks all 100 effect keys and 18 conditions. See VERIFICATION.md for evidence and remaining acceptance limits.

1. Build and fix the completed batch.
2. One runtime smoke checks registration, original model/orb availability, hero starting-weapon inventories, icon files, sampled stacking/healing, and spawning every enemy definition.
3. One normal play session checks menu-to-run flow, mixed waves, perk behavior, card presentation and the two HP indicator styles. A smoke result alone does not prove that all 694 effects behave correctly during a complete run.

## Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File mods/megabonk-wildforge/scripts/build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File mods/megabonk-wildforge/scripts/smoke-test.ps1 -SkipBuild
powershell -NoProfile -ExecutionPolicy Bypass -File mods/megabonk-wildforge/scripts/package.ps1 -SkipBuild
```

Source export lives in `scripts/export-catalog.mjs` and `content/wildforge-catalog.json`. Stable custom IDs preserve the earlier Duck/Fang/Clover/Boots IDs. Save isolation remains at `BepInEx/config/WildforgeProfile/Saves`; original saves and native game binaries are retained. Packages exclude personal profiles and game assemblies.

## Pinned environment

Megabonk 1.0.69, Unity 2023.2.22f1, BepInEx 6.0.738 IL2CPP x64 and .NET SDK 6.0.428. GameAssembly SHA256: `4350a7ae25ba7aec35677c213fdceabbb638676bb00ab59131d7d9c37b6e3d9e`.
