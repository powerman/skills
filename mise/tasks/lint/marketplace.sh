#!/usr/bin/env bash
#MISE description="Check that the plugin marketplace lists every skill under its own name"
#MISE hide=true
#MISE sources=["*/SKILL.md", ".claude-plugin/marketplace.json", "mise.lock"]
set -euo pipefail

m=.claude-plugin/marketplace.json
plugins=$(jq -r '.plugins[].source | ltrimstr("./")' "$m" | sort)
diff -u --label 'skills' --label "plugins of $m" \
    <(printf '%s\n' */SKILL.md | sed 's|/SKILL.md$||' | sort) - <<<"$plugins" >&2
jq -e 'all(.plugins[]; .source == "./" + .name)' "$m" >/dev/null || {
    echo "A plugin of $m is named not by its directory" >&2
    exit 1
}
