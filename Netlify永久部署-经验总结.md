# Netlify 永久部署 · 经验总结（可直接转发给下一个项目）

> 目标：把「可交互 HTML 原型」变成 **永久不过期、公开可访问、可放简历** 的链接 + 二维码。
> 全程结论：**Netlify 比临时网盘靠谱，但新站点默认开访问保护（401）是最大的坑，必须用 curl 直连 API 关掉。**

---

## 一、完整流程（照抄即可）

```bash
# 1) 安装 netlify-cli（npm 默认缓存损坏时加 --cache）
mkdir -p /private/tmp/nfcli /private/tmp/npmcache
npm install --prefix /private/tmp/nfcli netlify-cli --cache /private/tmp/npmcache

# 2) 登录（必须用户本人在浏览器授权一次，这一步无法代做）
/private/tmp/nfcli/node_modules/.bin/netlify login

# 3) 建站（改你自己的站点名）
/private/tmp/nfcli/node_modules/.bin/netlify sites:create --name 你的站点名
# 记住返回的 Site ID 和 https://xxx.netlify.app

# 4) 部署【关键：先 cd 进站点目录，别带中文路径 --dir】
mkdir -p /private/tmp/site_deploy
cp "/你的项目路径/原型.html" /private/tmp/site_deploy/index.html
cd /private/tmp/site_deploy && /private/tmp/nfcli/node_modules/.bin/netlify deploy --prod --site <SITE_ID>

# 5) 【最关键】关掉默认访问保护（见第二节），否则所有人打开都是 401 登录页
# 6) 验证（见第三节）
```

---

## 二、最大的坑：新站点默认「访问保护」→ 所有人 401

**现象**：部署显示 `Deploy is live!`，但 `curl https://xxx.netlify.app/` 返回 **HTTP 401**，页面是 `app.netlify.com/edge-access?...` 登录跳转。

**原因**：Netlify 新站点默认开了 Login Redirect / Edge Access Control（`sso_login=true`）。

**坑中坑**：用 `netlify api updateSite --data '{"sso_login":false}'` **没用** —— netlify-cli 会按 OpenAPI schema 剥离未知字段，服务端根本没收到。**必须拿 token 用 curl 直连 API**：

```bash
# token 位置（macOS）：~/Library/Preferences/netlify/config.json
# 里面 users.<userId>.auth.token 就是 Bearer token

TOKEN="<上面拿到的token>"
SITE_ID="<你的site_id>"
curl -X PATCH "https://api.netlify.com/api/v1/sites/$SITE_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sso_login": false, "sso_login_context": "all", "account_sso_login": false, "password": ""}'
```

**成功标志**：返回 JSON 里 `sso_login=false`、`account_sso_login=false`。

---

## 三、验证（部署完必须做）

```bash
# 1) 公开可访问：必须 HTTP 200，且包含原型关键字
curl -s -o /dev/null -w "%{http_code}\n" https://你的站点.netlify.app/
curl -s https://你的站点.netlify.app/ | grep -c "页面标题关键字"

# 2) 内容是最新版：对比线上 HTML 与本地文件（允许差一行 Netlify 注入的 hud 脚本）
diff <(curl -s https://你的站点.netlify.app/) 本地index.html

# 3) 二维码解码验证（swift Vision 在这台机器报 ANE error，用 OpenCV）
python3 -m pip install --quiet --target /private/tmp/pylibs2 opencv-python-headless
python3 -c "
import sys; sys.path.insert(0,'/private/tmp/pylibs2')
import cv2
print(cv2.QRCodeDetector().detectAndDecode(cv2.imread('二维码.png'))[0])"
# 期望输出 = 永久 URL
```

---

## 四、其他踩过的坑

| # | 坑 | 解法 |
|---|---|---|
| 1 | npm 默认缓存路径损坏，装不上 netlify-cli | 装到 /private/tmp + `--cache /private/tmp/npmcache` |
| 2 | `netlify deploy --dir "中文路径"` 失败 | 先 `cd /private/tmp/site_deploy`，再 deploy（不带中文路径） |
| 3 | `netlify api updateSite` 关不掉 sso | CLI 剥离未知字段，改用 curl 直连 API（第二节） |
| 4 | 临时链接（catbox/litterbox）24h 过期，不能进简历 | 必须 Netlify / GitHub Pages 这类永久托管 |
| 5 | swift Vision 解码 QR 报 ANE error | 用 `opencv-python-headless` 的 QRCodeDetector 解码 |
| 6 | 站点内容与本地不一致 | 线上会多一行 Netlify 注入的 hud 脚本，diff 时忽略即可 |

---

## 五、给下一个项目的 checklist

- [ ] 原型是**单文件自包含**（CSS/JS 全内嵌，无外部依赖、无相对路径资源）
- [ ] 有 `<meta name="viewport">`（移动端能看）
- [ ] 数据存 localStorage（每人浏览器独立，互不干扰）
- [ ] 建站 → 部署 → **关访问保护** → curl 验证 200
- [ ] 生成二维码 → **解码验证** = 永久 URL
- [ ] 更新说明文档：链接不变，改完重跑 deploy 即可

---

## 六、一句话给面试/复盘

> 「原型上线卡在 401：原因是 Netlify 新站点默认开访问保护，而官方 CLI 的 updateSite 会过滤未知字段，
> 绕过 CLI 直接调 PATCH /sites/{id} 关掉 sso_login 后解决 —— 部署链路要同时考虑『默认安全策略』和『工具链的字段透传』两层。」
