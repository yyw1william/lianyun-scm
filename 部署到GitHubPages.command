#!/bin/zsh
# 一键把原型部署成永久 GitHub Pages 链接（前提：有 GitHub 账号）
cd "$(dirname "$0")"
echo "════════════════════════════════════════"
echo "  链运 SCM · 一键部署 GitHub Pages"
echo "════════════════════════════════════════"
if ! command -v gh >/dev/null 2>&1; then
  echo ""
  echo "第一步：安装 GitHub 命令行工具 gh"
  echo "  在终端执行：  brew install gh"
  echo "  然后执行：    gh auth login   （用你的 GitHub 账号登录）"
  echo "完成后重新双击本脚本即可。"
  echo "按回车关闭…"; read; exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "请先运行 gh auth login 登录 GitHub，再重新双击本脚本。"
  echo "按回车关闭…"; read; exit 1
fi
USER=$(gh api user --jq .login)
echo ""
echo "已登录 GitHub 账号：$USER"
echo -n "仓库名（默认 lianyun-scm，直接回车）: "
read REPO
REPO=${REPO:-lianyun-scm}
cp mockup/APP.html docs/index.html
git add -A
git commit -m "init: 链运 SCM 原型" 2>/dev/null || true
gh repo create "$REPO" --public --source=. --remote=origin --push 2>&1 | tail -2
echo ""
echo "开启 GitHub Pages…"
gh api -X POST "repos/$USER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/docs" >/dev/null 2>&1 \
  || gh api -X PUT "repos/$USER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/docs" >/dev/null 2>&1
echo ""
echo "✅ 完成！你的永久链接："
echo "   https://$USER.github.io/$REPO/"
echo "（首次生效约 1-3 分钟；以后改原型双击「更新原型并推送.command」即可更新）"
echo "按回车关闭…"; read
