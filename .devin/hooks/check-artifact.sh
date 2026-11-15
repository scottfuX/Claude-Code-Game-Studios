#!/usr/bin/env bash
# PostToolUse(run_subagent) — Devin-native port of validate-agent-artifact.sh.
# Upstream reads the subagent transcript for "Write your full output to <path>";
# here the same instruction lives in tool_input.task, so we scan that. Warns
# (never blocks) when a named output path is missing after the agent returns.
set -u
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat)
# Background subagents haven't run yet when PostToolUse fires — skip them;
# a premature "missing artifact" warning would always be a false positive.
IS_BG=$(printf '%s' "$INPUT" | jq -r '.tool_input.is_background // false')
[ "$IS_BG" = "true" ] && exit 0
TASK=$(printf '%s' "$INPUT" | jq -r '.tool_input.task // empty')
[ -z "$TASK" ] && exit 0
ROOT="${DEVIN_PROJECT_DIR:-$PWD}"

# Paths that follow a write/output keyword within the same line segment.
PATHS=$(printf '%s' "$TASK" | grep -oE \
  '(write|Write|output|Output|produce|save|Save|emit|deliver)[^`]{0,90}`[a-zA-Z0-9_./-]+\.(md|txt|json|ya?ml|csv|tsv|html|png|jpe?g|gif|svg|mp3|wav|ogg|glb|gltf|fbx|zip)`' \
  | grep -oE '`[^`]+`' | tr -d '`' | sort -u)

missing=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  [ -f "$ROOT/$p" ] || missing="$missing
  - $p"
done <<EOF
$PATHS
EOF
[ -z "$missing" ] && exit 0

jq -n --arg c "Subagent returned but named artifact(s) are missing on disk:$missing
If it reported BLOCKED this is expected; otherwise ask it to write the file." \
  '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
