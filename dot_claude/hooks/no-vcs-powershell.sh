#!/usr/bin/env bash
# no-vcs-powershell.sh — PreToolUse guard for the PowerShell tool.
#
# Denies git / gh / glab invocations made through PowerShell; they must be run
# via the Bash tool instead. Matches the command at statement position (start,
# or after ; & | ( or a call operator), so mere mentions as arguments
# (Get-Command git, winget install Git.Git, "git is great") are not blocked.
#
# Reads the PreToolUse hook payload (JSON) on stdin.

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

if echo "$cmd" | grep -qiE '(^|[;&|(]|&&|\|\|)[[:space:]]*(&[[:space:]]*)?["'"'"']?(git|gh|glab)["'"'"']?(\.exe)?([[:space:]]|;|$)'; then
  jq -nc '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"git, gh, and glab must not be run through PowerShell. Re-issue this command with the Bash tool instead."}}'
fi
exit 0
