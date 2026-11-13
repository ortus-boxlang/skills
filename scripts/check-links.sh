#!/usr/bin/env bash
# Checks every http(s) URL in the repo and fails on 404/410/connection errors.
# Skips placeholder hosts (example.*, localhost, templated URLs) and POST-only MCP endpoints.
set -u
cd "$(dirname "$0")/.."

SKIP='example\.|localhost|127\.0\.0\.1|mypodcast|myapp|mycompany|docker\.internal|git\.heroku\.com|~gitbook/mcp|[{}<$]|debs/noarch$|/org/|/you/|/your-org/'

urls=$(grep -rhoE 'https?://[^][ )>"`'"'"'}|\\]+' . --exclude-dir=.git --exclude-dir=node_modules \
  | sed -E 's/[.,;:*_]+$//' | sort -u | grep -vE "$SKIP" | grep -E '^https?://[^/]+\.[a-z]')

check() {
	code=$(curl -sS -o /dev/null -L -m 20 --retry 2 -A 'Mozilla/5.0 (link-check)' -w '%{http_code}' "$1" 2>/dev/null)
	case "$code" in
		404|410|000) echo "BROKEN $code $1" ;;
	esac
}
export -f check

out=$(echo "$urls" | xargs -P 10 -I{} bash -c 'check "{}"')
if [ -n "$out" ]; then
	echo "$out" | sort
	echo; echo "Broken links found. Locate with: grep -rn --exclude-dir=.git -F '<url>' ."
	exit 1
fi
echo "All links OK ($(echo "$urls" | wc -l) checked)"
