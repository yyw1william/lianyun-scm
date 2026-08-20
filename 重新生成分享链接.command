#!/bin/zsh
# 链运 SCM · 一键生成可转发的分享链接（上传到 litterbox，24 小时有效）
cd "$(dirname "$0")/mockup" || exit 1

echo "正在上传 APP.html 并生成链接…"
URL=$(curl -s --max-time 60 -F "reqtype=fileupload" -F "time=24h" -F "fileToUpload=@APP.html" "https://litterbox.catbox.moe/resources/internals/api.php")

if [[ "$URL" == https://* ]]; then
  echo "$URL" | pbcopy
  echo ""
  echo "✅ 分享链接（已复制到剪贴板）："
  echo "   $URL"
  echo ""
  echo "⏳ 链接 24 小时后失效，失效后双击本脚本重新生成即可。"
  echo "🔁 现在自动打开浏览器预览…"
  open "$URL"
else
  echo "❌ 上传失败：$URL"
  echo "   请检查网络后重试。"
fi
echo ""
echo "按回车键关闭窗口…"
read
