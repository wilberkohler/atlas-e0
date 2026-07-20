# Hero Assets v1 Report

## Summary

- Scope: static Blender hero scene and individual GLB exports for the Rocket Workshop.
- Product direction: handmade scientific model realism, without operational launcher details.
- Blender version: 5.1.2
- Render engine used: CYCLES
- Color management: AgX
- Approximate execution time: 167.0 seconds

## Files Created

- Source blend: `assets_3d\source\v1\rocket_workshop_hero_v1.blend`
- GLB: `assets_3d\export\v1\pet_bottle.glb`
- GLB: `assets_3d\export\v1\paper_nose_cone.glb`
- GLB: `assets_3d\export\v1\cardboard_fin.glb`
- GLB: `assets_3d\export\v1\launch_stand.glb`
- GLB: `assets_3d\export\v1\workbench.glb`
- GLB: `assets_3d\export\v1\tape_roll.glb`
- Render: `assets_3d\renders\v1\hero_workbench_1920x1080.png`
- Render: `assets_3d\renders\v1\asset_sheet_1920x1080.png`
- Render: `assets_3d\renders\v1\wireframe_debug_1920x1080.png`
- Report: `docs\builds\hero_assets_v1_report.md`

## Polygon Counts

| Asset | Approx. triangles | Target |
| --- | ---: | ---: |
| pet_bottle | 12712 | 15000 |
| paper_nose_cone | 1514 | 3000 |
| cardboard_fin | 328 | 3000 |
| launch_stand | 1800 | 15000 |
| workbench | 3152 | 10000 |
| tape_roll | 3160 | 5000 |

## Materials Created

- `MAT_Backdrop_Neutral`
- `MAT_Cardboard`
- `MAT_Cardboard_Edge`
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

- `assets_3d\export\v1\pet_bottle.glb`: ok
- `assets_3d\export\v1\paper_nose_cone.glb`: ok
- `assets_3d\export\v1\cardboard_fin.glb`: ok
- `assets_3d\export\v1\launch_stand.glb`: ok
- `assets_3d\export\v1\workbench.glb`: ok
- `assets_3d\export\v1\tape_roll.glb`: ok

## Renders

- `assets_3d\renders\v1\hero_workbench_1920x1080.png`: ok
- `assets_3d\renders\v1\asset_sheet_1920x1080.png`: ok
- `assets_3d\renders\v1\wireframe_debug_1920x1080.png`: ok

## Validation

- collections_missing: ok
- objects_missing: ok
- materials_missing: ok
- markers_missing: ok
- exports_missing: ok
- renders_missing: ok
- duplicate_object_names: ok
- orphaned_managed_objects: ok

## Known Limitations

- This is a procedural first-pass model pack; final art direction still needs human visual approval.
- PET scratches and surface noise are deliberately subtle and may need hand-authored texture work in v2.
- Procedural noise nodes improve Blender renders but are not essential to recognizing the exported GLBs.
- The launch stand is intentionally non-operational and avoids realistic pressure hardware.
- Marker names are globally unique where Blender requires uniqueness; `FIN_GRAB_PIVOT` represents the fin GRAB_PIVOT role.

## Suggested v2 Work

- Hand-paint PET micro-scuffs and edge highlights after the visual direction is approved.
- Create UV-authored cardboard fibers and paper seam variations.
- Tune Godot import materials only after this Blender pass is approved.
- Add optional LODs if runtime profiling asks for them.
- Refine the hero composition based on human visual review.

## Commands Executed

```powershell
C:\Program Files\Blender Foundation\Blender 5.1\blender.exe --background --python tools\blender\generate_hero_assets_v1.py
```

## Errors

- None encountered during script execution.

## Human Review Needed

- Confirm the PET bottle reads immediately as a reused PET bottle, not a generic transparent cylinder.
- Confirm the cone reads as paper/card stock.
- Confirm the fin reads as hand-cut cardboard.
- Confirm the test stand feels like a safe fictional workshop prop rather than real pressure equipment.
- Confirm the hero shot lighting and composition feel warm, tactile, and inviting.
