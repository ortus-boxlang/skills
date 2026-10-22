#!/usr/bin/env bash
#
# Keep the version of every plugin manifest in sync.
#
#   scripts/sync-version.sh 1.4.0    set every manifest to 1.4.0
#   scripts/sync-version.sh --check  fail when the manifests disagree
#
set -euo pipefail
cd "$( dirname "$0" )/.."

MANIFESTS=(
	.claude-plugin/plugin.json
	.cursor-plugin/plugin.json
	.grok-plugin/plugin.json
	.codex-plugin/plugin.json
	plugins/bx-playwright/.claude-plugin/plugin.json
	plugins/bx-playwright/.codex-plugin/plugin.json
)
MARKETPLACE=.claude-plugin/marketplace.json

versions() {
	for file in "${MANIFESTS[@]}"; do
		printf '%s %s\n' "$( jq -r '.version' "$file" )" "$file"
	done
	printf '%s %s\n' "$( jq -r '.metadata.version' "$MARKETPLACE" )" "$MARKETPLACE (metadata)"
	jq -r --arg f "$MARKETPLACE" '.plugins[] | "\(.version) \($f) (\(.name))"' "$MARKETPLACE"
}

if [[ "${1:-}" == "--check" ]]; then
	count=$( versions | cut -d' ' -f1 | sort -u | wc -l )
	if [[ "$count" -ne 1 ]]; then
		echo "Plugin manifest versions disagree:" >&2
		versions >&2
		echo "Fix: scripts/sync-version.sh <version>" >&2
		exit 1
	fi
	echo "All plugin manifests are at $( versions | head -1 | cut -d' ' -f1 )"
	exit 0
fi

version="${1:?Usage: scripts/sync-version.sh <version> | --check}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Not a semantic version: $version" >&2
	exit 1
fi

# Edit only the version lines so each file keeps its formatting
for file in "${MANIFESTS[@]}" "$MARKETPLACE"; do
	sed -i.bak -E "s/\"version\": \"[^\"]*\"/\"version\": \"$version\"/" "$file" && rm "$file.bak"
done
echo "Set every plugin manifest to $version"
