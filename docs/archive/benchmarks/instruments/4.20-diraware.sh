#!/usr/bin/env bash
set -Eeuo pipefail
LOG="$HOME/log-${0##*/}.log"
exec > >(tee "$LOG") 2>&1

# t-diraware.sh — dir-aware-display prototype + its own cost measurement.
# Row design (CHOICES `dir-aware-display`): a small user-editable mapping
# file (path-prefix -> display profile) read by a PROMPT_COMMAND hook that
# fires only on directory CHANGE, driving kitty tab/window title and prompt
# color. Hot path (unchanged dir) must be ~free — BUDGET's per-prompt
# bucket is the strictest in the ledger (direnv's ungated 15 ms/prompt is
# the cautionary tale). Fork-free everywhere; bash builtins only.

MAP="${XDG_CONFIG_HOME:-$HOME/.config}/bunne/dirmap.conf"
mkdir -p "${MAP%/*}"
cat >"$MAP" <<'EOF'
# prefix	name	ansi-color
/home/bunne/tradeswell	work	1
/home/bunne/github	oss	5
/home/bunne/t-proj	scratch	3
EOF

# --- the prototype (this block is what would ship, ~25 lines) ---
_bunne_dirmap_load() {
	_BUNNE_PREFIXES=() _BUNNE_NAMES=() _BUNNE_COLORS=()
	local p n c
	while IFS=$'\t' read -r p n c; do
		[[ -z $p || $p == \#* ]] && continue
		_BUNNE_PREFIXES+=("$p") _BUNNE_NAMES+=("$n") _BUNNE_COLORS+=("$c")
	done <"$MAP"
}

_bunne_dirhook() {
	[[ $PWD == "${_BUNNE_LAST_PWD-}" ]] && return 0
	_BUNNE_LAST_PWD=$PWD
	local i name="" color=2
	for i in "${!_BUNNE_PREFIXES[@]}"; do
		if [[ $PWD == "${_BUNNE_PREFIXES[i]}" || $PWD == "${_BUNNE_PREFIXES[i]}"/* ]]; then
			name=${_BUNNE_NAMES[i]} color=${_BUNNE_COLORS[i]}
			break
		fi
	done
	if [[ -n $name ]]; then
		printf '\033]2;[%s] %s\007' "$name" "${PWD/#$HOME/\~}"
	else
		printf '\033]2;%s\007' "${PWD/#$HOME/\~}"
	fi
	_BUNNE_PROMPT_COLOR=$color
}
# --- end prototype ---

_bunne_dirmap_load
echo "map loaded: ${#_BUNNE_PREFIXES[@]} entries"

echo "--- functional demo"
for d in /home/bunne/tradeswell/mmm /home/bunne/github/x /tmp /home/bunne/t-proj; do
	PWD=$d _bunne_dirhook >/dev/null
	echo "PWD=$d -> color=$_BUNNE_PROMPT_COLOR last=$_BUNNE_LAST_PWD"
done

echo "--- cost: hot path (unchanged dir), 100k calls"
PWD=/home/bunne/tradeswell/mmm _bunne_dirhook >/dev/null
t0=$EPOCHREALTIME
for ((i = 0; i < 100000; i++)); do _bunne_dirhook; done >/dev/null
t1=$EPOCHREALTIME
echo "unchanged-dir: $(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.2f", (b-a)*1e9/100000}') ns/call"

echo "--- cost: change path (alternating mapped dirs), 10k calls"
t0=$EPOCHREALTIME
for ((i = 0; i < 5000; i++)); do
	PWD=/home/bunne/tradeswell _bunne_dirhook
	PWD=/home/bunne/github _bunne_dirhook
done >/dev/null
t1=$EPOCHREALTIME
echo "changed-dir (match): $(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.2f", (b-a)*1e6/10000}') us/call"

echo "--- cost: change path, worst case (no match, full scan), 10k calls"
t0=$EPOCHREALTIME
for ((i = 0; i < 5000; i++)); do
	PWD=/tmp _bunne_dirhook
	PWD=/var _bunne_dirhook
done >/dev/null
t1=$EPOCHREALTIME
echo "changed-dir (no match): $(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.2f", (b-a)*1e6/10000}') us/call"

echo "DONE $(date -Is)"
