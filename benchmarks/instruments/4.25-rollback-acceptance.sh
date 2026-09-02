#!/usr/bin/env bash
# The snapshot-rollback acceptance test, minus the one step a script cannot do.
#
# `CHOICES.md` snapshot-boot-entries names the gate: snapshot -> canary file ->
# restore the snapshot from the Limine menu -> reboot -> canary gone, Docker data
# still there, "backup" entry puts the machine back. Selecting a snapshot is a
# keyboard act at the boot menu, so this script does the two halves around it and
# leaves a record that survives the rollback:
#
#   arm     take the snapshot, drop the canary, record the state to compare against
#   verify  after the restore + reboot: canary gone? Docker intact? caps intact?
#   undo    remove the canary if you abandon the test without restoring
#
# The record lives in $HOME, which is @home -- a different subvolume, so a
# rollback of @ cannot take the evidence with it. That is the same property the
# test is checking for /var/lib/docker, which is why it is worth stating.
#
# Usage: 4.25-rollback-acceptance.sh {arm|verify|undo} [--help]
set -Eeuo pipefail

CANARY=/rollback-canary.txt
RECORD="${XDG_STATE_HOME:-$HOME/.local/state}/bunne-rollback-acceptance"

usage() {
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit "${1:-0}"
}

state() {
	echo "## snapshot"
	sudo snapper -c root list | tail -3
	echo "## docker subvolumes"
	sudo btrfs subvolume list / | grep -E '@containerd|@dockervol' || echo "MISSING"
	echo "## caps"
	sudo btrfs qgroup show -re / | grep -E '@containerd|@dockervol' || echo "MISSING"
	echo "## docker content"
	sudo docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' 2>/dev/null | sort || echo "docker not answering"
	sudo find /var/lib/docker /var/lib/containerd -mindepth 1 -maxdepth 1 | sort
}

arm() {
	mkdir -p "$(dirname "$RECORD")"
	sudo snapper -c root create -d "rollback acceptance test — restore THIS one"
	local num
	num=$(sudo snapper -c root list | tail -1 | awk -F'|' '{gsub(/ /,"",$1); print $1}')
	# Written AFTER the snapshot, so a correct restore must remove it.
	echo "canary written $(date -Is) — a correct restore of snapshot $num deletes this file" |
		sudo tee "$CANARY" >/dev/null
	{
		echo "# armed $(date -Is), restore target: snapshot $num"
		state
	} >"$RECORD"
	echo
	echo "Armed. Restore snapshot $num from the Limine menu, reboot, then run: $0 verify" >&2
	echo "Record: $RECORD (on @home, so the rollback cannot eat it)" >&2
}

verify() {
	[ -r "$RECORD" ] || {
		echo "no record at $RECORD — run '$0 arm' first" >&2
		exit 1
	}
	local fail=0
	echo "== armed as =="
	head -1 "$RECORD"

	if [ -e "$CANARY" ]; then
		echo "FAIL: $CANARY still exists — the restore did not replace @."
		echo "      This is the failure snapper rollback already had here: it looked"
		echo "      correct and did nothing, because @ is pinned by name in two places."
		fail=1
	else
		echo "PASS: canary is gone — @ really was replaced."
	fi

	if findmnt -no TARGET /var/lib/docker >/dev/null 2>&1 &&
		findmnt -no TARGET /var/lib/containerd >/dev/null 2>&1; then
		echo "PASS: both Docker subvolumes are still mounted after the rollback."
	else
		echo "FAIL: a Docker subvolume is not mounted — the promotion did not survive."
		echo "      Gripes #1 and #2 are open again: Docker is writing into @, uncapped."
		fail=1
	fi

	echo "== state now, against the record =="
	diff <(sed '1d' "$RECORD") <(state) && echo "(identical)"

	[ "$fail" = 0 ] && echo "ACCEPTANCE PASS" || echo "ACCEPTANCE FAIL"
	return "$fail"
}

case "${1-}" in
arm) arm ;;
verify) verify ;;
undo) sudo rm -f "$CANARY" && echo "canary removed; the snapshot and $RECORD are left alone" >&2 ;;
-h | --help | "") usage ;;
*)
	echo "unknown: $1" >&2
	usage 1
	;;
esac
