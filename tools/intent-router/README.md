# tools/intent-router (placeholder)

Source: `~/projects/openclaw-intent-router/` — currently NOT a git repo.

To convert this placeholder into a real submodule:

```bash
cd ~/projects/openclaw-intent-router
git init
git add -A
git commit -m "chore: initial import"

cd ~/projects/openclaw-stack
rm -rf tools/intent-router
git submodule add ~/projects/openclaw-intent-router tools/intent-router
git add .gitmodules tools/intent-router
git commit -m "feat: vendor openclaw-intent-router as submodule"
```
