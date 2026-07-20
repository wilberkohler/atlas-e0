"""
Procedural asset generator for the Rocket Workshop.

Run from the repository root:
    blender --background --python tools/blender/generate_rocket_workshop_v3.py

The script creates a semirealistic first pass, saves a .blend source file,
exports individual .glb files, and mirrors the exports into the Godot project.
It avoids practical real-world launcher details; all assets are visual props.
"""

from __future__ import annotations

import math
import shutil
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "assets_3d" / "source"
EXPORT_DIR = ROOT / "assets_3d" / "export" / "v3"
GODOT_DIR = ROOT / "app" / "godot" / "rocket_workshop"
GODOT_EXPORT_DIR = GODOT_DIR / "assets_3d" / "export" / "v3"
BLEND_PATH = SOURCE_DIR / "oficina_foguete_v3.blend"
MANAGED_PREFIX = "RW3_"

ASSET_EXPORTS = {
    "pet_bottle_main": "pet_bottle_main.glb",
    "pet_bottle_impact": "pet_bottle_impact.glb",
    "bottle_cap": "bottle_cap.glb",
    "nose_cone_a": "nose_cone_a.glb",
    "nose_cone_b": "nose_cone_b.glb",
    "cardboard_fin_straight": "cardboard_fin_straight.glb",
    "cardboard_fin_warped": "cardboard_fin_warped.glb",
    "tape_set": "tape_set.glb",
    "elastic_set": "elastic_set.glb",
    "launch_stand": "launch_stand.glb",
    "workbench": "workbench.glb",
    "workshop_props": "workshop_props.glb",
}


def ensure_dirs() -> None:
    for path in [SOURCE_DIR, EXPORT_DIR, GODOT_EXPORT_DIR]:
        path.mkdir(parents=True, exist_ok=True)


def clear_managed_scene() -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in list(bpy.data.objects):
        if obj.name.startswith(MANAGED_PREFIX) or obj.get("rocket_workshop_v3"):
            bpy.data.objects.remove(obj, do_unlink=True)
    for collection in list(bpy.data.collections):
        if collection.name.startswith(MANAGED_PREFIX):
            bpy.data.collections.remove(collection)


def create_collection(asset_key: str) -> bpy.types.Collection:
    collection = bpy.data.collections.new(f"{MANAGED_PREFIX}{asset_key}")
    bpy.context.scene.collection.children.link(collection)
    return collection


def link_to(collection: bpy.types.Collection, obj: bpy.types.Object) -> bpy.types.Object:
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    collection.objects.link(obj)
    obj["rocket_workshop_v3"] = True
    return obj


def material_principled(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float,
    metallic: float = 0.0,
    alpha: float = 1.0,
    transmission: float = 0.0,
) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = color
    mat.roughness = roughness
    mat.metallic = metallic
    mat.use_nodes = True
    if alpha < 1.0:
        mat.blend_method = "BLEND"
        mat.use_screen_refraction = True
        mat.show_transparent_back = True

    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        set_input(bsdf, "Base Color", color)
        set_input(bsdf, "Alpha", alpha)
        set_input(bsdf, "Roughness", roughness)
        set_input(bsdf, "Metallic", metallic)
        set_input(bsdf, "Transmission Weight", transmission)
        set_input(bsdf, "IOR", 1.46)
    return mat


def set_input(node: bpy.types.Node, input_name: str, value) -> None:
    if input_name in node.inputs:
        node.inputs[input_name].default_value = value


def assign_material(obj: bpy.types.Object, mat: bpy.types.Material) -> bpy.types.Object:
    obj.data.materials.append(mat)
    return obj


