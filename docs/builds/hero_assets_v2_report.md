# Hero Assets v2 Report

## Summary

- Scope: static Blender hero scene, close-up renders, and individual GLB exports for the Rocket Workshop.
- Product direction: stop-motion scientific handmade diorama, without operational launcher details.
- Blender version: 5.1.2
- Render engine used: CYCLES
- Color management: AgX
- Approximate execution time: 254.6 seconds
- Godot integration: not performed; script output paths stay outside `app/godot/`.

## Objective Comparison With v1

- PET bottle: v2 removes the loose transparent ring stack and uses one continuous bottle body with integrated shoulder, neck, mouth lip, and base shaping.
- Fins: v2 makes the exported fin much thinner and emphasizes cardboard faces, darker fiber edges, cut marks, and light warping.
- Paper cone: v2 adds a visible seam, bottom edge, soft folds, warmer matte paper, and less perfect symmetry.
- Tape: v2 keeps a clear core, translucent outer roll, and loose end for faster recognition.
- Base: v2 uses clearer wood, dark plastic, soft metal, and an indicator while avoiding functional hardware.
- Composition and lighting: v2 brightens the right side, reduces dark empty space, reduces prop noise, and adds dedicated PET/material close-ups.

## Files Created

- Source blend: `assets_3d\source\v2\rocket_workshop_hero_v2.blend`
- GLB: `assets_3d\export\v2\pet_bottle.glb`
- GLB: `assets_3d\export\v2\paper_nose_cone.glb`
- GLB: `assets_3d\export\v2\cardboard_fin.glb`
- GLB: `assets_3d\export\v2\launch_stand.glb`
- GLB: `assets_3d\export\v2\workbench.glb`
- GLB: `assets_3d\export\v2\tape_roll.glb`
- Render: `assets_3d\renders\v2\hero_workbench_v2_1920x1080.png`
- Render: `assets_3d\renders\v2\asset_sheet_v2_1920x1080.png`
- Render: `assets_3d\renders\v2\pet_bottle_closeup_v2_1920x1080.png`
- Render: `assets_3d\renders\v2\material_closeups_v2_1920x1080.png`
- Render: `assets_3d\renders\v2\wireframe_debug_v2_1920x1080.png`
- Report: `docs\builds\hero_assets_v2_report.md`

## Polygon Counts

| Asset | Approx. triangles | Target |
| --- | ---: | ---: |
| pet_bottle | 4604 | 15000 |
| paper_nose_cone | 1520 | 3000 |
| cardboard_fin | 328 | 3000 |
| launch_stand | 1800 | 15000 |
| workbench | 2800 | 10000 |
| tape_roll | 3160 | 5000 |

## Materials Created

- `MAT_Backdrop_Neutral`
- `MAT_Cardboard`
- `MAT_Cardboard_Edge`
- `MAT_Closeup_Backdrop`
- `MAT_Graphite`
- `MAT_Indicator`
- `MAT_Metal_Soft`
- `MAT_PET_Clear`
- `MAT_PET_Edge`
- `MAT_PET_Scuff`
- `MAT_Paper_Edge`
- `MAT_Paper_OffWhite`
- `MAT_Pencil_Wood`
- `MAT_Plastic_Dark`
- `MAT_Scratch_Dark`
- `MAT_Stain`
- `MAT_Tape_Clear`
- `MAT_Tape_Core`
- `MAT_Wood_Base`
- `MAT_Wood_Workbench`
- `MAT_Wood_Workbench_Dark`

## Exports

- `assets_3d\export\v2\pet_bottle.glb`: ok
- `assets_3d\export\v2\paper_nose_cone.glb`: ok
- `assets_3d\export\v2\cardboard_fin.glb`: ok
- `assets_3d\export\v2\launch_stand.glb`: ok
- `assets_3d\export\v2\workbench.glb`: ok
- `assets_3d\export\v2\tape_roll.glb`: ok

## Renders

- `assets_3d\renders\v2\hero_workbench_v2_1920x1080.png`: ok
- `assets_3d\renders\v2\asset_sheet_v2_1920x1080.png`: ok
- `assets_3d\renders\v2\pet_bottle_closeup_v2_1920x1080.png`: ok
- `assets_3d\renders\v2\material_closeups_v2_1920x1080.png`: ok
- `assets_3d\renders\v2\wireframe_debug_v2_1920x1080.png`: ok

## Validation

- collections_missing: ok
- objects_missing: ok
- materials_missing: ok
- markers_missing: ok
- exports_missing: ok
- renders_missing: ok
- helpers_visible_in_render: ok
- pet_transparent_loose_rings: ok
- hero_interpenetration_warnings: ok
- transforms_not_applied: ok
- duplicate_object_names: ok
- orphaned_managed_objects: ok
- godot_output_paths: ok

## Known Limitations

- This is still a procedural model pack; final art direction needs human visual approval.
- PET scratches and surface noise are deliberately subtle and may need hand-authored texture work in a later pass.
- Procedural noise nodes improve Blender renders but are not essential to recognizing the exported GLBs.
- The launch stand is intentionally non-operational and avoids realistic pressure hardware.
- Marker names are globally unique where Blender requires uniqueness; `FIN_GRAB_PIVOT` represents the fin GRAB_PIVOT role.
- Automated interpenetration validation is conservative and cannot replace visual review of the rendered hero shot.

## Suggested Next Work After Human Approval

- Hand-paint PET micro-scuffs and edge highlights after the visual direction is approved.
- Create UV-authored cardboard fibers and paper seam variations.
- Tune Godot import materials only after this Blender pass is approved.
- Add optional LODs if runtime profiling asks for them.
- Refine the hero composition based on human visual review.

## Commands Executed

```powershell
C:\Program Files\Blender Foundation\Blender 5.1\blender.exe --background --python tools\blender\generate_hero_assets_v2.py
```

## Errors

- None encountered during script execution.

## Human Review Needed

- Confirm the PET bottle reads immediately as a reused PET bottle, not a generic transparent cylinder.
- Confirm the cone reads as paper/card stock.
- Confirm the fin reads as hand-cut cardboard.
- Confirm the test stand feels like a safe fictional workshop prop rather than real pressure equipment.
- Confirm the hero shot lighting and composition feel warm, tactile, and inviting.
- Confirm that no technical helpers, snap zones, or strange transparent rings are visible in the renders.
