#!/usr/bin/env python3
"""Pin every git package in packages/*.cmake to a commit: adds `GIT_RESET <sha>`
(the branch head right now) where a package only follows a branch. mpv and ffmpeg
are pinned by tag variables instead (MPV_REF / FFMPEG_REF).

  python3 scripts/pin_deps.py            # pin unpinned packages
  python3 scripts/pin_deps.py --update   # re-pin everything (dependency bump)
"""
import pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / "packages"
SKIP = {"mpv", "ffmpeg"}
update = "--update" in sys.argv

for f in sorted(ROOT.glob("*.cmake")):
    text = f.read_text()
    m_repo = re.search(r"GIT_REPOSITORY\s+(\S+)", text)
    if not m_repo or f.stem in SKIP:
        continue
    has_reset = re.search(r"^\s*GIT_RESET\s+\S+", text, re.M)
    if has_reset and not update:
        continue
    m_tag = re.search(r"^\s*GIT_TAG\s+(\S+)", text, re.M)
    ref = m_tag.group(1) if m_tag else "HEAD"
    out = subprocess.run(["git", "ls-remote", m_repo.group(1), ref],
                         capture_output=True, text=True, timeout=60).stdout.split()
    if not out:
        print(f"!! {f.stem}: could not resolve {ref}", file=sys.stderr)
        continue
    sha = out[0]
    if has_reset:
        text = re.sub(r"^(\s*)GIT_RESET\s+\S+.*$", rf"\g<1>GIT_RESET {sha}", text, count=1, flags=re.M)
    else:
        text = re.sub(r"^(\s*)GIT_REPOSITORY\s+\S+\s*$",
                      lambda m: f"{m.group(0)}\n{m.group(1)}GIT_RESET {sha}", text, count=1, flags=re.M)
    f.write_text(text)
    print(f"{f.stem}: {ref} -> {sha[:12]}")
