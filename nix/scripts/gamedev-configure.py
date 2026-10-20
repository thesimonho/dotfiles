"""Merge managed external-editor settings without replacing other preferences."""

import base64
import json
import xml.etree.ElementTree as ET
from pathlib import Path

home = Path.home()
bridge = str(home / ".local/share/gamedev/bin/code")
godot_dir = home / ".var/app/org.godotengine.GodotSharp/config/godot"
settings = {
    "filesystem/import/blender/blender_path": json.dumps(
        str(home / ".local/share/godot-flatpak/bin/blender")
    ),
    "text_editor/external/use_external_editor": "true",
    "text_editor/external/exec_path": json.dumps(bridge),
    "text_editor/external/exec_flags": json.dumps(
        '--project "{project}" --file "{file}" --line {line} --column {col} --zero-based'
    ),
    "dotnet/editor/external_editor": "6",
    "dotnet/editor/custom_exec_path": json.dumps(bridge),
    "dotnet/editor/custom_exec_path_args": json.dumps(
        '--project "{project}" --file "{file}" --line {line} --column {col} --zero-based'
    ),
}
# Update installed editor versions; do not guess a future version's filename.
for path in godot_dir.glob("editor_settings-*.tres"):
    text = path.read_text()
    if "[resource]" not in text:
        raise ValueError(f"Missing resource section: {path}")
    remaining = dict(settings)
    lines = []
    for line in text.splitlines():
        key = line.split(" = ", 1)[0]
        if key in settings:
            line = f"{key} = {settings[key]}"
            remaining.pop(key, None)
        lines.append(line)
        if line == "[resource]":
            insert_at = len(lines)
    lines[insert_at:insert_at] = [
        f"{key} = {value}" for key, value in remaining.items()
    ]
    path.write_text("\n".join(lines) + "\n")

path = home / ".var/app/com.unity.UnityHub/data/unity3d/prefs"
path.parent.mkdir(parents=True, exist_ok=True)
tree = (
    ET.parse(path)
    if path.exists()
    else ET.ElementTree(ET.Element("unity_prefs", version_major="1", version_minor="1"))
)
root = tree.getroot()
for key, value in {
    "kScriptsDefaultApp": bridge,
    "kScriptEditorArgs" + bridge: '"$(ProjectPath)" -g "$(File):$(Line):$(Column)"',
    "kScriptEditorArgs": '"$(ProjectPath)" -g "$(File):$(Line):$(Column)"',
}.items():
    node = next(
        (node for node in root.findall("pref") if node.get("name") == key), None
    )
    if node is None:
        node = ET.SubElement(root, "pref", name=key, type="string")
    node.text = base64.b64encode(value.encode()).decode()
ET.indent(tree)
tree.write(path, encoding="unicode")
