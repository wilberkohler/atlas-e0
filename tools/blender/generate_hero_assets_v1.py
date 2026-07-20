"""
Generate the Rocket Workshop hero asset pack v1.

Run from the repository root:
    blender --background --python tools/blender/generate_hero_assets_v1.py

Optional:
    blender --background --python tools/blender/generate_hero_assets_v1.py -- --engine CYCLES
    blender --background --python tools/blender/generate_hero_assets_v1.py -- --engine EEVEE
    blender --background --python tools/blender/generate_hero_assets_v1.py -- --skip-renders

The script creates only versioned v1 outputs. It does not edit Godot scenes,
scripts, imports, or existing v3 assets.
"""

from __future__ import annotations

import math
import sys
import time
import traceback
from pathlib import Path
from typing import Iterable

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "assets_3d" / "source" / "v1"
EXPORT_DIR = ROOT / "assets_3d" / "export" / "v1"
RENDER_DIR = ROOT / "assets_3d" / "renders" / "v1"
REPORT_DIR = ROOT / "docs" / "builds"
BLEND_PATH = SOURCE_DIR / "rocket_workshop_hero_v1.blend"
REPORT_PATH = REPORT_DIR / "hero_assets_v1_report.md"

MANAGED_PROP = "hero_assets_v1_managed"
ROLE_PROP = "hero_assets_v1_role"
ASSET_PROP = "hero_assets_v1_asset"

ASSET_EXPORTS = {
    "pet_bottle": "pet_bottle.glb",
    "paper_nose_cone": "paper_nose_cone.glb",
    "cardboard_fin": "cardboard_fin.glb",
    "launch_stand": "launch_stand.glb",
    "workbench": "workbench.glb",
    "tape_roll": "tape_roll.glb",
}

ASSET_COLLECTIONS = {
    "pet_bottle": ("HERO_ASSETS", "PET_Bottle"),
    "paper_nose_cone": ("HERO_ASSETS", "Paper_Nose_Cone"),
    "cardboard_fin": ("HERO_ASSETS", "Cardboard_Fin"),
    "launch_stand": ("HERO_ASSETS", "Launch_Stand"),
    "tape_roll": ("HERO_ASSETS", "Tape_Roll"),
    "workbench": ("ENVIRONMENT", "Workbench"),
}

REQUIRED_COLLECTION_PATHS = [
    ("HERO_ASSETS",),
    ("HERO_ASSETS", "PET_Bottle"),
    ("HERO_ASSETS", "Paper_Nose_Cone"),
    ("HERO_ASSETS", "Cardboard_Fin"),
    ("HERO_ASSETS", "Launch_Stand"),
    ("HERO_ASSETS", "Tape_Roll"),
    ("ENVIRONMENT",),
    ("ENVIRONMENT", "Workbench"),
    ("ENVIRONMENT", "Background_Props"),
    ("LIGHTING",),
    ("CAMERAS",),
    ("EXPORT_HELPERS",),
]

REQUIRED_MATERIALS = [
    "MAT_PET_Clear",
    "MAT_Paper_OffWhite",
    "MAT_Cardboard",
    "MAT_Wood_Base",
    "MAT_Plastic_Dark",
    "MAT_Metal_Soft",
    "MAT_Indicator",
    "MAT_Wood_Workbench",
    "MAT_Tape_Clear",
    "MAT_Tape_Core",
]

REQUIRED_OBJECTS = [
    "PET_Bottle_Body",
    "Paper_Nose_Cone_Body",
    "Cardboard_Fin_Body",
    "Launch_Stand_Base",
    "Workbench_Top",
    "Tape_Roll_Body",
]

REQUIRED_MARKERS = [
    "GRAB_PIVOT",
    "SNAP_NOSE",
    "SNAP_FIN_1",
    "SNAP_FIN_2",
    "SNAP_FIN_3",
    "BOTTLE_CENTER_REFERENCE",
    "FIN_GRAB_PIVOT",
    "SNAP_CONTACT",
    "FIN_ROOT_REFERENCE",
    "FIN_TIP_REFERENCE",
    "ROCKET_PLACEMENT_POINT",
]

RENDER_OUTPUTS = {
    "hero": RENDER_DIR / "hero_workbench_1920x1080.png",
    "asset_sheet": RENDER_DIR / "asset_sheet_1920x1080.png",
    "wireframe": RENDER_DIR / "wireframe_debug_1920x1080.png",
}


class BuildState:
    def __init__(self) -> None:
        self.collections: dict[tuple[str, ...], bpy.types.Collection] = {}
        self.materials: dict[str, bpy.types.Material] = {}
        self.asset_roots: dict[str, bpy.types.Object] = {}
        self.render_engine = "UNKNOWN"
        self.color_view = "UNKNOWN"
        self.errors: list[str] = []
        self.exported: list[Path] = []
        self.rendered: list[Path] = []
        self.poly_counts: dict[str, int] = {}
        self.validation: dict[str, object] = {}
        self.started_at = time.perf_counter()


STATE = BuildState()


def parse_args() -> dict[str, object]:
    user_args: list[str] = []
    if "--" in sys.argv:
        user_args = sys.argv[sys.argv.index("--") + 1 :]

    options: dict[str, object] = {"engine": "AUTO", "skip_renders": False}
    index = 0
    while index < len(user_args):
        arg = user_args[index]
        if arg == "--engine" and index + 1 < len(user_args):
            options["engine"] = user_args[index + 1].upper()
            index += 2
        elif arg == "--skip-renders":
            options["skip_renders"] = True
            index += 1
        else:
            index += 1
    return options


def ensure_dirs() -> None:
    for path in [SOURCE_DIR, EXPORT_DIR, RENDER_DIR, REPORT_DIR]:
        path.mkdir(parents=True, exist_ok=True)


def mark_datablock(datablock, role: str | None = None, asset_key: str | None = None) -> None:
    datablock[MANAGED_PROP] = True
    if role is not None:
        datablock[ROLE_PROP] = role
    if asset_key is not None:
        datablock[ASSET_PROP] = asset_key


def is_managed(datablock) -> bool:
    try:
        return bool(datablock.get(MANAGED_PROP))
    except AttributeError:
        return False


def clear_managed_scene() -> None:
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.ops.object.mode_set.poll() else None
    bpy.ops.object.select_all(action="DESELECT")

    for obj in list(bpy.data.objects):
        if is_managed(obj) or obj.name in {"Cube", "Camera", "Light"}:
            bpy.data.objects.remove(obj, do_unlink=True)

    for collection in sorted(list(bpy.data.collections), key=lambda col: len(col.name), reverse=True):
        if is_managed(collection) or collection.name in {path[-1] for path in REQUIRED_COLLECTION_PATHS}:
            bpy.data.collections.remove(collection)

    for material in list(bpy.data.materials):
        if is_managed(material):
            bpy.data.materials.remove(material, do_unlink=True)

    for mesh in list(bpy.data.meshes):
        if mesh.users == 0:
            bpy.data.meshes.remove(mesh)

    for curve in list(bpy.data.curves):
        if curve.users == 0:
            bpy.data.curves.remove(curve)


def link_collection(collection: bpy.types.Collection, parent: bpy.types.Collection | None) -> None:
    if parent is None:
        bpy.context.scene.collection.children.link(collection)
    else:
        parent.children.link(collection)


def create_collection(path: tuple[str, ...]) -> bpy.types.Collection:
    if path in STATE.collections:
        return STATE.collections[path]

    parent = None if len(path) == 1 else create_collection(path[:-1])
    collection = bpy.data.collections.new(path[-1])
    mark_datablock(collection)
    link_collection(collection, parent)
    STATE.collections[path] = collection
    return collection


