# openclaw-config-patches.md

What `patches/openclaw.json.jq` does to `~/.openclaw/openclaw.json`.

The patch is **idempotent** — re-running it yields the same config. Every
mutation uses `unique` or null-coalescing so duplicate entries cannot
accumulate.

## Mutation 1 — register research-watch hooks

```jq
.hooks.internal.load.extraDirs += [STACK_ROOT + "/workflows/research-watch/hooks"]
| unique
```

OpenClaw rejects symlinks under `~/.openclaw/hooks/`, so the hook directory
is registered as an external path. The stack's hooks live inside the
research-watch submodule (`workflows/research-watch/hooks/lobster-approve-reply/`).

## Mutation 2 — extend agents.list[0].tools.alsoAllow

Ensures `lobster` and `llm-task` plugins are usable from the main agent.
Legacy configs that wrote a restrictive `tools.allow` list get downgraded
to `tools.alsoAllow` (preserving prior entries) so research-watch's
plugin-driven stages keep working.

```jq
.agents.list[0].tools.alsoAllow = (.alsoAllow + ["lobster","llm-task"]) | unique
# if .allow exists: merge into alsoAllow, drop .allow
```

## How to apply

`bash install.sh` runs this automatically. To apply / re-apply manually:

```bash
STACK_ROOT="/Users/qiuyuxun/projects/openclaw-stack"
CFG="$HOME/.openclaw/openclaw.json"
jq -f "$STACK_ROOT/patches/openclaw.json.jq" \
   --arg STACK_ROOT "$STACK_ROOT" "$CFG" > /tmp/oc.json
cp "$CFG" "$CFG.bak.$(date +%s)"
mv /tmp/oc.json "$CFG"
```

## Rollback

```bash
ls -t ~/.openclaw/openclaw.json.bak.* | head -1 | xargs -I{} cp {} ~/.openclaw/openclaw.json
```

## What the patch deliberately does NOT do

- It does **not** add MCP servers — those are a per-user choice; configure
  them via `openclaw mcp set <name> '<json>'`.
- It does **not** write secrets — secrets live in `~/.openclaw/.env` per the
  remediation plan from 2026-05-01.
- It does **not** enable plugins — run `openclaw plugins enable lobster`
  and `openclaw plugins enable llm-task` once after install.
