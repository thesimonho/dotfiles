"""Translate Godot/Unity editor requests into a host Ghostty/Neovim window."""

import argparse
import os
import re
import uuid
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--project", type=Path)
parser.add_argument("--file", type=Path)
parser.add_argument("--line", type=int, default=1)
parser.add_argument("--column", type=int, default=1)
parser.add_argument("--zero-based", action="store_true")
parser.add_argument("--reuse-window", action="store_true")
parser.add_argument("-g", "--goto", dest="location")
parser.add_argument("paths", nargs="*")
args = parser.parse_args()

project = args.project
file = args.file
line, column = args.line, args.column
if args.location:
    match = re.fullmatch(r"(.*?):(\d+)(?::(\d+))?", args.location)
    if match:
        file = Path(match[1])
        line, column = int(match[2]), int(match[3] or 1)
    else:
        file = Path(args.location)
for path in args.paths:
    path = Path(path)
    if path.is_dir():
        project = path
    else:
        file = path
if args.zero_based:
    line, column = line + 1, column + 1
if file:
    file = file.resolve()
project = (project or (file.parent if file else Path.cwd())).resolve()
# Host binaries come from the normal profile, never the Flatpak runtime.
os.environ["PATH"] = os.pathsep.join(
    [
        str(Path.home() / ".nix-profile/bin"),
        "/usr/local/bin",
        "/usr/bin",
        os.environ.get("PATH", ""),
    ]
)
socket = (
    Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
    / f"gamedev-nvim-{uuid.uuid4().hex}.sock"
)
command = [
    "ghostty",
    "--gtk-single-instance=false",
    "--initial-window=true",
    "--quit-after-last-window-closed=true",
    f"--working-directory={project}",
    "-e",
    "nvim",
    "--listen",
    str(socket),
]
if file:
    command += [
        "--cmd",
        f"autocmd VimEnter * ++once call cursor({max(1, line)},{max(1, column)})",
        "--",
        str(file),
    ]
os.execvp(command[0], command)
