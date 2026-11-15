#!/usr/bin/env bash
# Devin hook adapter — runs a CCGS .claude/hooks/*.sh script and translates its
# output into Devin's hook protocol. stdin (the Devin hook payload) is piped
# straight through to the script, whose own field names (tool_input.command,
# tool_input.file_path) match.
#
# Usage (from .devin/hooks.v1.json):
#   ccgs-hook.sh gate    .claude/hooks/validate-commit.sh   # PreToolUse
#   ccgs-hook.sh context SessionStart .claude/hooks/session-start.sh
#   ccgs-hook.sh raw     .claude/hooks/session-stop.sh      # side effects only
set -u
MODE="$1"; shift
case "$MODE" in
  context)
    EVENT="$1"; shift
    SCRIPT="$1"
    INPUT=$(cat)
    OUT=$(printf '%s' "$INPUT" | bash "$DEVIN_PROJECT_DIR/$SCRIPT" 2>/dev/null)
    [ -z "$OUT" ] && exit 0
    jq -n --arg e "$EVENT" --arg c "$OUT" \
      '{hookSpecificOutput:{hookEventName:$e,additionalContext:$c}}'
    ;;
  gate)
    SCRIPT="$1"
    INPUT=$(cat)
    OUT=$(printf '%s' "$INPUT" | bash "$DEVIN_PROJECT_DIR/$SCRIPT" 2>&1)
    CODE=$?
    if [ "$CODE" -eq 2 ]; then
      jq -n --arg r "$OUT" '{decision:"block",reason:$r}'
    elif [ -n "$OUT" ]; then
      jq -n --arg r "$OUT" '{decision:"approve",reason:$r}'
    fi
    exit 0
    ;;
  raw)
    SCRIPT="$1"
    cat | bash "$DEVIN_PROJECT_DIR/$SCRIPT" >/dev/null 2>&1
    exit 0
    ;;
  # Translate a Devin tool-event payload into the Claude-style payload the
  # upstream script expects, then pipe it through. Never blocks.
  xlate)
    KIND="$1"; shift
    SCRIPT="$1"
    INPUT=$(cat)
    case "$KIND" in
      # Devin PreToolUse(run_subagent) -> Claude SubagentStart
      agent-start)
        OUT=$(printf '%s' "$INPUT" | jq -c '{
          session_id,
          agent_id: (.prompt_id // "unknown"),
          agent_type: (.tool_input.profile // .tool_input.title // "unknown"),
          event: "SubagentStart",
          prompt: (.tool_input.task // "")}' 2>/dev/null)
        ;;
      # Devin PostToolUse(run_subagent) -> Claude SubagentStop
      agent-stop)
        OUT=$(printf '%s' "$INPUT" | jq -c '{
          session_id,
          agent_id: (.prompt_id // "unknown"),
          agent_type: (.tool_input.profile // .tool_input.title // "unknown"),
          agent_transcript_path: "",
          last_assistant_message: ((.tool_response.output // "") | .[0:4000])}' 2>/dev/null)
        ;;
      # Devin PermissionRequest -> Claude Notification(permission_prompt)
      notify-perm)
        OUT=$(printf '%s' "$INPUT" | jq -c '{
          message: ("Devin is waiting for approval: " + .tool_name
                    + " — " + ((.tool_input.command // .tool_input.file_path // "") | tostring | .[0:120])),
          notification_type: "permission_prompt"}' 2>/dev/null)
        ;;
      *) exit 0 ;;
    esac
    [ -z "${OUT:-}" ] && exit 0
    printf '%s' "$OUT" | bash "$DEVIN_PROJECT_DIR/$SCRIPT" >/dev/null 2>&1
    exit 0
    ;;
esac
exit 0
