#!/usr/bin/env bash
# Create private source + public runtime-only release repositories and configure publication.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
gh auth status
# The publishing credential stays inside gh and is piped into the Actions secret, never printed.
if ! gh repo view LazyAlgorithm/BistroBlitz >/dev/null 2>&1; then
  gh repo create LazyAlgorithm/BistroBlitz --private --description 'Cooperative Tessera kitchen game; private source'
fi
test "$(gh repo view LazyAlgorithm/BistroBlitz --json visibility --jq .visibility)" = PRIVATE
if ! gh repo view LazyAlgorithm/bistro-blitz-releases >/dev/null 2>&1; then
  gh repo create LazyAlgorithm/bistro-blitz-releases --public --description 'Bistro Blitz runtime player downloads; no source' --add-readme
fi
if ! git rev-parse --show-toplevel >/dev/null 2>&1 || [ "$(git rev-parse --show-toplevel)" != "$project_root" ]; then
  git init -b main
fi
if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin https://github.com/LazyAlgorithm/BistroBlitz.git
fi
test "$(git remote get-url origin)" = https://github.com/LazyAlgorithm/BistroBlitz.git
git add .
if ! git diff --cached --quiet; then
  git commit -m 'Update Bistro Blitz game and build pipelines'
fi
# First verify this credential can update the existing Hub; publishing uses the same account conventions as other games.
gh api repos/LazyAlgorithm/tessera-hub --jq .permissions.push | grep -Fx true
gh auth token | gh secret set HUB_RELEASE_TOKEN --repo LazyAlgorithm/BistroBlitz
git push -u origin main
gh workflow run web-build.yml --repo LazyAlgorithm/BistroBlitz --ref main
printf '%s\n' 'Source pushed. The Windows/Linux workflow publishes validated packages, then adds the game to the Hub.'
