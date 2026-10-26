# 臺北 262 真實回應的回歸資料

2026-10-26 使用使用者授權的本機 TDX 憑證查詢。僅保留公車公開資料欄位；不包含金鑰、token、認證回應或 HTTP headers。

- 臺北路線查詢：262（TPE10961）、262區（TPE10962）。
- 新北同名查詢：空清單。
- 262 站序：去程 72 站、返程 77 站，含 SubRouteUID 與 StopSequence。
- 262 ETA：149 筆，均未提供 SubRouteUID 與 StopSequence；以 RouteUID、Direction、StopUID 可唯一對應全部 149 個站序。
- 本次快照 StopStatus：正常 129 筆、尚未發車 20 筆。此快照只用於回歸測試，不代表當下即時狀態。
