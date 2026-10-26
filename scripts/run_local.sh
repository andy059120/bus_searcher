#!/bin/sh
set -eu

# 無論從哪個目錄執行，都使用專案的 SDK 與本機設定。
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"

if [ ! -f config/tdx.local.json ]; then
  printf '%s\n' '找不到 config/tdx.local.json，請先依 docs/tdx_auth.md 設定 TDX 憑證。' >&2
  exit 1
fi

if [ ! -x .fvm/flutter_sdk/bin/flutter ]; then
  printf '%s\n' '找不到專案 Flutter SDK，請先執行 fvm install。' >&2
  exit 1
fi

# App 已會自行載入本機設定；此腳本僅保留為選用的 SDK 啟動捷徑。
exec .fvm/flutter_sdk/bin/flutter run "$@"
