#!/usr/bin/env bash
# git-guard.sh — PreToolUse guard for Bash git commands under auto mode.
#
# Auto-approves git commit / reset / rebase / push, but escalates to a
# confirmation prompt ("ask") when the operation targets the default branch
# (main/master) or is a force-push without --force-with-lease. Stays silent
# (no decision) for everything else, so non-git commands and other git
# subcommands fall through to the normal permission flow untouched.
#
# Reads the PreToolUse hook payload (JSON) on stdin; the shell command is at
# .tool_input.command.

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

emit() { # $1=decision  $2=reason
  jq -nc --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}

has() { echo "$cmd" | grep -qiE -- "$1"; }

# "git ... <sub>" — tolerates global options such as `git -C path commit`.
is_sub() { has "\\bgit( +[^ ]+)* +$1\\b"; }

is_commit=false; is_reset=false; is_rebase=false; is_push=false
is_sub commit && is_commit=true
is_sub reset  && is_reset=true
is_sub rebase && is_rebase=true
is_sub push   && is_push=true

$is_commit || $is_reset || $is_rebase || $is_push || exit 0

# Force-push policy (push only): --force-with-lease / --force-if-includes are
# fine; a bare --force / -f or a +refspec is not auto-enabled — confirm first.
if $is_push; then
  if has '--force-with-lease|--force-if-includes'; then
    :
  elif has '(^|[[:space:]])(--force|-f)([[:space:]]|=|$)' \
    || has '[[:space:]]\+[^[:space:]=]'; then
    emit ask "Force-push detected without --force-with-lease. Force-push is not auto-enabled; re-run with --force-with-lease, or confirm this prompt."
  fi
fi

# Default-branch policy: these four ops on main/master still need confirmation.
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  emit ask "Current branch is '$branch'. git commit/reset/rebase/push on the default branch still needs confirmation."
fi

# Explicit main/master as an argument (push origin main, rebase master, ...).
# Skipped for commit, whose -m message is free text and would false-positive.
if ! $is_commit && has '(^|[[:space:]])(origin/)?(main|master)([[:space:]]|:|$)'; then
  emit ask "Operation references the default branch (main/master). Confirm before running."
fi

emit allow "Auto-approved: git commit/reset/rebase/push on a non-default branch, no bare force-push."
