#!/bin/bash -e
# Applies patches/<dep>/*.patch to deps/<dep> (plain source trees, so `patch`, not `git apply`).

ROOT=$(pwd)
for dep_path in patches/*; do
	[ -d "$dep_path" ] || continue
	dep=$(basename "$dep_path")
	for p in "$dep_path"/*.patch; do
		echo "Applying $p to $dep"
		patch -d "deps/$dep" -p1 -N --no-backup-if-mismatch < "$ROOT/$p"
	done
done
