# mcp/crawl4ai (placeholder)

Source: `~/projects/crawl4ai-openclaw/` — currently NOT a git repo.

To convert this placeholder into a real submodule:

```bash
cd ~/projects/crawl4ai-openclaw
git init
git add -A
git commit -m "chore: initial import"
# (optionally push to GitHub for portability)

cd ~/projects/openclaw-stack
rm -rf mcp/crawl4ai
git submodule add ~/projects/crawl4ai-openclaw mcp/crawl4ai
git add .gitmodules mcp/crawl4ai
git commit -m "feat: vendor crawl4ai-openclaw as submodule"
```
