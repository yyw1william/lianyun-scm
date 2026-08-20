#!/bin/zsh
# 改完 mockup/APP.html 后运行：同步到 docs/index.html 并推送到 GitHub Pages
cd "$(dirname "$0")"
cp mockup/APP.html docs/index.html
git add -A
git commit -m "更新原型 $(date '+%Y-%m-%d %H:%M')" || echo "（无改动）"
git push origin main 2>&1 | tail -3
echo ""
echo "✅ 已推送，稍等 1-2 分钟即可看到最新版"
echo "按回车关闭…"
read