def create_collections() -> None:
    for path in REQUIRED_COLLECTION_PATHS:
        create_collection(path)


def collection_for_asset(asset_key: str) -> bpy.types.Collection:
    return STATE.collections[ASSET_COLLECTIONS[asset_key]]


def unlink_from_all_collections(obj: bpy.types.Object) -> None:
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)


def link_object(
    obj: bpy.types.Object,
    collection: bpy.types.Collection,
    role: str,
    asset_key: str | None = None,
    parent: bpy.types.Object | None = None,
) -> bpy.types.Object:
    unlink_from_all_collections(obj)
    collection.objects.link(obj)
    obj.parent = parent
    mark_datablock(obj, role=role, asset_key=asset_key)
    if obj.data is not None:
        mark_datablock(obj.data)
    return obj


def set_node_input(node: bpy.types.Node, names: Iterable[str], value) -> None:
    for name in names:
        if name in node.inputs:
            node.inputs[name].default_value = value
            return


def create_material(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float,
    metallic: float = 0.0,
    alpha: float = 1.0,
    transmission: float = 0.0,
    emission: tuple[float, float, float, float] | None = None,
    emission_strength: float = 0.0,
    bump_strength: float = 0.0,
    bump_scale: float = 40.0,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    mark_datablock(material)
    material.use_nodes = True
    material.diffuse_color = color
    material.roughness = roughness
    material.metallic = metallic

    if alpha < 1.0:
        material.blend_method = "BLEND"
        material.show_transparent_back = False
        if hasattr(material, "use_screen_refraction"):
            material.use_screen_refraction = True

    bsdf = material.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        set_node_input(bsdf, ["Base Color"], color)
        set_node_input(bsdf, ["Alpha"], alpha)
        set_node_input(bsdf, ["Roughness"], roughness)
        set_node_input(bsdf, ["Metallic"], metallic)
        set_node_input(bsdf, ["Transmission Weight", "Transmission"], transmission)
        set_node_input(bsdf, ["IOR"], 1.46)
        if emission is not None:
            set_node_input(bsdf, ["Emission Color", "Emission"], emission)
            set_node_input(bsdf, ["Emission Strength"], emission_strength)
        if bump_strength > 0.0:
            noise = material.node_tree.nodes.new("ShaderNodeTexNoise")
            noise.inputs["Scale"].default_value = bump_scale
            noise.inputs["Detail"].default_value = 6.0
            noise.inputs["Roughness"].default_value = 0.62
            bump = material.node_tree.nodes.new("ShaderNodeBump")
            bump.inputs["Strength"].default_value = bump_strength
            bump.inputs["Distance"].default_value = 0.055
            material.node_tree.links.new(noise.outputs["Fac"], bump.inputs["Height"])
            material.node_tree.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    STATE.materials[name] = material
    return material


def create_debug_wire_material() -> bpy.types.Material:
    material = bpy.data.materials.new("MAT_Debug_Wireframe")
    mark_datablock(material)
    material.use_nodes = True
    material.diffuse_color = (0.84, 0.84, 0.78, 1.0)
    nodes = material.node_tree.nodes
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    mix = nodes.new("ShaderNodeMixShader")
    diffuse = nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.inputs["Color"].default_value = (0.76, 0.74, 0.68, 1.0)
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = (0.02, 0.025, 0.025, 1.0)
    emission.inputs["Strength"].default_value = 0.45
    wire = nodes.new("ShaderNodeWireframe")
    wire.inputs["Size"].default_value = 0.006
    material.node_tree.links.new(wire.outputs["Fac"], mix.inputs["Fac"])
    material.node_tree.links.new(diffuse.outputs["BSDF"], mix.inputs[1])
    material.node_tree.links.new(emission.outputs["Emission"], mix.inputs[2])
    material.node_tree.links.new(mix.outputs["Shader"], output.inputs["Surface"])
    STATE.materials[material.name] = material
    return material


def create_materials() -> None:
    create_material(
        "MAT_PET_Clear",
        (0.68, 0.92, 0.96, 0.34),
        roughness=0.13,
        alpha=0.34,
        transmission=0.65,
        bump_strength=0.018,
        bump_scale=95.0,
    )
    create_material("MAT_PET_Edge", (0.82, 0.98, 1.0, 0.58), 0.18, alpha=0.58, transmission=0.35)
    create_material("MAT_PET_Scuff", (0.94, 1.0, 1.0, 0.30), 0.65, alpha=0.30)
    create_material("MAT_Paper_OffWhite", (0.91, 0.86, 0.73, 1.0), 0.86, bump_strength=0.024, bump_scale=58.0)
    create_material("MAT_Paper_Edge", (0.68, 0.61, 0.48, 1.0), 0.90, bump_strength=0.018, bump_scale=64.0)
    create_material("MAT_Cardboard", (0.56, 0.37, 0.18, 1.0), 0.93, bump_strength=0.045, bump_scale=72.0)
    create_material("MAT_Cardboard_Edge", (0.32, 0.20, 0.10, 1.0), 0.96, bump_strength=0.035, bump_scale=82.0)
    create_material("MAT_Wood_Base", (0.47, 0.28, 0.13, 1.0), 0.78, bump_strength=0.032, bump_scale=36.0)
    create_material("MAT_Plastic_Dark", (0.10, 0.12, 0.12, 1.0), 0.64)
    create_material("MAT_Metal_Soft", (0.52, 0.54, 0.51, 1.0), 0.46, metallic=0.20)
    create_material(
        "MAT_Indicator",
        (0.08, 0.96, 0.58, 1.0),
        0.22,
        emission=(0.04, 0.80, 0.40, 1.0),
        emission_strength=0.75,
    )
    create_material("MAT_Wood_Workbench", (0.59, 0.36, 0.18, 1.0), 0.74, bump_strength=0.038, bump_scale=31.0)
    create_material("MAT_Wood_Workbench_Dark", (0.28, 0.15, 0.075, 1.0), 0.82)
    create_material("MAT_Tape_Clear", (0.96, 0.92, 0.70, 0.38), 0.18, alpha=0.38, transmission=0.24)
    create_material("MAT_Tape_Core", (0.50, 0.33, 0.17, 1.0), 0.90, bump_strength=0.030, bump_scale=62.0)
    create_material("MAT_Backdrop_Neutral", (0.18, 0.20, 0.20, 1.0), 0.72)
    create_material("MAT_Scratch_Dark", (0.16, 0.095, 0.045, 1.0), 0.88)
    create_material("MAT_Stain", (0.11, 0.075, 0.045, 0.44), 0.90, alpha=0.44)
    create_material("MAT_Pencil_Wood", (0.80, 0.54, 0.23, 1.0), 0.72)
    create_material("MAT_Graphite", (0.05, 0.05, 0.05, 1.0), 0.52)
    create_debug_wire_material()


def set_smooth(obj: bpy.types.Object, smooth: bool = True) -> None:
    if obj.type == "MESH":
        for polygon in obj.data.polygons:
            polygon.use_smooth = smooth
        obj.data.update()


def add_weighted_normals(obj: bpy.types.Object) -> None:
    if obj.type == "MESH":
        modifier = obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
        modifier.keep_sharp = True


def add_uv(obj: bpy.types.Object) -> None:
    if obj.type != "MESH":
        return
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
        bpy.ops.object.mode_set(mode="OBJECT")
    except Exception:
        if bpy.ops.object.mode_set.poll():
            bpy.ops.object.mode_set(mode="OBJECT")
    finally:
        obj.select_set(False)


def assign_material(obj: bpy.types.Object, material: bpy.types.Material) -> None:
    if obj.type == "MESH":
        obj.data.materials.append(material)


def create_mesh_object(
    name: str,
    vertices: list[tuple[float, float, float]],
    faces: list[tuple[int, ...]],
    collection: bpy.types.Collection,
    material: bpy.types.Material,
    role: str,
    asset_key: str | None = None,
    parent: bpy.types.Object | None = None,
    smooth: bool = False,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mark_datablock(mesh)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    link_object(obj, collection, role=role, asset_key=asset_key, parent=parent)
    assign_material(obj, material)
    set_smooth(obj, smooth)
    add_uv(obj)
    return obj


def create_empty(
    name: str,
    collection: bpy.types.Collection,
    role: str,
    asset_key: str | None = None,
    parent: bpy.types.Object | None = None,
    location: tuple[float, float, float] = (0.0, 0.0, 0.0),
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    scale: tuple[float, float, float] = (1.0, 1.0, 1.0),
    display_size: float = 0.12,
) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = display_size
    obj.location = location
    obj.rotation_euler = rotation
    obj.scale = scale
    link_object(obj, collection, role=role, asset_key=asset_key, parent=parent)
    return obj


def create_beveled_box(
    name: str,
    size: tuple[float, float, float],
    location: tuple[float, float, float],
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    role: str,
    asset_key: str | None = None,
    parent: bpy.types.Object | None = None,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    bevel_width: float | None = None,
    bevel_segments: int = 2,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    link_object(obj, collection, role=role, asset_key=asset_key, parent=parent)
    assign_material(obj, material)
    if bevel_width is None:
        bevel_width = max(0.004, min(size) * 0.08)
    if bevel_width > 0.0:
        bevel = obj.modifiers.new("Soft_Bevel", "BEVEL")
        bevel.width = bevel_width
        bevel.segments = bevel_segments
    add_weighted_normals(obj)
    add_uv(obj)
    return obj


def create_cylinder(
    name: str,
    radius: float,
    depth: float,
    location: tuple[float, float, float],
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    role: str,
    asset_key: str | None = None,
    parent: bpy.types.Object | None = None,
    vertices: int = 48,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    bevel: bool = True,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    link_object(obj, collection, role=role, asset_key=asset_key, parent=parent)
    assign_material(obj, material)
    set_smooth(obj)
    if bevel:
        modifier = obj.modifiers.new("Soft_Rim_Bevel", "BEVEL")
        modifier.width = min(radius, depth) * 0.035
        modifier.segments = 2
    add_weighted_normals(obj)
    add_uv(obj)
    return obj


def create_torus(
    name: str,
    major_radius: float,
    minor_radius: float,
    location: tuple[float, float, float],
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    role: str,
    asset_key: str | None = None,
    parent: bpy.types.Object | None = None,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    major_segments: int = 72,
    minor_segments: int = 10,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(
        major_segments=major_segments,
        minor_segments=minor_segments,
        major_radius=major_radius,
        minor_radius=minor_radius,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    link_object(obj, collection, role=role, asset_key=asset_key, parent=parent)
    assign_material(obj, material)
    set_smooth(obj)
    add_uv(obj)
    return obj


def create_ellipsoid(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    role: str,
    asset_key: str | None = None,
    parent: bpy.types.Object | None = None,
    segments: int = 24,
    rings: int = 12,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    link_object(obj, collection, role=role, asset_key=asset_key, parent=parent)
    assign_material(obj, material)
    set_smooth(obj)
    add_uv(obj)
    return obj


def create_asset_root(asset_key: str, name: str, collection: bpy.types.Collection) -> bpy.types.Object:
    root = create_empty(name, collection, role="canonical", asset_key=asset_key, display_size=0.18)
    STATE.asset_roots[asset_key] = root
    return root


def build_pet_bottle() -> None:
    asset_key = "pet_bottle"
    collection = collection_for_asset(asset_key)
    root = create_asset_root(asset_key, "PET_Bottle_Root", collection)
    mat_pet = STATE.materials["MAT_PET_Clear"]
    mat_edge = STATE.materials["MAT_PET_Edge"]
    mat_scuff = STATE.materials["MAT_PET_Scuff"]

    profile = [
        (-1.18, 0.12),
        (-1.12, 0.34),
        (-1.04, 0.40),
        (-0.92, 0.36),
        (-0.78, 0.39),
        (-0.45, 0.38),
        (-0.05, 0.365),
        (0.38, 0.38),
        (0.72, 0.36),
        (0.88, 0.30),
        (1.00, 0.23),
        (1.12, 0.17),
        (1.28, 0.16),
        (1.35, 0.18),
    ]
    segments = 96
    vertices: list[tuple[float, float, float]] = []
    faces: list[tuple[int, ...]] = []

    for ring_index, (z, radius) in enumerate(profile):
        for seg in range(segments):
            angle = math.tau * seg / segments
            lower = max(0.0, min(1.0, (-0.72 - z) / 0.46))
            foot_wave = 1.0 + lower * (0.12 * math.cos(angle * 5.0) + 0.035 * math.cos(angle * 10.0))
            hand_wobble = 1.0 + 0.010 * math.sin(angle * 3.0 + z * 4.0) + 0.008 * math.cos(angle * 7.0 - z)
            dent = -0.032 * math.exp(-((z - 0.25) ** 2) / 0.22) * max(0.0, math.cos(angle - 0.65))
            dent += -0.018 * math.exp(-((z + 0.28) ** 2) / 0.16) * max(0.0, math.cos(angle + 2.15))
            final_radius = max(0.055, radius * foot_wave * hand_wobble + dent)
            x = math.cos(angle) * final_radius
            y = math.sin(angle) * (final_radius + dent * 0.22)
            vertices.append((x, y, z))

    for ring in range(len(profile) - 1):
        for seg in range(segments):
            a = ring * segments + seg
            b = ring * segments + (seg + 1) % segments
            c = (ring + 1) * segments + (seg + 1) % segments
            d = (ring + 1) * segments + seg
            faces.append((a, b, c, d))

    bottom_center_index = len(vertices)
    vertices.append((0.0, 0.0, profile[0][0]))
    for seg in range(segments):
        faces.append((bottom_center_index, seg, (seg + 1) % segments))

    body = create_mesh_object(
        "PET_Bottle_Body",
        vertices,
        faces,
        collection,
        mat_pet,
        role="canonical",
        asset_key=asset_key,
        parent=root,
        smooth=True,
    )
    body.modifiers.new("Bottle_Weighted_Normals", "WEIGHTED_NORMAL")

    for name, radius, z, minor in [
        ("PET_Base_Foot_Ridge", 0.352, -1.045, 0.008),
        ("PET_Lower_Grip_Ring", 0.382, -0.54, 0.006),
        ("PET_Midbody_Subtle_Ring", 0.367, 0.16, 0.0045),
        ("PET_Shoulder_Read_Ring", 0.248, 0.97, 0.007),
        ("PET_Neck_Ring", 0.168, 1.18, 0.010),
        ("PET_Mouth_Rim", 0.181, 1.35, 0.012),
    ]:
        create_torus(name, radius, minor, (0.0, 0.0, z), mat_edge, collection, "canonical", asset_key, root)

    for index in range(5):
        angle = math.tau * index / 5.0 + 0.18
        create_ellipsoid(
            f"PET_Base_Foot_{index + 1}",
            (math.cos(angle) * 0.245, math.sin(angle) * 0.245, -1.145),
            (0.072, 0.036, 0.030),
            mat_edge,
            collection,
            "canonical",
            asset_key,
            root,
            segments=18,
            rings=8,
        )

    for index, (z, angle, length) in enumerate(
        [
            (-0.18, 0.32, 0.19),
            (0.22, 1.12, 0.15),
            (0.52, -0.75, 0.13),
            (-0.62, 2.60, 0.16),
            (0.05, 2.05, 0.10),
        ]
    ):
        radius = 0.385
        location = (math.cos(angle) * radius, math.sin(angle) * radius, z)
        create_beveled_box(
            f"PET_Soft_Scuff_{index + 1}",
            (length, 0.004, 0.012),
            location,
            mat_scuff,
            collection,
            "canonical",
            asset_key,
            root,
            rotation=(0.0, 0.0, angle + math.pi / 2.0),
            bevel_width=0.002,
            bevel_segments=1,
        )

    create_empty("GRAB_PIVOT", collection, "canonical", asset_key, root, (0.0, 0.0, 0.0), display_size=0.13)
    create_empty("SNAP_NOSE", collection, "canonical", asset_key, root, (0.0, 0.0, 1.42), display_size=0.10)
    for index, angle in enumerate([math.radians(90), math.radians(210), math.radians(330)], start=1):
        create_empty(
            f"SNAP_FIN_{index}",
            collection,
            "canonical",
            asset_key,
            root,
            (math.cos(angle) * 0.39, math.sin(angle) * 0.39, -0.50),
            display_size=0.09,
        )
    create_empty("BOTTLE_CENTER_REFERENCE", collection, "canonical", asset_key, root, (0.0, 0.0, 0.02), display_size=0.11)


def build_paper_cone() -> None:
    asset_key = "paper_nose_cone"
    collection = collection_for_asset(asset_key)
    root = create_asset_root(asset_key, "Paper_Nose_Cone_Root", collection)
    mat_paper = STATE.materials["MAT_Paper_OffWhite"]
    mat_edge = STATE.materials["MAT_Paper_Edge"]
    segments = 72
    height = 0.78
    base_radius = 0.34
    vertices: list[tuple[float, float, float]] = [(0.018, -0.012, height)]

    for seg in range(segments):
        angle = math.tau * seg / segments
        wobble = 1.0 + 0.028 * math.sin(angle * 3.0 + 0.35) + 0.010 * math.cos(angle * 7.0)
        z_offset = 0.012 * math.sin(angle * 5.0)
        vertices.append((math.cos(angle) * base_radius * wobble, math.sin(angle) * base_radius, z_offset))

    faces = []
    for seg in range(segments):
        faces.append((0, 1 + seg, 1 + ((seg + 1) % segments)))

    cone = create_mesh_object(
        "Paper_Nose_Cone_Body",
        vertices,
        faces,
        collection,
        mat_paper,
        "canonical",
        asset_key,
        root,
        smooth=True,
    )
    cone.modifiers.new("Paper_Weighted_Normals", "WEIGHTED_NORMAL")
    create_torus("Paper_Nose_Cone_Lower_Edge", base_radius, 0.008, (0.0, 0.0, 0.0), mat_edge, collection, "canonical", asset_key, root)

    seam_angle = math.radians(34.0)
    seam_width = math.radians(7.0)
    seam_vertices: list[tuple[float, float, float]] = []
    for z, radius in [(0.015, base_radius * 1.012), (height * 0.90, base_radius * 0.105)]:
        for angle in [seam_angle - seam_width * 0.5, seam_angle + seam_width * 0.5]:
            seam_vertices.append((math.cos(angle) * radius, math.sin(angle) * radius, z))
    seam_faces = [(0, 1, 3, 2)]
    create_mesh_object(
        "Paper_Nose_Cone_Overlap_Seam",
        seam_vertices,
        seam_faces,
        collection,
        mat_edge,
        "canonical",
        asset_key,
        root,
        smooth=False,
    )
    create_empty("CONE_BASE_PIVOT", collection, "canonical", asset_key, root, (0.0, 0.0, 0.0), display_size=0.10)


def build_cardboard_fin() -> None:
    asset_key = "cardboard_fin"
    collection = collection_for_asset(asset_key)
    root = create_asset_root(asset_key, "Cardboard_Fin_Root", collection)
    mat_face = STATE.materials["MAT_Cardboard"]
    mat_edge = STATE.materials["MAT_Cardboard_Edge"]
    thickness = 0.052
    points = [
        (0.00, -0.33),
        (0.12, -0.36),
        (0.70, -0.22),
        (0.78, 0.20),
        (0.24, 0.48),
        (0.02, 0.34),
    ]
    vertices: list[tuple[float, float, float]] = []
    for side in [-thickness * 0.5, thickness * 0.5]:
        for index, (x, z) in enumerate(points):
            edge_wobble = 0.012 * math.sin(index * 1.8 + x * 4.0)
            warp = 0.018 * math.sin(x * 5.5 + z * 2.0)
            vertices.append((x + edge_wobble, side + warp, z + 0.006 * math.cos(index * 2.1)))

    faces = [
        (0, 1, 2, 3, 4, 5),
        (11, 10, 9, 8, 7, 6),
    ]
    for index in range(len(points)):
        next_index = (index + 1) % len(points)
        faces.append((index, next_index, next_index + len(points), index + len(points)))

    mesh = bpy.data.meshes.new("Cardboard_Fin_Body_Mesh")
    mark_datablock(mesh)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Cardboard_Fin_Body", mesh)
    link_object(obj, collection, "canonical", asset_key, root)
    obj.data.materials.append(mat_face)
    obj.data.materials.append(mat_edge)
    for poly_index, polygon in enumerate(obj.data.polygons):
        polygon.material_index = 0 if poly_index < 2 else 1
    add_uv(obj)
    add_weighted_normals(obj)

    for index, z in enumerate([-0.18, -0.02, 0.14, 0.30], start=1):
        create_beveled_box(
            f"Cardboard_Fiber_Line_{index}",
            (0.56, 0.005, 0.010),
            (0.34, thickness * 0.64, z),
            mat_edge,
            collection,
            "canonical",
            asset_key,
            root,
            rotation=(0.0, 0.0, math.radians(3.0 + index * 1.5)),
            bevel_width=0.0015,
            bevel_segments=1,
        )
    for index, (x, z, rot) in enumerate([(0.10, -0.34, -8.0), (0.68, -0.13, 12.0), (0.41, 0.39, -14.0)], start=1):
        create_beveled_box(
            f"Cardboard_Cut_Mark_{index}",
            (0.075, 0.006, 0.014),
            (x, thickness * 0.69, z),
            mat_edge,
            collection,
            "canonical",
            asset_key,
            root,
            rotation=(0.0, 0.0, math.radians(rot)),
            bevel_width=0.0015,
            bevel_segments=1,
        )

    create_empty("FIN_GRAB_PIVOT", collection, "canonical", asset_key, root, (0.08, 0.0, 0.0), display_size=0.10)
    create_empty("SNAP_CONTACT", collection, "canonical", asset_key, root, (0.0, 0.0, 0.0), display_size=0.10)
    create_empty("FIN_ROOT_REFERENCE", collection, "canonical", asset_key, root, (0.0, 0.0, 0.34), display_size=0.08)
    create_empty("FIN_TIP_REFERENCE", collection, "canonical", asset_key, root, (0.78, 0.0, 0.20), display_size=0.08)


def build_launch_stand() -> None:
    asset_key = "launch_stand"
    collection = collection_for_asset(asset_key)
    root = create_asset_root(asset_key, "Launch_Stand_Root", collection)
    mat_wood = STATE.materials["MAT_Wood_Base"]
    mat_plastic = STATE.materials["MAT_Plastic_Dark"]
    mat_metal = STATE.materials["MAT_Metal_Soft"]
    mat_indicator = STATE.materials["MAT_Indicator"]

    create_beveled_box("Launch_Stand_Base", (1.24, 0.82, 0.12), (0.0, 0.0, 0.06), mat_wood, collection, "canonical", asset_key, root, bevel_width=0.035, bevel_segments=3)
    create_beveled_box("Launch_Stand_Front_Foot", (1.34, 0.13, 0.10), (0.0, -0.40, 0.08), mat_plastic, collection, "canonical", asset_key, root, bevel_width=0.018)
    create_beveled_box("Launch_Stand_Back_Foot", (1.34, 0.13, 0.10), (0.0, 0.40, 0.08), mat_plastic, collection, "canonical", asset_key, root, bevel_width=0.018)
    create_beveled_box("Launch_Stand_Left_Upright", (0.08, 0.08, 0.62), (-0.26, 0.04, 0.40), mat_plastic, collection, "canonical", asset_key, root, bevel_width=0.012)
    create_beveled_box("Launch_Stand_Right_Upright", (0.08, 0.08, 0.62), (0.26, 0.04, 0.40), mat_plastic, collection, "canonical", asset_key, root, bevel_width=0.012)
    create_beveled_box("Launch_Stand_Soft_Cradle_A", (0.74, 0.055, 0.055), (0.0, -0.09, 0.54), mat_metal, collection, "canonical", asset_key, root, rotation=(0.0, 0.0, math.radians(0.0)), bevel_width=0.020)
    create_beveled_box("Launch_Stand_Soft_Cradle_B", (0.56, 0.055, 0.055), (0.0, 0.21, 0.43), mat_metal, collection, "canonical", asset_key, root, bevel_width=0.020)
    create_beveled_box("Launch_Stand_Abstract_Lever", (0.11, 0.44, 0.065), (0.45, -0.08, 0.21), mat_metal, collection, "canonical", asset_key, root, rotation=(0.0, 0.0, math.radians(-12.0)), bevel_width=0.018)
    create_cylinder("Launch_Stand_Round_Button", 0.095, 0.040, (-0.42, -0.18, 0.16), mat_plastic, collection, "canonical", asset_key, root, vertices=40)
    create_cylinder("Launch_Stand_Indicator_Lens", 0.060, 0.034, (-0.42, 0.06, 0.16), mat_indicator, collection, "canonical", asset_key, root, vertices=32)
    create_empty("ROCKET_PLACEMENT_POINT", collection, "canonical", asset_key, root, (0.0, 0.03, 0.61), display_size=0.12)


def build_workbench() -> None:
    asset_key = "workbench"
    collection = collection_for_asset(asset_key)
    root = create_asset_root(asset_key, "Workbench_Root", collection)
    mat_wood = STATE.materials["MAT_Wood_Workbench"]
    mat_dark = STATE.materials["MAT_Wood_Workbench_Dark"]
    mat_scratch = STATE.materials["MAT_Scratch_Dark"]
    mat_stain = STATE.materials["MAT_Stain"]

    create_beveled_box("Workbench_Top", (5.9, 3.25, 0.18), (0.0, 0.0, 0.0), mat_wood, collection, "canonical", asset_key, root, bevel_width=0.075, bevel_segments=6)
    for name, x, y in [
        ("Workbench_Leg_FL", -2.58, -1.36),
        ("Workbench_Leg_FR", 2.58, -1.36),
        ("Workbench_Leg_BL", -2.58, 1.36),
        ("Workbench_Leg_BR", 2.58, 1.36),
    ]:
        create_beveled_box(name, (0.25, 0.25, 1.15), (x, y, -0.65), mat_dark, collection, "canonical", asset_key, root, bevel_width=0.025)

    for index in range(16):
        x = -2.65 + index * 0.35
        y = math.sin(index * 1.35) * 1.25
        length = 0.18 + (index % 5) * 0.05
        create_beveled_box(
            f"Workbench_Scratch_{index + 1}",
            (length, 0.018, 0.006),
            (x, y, 0.095),
            mat_scratch,
            collection,
            "canonical",
            asset_key,
            root,
            rotation=(0.0, 0.0, math.radians((index % 7 - 3) * 8.0)),
            bevel_width=0.002,
            bevel_segments=1,
        )
    for index, (x, y, sx, sy) in enumerate([(-1.8, 0.72, 0.30, 0.16), (1.24, -0.82, 0.24, 0.13), (0.05, 1.05, 0.18, 0.10)], start=1):
        create_cylinder(
            f"Workbench_Soft_Stain_{index}",
            1.0,
            0.006,
            (x, y, 0.099),
            mat_stain,
            collection,
            "canonical",
            asset_key,
            root,
            vertices=40,
        ).scale = (sx, sy, 1.0)


def build_tape_roll() -> None:
    asset_key = "tape_roll"
    collection = collection_for_asset(asset_key)
    root = create_asset_root(asset_key, "Tape_Roll_Root", collection)
    mat_tape = STATE.materials["MAT_Tape_Clear"]
    mat_core = STATE.materials["MAT_Tape_Core"]

    create_torus("Tape_Roll_Body", 0.285, 0.058, (0.0, 0.0, 0.0), mat_tape, collection, "canonical", asset_key, root, major_segments=80, minor_segments=12)
    create_torus("Tape_Roll_Cardboard_Core", 0.170, 0.036, (0.0, 0.0, 0.0), mat_core, collection, "canonical", asset_key, root, major_segments=64, minor_segments=8)
    create_beveled_box(
        "Tape_Roll_Loose_End",
        (0.58, 0.095, 0.012),
        (0.55, -0.02, 0.01),
        mat_tape,
        collection,
        "canonical",
        asset_key,
        root,
        rotation=(0.0, 0.0, math.radians(-7.0)),
        bevel_width=0.009,
        bevel_segments=2,
    )
    create_beveled_box(
        "Tape_Roll_Loose_End_Curl",
        (0.13, 0.092, 0.012),
        (0.86, -0.06, 0.035),
        mat_tape,
        collection,
        "canonical",
        asset_key,
        root,
        rotation=(math.radians(10.0), 0.0, math.radians(-17.0)),
        bevel_width=0.009,
        bevel_segments=2,
    )


def create_props() -> None:
    collection = STATE.collections[("ENVIRONMENT", "Background_Props")]
    mat_pencil = STATE.materials["MAT_Pencil_Wood"]
    mat_graphite = STATE.materials["MAT_Graphite"]
    mat_cardboard = STATE.materials["MAT_Cardboard"]
    mat_paper = STATE.materials["MAT_Paper_OffWhite"]

    create_cylinder("Prop_Pencil_Body", 0.035, 0.92, (-1.98, -0.78, 0.135), mat_pencil, collection, "environment", vertices=12, rotation=(0.0, math.radians(90.0), math.radians(-16.0)))
    create_cylinder("Prop_Pencil_Tip", 0.020, 0.08, (-1.55, -0.91, 0.136), mat_graphite, collection, "environment", vertices=12, rotation=(0.0, math.radians(90.0), math.radians(-16.0)))
    create_beveled_box("Prop_Plain_Ruler", (0.95, 0.085, 0.018), (1.46, -1.06, 0.112), mat_paper, collection, "environment", rotation=(0.0, 0.0, math.radians(9.0)), bevel_width=0.006)
    for index, (x, y, rot, sx, sy) in enumerate(
        [(-2.16, 0.58, 13.0, 0.34, 0.20), (-1.74, 0.82, -9.0, 0.42, 0.17), (2.18, 0.52, 27.0, 0.31, 0.21)],
        start=1,
    ):
        create_beveled_box(
            f"Prop_Cardboard_Scrap_{index}",
            (sx, sy, 0.022),
            (x, y, 0.112),
            mat_cardboard,
            collection,
            "environment",
            rotation=(0.0, 0.0, math.radians(rot)),
            bevel_width=0.004,
            bevel_segments=1,
        )


def build_assets() -> None:
    build_pet_bottle()
    build_paper_cone()
    build_cardboard_fin()
    build_launch_stand()
    build_workbench()
    build_tape_roll()
    create_props()


def copy_object_for_instance(source: bpy.types.Object, name: str, collection: bpy.types.Collection, role: str, parent: bpy.types.Object) -> bpy.types.Object:
    obj = source.copy()
    obj.name = name
    obj.data = source.data
    collection.objects.link(obj)
    mark_datablock(obj, role=role, asset_key=source.get(ASSET_PROP))
    obj.parent = parent
    obj.location = source.location.copy()
    obj.rotation_euler = source.rotation_euler.copy()
    obj.scale = source.scale.copy()
    return obj


def create_asset_instance(
    asset_key: str,
    name: str,
    collection: bpy.types.Collection,
    role: str,
    location: tuple[float, float, float],
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    scale: tuple[float, float, float] = (1.0, 1.0, 1.0),
) -> bpy.types.Object:
    root = create_empty(name, collection, role=role, asset_key=asset_key, location=location, rotation=rotation, scale=scale, display_size=0.10)
    for source in list(bpy.data.objects):
        if source.get(ASSET_PROP) != asset_key or source.get(ROLE_PROP) != "canonical":
            continue
        if source.type not in {"MESH", "CURVE"}:
            continue
        copy_object_for_instance(source, f"{name}_{source.name}", collection, role, root)
    return root


def create_scene_instances() -> None:
    hero_col = STATE.collections[("HERO_ASSETS", "PET_Bottle")]
    cone_col = STATE.collections[("HERO_ASSETS", "Paper_Nose_Cone")]
    fin_col = STATE.collections[("HERO_ASSETS", "Cardboard_Fin")]
    stand_col = STATE.collections[("HERO_ASSETS", "Launch_Stand")]
    tape_col = STATE.collections[("HERO_ASSETS", "Tape_Roll")]
    workbench_col = STATE.collections[("ENVIRONMENT", "Workbench")]
    sheet_col = STATE.collections[("EXPORT_HELPERS",)]

    create_asset_instance("workbench", "Hero_Workbench", workbench_col, "hero", (0.0, 0.0, 0.0))
    create_asset_instance("pet_bottle", "Hero_PET_Bottle", hero_col, "hero", (-0.56, -0.12, 0.49), (0.0, math.radians(87.0), math.radians(-7.5)))
    create_asset_instance("paper_nose_cone", "Hero_Paper_Nose_Cone", cone_col, "hero", (1.08, -0.76, 0.18), (0.0, math.radians(83.0), math.radians(18.0)))
    create_asset_instance("cardboard_fin", "Hero_Cardboard_Fin_A", fin_col, "hero", (-0.54, -0.86, 0.125), (math.radians(1.5), 0.0, math.radians(24.0)))
    create_asset_instance("cardboard_fin", "Hero_Cardboard_Fin_B", fin_col, "hero", (0.18, 0.96, 0.125), (math.radians(-2.5), 0.0, math.radians(-16.0)))
    create_asset_instance("cardboard_fin", "Hero_Cardboard_Fin_C", fin_col, "hero", (-0.92, 1.02, 0.125), (math.radians(2.0), 0.0, math.radians(52.0)))
    create_asset_instance("tape_roll", "Hero_Tape_Roll", tape_col, "hero", (-1.78, -0.74, 0.185), (0.0, 0.0, math.radians(-12.0)))
    create_asset_instance("launch_stand", "Hero_Launch_Stand", stand_col, "hero", (1.66, 0.58, 0.115), (0.0, 0.0, math.radians(-8.0)))

    create_beveled_box(
        "Asset_Sheet_Neutral_Base",
        (6.4, 3.2, 0.035),
        (0.0, 0.0, -0.035),
        STATE.materials["MAT_Backdrop_Neutral"],
        sheet_col,
        "sheet",
        bevel_width=0.0,
    )
    create_asset_instance("pet_bottle", "Sheet_PET_Bottle", sheet_col, "sheet", (-1.48, 0.82, 0.34), (0.0, math.radians(89.0), math.radians(-8.0)), (0.62, 0.62, 0.62))
    create_asset_instance("paper_nose_cone", "Sheet_Paper_Nose_Cone", sheet_col, "sheet", (0.08, 0.88, 0.11), (0.0, math.radians(83.0), math.radians(12.0)), (0.88, 0.88, 0.88))
    create_asset_instance("cardboard_fin", "Sheet_Cardboard_Fin", sheet_col, "sheet", (1.34, 0.78, 0.08), (0.0, 0.0, math.radians(8.0)), (0.95, 0.95, 0.95))
    create_asset_instance("launch_stand", "Sheet_Launch_Stand", sheet_col, "sheet", (-1.58, -0.78, 0.05), (0.0, 0.0, math.radians(6.0)), (0.78, 0.78, 0.78))
    create_asset_instance("tape_roll", "Sheet_Tape_Roll", sheet_col, "sheet", (0.02, -0.80, 0.17), (0.0, 0.0, math.radians(-12.0)), (0.82, 0.82, 0.82))
    create_asset_instance("workbench", "Sheet_Workbench", sheet_col, "sheet", (1.56, -0.85, 0.08), (0.0, 0.0, math.radians(-5.0)), (0.30, 0.30, 0.30))


def hide_canonical_objects() -> None:
    for obj in bpy.data.objects:
        if obj.get(ROLE_PROP) == "canonical":
            obj.hide_render = True
            obj.hide_viewport = False
        elif obj.get(ROLE_PROP) == "sheet":
            obj.hide_render = True
        elif obj.get(ROLE_PROP) in {"hero", "environment"}:
            obj.hide_render = False


def set_role_render_visibility(*, hero: bool, sheet: bool, environment: bool, canonical: bool = False) -> None:
    for obj in bpy.data.objects:
        role = obj.get(ROLE_PROP)
        if role == "hero":
            obj.hide_render = not hero
        elif role == "sheet":
            obj.hide_render = not sheet
        elif role == "environment":
            obj.hide_render = not environment
        elif role == "canonical":
            obj.hide_render = not canonical


def create_background() -> None:
    collection = STATE.collections[("ENVIRONMENT", "Background_Props")]
    material = STATE.materials["MAT_Backdrop_Neutral"]
    create_beveled_box("Workshop_Back_Wall", (6.4, 0.08, 2.8), (0.0, 1.82, 1.23), material, collection, "environment", bevel_width=0.0)
    create_beveled_box("Workshop_Left_Shadow_Panel", (0.08, 3.2, 2.1), (-3.04, 0.18, 1.02), material, collection, "environment", bevel_width=0.0)


def look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def create_camera(
    name: str,
    location: tuple[float, float, float],
    target: tuple[float, float, float],
    lens: float = 50.0,
    ortho_scale: float | None = None,
    dof: bool = False,
) -> bpy.types.Object:
    collection = STATE.collections[("CAMERAS",)]
    bpy.ops.object.camera_add(location=location)
    camera = bpy.context.object
    camera.name = name
    link_object(camera, collection, "camera")
    look_at(camera, target)
    camera.data.lens = lens
    if ortho_scale is not None:
        camera.data.type = "ORTHO"
        camera.data.ortho_scale = ortho_scale
    if dof:
        camera.data.dof.use_dof = True
        camera.data.dof.focus_distance = (Vector(location) - Vector(target)).length
        camera.data.dof.aperture_fstop = 8.0
    return camera


def create_lighting() -> None:
    collection = STATE.collections[("LIGHTING",)]
    lights = [
        ("Warm_Key_Area", "AREA", (0.2, -2.8, 3.1), (-58.0, 0.0, 10.0), 520.0, 4.0, (1.0, 0.82, 0.62)),
        ("Cool_Fill_Area", "AREA", (-2.6, 0.4, 2.0), (-45.0, 0.0, -48.0), 95.0, 3.4, (0.62, 0.72, 1.0)),
        ("PET_Rim_Area", "AREA", (2.6, 1.5, 1.55), (-38.0, 0.0, 132.0), 145.0, 1.25, (0.78, 0.92, 1.0)),
    ]
    for name, light_type, location, rotation_deg, energy, size, color in lights:
        bpy.ops.object.light_add(type=light_type, location=location, rotation=tuple(math.radians(value) for value in rotation_deg))
        light = bpy.context.object
        light.name = name
        link_object(light, collection, "light")
        light.data.energy = energy
        light.data.color = color
        if hasattr(light.data, "size"):
            light.data.size = size


def set_color_management() -> None:
    view_settings = bpy.context.scene.view_settings
    for candidate in ["AgX", "Filmic", "Standard"]:
        try:
            view_settings.view_transform = candidate
            STATE.color_view = candidate
            break
        except TypeError:
            continue
    for candidate in ["Medium High Contrast", "Medium Contrast", "None"]:
        try:
            view_settings.look = candidate
            break
        except TypeError:
            continue
    view_settings.exposure = 0.0
    view_settings.gamma = 1.0


def configure_render(engine_option: str) -> None:
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.film_transparent = False
    scene.world.color = (0.055, 0.060, 0.058)

    candidates: list[str]
    if engine_option == "CYCLES":
        candidates = ["CYCLES"]
    elif engine_option in {"EEVEE", "BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"}:
        candidates = ["BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"]
    else:
        candidates = ["CYCLES", "BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"]

    chosen = None
    for candidate in candidates:
        try:
            scene.render.engine = candidate
            chosen = scene.render.engine
            break
        except TypeError:
            continue
    if chosen is None:
        scene.render.engine = "BLENDER_WORKBENCH"
        chosen = scene.render.engine
    STATE.render_engine = chosen

    if chosen == "CYCLES":
        scene.cycles.samples = 64
        scene.cycles.preview_samples = 24
        scene.cycles.use_denoising = True
        scene.cycles.max_bounces = 5
        scene.cycles.transparent_max_bounces = 5
    else:
        if hasattr(scene, "eevee"):
            eevee = scene.eevee
            if hasattr(eevee, "use_gtao"):
                eevee.use_gtao = True
                eevee.gtao_distance = 3.0
                eevee.gtao_factor = 1.0
            if hasattr(eevee, "taa_render_samples"):
                eevee.taa_render_samples = 96

    set_color_management()


def create_cameras_and_scene() -> None:
    create_background()
    create_lighting()
    create_camera("CAM_Hero", (3.65, -4.35, 2.05), (0.04, -0.05, 0.42), lens=52.0, dof=True)
    create_camera("CAM_AssetSheet", (0.0, -5.25, 3.05), (0.0, 0.0, 0.20), lens=55.0, ortho_scale=4.75)


def canonical_objects_for_asset(asset_key: str) -> list[bpy.types.Object]:
    objects = [
        obj
        for obj in bpy.data.objects
        if obj.get(ASSET_PROP) == asset_key and obj.get(ROLE_PROP) == "canonical"
    ]
    objects.sort(key=lambda obj: obj.name)
    return objects


def export_asset(asset_key: str) -> Path:
    output = EXPORT_DIR / ASSET_EXPORTS[asset_key]
    bpy.ops.object.select_all(action="DESELECT")
    objects = canonical_objects_for_asset(asset_key)
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
        export_extras=True,
    )
    STATE.exported.append(output)
    return output


def export_assets() -> None:
    for asset_key in ASSET_EXPORTS:
        export_asset(asset_key)


def render_still(path: Path, camera_name: str) -> None:
    camera = bpy.data.objects[camera_name]
    bpy.context.scene.camera = camera
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    STATE.rendered.append(path)


def render_outputs(skip_renders: bool) -> None:
    if skip_renders:
        return

    set_role_render_visibility(hero=True, sheet=False, environment=True, canonical=False)
    render_still(RENDER_OUTPUTS["hero"], "CAM_Hero")

    set_role_render_visibility(hero=False, sheet=True, environment=False, canonical=False)
    render_still(RENDER_OUTPUTS["asset_sheet"], "CAM_AssetSheet")

    original_materials: dict[str, list[bpy.types.Material]] = {}
    debug_material = STATE.materials["MAT_Debug_Wireframe"]
    for obj in bpy.data.objects:
        if obj.type == "MESH" and obj.get(ROLE_PROP) in {"hero", "environment"}:
            original_materials[obj.name] = list(obj.data.materials)
            obj.data.materials.clear()
            obj.data.materials.append(debug_material)

    set_role_render_visibility(hero=True, sheet=False, environment=True, canonical=False)
    render_still(RENDER_OUTPUTS["wireframe"], "CAM_Hero")

    for obj_name, materials in original_materials.items():
        obj = bpy.data.objects.get(obj_name)
        if obj is None:
            continue
        obj.data.materials.clear()
        for material in materials:
            obj.data.materials.append(material)

    set_role_render_visibility(hero=True, sheet=False, environment=True, canonical=False)


def calculate_poly_counts() -> dict[str, int]:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    counts: dict[str, int] = {}
    for asset_key in ASSET_EXPORTS:
        count = 0
        for obj in canonical_objects_for_asset(asset_key):
            if obj.type != "MESH":
                continue
            evaluated = obj.evaluated_get(depsgraph)
            mesh = evaluated.to_mesh()
            mesh.calc_loop_triangles()
            count += len(mesh.loop_triangles)
            evaluated.to_mesh_clear()
        counts[asset_key] = count
    STATE.poly_counts = counts
    return counts


def collection_exists(path: tuple[str, ...]) -> bool:
    collection = bpy.data.collections.get(path[-1])
    if collection is None:
        return False
    if len(path) == 1:
        return True
    parent = bpy.data.collections.get(path[-2])
    return parent is not None and collection.name in parent.children


def validate_outputs(skip_renders: bool) -> dict[str, object]:
    collections_missing = ["/".join(path) for path in REQUIRED_COLLECTION_PATHS if not collection_exists(path)]
    objects_missing = [name for name in REQUIRED_OBJECTS if bpy.data.objects.get(name) is None]
    materials_missing = [name for name in REQUIRED_MATERIALS if bpy.data.materials.get(name) is None]
    markers_missing = [name for name in REQUIRED_MARKERS if bpy.data.objects.get(name) is None]
    exports_missing = [str(EXPORT_DIR / filename) for filename in ASSET_EXPORTS.values() if not (EXPORT_DIR / filename).exists()]
    renders_expected = [] if skip_renders else [path for path in RENDER_OUTPUTS.values()]
    renders_missing = [str(path) for path in renders_expected if not path.exists()]
    duplicate_object_names: list[str] = []
    seen: set[str] = set()
    for obj in bpy.data.objects:
        if obj.name in seen:
            duplicate_object_names.append(obj.name)
        seen.add(obj.name)
    orphaned_managed_objects = [
        obj.name
        for obj in bpy.data.objects
        if is_managed(obj) and len(obj.users_collection) == 0
    ]

    validation = {
        "collections_missing": collections_missing,
        "objects_missing": objects_missing,
        "materials_missing": materials_missing,
        "markers_missing": markers_missing,
        "exports_missing": exports_missing,
        "renders_missing": renders_missing,
        "duplicate_object_names": duplicate_object_names,
        "orphaned_managed_objects": orphaned_managed_objects,
    }
    STATE.validation = validation
    return validation


def write_report(command_line: str, skip_renders: bool) -> None:
    elapsed = time.perf_counter() - STATE.started_at
    validation = STATE.validation
    exported_files = [EXPORT_DIR / filename for filename in ASSET_EXPORTS.values()]
    render_files = list(RENDER_OUTPUTS.values())

    lines = [
        "# Hero Assets v1 Report",
        "",
        "## Summary",
        "",
        "- Scope: static Blender hero scene and individual GLB exports for the Rocket Workshop.",
        "- Product direction: handmade scientific model realism, without operational launcher details.",
        f"- Blender version: {bpy.app.version_string}",
        f"- Render engine used: {STATE.render_engine}",
        f"- Color management: {STATE.color_view}",
        f"- Approximate execution time: {elapsed:.1f} seconds",
        "",
        "## Files Created",
        "",
        f"- Source blend: `{BLEND_PATH.relative_to(ROOT)}`",
    ]
    lines.extend([f"- GLB: `{path.relative_to(ROOT)}`" for path in exported_files])
    if skip_renders:
        lines.append("- Renders: skipped by `--skip-renders`.")
    else:
        lines.extend([f"- Render: `{path.relative_to(ROOT)}`" for path in render_files])
    lines.append(f"- Report: `{REPORT_PATH.relative_to(ROOT)}`")

    lines.extend(
        [
            "",
            "## Polygon Counts",
            "",
            "| Asset | Approx. triangles | Target |",
            "| --- | ---: | ---: |",
        ]
    )
    targets = {
        "pet_bottle": 15000,
        "paper_nose_cone": 3000,
        "cardboard_fin": 3000,
        "launch_stand": 15000,
        "workbench": 10000,
        "tape_roll": 5000,
    }
    for asset_key, triangles in STATE.poly_counts.items():
        lines.append(f"| {asset_key} | {triangles} | {targets.get(asset_key, 0)} |")

    lines.extend(
        [
            "",
            "## Materials Created",
            "",
        ]
    )
    for material_name in sorted(STATE.materials):
        if material_name != "MAT_Debug_Wireframe":
            lines.append(f"- `{material_name}`")

    lines.extend(
        [
            "",
            "## Exports",
            "",
        ]
    )
    for path in exported_files:
        status = "ok" if path.exists() else "missing"
        lines.append(f"- `{path.relative_to(ROOT)}`: {status}")

    lines.extend(
        [
            "",
            "## Renders",
            "",
        ]
    )
    if skip_renders:
        lines.append("- Render generation was skipped by command-line option.")
    else:
        for path in render_files:
            status = "ok" if path.exists() else "missing"
            lines.append(f"- `{path.relative_to(ROOT)}`: {status}")

    lines.extend(
        [
            "",
            "## Validation",
            "",
        ]
    )
    for key, values in validation.items():
        if values:
            joined = ", ".join(f"`{value}`" for value in values)
            lines.append(f"- {key}: {joined}")
        else:
            lines.append(f"- {key}: ok")

    lines.extend(
        [
            "",
            "## Known Limitations",
            "",
            "- This is a procedural first-pass model pack; final art direction still needs human visual approval.",
            "- PET scratches and surface noise are deliberately subtle and may need hand-authored texture work in v2.",
            "- Procedural noise nodes improve Blender renders but are not essential to recognizing the exported GLBs.",
            "- The launch stand is intentionally non-operational and avoids realistic pressure hardware.",
            "- Marker names are globally unique where Blender requires uniqueness; `FIN_GRAB_PIVOT` represents the fin GRAB_PIVOT role.",
            "",
            "## Suggested v2 Work",
            "",
            "- Hand-paint PET micro-scuffs and edge highlights after the visual direction is approved.",
            "- Create UV-authored cardboard fibers and paper seam variations.",
            "- Tune Godot import materials only after this Blender pass is approved.",
            "- Add optional LODs if runtime profiling asks for them.",
            "- Refine the hero composition based on human visual review.",
            "",
            "## Commands Executed",
            "",
            f"```powershell\n{command_line}\n```",
            "",
            "## Errors",
            "",
        ]
    )
    if STATE.errors:
        lines.extend([f"- {error}" for error in STATE.errors])
    else:
        lines.append("- None encountered during script execution.")

    lines.extend(
        [
            "",
            "## Human Review Needed",
            "",
            "- Confirm the PET bottle reads immediately as a reused PET bottle, not a generic transparent cylinder.",
            "- Confirm the cone reads as paper/card stock.",
            "- Confirm the fin reads as hand-cut cardboard.",
            "- Confirm the test stand feels like a safe fictional workshop prop rather than real pressure equipment.",
            "- Confirm the hero shot lighting and composition feel warm, tactile, and inviting.",
        ]
    )

    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def print_summary() -> None:
    print("\nHero assets v1 generation complete.")
    print(f"Blend: {BLEND_PATH}")
    print(f"Render engine: {STATE.render_engine}")
    for asset_key, count in STATE.poly_counts.items():
        print(f"Triangles {asset_key}: {count}")
    for path in STATE.exported:
        print(f"GLB: {path}")
    for path in STATE.rendered:
        print(f"Render: {path}")
    print(f"Report: {REPORT_PATH}")

    problems = [item for values in STATE.validation.values() for item in values]
    if problems:
        print("\nValidation warnings:")
        for key, values in STATE.validation.items():
            if values:
                print(f"- {key}: {values}")
    else:
        print("Validation: all required outputs and scene items found.")


def save_blend() -> None:
    try:
        bpy.context.preferences.filepaths.save_version = 0
    except Exception:
        pass
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    backup_path = BLEND_PATH.with_suffix(".blend1")
    if backup_path.exists():
        backup_path.unlink()


def main() -> None:
    options = parse_args()
    command_line = " ".join(sys.argv)
    skip_renders = bool(options["skip_renders"])

    ensure_dirs()
    clear_managed_scene()
    create_collections()
    create_materials()
    configure_render(str(options["engine"]))
    build_assets()
    create_scene_instances()
    create_cameras_and_scene()
    hide_canonical_objects()
    save_blend()
    export_assets()
    render_outputs(skip_renders)
    calculate_poly_counts()
    validate_outputs(skip_renders)
    set_role_render_visibility(hero=True, sheet=False, environment=True, canonical=False)
    save_blend()
    write_report(command_line, skip_renders)
    print_summary()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        STATE.errors.append(f"{type(exc).__name__}: {exc}")
        traceback.print_exc()
        try:
            calculate_poly_counts()
            validate_outputs(skip_renders=False)
            write_report(" ".join(sys.argv), skip_renders=False)
        except Exception:
            traceback.print_exc()
        raise
