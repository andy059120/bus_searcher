# TDX 認證與本機設定

## 憑證問題是什麼？

TDX 使用 Client Credentials 流程。`client_id` 是識別資訊，`client_secret` 用來取得 access token；取得 token 後，資料請求帶上 `Authorization: Bearer ...`。

取得 secret 的人也可能取得 token，使用這組金鑰允許的服務。即使 app 只讀取資料，授權仍可能遭冒用、消耗用量；這不代表對方因此具有修改 TDX 公車資料的權限。

本專案目前保留純前端。將憑證移出程式碼並排除 Git，可降低原始碼意外洩漏的風險，但自動載入的 `config/tdx.local.json` 會作為 Flutter asset 進入建置產物；編譯期參數的值也會進入產物。這不是加密或伺服器端秘密儲存；公開散布的 app 若需要保護開發者的共用 secret，應改用受控的後端代理。

## 本機設定

設定檔是 `config/tdx.local.json`，已由 `.gitignore` 排除。這次遷移已將原本的設定搬入本機檔案，沒有替你驗證、撤銷或更換平台金鑰。

新環境尚未有此檔案時，可以執行：

```sh
cp -n config/tdx.example.json config/tdx.local.json
chmod 600 config/tdx.local.json
```

用編輯器填入 TDX 會員中心的值，不要將值貼進終端機指令、截圖或測試檔：

```json
{
  "TDX_CLIENT_ID": "填入 Client Id",
  "TDX_CLIENT_SECRET": "填入 Client Secret"
}
```

`config/tdx.example.json` 僅包含空字串，可以提交。`config/tdx.local.json` 不應提交；可用下列指令確認忽略規則：

```sh
git check-ignore config/tdx.local.json
```

## 執行與建置

設定檔已列入 Flutter assets。App 啟動時先讀取設定，再建立共用的 API client 與 repository，不需要執行憑證腳本或另外加參數：

```sh
flutter run
# 多個裝置時指定模擬器
flutter run -d B977C1CA-DBFB-4128-BD02-98189B626B78
# 只確認建置
flutter build ios --simulator --debug
```

VS Code 按 F5 也使用相同流程。`scripts/run_local.sh` 僅保留為選用的專案 SDK 捷徑。
修改本機 JSON 後應停止 App 並重新執行 `flutter run`，確保新版設定已打包進 asset bundle。

既有的 `--dart-define-from-file` 仍可用於覆寫設定；編譯期設定必須同時提供 ID 與 Secret，不會與 JSON 混搭。

缺少設定檔、JSON 格式不正確或欄位未填時，啟動畫面會顯示固定錯誤訊息，不會顯示 JSON、secret 或 token，也不會先向 TDX 送出請求。

新環境若尚未建立本機檔案，請先完成前述「本機設定」。測試以模擬的 asset bundle 與 HTTP 回應執行，不需要真正的金鑰，也不會呼叫 TDX：

```sh
flutter test
```

## 認證行為

- 向固定的 HTTPS 認證端點送出表單 POST，使用 `grant_type=client_credentials`。
- 全 app 共用一份記憶體 token 快取，依回應的 `expires_in` 計算有效期，不固定假設為一天。
- 到期前最多提前 60 秒更新；短效 token 的提前量不超過有效期的 10%，且請求耗時會計入有效期。
- 同時發出的認證需求共用同一個進行中的請求；失敗後可再次嘗試。
- 每次資料查詢重新向 token service 取得當下有效的 token，不再沿用頁面初始化時的 Future。
- 資料 API 回傳 401 時，作廢對應 token 並重新認證、重試一次；再次 401 不再循環。403、429 等回應不會觸發反覆重新認證。
- 認證及資料請求分別有 10 秒與 15 秒 timeout；token 不落地保存。
- 基礎會員模式將認證與資料請求保守計入共用的每 61 秒 5 次限流；429 遵循冷卻時間，不自動重試。快取與手動搜尋策略請參閱 [查詢策略](basic_membership.md)。
- API client 只允許 TDX 主機的 HTTPS `/api/` 路徑；不自動跟隨重新導向，避免將憑證或授權轉送到其他位置。
- 認證錯誤不顯示 response body、secret 或 token。不要另外將 request body、Authorization header 或完整建置環境寫入 log。

## 已提交過的憑證

移除目前程式中的值，不會刪掉 Git 歷史裡的舊值。若舊金鑰仍有效，應由你到 TDX 會員中心更換／停用，並把新值更新至本機設定檔。此次沒有改寫 Git 歷史，也沒有替你執行平台金鑰操作。

## 官方文件

- [TDX API 授權驗證與使用方式](https://motc-ptx.gitbook.io/tdx-xin-shou-zhi-yin/api-shi-yong-shuo-ming/api-shou-quan-yan-zheng-yu-shi-yong-fang-shi)
- [Flutter：混淆的限制與憑證保護](https://docs.flutter.dev/deployment/obfuscate)
