# architecture.md

## Why a meta-repo

Before this layout, six+ openclaw-related repos lived as siblings under
`~/projects/`. Each had its own `install.sh` patching `~/.openclaw/openclaw.json`
in-place, no shared bootstrap, and cross-cutting changes (e.g. wiring the
academic-search skill's `s2.py batch` into research-watch's `rank.py`) had
to land as two unrelated commits in two repos with no atomic checkpoint.

`openclaw-stack` solves three problems:

1. **One bootstrap.** `bash install.sh` initializes every submodule, lays down
   every symlink, applies one consolidated `jq` patch to `openclaw.json`, and
   exits idempotent.
2. **Atomic stack snapshots.** The meta-repo pins each component to a SHA via
   `.gitmodules`. Cross-cutting changes get tested across components and then
   captured as a single meta-commit that bumps multiple submodule pointers.
3. **Declarative config.** `patches/openclaw.json.jq` is the single source of
   truth for what mutations the stack makes to global openclaw config.

## Why submodules and not a monorepo

- SKILL_VAULT is published as a public reference repo. Moving its history
  into a monorepo would lose its identity.
- The forked `academic-search` lives in `birdeclipse/academic-search` so it
  can rebase against `ustc-ai4science/academic-search` upstream. Submodules
  preserve that.
- Per-component repos can still be cloned and used standalone; the meta-repo
  is opt-in.

The downside (submodule UX cliffs, every contributor needs
`--recursive`) is documented in the top-level README and absorbed by
`install.sh`.

## Component map

| Path | Submodule | Purpose |
|---|---|---|
| `skill-vault/` | `~/projects/SKILL_VAULT` (local-only) | Skills bundle: arxiv-papers, openalex-papers, github-trending, plus academic-search as a nested submodule |
| `skill-vault/skills/academic-search/` | `birdeclipse/academic-search` (GitHub) | Forked multi-platform discovery skill; nested submodule so upstream rebase stays clean |
| `workflows/research-watch/` | `~/projects/openclaw-research-watch` (local) | The 12-stage tier-3 academic paper triage pipeline |
| `tools/chat/` | `~/projects/openclaw-chat` (local) | Helper |
| `tools/trim-tools/` | `~/projects/openclaw-trim-tools` (local) | Helper |
| `docs/awesome-openclaw-agents/` | `mergisi/awesome-openclaw-agents` (GitHub) | Third-party agent catalog, read-only reference |
| `mcp/crawl4ai/` | placeholder | Once `~/projects/crawl4ai-openclaw` becomes a git repo, swap for a submodule |
| `tools/intent-router/` | placeholder | Same pattern as crawl4ai |

## Symlink topology after `install.sh`

```
~/.claude/
├── agents/paper-analyst.md  → STACK/workflows/research-watch/claude-agents/paper-analyst.md
└── skills/
    ├── arxiv-papers         → STACK/skill-vault/skills/arxiv-papers
    ├── openalex-papers      → STACK/skill-vault/skills/openalex-papers
    ├── academic-search      → STACK/skill-vault/skills/academic-search
    └── github-trending      → STACK/skill-vault/skills/github-trending

~/.openclaw/
├── workspace/research-watch → STACK/workflows/research-watch/workspace/research-watch
└── openclaw.json
    └── hooks.internal.load.extraDirs[] += STACK/workflows/research-watch/hooks
```

The pre-existing direct symlinks under `~/.claude` and `~/.openclaw` remain
untouched if they already point at the original `~/projects/<repo>` paths.
`install.sh` only creates new symlinks for missing entries; it does not
overwrite. Migrate manually by `rm`-ing old symlinks and re-running install.

## Cross-component change ritual

```bash
# 1. enter the component
cd workflows/research-watch
git checkout -b feat/X
# 2. edit + test + commit
git commit -m "feat(...)"
# 3. (if needed) edit a sibling component
cd ../../skill-vault
git checkout -b feat/X
git commit -m "feat(...)"
# 4. capture both pin bumps in one meta-commit
cd ../..
git add workflows/research-watch skill-vault
git commit -m "chore: bump research-watch + skill-vault for X"
```

The atomicity guarantee is at the meta-repo's commit boundary: anyone who
checks out that meta-commit gets both component SHAs together.
