# openclaw-stack

Meta-repo that bundles every OpenClaw component I run together — skills,
workflows, MCP servers, helper tools, and the third-party agent catalog —
behind one `install.sh` and one declarative config-patch file.

Each component remains an independent git repo and is included here as a
**git submodule**. `git submodule update --remote` pulls fresh tips;
`git commit` here pins the chosen SHAs. Cross-component changes still happen
inside the per-component repo, then get captured by bumping the pin in this
meta-repo. Atomic stack snapshots without losing per-component history.

## Layout

```
openclaw-stack/
├── README.md
├── install.sh                       one-shot bootstrap (idempotent)
├── .gitmodules                      pinned submodules
├── docs/
│   ├── architecture.md              this layout, why it exists
│   ├── openclaw-config-patches.md   what install.sh patches in openclaw.json
│   └── awesome-openclaw-agents/     ── submodule (mergisi/awesome-openclaw-agents)
├── patches/
│   └── openclaw.json.jq             declarative jq patch, idempotent
├── skill-vault/                     ── submodule (SKILL_VAULT)
│   └── skills/
│       ├── arxiv-papers/            arXiv-id deep reads, multi-format download
│       ├── openalex-papers/         OpenAlex full filter surface, group-by, sample
│       ├── academic-search/         ── nested submodule (forked academic-search)
│       └── github-trending/         daily trending repo report skill
├── workflows/
│   └── research-watch/              ── submodule (openclaw-research-watch)
│       ├── workspace/research-watch/  the actual pipeline
│       ├── claude-agents/             paper-analyst.md
│       └── hooks/                     lobster-approve-reply
├── mcp/
│   └── crawl4ai/                    placeholder; see "Pending submodules" below
└── tools/
    ├── chat/                        ── submodule (openclaw-chat)
    ├── trim-tools/                  ── submodule (openclaw-trim-tools)
    └── intent-router/               placeholder; see "Pending submodules" below
```

## What `install.sh` does

| Step | Effect |
|---|---|
| 1 | `git submodule update --init --recursive` so all five submodules are present and at pinned SHAs |
| 2 | symlinks every `skill-vault/skills/<name>/` into `~/.claude/skills/<name>` (skips if already present) |
| 3 | symlinks `workflows/research-watch/workspace/research-watch` into `~/.openclaw/workspace/research-watch` |
| 4 | symlinks `workflows/research-watch/claude-agents/paper-analyst.md` into `~/.claude/agents/paper-analyst.md` |
| 5 | registers `workflows/research-watch/hooks/` into `~/.openclaw/openclaw.json` `hooks.internal.load.extraDirs` |
| 6 | applies `patches/openclaw.json.jq` to `~/.openclaw/openclaw.json` (idempotent, jq-based, with backup) |
| 7 | runs each component's own `install.sh` if present (so per-component bootstrap stays usable) |

Re-running is safe — every step is idempotent and leaves a `.bak` of `openclaw.json` so you can roll back.

## Pending submodules

Two siblings are not git repos yet, so they're scaffolded as plain directories with a `README.md` placeholder:

| Path | Source | To-do |
|---|---|---|
| `mcp/crawl4ai/` | `~/projects/crawl4ai-openclaw/` | `cd ~/projects/crawl4ai-openclaw && git init && git add -A && git commit -m initial`, then `git submodule add <path> mcp/crawl4ai` |
| `tools/intent-router/` | `~/projects/openclaw-intent-router/` | same pattern |

Once each is a real git repo with at least one commit, swap the placeholder for a real submodule.

## Submodule URLs

Five of the seven components currently use **local file paths** (`/Users/qiuyuxun/projects/<name>`) as their `url` because those repos have no GitHub remote yet. This works on this machine; cloning the meta-repo to another machine will fail on those submodules until the underlying repos are pushed and the URL is updated:

```bash
# Once you push the local repo to GitHub:
git config -f .gitmodules submodule.skill-vault.url https://github.com/<you>/SKILL_VAULT.git
git submodule sync skill-vault
```

The two repos that already have remotes are pinned to remote URLs:
- `skill-vault/skills/academic-search` → `https://github.com/birdeclipse/academic-search.git`
- `docs/awesome-openclaw-agents` → `https://github.com/mergisi/awesome-openclaw-agents.git`

## Daily workflow

```bash
# pull fresh tips of every component
git submodule update --remote --rebase

# inspect what changed across the stack
git diff

# commit the new pinned SHAs
git commit -am "chore: bump submodules <reason>"
```

## Working inside a component

```bash
cd workflows/research-watch
# edit, test, commit on its own branch
git commit -m "feat(...)"
cd ../..
git add workflows/research-watch
git commit -m "chore: bump research-watch to <sha>"
```

## License

Each component carries its own license (mostly MIT). This meta-repo's own files (this README, `install.sh`, `patches/`, `docs/`) are MIT.
