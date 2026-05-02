# openclaw-stack

Meta-repo bundling every OpenClaw component (skills, workflows, MCP servers, tools, agent catalog) as git submodules behind one `install.sh` + one declarative jq patch.

## Layout

```
skill-vault/skills/      arxiv-papers, openalex-papers, academic-search, github-trending,
                         last30days (-> last30days-skill/skills/last30days, relative symlink)
skill-vault/skills/last30days-skill  birdeclipse/last30days-skill submodule (feat branch)
workflows/research-watch  paper pipeline + hooks + paper-analyst agent
mcp/crawl4ai             crawl4ai MCP server
tools/                   intent-router, trim-tools, chat
patches/openclaw.json.jq declarative idempotent jq patch
docs/awesome-openclaw-agents  third-party agent catalog
```

## last30days news-watch skill

Forked at `birdeclipse/last30days-skill@feat/edge-cookies-and-vault-output`
with two patches: (1) Microsoft Edge cookie extractor for X auth on macOS,
(2) `LAST30DAYS_OUTPUT_DIR` + `LAST30DAYS_OUTPUT_TEMPLATE` env vars that
route briefings into the Obsidian vault with YAML frontmatter.

Live wiring:

- `~/.config/last30days/.env` (mode 600) holds the keys and vault paths;
  shared by Claude Code and OpenClaw.
- Vault output: `~/knowledge/yuxun_notes/02-AI-Agents/_news-watch/{YYYY-MM}/{topic-slug}.md`
- Watchlist: `python3 skill-vault/skills/last30days/scripts/watchlist.py run-all`
  (cron is owned by OpenClaw, not openclaw-stack).
- Notifications: vault folder watcher → OpenClaw's `channels.telegram` +
  `channels.mattermost`. Skill itself does NOT post directly.

## install.sh (idempotent)

1. `git submodule update --init --recursive`
2. symlink `skill-vault/skills/*` → `~/.claude/skills/<name>`
3. symlink `workflows/research-watch/workspace/research-watch` → `~/.openclaw/workspace/research-watch`
4. symlink `workflows/research-watch/claude-agents/paper-analyst.md` → `~/.claude/agents/paper-analyst.md`
5. register `workflows/research-watch/hooks/` into `~/.openclaw/openclaw.json` `hooks.internal.load.extraDirs`
6. apply `patches/openclaw.json.jq` (writes `.bak`)
7. run per-component `install.sh` if present

## Live wiring (`~/.openclaw/openclaw.json`)

- `skills.load.extraDirs` → `skill-vault/skills`
- `mcp.crawl4ai.args[1]` → `mcp/crawl4ai/bin/server.mjs`
- `hooks.internal.load.extraDirs` → `workflows/research-watch/hooks`
- `plugins.load.paths` → `tools/intent-router`, `tools/trim-tools`

## Cron

`~/.openclaw/cron/jobs.json`. Only one shim invokes a script: `github-trending-weekly` → `~/.openclaw/workspace/github-trending/run_weekly.sh` (`cd`s into `skill-vault/skills/github-trending`).

## Working with submodules

- update tips: `git submodule update --remote`
- pin SHAs: commit here
- cross-component edits: do them in the per-component repo, then bump pin here

## Conventions

- absolute paths in shims/configs MUST point at `~/projects/openclaw-stack/...`
- old `~/projects/SKILL_VAULT` is gone — never reintroduce
- `_common.py` honors `SKILL_VAULT_ROOT` env override; default already correct
