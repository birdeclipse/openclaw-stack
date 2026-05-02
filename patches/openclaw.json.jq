# patches/openclaw.json.jq
#
# Declarative jq patch consolidating every openclaw.json mutation that the
# stack's components used to make ad-hoc inside their own install scripts.
#
# Apply via:
#   jq -f patches/openclaw.json.jq ~/.openclaw/openclaw.json > /tmp/oc.json \
#     && mv ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak \
#     && mv /tmp/oc.json ~/.openclaw/openclaw.json
#
# Idempotent: every mutation uses `unique` / null-coalescing so re-running
# the same patch is a no-op.
#
# Inputs (set as jq --arg before applying):
#   STACK_ROOT  absolute path to the openclaw-stack checkout

# 1) Register research-watch hooks dir under hooks.internal.load.extraDirs.
#    Also strips obsolete pre-migration paths so re-runs don't accumulate
#    stale entries (~/projects/openclaw-research-watch/hooks existed before
#    R5 of the stack migration).
.hooks                                  = (.hooks // {})
| .hooks.internal                       = (.hooks.internal // {})
| .hooks.internal.load                  = (.hooks.internal.load // {})
| .hooks.internal.load.extraDirs        = (
    ((.hooks.internal.load.extraDirs // [])
     | map(select(test("openclaw-research-watch/hooks") | not))
     + [($STACK_ROOT + "/workflows/research-watch/hooks")])
    | unique)

# 2) Ensure agents.list[0].tools.alsoAllow contains the plugins research-watch
#    relies on. Downgrade any restrictive `allow` to `alsoAllow` (legacy fix).
| .agents                               = (.agents // {})
| .agents.list                          = (.agents.list // [])
| (
    if (.agents.list | length) == 0 then
      .agents.list = [{
        "id": "main",
        "tools": {"alsoAllow": ["lobster", "llm-task"]}
      }]
    else
      .agents.list[0].tools                = (.agents.list[0].tools // {})
      # Append-then-dedup-preserving-order so re-runs don't reorder existing
      # entries cosmetically. `reduce` walks the list once.
      | .agents.list[0].tools.alsoAllow    = (
          ((.agents.list[0].tools.alsoAllow // []) +
           ["lobster", "llm-task"])
          | reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end))
      | (
          if (.agents.list[0].tools.allow // null) != null then
            .agents.list[0].tools.alsoAllow = (
              (.agents.list[0].tools.alsoAllow + .agents.list[0].tools.allow)
              | reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end))
            | del(.agents.list[0].tools.allow)
          else . end
        )
    end
  )
