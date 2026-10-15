# Ground-art direction — October 15, 2026

The user rejects the current bare-looking ground and muted overall result. The goal is a finished, colour-rich Hades-inspired scene, with natural scenery rather than architecture. This is a new open task, not a completed art pass.

## Recommended approach

Start with low clustered geometry: grass and moss in woods, reeds and luminous fungus in marshes, crystal splinters on the moon, pale turquoise grass and petals in cloudwilds, dark ember scrub in the burnt biome, violet coral sprouts in space. Use irregular islands with open travel/combat lanes. Give plants dark roots, saturated middle colours and selective warm or cyan highlights. Let bright flowers occupy small focal patches. Avoid making every blade emissive or raising the whole terrain's brightness.

Use several small MultiMeshes per streamed chunk, not one world-wide batch. Godot documents efficient instancing but no individual-instance frustum culling; dividing the world into areas avoids drawing every plant. Opaque low-poly blade clumps avoid overlapping transparent cards. Apply wind in a vertex shader, with roots anchored and modest motion. No physics collision or navigation obstacles for ground cover.

Mist is optional atmosphere, not a substitute for ground detail. Trial localized low-density pockets outside fighting lanes, particularly in marshes and cloudwilds. Godot warns that thin volumes can flicker; thicker low-density volumes or a shorter fog range are alternatives. Volumetric fog is Forward+ only. Flashing attack lights should not feed temporally reprojected fog because they can leave ghosts. Keep sky and warning shapes legible.

## Sources

- [Godot: Optimization using MultiMeshes](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html) — batching and area-based culling tradeoffs.
- [Godot: Volumetric fog and fog volumes](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html) — local density, thin-volume flicker, temporal ghosting and renderer limits.
- [Godot: Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html) — transparency/fill-rate cost and instancing.

The palette/composition recommendations above are proposed art direction for Wildforge, not claims about Supergiant's internal implementation. Verify against rendered gameplay rather than relying on saturation numbers or thumbnail art.

## Acceptance

Capture matched before/after frames in all six biomes, normal combat and Eclipse. Check warning circles, pickups, player silhouette and shadow separation. Compare frame percentiles on the same machine/camera/seed. Keep density adjustable, and keep this task open until the visual result is actually convincing.
