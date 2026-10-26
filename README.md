# bus_searcher

本機開發與 iOS Simulator 執行方式，請參閱 [開發環境恢復指南](docs/development.md)。
TDX 憑證設定與 token 管理，請參閱 [TDX 認證說明](docs/tdx_auth.md)。
基礎會員的限流、快取與查詢方式，請參閱 [查詢策略](docs/basic_membership.md)。

填好 `config/tdx.local.json` 後，直接執行 `flutter run`，App 會自動讀取設定。
指定裝置可使用 `flutter run -d <device-id>`，不需要額外的憑證參數或腳本。

### This is a Flutter application for querying bus routes. Users can check the arrival times of buses and view detailed route information. 

### The app currently supports querying bus routes only in New Taipei City and Taipei City.

## Features
```
Query arrival times for specific bus routes.

Display detailed information about bus routes, including stops and arrival times.

Add favorite stops for quick access during the current app session.
```
## Directory Structure
```
lib/main.dart                     App 入口
lib/config/                       啟動設定讀取（不含實際憑證）
lib/features/home/presentation/    首頁
lib/features/search/presentation/  路線搜尋畫面
lib/features/route_detail/presentation/  路線與站牌明細畫面
lib/features/favorites/presentation/     常用站牌畫面
lib/data/models/                  API 資料模型
lib/data/services/                TDX 認證與 API 存取函式
docs/                             開發環境與操作文件
config/                           TDX 設定樣板與不進 Git 的本機設定
test/                             認證、限流、快取、真實 262 回應與畫面流程測試
```

`features/` 依功能區分畫面，`data/` 集中資料模型與外部資料存取。
專案內部的 Dart import 統一使用 `package:bus_project/...`。

本機 SDK 路徑、IDE 狀態及 Flutter 暫存產檔由 `.gitignore` 排除；
`pubspec.lock` 與 `.fvmrc` 保留在 Git，固定套件與 Flutter SDK 版本。

## Technical Details
```
This application utilizes the following technologies:

Flutter: A cross-platform mobile application framework used for building user interfaces.

Dart: The programming language used for writing application logic.
```
