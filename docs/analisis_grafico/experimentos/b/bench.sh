#!/usr/bin/env bash
# Mide FPS sin --fixed-fps ni --write-movie: bench.sh <features>
set -u
D=/tmp/claude-0/-home-user-game/3bec4478-e817-5ed9-8d65-70f79ec89943/scratchpad/gfx-exp-b
G=/home/user/game/.tools/godot/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64
FEATURES=${1:-}
timeout 300 xvfb-run -a -s "-screen 0 1400x1400x24" "$G" --path "$D" --rendering-driver opengl3 --audio-driver Dummy \
  -- --features="$FEATURES" --bench 2>&1 | grep -E "BENCH|ERROR|SCRIPT"
