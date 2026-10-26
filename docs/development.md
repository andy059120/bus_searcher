# 開發環境恢復指南

此專案使用 FVM 管理 Flutter SDK，固定使用 Flutter 3.47.8。Flutter SDK 已包含 Dart，不需要另外安裝 Dart。

2026-10-24 的本機設定：Flutter 3.47.8、Dart 3.13.7、Xcode 26.6、CocoaPods 1.17.0，以及 iOS 26.5 的 iPhone 17 Pro 模擬器。

這台 Mac 已在 `~/.zshrc` 加入 FVM 預設 SDK 的 PATH。新開終端機即可使用；若沿用設定前已開啟的終端機，先執行：

```sh
source ~/.zshrc
```

## 1. 進入專案並確認 SDK

```sh
cd /Users/changan/development/bus_searcher
fvm install
fvm flutter --version
```

`fvm install` 會依照 `.fvmrc` 安裝專案指定的 SDK。平常在此目錄使用 `fvm flutter`，即可選用專案的 Flutter 版本。

## 2. 檢查 iOS 工具鏈

```sh
fvm flutter doctor -v
```

先確認 Flutter 與 Xcode 項目正常。如果目前只開發 iOS，Android SDK 或 Android Studio 尚未安裝不會阻止 iOS 開發。

## 3. 還原套件

```sh
fvm flutter pub get
```

原始 repository 缺少 `pubspec.yaml`，目前依照 `pubspec.lock` 重建：保留套件名稱 `bus_project`，並沿用 `http`、`cupertino_icons` 與 `flutter_lints` 原本鎖定的直接依賴版本。Flutter SDK 自帶的間接依賴可能隨 SDK 版本調整。

首次 iOS 建置已由 Flutter 工具自動將最低 iOS 版本升至 15.0，並完成 Xcode 設定與 UIScene lifecycle 遷移。

## 4. 啟動並確認模擬器

在 Xcode 26 的環境執行：

```sh
open -a Simulator
fvm flutter devices
```

如果沒有啟動中的裝置，可在 Simulator 的 **File → Open Simulator** 選擇 iPhone。

## 5. 執行 app

先確認 `config/tdx.local.json` 已填入本機憑證；設定步驟與保護限制請參閱 [TDX 認證說明](tdx_auth.md)。

```sh
fvm flutter run --dart-define-from-file=config/tdx.local.json
```

出現裝置清單時選擇 iPhone Simulator。如果有多部裝置，也可以指定 `fvm flutter devices` 顯示的 device ID：

```sh
fvm flutter run -d <device-id> --dart-define-from-file=config/tdx.local.json
```

執行期間可按 `r` 進行 hot reload、`R` 進行 hot restart、`q` 結束此次執行。

若要單獨確認 iOS Simulator 建置是否成功，可執行：

```sh
fvm flutter build ios --simulator --debug --dart-define-from-file=config/tdx.local.json
```

## 6. 在 VS Code 開發

以 VS Code 開啟此專案目錄，保留 Dart 與 Flutter 擴充套件。專案 SDK 應指向 `.fvm/flutter_sdk`。若編輯器在設定前已開啟，可執行 **Developer: Reload Window** 重新載入。

選擇 iPhone Simulator 後，按 `F5` 啟動除錯。

## 平常使用的指令

```sh
fvm flutter pub get
fvm flutter analyze
fvm flutter devices
fvm flutter run --dart-define-from-file=config/tdx.local.json
```

套件下載成功與 app 啟動，僅代表本機建置環境可用；公車資料查詢仍取決於 TDX API、憑證與網路狀態。

## 本次驗證結果（2026-10-24）

- `flutter doctor -v`：Flutter、Xcode（含 CocoaPods）、裝置辨識與網路檢查皆通過；Android 工具鏈尚未設定完整。
- `flutter pub get`：成功。
- 靜態分析：沒有 error 或 warning，保留 6 項既有的 info 提示；此次使用 `--no-fatal-infos --no-fatal-warnings`。
- `flutter build ios --simulator --debug`：成功。
- `flutter run -d B977C1CA-DBFB-4128-BD02-98189B626B78 --no-resident`：成功啟動至 iPhone 17 Pro。

## 參考文件

- [Flutter 手動安裝](https://docs.flutter.dev/install/manual)
- [Flutter iOS 環境設定](https://docs.flutter.dev/platform-integration/ios/setup)
- [FVM 常用指令](https://fvm.app/documentation/guides/quick-reference)
