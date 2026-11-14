#!/bin/bash
cd /Volumes/SSDMacMini/DevMacMini/Flutter/PaliDict || exit 1
export PATH="/Volumes/SSDMacMini/.local/bin:/opt/homebrew/bin:$PATH"
[ -f data/lite_final.db.dat ] && mv data/lite_final.db.dat data/lite_final.db
[ -f data/core_pack.dat ] && mv data/core_pack.dat data/core_final.db.gz
[ -d .git ] || git init -q
exec agy --dangerously-skip-permissions -i="MUSE_TASK_ID: palidict-20261114-phase1-build. REQUESTED_BY: Muse. Read the brief at .agy/briefs/BRIEF-PHASE1-BUILD.md in this repo and execute it end to end. Data files are in data/: lite_final.db (bundled Lite pack) and core_final.db.gz (Core pack; gunzip a copy if you need to inspect its schema). Follow the brief exactly and write the DONE file it specifies when finished."
