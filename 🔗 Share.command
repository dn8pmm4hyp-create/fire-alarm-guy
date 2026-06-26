#!/bin/bash
# Double-click to publish Fire Alarm Guy to GitHub Pages and copy a shareable link.
# Safe to run repeatedly — it just pushes the latest version each time.

cd "$(dirname "$0")" || exit 1
export PATH="$HOME/.local/bin:$PATH"

REPO="fire-alarm-guy"

bye() { echo; echo "Press any key to close this window."; read -r -n1 -s; exit "${1:-0}"; }

echo "============================================="
echo "  🔥 Fire Alarm Guy — Publish & Share"
echo "============================================="
echo

# 1) Requirements -------------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  echo "❌ GitHub CLI (gh) isn't installed or isn't on PATH."
  echo "   Open a fresh terminal, or reinstall gh, then try again."
  bye 1
fi
if ! command -v git >/dev/null 2>&1; then
  echo "❌ git isn't available."; bye 1
fi

# 2) Auth ---------------------------------------------------------------------
if ! gh auth status >/dev/null 2>&1; then
  echo "🔑 First time: let's sign in to GitHub."
  echo "   Choose:  GitHub.com  →  HTTPS  →  Login with a web browser"
  echo
  gh auth login || { echo "❌ Sign-in didn't complete."; bye 1; }
  echo
fi

OWNER="$(gh api user --jq .login 2>/dev/null)"
if [ -z "$OWNER" ]; then echo "❌ Couldn't read your GitHub username."; bye 1; fi
URL="https://${OWNER}.github.io/${REPO}/"
echo "👤 Signed in as: $OWNER"
echo

# 3) Make sure the repo exists locally as git ---------------------------------
if [ ! -d .git ]; then
  git init -q && git branch -M main
  git config user.email "$(gh api user --jq '.email // "you@users.noreply.github.com"')"
  git config user.name  "$OWNER"
fi

# 4) Commit any pending changes ----------------------------------------------
git add -A
if ! git diff --cached --quiet 2>/dev/null; then
  git -c commit.gpgsign=false commit -q -m "Update Fire Alarm Guy" || true
  echo "📝 Saved your latest changes."
fi

# 5) Create the GitHub repo (first run) or push (later runs) -------------------
if git remote get-url origin >/dev/null 2>&1; then
  echo "⬆️  Uploading latest version…"
  git push -q origin main || { echo "❌ Push failed."; bye 1; }
else
  echo "📦 Creating your GitHub repo '${REPO}' (public)…"
  gh repo create "$REPO" --public --source=. --remote=origin --push \
    || { echo "❌ Repo creation failed."; bye 1; }
fi

# 6) Enable GitHub Pages (idempotent) ----------------------------------------
echo "🌐 Turning on GitHub Pages…"
gh api -X POST "repos/${OWNER}/${REPO}/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || gh api -X PUT "repos/${OWNER}/${REPO}/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || true

# 7) Set absolute image URLs so link previews show a thumbnail (once) ---------
if grep -q 'content="cover.png"' index.html 2>/dev/null; then
  sed -i '' "s#content=\"cover.png\"#content=\"${URL}cover.png\"#g" index.html
  git add index.html
  git -c commit.gpgsign=false commit -q -m "Use absolute link-preview image URL" || true
  git push -q origin main || true
fi

# 8) Done ---------------------------------------------------------------------
printf "%s" "$URL" | pbcopy 2>/dev/null
echo
echo "============================================="
echo "  ✅ Published!"
echo "  🔗 $URL"
echo "  (link copied to your clipboard — paste it to friends)"
echo "============================================="
echo
echo "Opening it now (may show 'not found' for ~1 min on the very first publish)…"
sleep 2
open "$URL"
bye 0
