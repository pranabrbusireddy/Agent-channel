#!/usr/bin/env bash
# Post-commit history check across every revision on every branch. Run from the repo root.
# Usage: history_check.sh [extra personal-data pattern ...]   (e.g. a name, email, project id)
# Prints hits by section; an empty section is clean. Judge each hit: test fixtures are not leaks.
set -uo pipefail
REVS=$(git rev-list --all) || exit 1
HEAD_SHA=$(git rev-parse --short HEAD)
echo "commits: $(echo "$REVS" | wc -l | tr -d ' ')   HEAD: $HEAD_SHA   branches: $(git branch --format='%(refname:short)' | tr '\n' ' ')"

echo "== secret-file paths ever committed"
git log --all --name-only --pretty=format: | sort -u | grep -Ei \
  '(^|/)(\.env($|\.)|credentials[^/]*\.json$|client_secret[^/]*$|token[^/]*\.json$|[^/]*\.(pem|key|p12|pfx|kdbx)$|id_(rsa|ed25519|ecdsa)$|\.netrc$|\.npmrc$|\.pypirc$)'

echo "== build / dependency output ever committed"
git log --all --name-only --pretty=format: | sort -u | grep -E '(^|/)(node_modules|dist|target|venv|\.venv|__pycache__|build)/' | head -20

echo "== secret values in any revision"
git grep -nIE 'AIza[0-9A-Za-z_-]{35}|sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{32,}|ya29\.[0-9A-Za-z_-]{20,}|1//0[0-9A-Za-z_-]{30,}|GOCSPX-[0-9A-Za-z_-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY|[0-9]{8,}-[a-z0-9]{32}\.apps\.googleusercontent\.com|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9-]{10,}|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.' $REVS | head -20

echo "== personal data in any revision (home paths + extra patterns)"
PAT="/Users/$(whoami)|/home/$(whoami)"
for p in "$@"; do PAT="$PAT|$p"; done
git grep -niIE "$PAT" $REVS | head -20

echo "== hidden / bidi characters in tracked files at HEAD (shown as U+XXXX)"
git ls-files | python3 -c '
import sys, subprocess
bad = set(range(0, 9)) | {11, 12} | set(range(13, 32)) | set(range(0x7f, 0xa0)) | {0xad, 0x61c, 0xfeff} \
    | set(range(0x200b, 0x2010)) | {0x2028, 0x2029} | set(range(0x202a, 0x202f)) | set(range(0x2060, 0x2065)) | set(range(0x2066, 0x206a))
for f in sys.stdin.read().splitlines():
    raw = subprocess.run(["git", "show", "HEAD:" + f], capture_output=True).stdout
    try: text = raw.decode("utf-8")
    except UnicodeDecodeError: continue
    if "\0" in text: continue
    for i, line in enumerate(text.split("\n"), 1):
        for c in line:
            if ord(c) in bad: print(f"{f}:{i} U+{ord(c):04X}")
'
echo "== done"
