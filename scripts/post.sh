#!/usr/bin/env bash
# Append one message to AGENT_CHANNEL.md with the next number and a timestamped header.
# Usage: post.sh AUTHOR RECIPIENT TYPE BODY_FILE [CHANNEL_PATH]
set -euo pipefail
[ $# -ge 4 ] || { echo "usage: post.sh AUTHOR RECIPIENT TYPE BODY_FILE [CHANNEL_PATH]" >&2; exit 2; }
AUTHOR=$1; RECIPIENT=$2; TYPE=$3; BODY=$4; CH=${5:-AGENT_CHANNEL.md}
case "$TYPE" in STATUS|REQUEST|QUESTION|ANSWER|FINDING|ACK|BLOCKER) ;; *) echo "bad TYPE: $TYPE" >&2; exit 2;; esac
[ -f "$CH" ] || { echo "no channel file: $CH" >&2; exit 1; }
[ -s "$BODY" ] || { echo "empty or missing body: $BODY" >&2; exit 1; }

# The two agents can post at the same moment; a mkdir lock serialises number choice + append.
LOCK="$CH.lock"
for _ in $(seq 1 50); do mkdir "$LOCK" 2>/dev/null && break; sleep 0.1; done
[ -d "$LOCK" ] || { echo "could not take lock $LOCK (stale? remove it)" >&2; exit 1; }
trap 'rmdir "$LOCK"' EXIT

LAST=$(grep -oE '^### #[0-9]+ \[' "$CH" | grep -oE '[0-9]+' | sort -n | tail -1 || true)
N=$(( ${LAST:-0} + 1 ))
TS=$(date '+%Y-%m-%d %H:%M %Z')
{ printf '\n### #%d [%s] %s → %s — %s\n\n' "$N" "$TS" "$AUTHOR" "$RECIPIENT" "$TYPE"; cat "$BODY"; printf '\n'; } >> "$CH"
echo "posted #$N"
