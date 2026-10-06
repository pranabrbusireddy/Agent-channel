#!/usr/bin/env bash
# Stream new channel headers addressed to ROLE, or posted by USER. One line per new message.
# Usage: watch.sh ROLE [CHANNEL_PATH]   (run under the Monitor tool; re-arm on expiry)
set -euo pipefail
ROLE=${1:?usage: watch.sh ROLE [CHANNEL_PATH]}; CH=${2:-AGENT_CHANNEL.md}
tail -n0 -F "$CH" 2>/dev/null | grep --line-buffered -E "^### #[0-9]+ \[.*(→ ${ROLE}|USER →)"
