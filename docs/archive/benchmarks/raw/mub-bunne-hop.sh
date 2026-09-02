#!/usr/bin/env bash
# bunne-hop.sh — ascii-bunnies row prototype: flip-book player, bash
# builtins only. ONE fork at init (the <(:)  subshell whose pipe fd gives
# read -t a fork-free timeout); ZERO forks per frame; exits when done —
# no process outlives the animation (the row's design rule).
set -Eeuo pipefail

exec 9<> <(:) # init fork; fd 9 never EOFs (we hold the write end)

f1=$'\n\n  (\\_/)\n  (o.o)\n (>   <)\n=========='
f2=$'\n  (\\_/)\n  (o.o)\n  /   \\\n\n=========='
f3=$'  (\\_/)\n  (^.^)\n  /   \\\n\n\n=========='
f4=$'\n  (\\_/)\n  (o.o)\n  \\   /\n\n=========='

frames=("$f1" "$f2" "$f3" "$f4" "$f1")
cycles=${1:-3}
delay=${2:-0.09}

printf '\033[2J\033[?25l'
for ((c = 0; c < cycles; c++)); do
	for f in "${frames[@]}"; do
		printf '\033[H%s\n' "$f"
		read -rt "$delay" -u 9 || true
	done
done
printf '\033[?25h'