def shade_smooth(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.shade_smooth()
    finally:
        obj.select_set(False)


def add_uv_project(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
        bpy.ops.object.mode_set(mode="OBJECT")
    except Exception:
        bpy.ops.object.mode_set(mode="OBJECT")
    finally:
        obj.select_set(False)


def make_lathe_x(
    name: str,
    profile: list[tuple[float, float]],
    segments: int,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    footed: bool = False,
    impact: bool = False,
) -> bpy.types.Object:
    verts = []
    faces = []
    for ring_index, (x, radius) in enumerate(profile):
        for seg in range(segments):
            angle = math.tau * seg / segments
            wave = 1.0
            if footed and x < profile[2][0]:
                wave += 0.12 * math.cos(angle * 5.0)
            wave += 0.012 * math.sin(angle * 7.0 + x * 3.0)
            dent = 0.0
            if impact:
                dent = -0.06 * math.exp(-((x - 0.22) ** 2) / 0.18) * max(0.0, math.cos(angle - 0.8))
            y = math.cos(angle) * max(0.02, radius * wave + dent)
            z = math.sin(angle) * max(0.02, radius * wave + dent * 0.45)
            verts.append((x, y, z))

    for ring in range(len(profile) - 1):
        for seg in range(segments):
            a = ring * segments + seg
            b = ring * segments + (seg + 1) % segments
            c = (ring + 1) * segments + (seg + 1) % segments
            d = (ring + 1) * segments + seg
            faces.append((a, b, c, d))

    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(f"{MANAGED_PREFIX}{name}", mesh)
    assign_material(obj, mat)
    link_to(collection, obj)
    shade_smooth(obj)
    add_uv_project(obj)
    return obj


def add_cylinder_x(
    name: str,
    radius: float,
    depth: float,
    location: tuple[float, float, float],
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    vertices: int = 48,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=(0.0, math.radians(90.0), 0.0),
    )
    obj = bpy.context.object
    obj.name = f"{MANAGED_PREFIX}{name}"
    assign_material(obj, mat)
    link_to(collection, obj)
    shade_smooth(obj)
    add_uv_project(obj)
    return obj


def add_box(
    name: str,
    size: tuple[float, float, float],
    location: tuple[float, float, float],
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = f"{MANAGED_PREFIX}{name}"
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_material(obj, mat)
    link_to(collection, obj)
    add_uv_project(obj)
    bevel = obj.modifiers.new("Soft_Bevel", "BEVEL")
    bevel.width = min(size) * 0.08
    bevel.segments = 2
    obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
    return obj


def add_torus_x(
    name: str,
    major_radius: float,
    minor_radius: float,
    location: tuple[float, float, float],
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    segments: int = 64,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(
        major_segments=segments,
        minor_segments=8,
        major_radius=major_radius,
        minor_radius=minor_radius,
        location=location,
        rotation=(0.0, math.radians(90.0), 0.0),
    )
    obj = bpy.context.object
    obj.name = f"{MANAGED_PREFIX}{name}"
    assign_material(obj, mat)
    link_to(collection, obj)
    shade_smooth(obj)
    add_uv_project(obj)
    return obj


def add_cone_x(
    name: str,
    radius: float,
    length: float,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    color_strip: bpy.types.Material | None = None,
    warp: float = 0.0,
) -> bpy.types.Object:
    segments = 48
    verts = [(length, 0.0, 0.0)]
    for seg in range(segments):
        angle = math.tau * seg / segments
        edge_wave = 1.0 + warp * math.sin(angle * 3.0 + 0.4)
        verts.append((0.0, math.cos(angle) * radius * edge_wave, math.sin(angle) * radius))
    faces = []
    for seg in range(segments):
        faces.append((0, 1 + seg, 1 + ((seg + 1) % segments)))
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(f"{MANAGED_PREFIX}{name}", mesh)
    assign_material(obj, mat)
    link_to(collection, obj)
    shade_smooth(obj)
    add_uv_project(obj)
    if color_strip is not None:
        add_box(
            f"{name}_Glue_Overlap",
            (length * 0.92, 0.018, 0.085),
            (length * 0.42, radius * 0.72, 0.02),
            color_strip,
            collection,
            (0.0, 0.0, math.radians(3.0)),
        )
    return obj


def make_fin_mesh(
    name: str,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    warped: bool = False,
) -> bpy.types.Object:
    thickness = 0.075
    points = [
        (0.00, -0.02),
        (0.64, -0.02),
        (0.54, 0.50),
        (0.05, 0.70),
    ]
    verts = []
    for side in [-thickness * 0.5, thickness * 0.5]:
        for x, z in points:
            wobble = 0.035 * math.sin((x + z) * 7.0) if warped else 0.0
            verts.append((x, side + wobble, z))
    faces = [
        (0, 1, 2, 3),
        (7, 6, 5, 4),
        (0, 4, 5, 1),
        (1, 5, 6, 2),
        (2, 6, 7, 3),
        (3, 7, 4, 0),
    ]
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(f"{MANAGED_PREFIX}{name}", mesh)
    assign_material(obj, mat)
    link_to(collection, obj)
    add_uv_project(obj)
    obj.modifiers.new("Cardboard_Edge_Softening", "WEIGHTED_NORMAL")
    return obj


def create_materials() -> dict[str, bpy.types.Material]:
    return {
        "pet": material_principled("PET_Clear_Used_Plastic", (0.62, 0.86, 0.96, 0.35), 0.18, alpha=0.35, transmission=0.65),
        "pet_edge": material_principled("PET_Thicker_Edges", (0.76, 0.95, 1.0, 0.48), 0.22, alpha=0.48, transmission=0.45),
        "cap": material_principled("Blue_Reused_Cap", (0.06, 0.33, 0.72, 1.0), 0.46),
        "paper_a": material_principled("Warm_Paper_Cone", (0.95, 0.88, 0.68, 1.0), 0.74),
        "paper_b": material_principled("Offwhite_Paper_Cone", (0.94, 0.92, 0.82, 1.0), 0.80),
        "paper_edge": material_principled("Paper_Overlap_Edge", (0.76, 0.70, 0.56, 1.0), 0.86),
        "cardboard": material_principled("Fibrous_Cardboard", (0.66, 0.43, 0.22, 1.0), 0.88),
        "cardboard_dark": material_principled("Cardboard_Exposed_Edge", (0.40, 0.25, 0.13, 1.0), 0.92),
        "tape": material_principled("Satin_Clear_Tape", (0.92, 0.90, 0.74, 0.36), 0.18, alpha=0.36, transmission=0.2),
        "rubber": material_principled("Matte_Rubber_Band", (0.28, 0.14, 0.10, 1.0), 0.82),
        "wood": material_principled("Warm_Scratched_Workbench_Wood", (0.58, 0.34, 0.17, 1.0), 0.70),
        "dark_wood": material_principled("Workbench_Dark_Edges", (0.30, 0.17, 0.09, 1.0), 0.82),
        "plastic": material_principled("Soft_Gray_Plastic", (0.34, 0.38, 0.36, 1.0), 0.64),
        "metal": material_principled("Dull_Safe_Metal", (0.54, 0.57, 0.55, 1.0), 0.46, metallic=0.25),
        "green": material_principled("Indicator_Green_Lens", (0.10, 0.95, 0.58, 1.0), 0.26),
        "graphite": material_principled("Graphite_Pencil", (0.10, 0.10, 0.11, 1.0), 0.55),
        "notebook": material_principled("Notebook_Blue_Cover", (0.12, 0.24, 0.55, 1.0), 0.62),
    }


def build_pet_bottle(collection: bpy.types.Collection, mats: dict[str, bpy.types.Material], impact: bool = False) -> None:
    profile = [
        (-1.58, 0.18),
        (-1.48, 0.39),
        (-1.32, 0.43),
        (-1.10, 0.38),
        (-0.68, 0.36),
        (-0.18, 0.335),
        (0.38, 0.36),
        (0.80, 0.35),
        (1.02, 0.30),
        (1.18, 0.23),
        (1.42, 0.19),
        (1.68, 0.19),
    ]
    make_lathe_x(
        "PET_Bottle_Impact" if impact else "PET_Bottle_Main",
        profile,
        72,
        mats["pet"],
        collection,
        footed=True,
        impact=impact,
    )
    for idx, x in enumerate([-1.25, -0.55, 0.12, 0.72, 1.38, 1.64]):
        radius = 0.38 if x < 1.0 else 0.19
        add_torus_x(f"PET_Ridge_{idx + 1}", radius, 0.007, (x, 0.0, 0.0), mats["pet_edge"], collection)
    if impact:
        add_box("Soft_Dent_Read", (0.04, 0.44, 0.18), (0.18, 0.33, 0.04), mats["pet_edge"], collection, (0.0, 0.0, math.radians(12.0)))


def build_cap(collection: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    add_cylinder_x("Bottle_Cap", 0.22, 0.20, (0.0, 0.0, 0.0), mats["cap"], collection, vertices=48)
    for idx, x in enumerate([-0.07, 0.0, 0.07]):
        add_torus_x(f"Cap_Rib_{idx + 1}", 0.22, 0.006, (x, 0.0, 0.0), mats["pet_edge"], collection, segments=48)


def build_tape_set(collection: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    add_torus_x("Tape_Roll", 0.27, 0.055, (0.0, 0.0, 0.0), mats["tape"], collection, segments=56)
    add_box("Tape_Strip_Short", (0.48, 0.012, 0.10), (0.62, 0.0, 0.0), mats["tape"], collection, (0.0, 0.0, math.radians(2.0)))
    add_box("Tape_Strip_Medium", (0.78, 0.012, 0.11), (0.12, 0.46, 0.0), mats["tape"], collection, (0.0, 0.0, math.radians(-9.0)))
    add_box("Tape_Strip_Folded", (0.42, 0.012, 0.11), (-0.55, -0.25, 0.04), mats["tape"], collection, (math.radians(12.0), 0.0, math.radians(16.0)))


def build_elastic_set(collection: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    add_torus_x("Elastic_Relaxed", 0.34, 0.035, (-0.35, 0.0, 0.0), mats["rubber"], collection, segments=64)
    stretched_a = add_box("Elastic_Stretched_A", (0.96, 0.04, 0.045), (0.46, 0.0, -0.15), mats["rubber"], collection)
    stretched_b = add_box("Elastic_Stretched_B", (0.96, 0.04, 0.045), (0.46, 0.0, 0.15), mats["rubber"], collection)
    stretched_a.scale.z = 1.0
    stretched_b.scale.z = 1.0
    add_torus_x("Elastic_Stretched_End_Left", 0.15, 0.026, (-0.02, 0.0, 0.0), mats["rubber"], collection, segments=36)
    add_torus_x("Elastic_Stretched_End_Right", 0.15, 0.026, (0.94, 0.0, 0.0), mats["rubber"], collection, segments=36)


def build_launch_stand(collection: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    add_box("Launch_Stand_Base", (1.35, 0.16, 0.85), (0.0, 0.0, 0.0), mats["plastic"], collection)
    add_box("Launch_Rail_Left", (1.18, 0.08, 0.08), (0.0, 0.13, 0.22), mats["metal"], collection)
    add_box("Launch_Rail_Right", (1.18, 0.08, 0.08), (0.0, 0.13, -0.22), mats["metal"], collection)
    add_box("Launch_Lever", (0.10, 0.60, 0.12), (0.20, 0.36, 0.00), mats["metal"], collection, (0.0, 0.0, math.radians(16.0)))
    add_cylinder_x("Launch_Indicator", 0.08, 0.035, (0.52, 0.12, -0.28), mats["green"], collection, vertices=32)


def build_workbench(collection: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    add_box("Workbench_Top", (5.8, 0.26, 3.25), (0.0, 0.0, 0.0), mats["wood"], collection)
    for x, z in [(-2.45, -1.25), (2.45, -1.25), (-2.45, 1.25), (2.45, 1.25)]:
        add_box("Workbench_Leg", (0.26, 1.15, 0.26), (x, -0.70, z), mats["dark_wood"], collection)
    for idx in range(14):
        x = -2.6 + idx * 0.38
        z = math.sin(idx * 1.8) * 1.15
        add_box(f"Workbench_Scratch_{idx + 1}", (0.30, 0.012, 0.018), (x, 0.14, z), mats["dark_wood"], collection, (0.0, math.radians(8.0), math.radians((idx % 5 - 2) * 9.0)))


def build_props(collection: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    add_cylinder_x("Prop_Pencil_Body", 0.035, 0.92, (-0.65, 0.0, 0.18), mats["paper_a"], collection, vertices=12)
    add_cylinder_x("Prop_Pencil_Graphite", 0.025, 0.10, (-0.18, 0.0, 0.18), mats["graphite"], collection, vertices=12)
    add_box("Prop_Ruler", (1.08, 0.025, 0.12), (0.48, 0.0, 0.22), mats["tape"], collection, (0.0, 0.0, math.radians(-6.0)))
    add_box("Prop_Notebook", (0.78, 0.06, 0.56), (0.12, 0.0, -0.48), mats["notebook"], collection, (0.0, 0.0, math.radians(5.0)))
    for idx, offset in enumerate([(-0.72, -0.48), (-0.98, -0.28), (-1.14, -0.64), (-0.42, -0.66)]):
        add_box(f"Prop_CardboardScrap_{idx + 1}", (0.34, 0.025, 0.22), (offset[0], 0.0, offset[1]), mats["cardboard"], collection, (0.0, 0.0, math.radians(idx * 17.0)))


def build_assets() -> dict[str, bpy.types.Collection]:
    mats = create_materials()
    collections: dict[str, bpy.types.Collection] = {}
    for key in ASSET_EXPORTS:
        collections[key] = create_collection(key)

    build_pet_bottle(collections["pet_bottle_main"], mats, impact=False)
    build_pet_bottle(collections["pet_bottle_impact"], mats, impact=True)
    build_cap(collections["bottle_cap"], mats)
    add_cone_x("Paper_Nose_Cone_A", 0.43, 0.86, mats["paper_a"], collections["nose_cone_a"], mats["paper_edge"], warp=0.025)
    add_cone_x("Paper_Nose_Cone_B", 0.43, 0.86, mats["paper_b"], collections["nose_cone_b"], mats["paper_edge"], warp=0.045)
    make_fin_mesh("Cardboard_Fin_Straight", mats["cardboard"], collections["cardboard_fin_straight"], warped=False)
    make_fin_mesh("Cardboard_Fin_Warped", mats["cardboard"], collections["cardboard_fin_warped"], warped=True)
    add_box("Fin_Tape_Straight", (0.08, 0.012, 0.48), (0.10, 0.05, 0.32), mats["tape"], collections["cardboard_fin_straight"], (0.0, 0.0, math.radians(-4.0)))
    add_box("Fin_Tape_Warped", (0.08, 0.012, 0.48), (0.10, 0.05, 0.32), mats["tape"], collections["cardboard_fin_warped"], (0.0, 0.0, math.radians(7.0)))
    build_tape_set(collections["tape_set"], mats)
    build_elastic_set(collections["elastic_set"], mats)
    build_launch_stand(collections["launch_stand"], mats)
    build_workbench(collections["workbench"], mats)
    build_props(collections["workshop_props"], mats)
    return collections


def export_collection(asset_key: str, collection: bpy.types.Collection) -> Path:
    output = EXPORT_DIR / ASSET_EXPORTS[asset_key]
    bpy.ops.object.select_all(action="DESELECT")
    objects = list(collection.all_objects)
    for obj in objects:
        obj.select_set(True)
    if objects:
        bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
    )
    godot_output = GODOT_EXPORT_DIR / output.name
    shutil.copy2(output, godot_output)
    return output


def save_blend() -> None:
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))


def configure_scene() -> None:
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.render.engine = "CYCLES"
    bpy.context.scene.view_settings.view_transform = "Filmic"
    bpy.context.scene.view_settings.look = "Medium High Contrast"
    bpy.context.scene.world.color = (0.06, 0.07, 0.07)
    bpy.ops.object.light_add(type="AREA", location=(0.0, 3.5, 2.8), rotation=(math.radians(-55.0), 0.0, math.radians(30.0)))
    light = bpy.context.object
    light.name = f"{MANAGED_PREFIX}Warm_Workbench_Area_Light"
    light.data.energy = 420
    light.data.size = 4.0


def main() -> None:
    ensure_dirs()
    clear_managed_scene()
    configure_scene()
    collections = build_assets()
    save_blend()
    exported = [export_collection(key, collection) for key, collection in collections.items()]
    print("\nRocket Workshop Blender pipeline complete.")
    print(f"Blend: {BLEND_PATH}")
    print(f"Godot mirror: {GODOT_EXPORT_DIR}")
    for path in exported:
        print(f"GLB: {path}")


if __name__ == "__main__":
    main()
