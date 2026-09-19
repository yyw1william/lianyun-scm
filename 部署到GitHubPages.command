#!/bin/zsh
# 链运 SCM · 一键部署永久 GitHub Pages 链接
cd "$(dirname "$0")"
echo "════════════════════════════════════════"
echo "  链运 SCM · 一键部署 GitHub Pages"
echo "════════════════════════════════════════"

# 1) 确保 gh 可用（没有就自动下载安装到 ~/gh-cli）
if ! command -v gh >/dev/null 2>&1; then
  echo "检测到未安装 GitHub CLI，正在自动下载安装…"
  ARCH=$(uname -m)
  case "$ARCH" in
    arm64) FILE="gh_*_macOS_arm64.zip";;
    *)     FILE="gh_*_macOS_amd64.zip";;
  esac
  mkdir -p ~/gh-cli
  curl -sL "https://github.com/cli/cli/releases/latest/download/$FILE" -o /tmp/gh.zip
  unzip -o -q /tmp/gh.zip -d /tmp/ghx
  cp /tmp/ghx/gh_*/bin/gh ~/gh-cli/gh 2>/dev/null || cp /tmp/ghx/*/bin/gh ~/gh-cli/gh
  chmod +x ~/gh-cli/gh
  export PATH="$HOME/gh-cli:$PATH"
fi

# 2) 登录检查
if ! gh auth status >/dev/null 2>&1; then
  echo ""
  echo "需要登录 GitHub（用你的账号，网页授权即可）："
  gh auth login
fi
USER=$(gh api user --jq .login)
echo ""
echo "✅ 已登录：$USER"
echo -n "仓库名（默认 lianyun-scm，直接回车）: "
read REPO
REPO=${REPO:-lianyun-scm}

# 3) 同步原型到站点根目录并推送
cp mockup/APP.html docs/index.html
git add -A
git commit -m "init: 链运 SCM 原型 $(date '+%m-%d %H:%M')" 2>/dev/null || true
gh repo create "$REPO" --public --source=. --remote=origin --push 2>&1 | tail -2

# 4) 开启 Pages（main 分支 /docs 目录）
echo "开启 GitHub Pages…"
gh api -X POST "repos/$USER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/docs" >/dev/null 2>&1 \
  || gh api -X PUT "repos/$USER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/docs" >/dev/null 2>&1

echo ""
echo "════════════════════════════════════════"
echo "🎉 永久链接："
echo "   https://$USER.github.io/$REPO/"
echo "（首次生效约 1-3 分钟）"
echo ""
echo "以后改原型：双击「更新原型并推送.command」即可，链接不变。"
echo "把链接发给 AI，可一键生成配套简历二维码。"
echo "按回车关闭…"
read
