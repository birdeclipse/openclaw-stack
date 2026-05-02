#!/usr/bin/env bash
# install.sh — bootstrap the entire openclaw stack on a fresh checkout.
#
# Idempotent: every step skips work that is already done. Re-running is safe.
# Usage:
#   bash install.sh                  apply everything
#   bash install.sh --dry-run        list planned operations, change nothing
#   bash install.sh --skip-patches   symlinks only, no openclaw.json mutation
set -euo pipefail

DRY=""
SKIP_PATCHES=""
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY=1 ;;
    --skip-patches) SKIP_PATCHES=1 ;;
    --help|-h)
      sed -n '1,11p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

STACK_ROOT="$(cd "$(dirname "$0")" && pwd)"
HOME_OPENCLAW="${OPENCLAW_HOME:-$HOME/.openclaw}"
HOME_CLAUDE="${CLAUDE_HOME:-$HOME/.claude}"

say() { printf "%s\n" "$*"; }
do_or_show() {
  if [ -n "$DRY" ]; then say "  [dry-run] $*"; else eval "$@"; fi
}

# 1. submodules
say "[1/7] init submodules"
do_or_show "git -C \"$STACK_ROOT\" submodule update --init --recursive"

# 2. skill symlinks
say "[2/7] symlink skill-vault skills into $HOME_CLAUDE/skills/"
mkdir -p "$HOME_CLAUDE/skills"
for skill_dir in "$STACK_ROOT/skill-vault/skills"/*/; do
  skill_name="$(basename "$skill_dir")"
  target="$HOME_CLAUDE/skills/$skill_name"
  if [ -L "$target" ] || [ -e "$target" ]; then
    say "  - $skill_name (already present)"
    continue
  fi
  do_or_show "ln -sfn \"$skill_dir\" \"$target\""
  say "  + $skill_name"
done

# 3. workspace symlink
say "[3/7] symlink research-watch workspace into $HOME_OPENCLAW/workspace/"
mkdir -p "$HOME_OPENCLAW/workspace"
RW_SRC="$STACK_ROOT/workflows/research-watch/workspace/research-watch"
RW_DST="$HOME_OPENCLAW/workspace/research-watch"
if [ ! -e "$RW_DST" ]; then
  do_or_show "ln -sfn \"$RW_SRC\" \"$RW_DST\""
  say "  + research-watch -> $RW_SRC"
else
  say "  - research-watch (already present)"
fi

# 4. paper-analyst agent symlink
say "[4/7] symlink paper-analyst.md into $HOME_CLAUDE/agents/"
mkdir -p "$HOME_CLAUDE/agents"
PA_SRC="$STACK_ROOT/workflows/research-watch/claude-agents/paper-analyst.md"
PA_DST="$HOME_CLAUDE/agents/paper-analyst.md"
if [ ! -e "$PA_DST" ]; then
  do_or_show "ln -sfn \"$PA_SRC\" \"$PA_DST\""
  say "  + paper-analyst.md"
else
  say "  - paper-analyst.md (already present)"
fi

# 5. apply openclaw.json patches
if [ -n "$SKIP_PATCHES" ]; then
  say "[5/7] skip patches (--skip-patches)"
else
  say "[5/7] apply openclaw.json patches"
  CFG="$HOME_OPENCLAW/openclaw.json"
  PATCH="$STACK_ROOT/patches/openclaw.json.jq"
  if [ ! -f "$CFG" ]; then
    say "  ! $CFG missing — skipping patch (run \`openclaw\` once first)"
  elif [ ! -f "$PATCH" ]; then
    say "  ! $PATCH missing — skipping"
  else
    if [ -n "$DRY" ]; then
      say "  [dry-run] jq -f $PATCH --arg STACK_ROOT $STACK_ROOT $CFG > /tmp/oc.\$\$.json"
      say "  [dry-run] backup $CFG → $CFG.bak.\$(date +%s)"
      say "  [dry-run] mv /tmp/oc.\$\$.json $CFG"
    else
      tmp="$(mktemp -t oc-stack-cfg)"
      jq -f "$PATCH" --arg STACK_ROOT "$STACK_ROOT" "$CFG" > "$tmp"
      cp "$CFG" "$CFG.bak.$(date +%s)"
      mv "$tmp" "$CFG"
      say "  + patched $CFG (backup at $CFG.bak.<ts>)"
    fi
  fi
fi

# 6. delegate to per-component installers when present (idempotent, optional)
say "[6/7] run component installers"
for sub in workflows/research-watch tools/chat tools/trim-tools mcp/crawl4ai tools/intent-router; do
  inst="$STACK_ROOT/$sub/install.sh"
  if [ -x "$inst" ]; then
    say "  → $sub/install.sh"
    do_or_show "(cd \"$STACK_ROOT/$sub\" && bash install.sh --skip-config 2>/dev/null || bash install.sh) >/dev/null"
  fi
done

# 7. summary
say "[7/7] done"
say ""
say "Verify:"
say "  ls -la \"$HOME_CLAUDE/skills/\""
say "  ls -la \"$HOME_OPENCLAW/workspace/research-watch\""
say "  jq '.hooks.internal.load.extraDirs' \"$HOME_OPENCLAW/openclaw.json\""
