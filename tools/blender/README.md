# Blender asset pipeline

This folder contains reproducible Blender scripts for procedural Rocket Workshop
assets. The v1 hero pass is intentionally separate from the existing v3 package
and does not modify Godot gameplay, scenes, scripts, or import files.

## Hero assets v1

Run from the repository root:

```powershell
blender --background --python tools/blender/generate_hero_assets_v1.py
```

On Windows, if Blender is not in `PATH`, locate it with:

```powershell
where blender
Get-ChildItem -Recurse -Filter blender.exe "C:\Program Files\Blender Foundation"
```

Then run with the full executable path, for example:

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe" --background --python "tools/blender/generate_hero_assets_v1.py"
```

Optional render engine selection:

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe" --background --python "tools/blender/generate_hero_assets_v1.py" -- --engine CYCLES
& "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe" --background --python "tools/blender/generate_hero_assets_v1.py" -- --engine EEVEE
```

Skip renders while testing script logic:

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe" --background --python "tools/blender/generate_hero_assets_v1.py" -- --skip-renders
```

## Outputs

Source file:

```text
assets_3d/source/v1/rocket_workshop_hero_v1.blend
```

Individual GLB exports:

```text
assets_3d/export/v1/pet_bottle.glb
assets_3d/export/v1/paper_nose_cone.glb
assets_3d/export/v1/cardboard_fin.glb
assets_3d/export/v1/launch_stand.glb
assets_3d/export/v1/workbench.glb
assets_3d/export/v1/tape_roll.glb
```

Review renders:

```text
assets_3d/renders/v1/hero_workbench_1920x1080.png
assets_3d/renders/v1/asset_sheet_1920x1080.png
assets_3d/renders/v1/wireframe_debug_1920x1080.png
```

Build report:

```text
docs/builds/hero_assets_v1_report.md
```

## Scene structure

The script creates these Blender collections:

```text
HERO_ASSETS
  PET_Bottle
  Paper_Nose_Cone
  Cardboard_Fin
  Launch_Stand
  Tape_Roll
ENVIRONMENT
  Workbench
  Background_Props
LIGHTING
CAMERAS
EXPORT_HELPERS
```

Canonical export objects are hidden from render and kept in their asset
collections. Visible linked copies are used for the hero shot and asset sheet.
This keeps GLB pivots near the useful manipulation points while allowing a
composed Blender scene.

## Safety and scope

The generated stand is a fictional, non-operational workshop prop. The assets do
not include pressure values, real launcher diagrams, functional valves, hoses,
or construction instructions. This pipeline stops at visual asset generation and
does not integrate anything into Godot.

## Hero assets v2

The v2 pass preserves every v1 output and writes only to versioned v2 paths:

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe" --background --python "tools/blender/generate_hero_assets_v2.py"
```

Outputs:

```text
assets_3d/source/v2/rocket_workshop_hero_v2.blend
assets_3d/export/v2/pet_bottle.glb
assets_3d/export/v2/paper_nose_cone.glb
assets_3d/export/v2/cardboard_fin.glb
assets_3d/export/v2/launch_stand.glb
assets_3d/export/v2/workbench.glb
assets_3d/export/v2/tape_roll.glb
assets_3d/renders/v2/hero_workbench_v2_1920x1080.png
assets_3d/renders/v2/asset_sheet_v2_1920x1080.png
assets_3d/renders/v2/pet_bottle_closeup_v2_1920x1080.png
assets_3d/renders/v2/material_closeups_v2_1920x1080.png
assets_3d/renders/v2/wireframe_debug_v2_1920x1080.png
docs/builds/hero_assets_v2_report.md
```

This pass focuses on the official v2 art direction: stop-motion scientific
handmade diorama. It removes the v1 PET ring-stack look, uses a continuous
bottle body, thins the cardboard fin, adds paper folds/seams, brightens the hero
shot, and adds PET/material close-up renders for review.
