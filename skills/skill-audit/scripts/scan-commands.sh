#!/bin/bash
# Usage: scan-commands.sh [targets.md path]
# targets.md の target（複数可）配下の日付別ログ(<date>.log)を lookback_days 範囲で読み、
# 全 target をまたいで1つのコマンド頻度ランキングを出力する。
# 出力: 「回数<TAB>コマンド」降順。noise除去はしない（生の頻度）。
set -euo pipefail

TARGETS="${1:-$(dirname "$0")/../targets.md}"

# "key:" に続く "  - value" の列挙を取り出す
get_list() {
  awk -v key="$1:" '$0==key{f=1;next} f&&/^[[:space:]]+- /{sub(/^[[:space:]]*- /,"");gsub(/"/,"");print;next} f&&/^[^[:space:]]/{f=0}' "$TARGETS"
}
# "key: value" の単一値を取り出す
get_val() {
  grep -E "^$1:" "$TARGETS" | head -1 | awk '{print $2}'
}

LOOKBACK=$(get_val lookback_days); LOOKBACK=${LOOKBACK:-30}

# target を1つずつ解決し、存在するディレクトリだけを集める
mapfile -t TARGET_DIRS < <(get_list target)
VALID_DIRS=()
for dir in "${TARGET_DIRS[@]}"; do
  [ -z "$dir" ] && continue
  dir="${dir/#\~/$HOME}"
  if [ -d "$dir" ]; then
    VALID_DIRS+=("$dir")
  else
    echo "skip: $dir (not found)" >&2
  fi
done

if [ "${#VALID_DIRS[@]}" -eq 0 ]; then
  echo "target ディレクトリが見つかりません" >&2
  exit 0
fi

# 全 target 配下の日付別ログを lookback 範囲で連結 → コマンドで頻度集計
find "${VALID_DIRS[@]}" -type f -name '*.log' -mtime -"$LOOKBACK" -exec cat {} + \
  | sort | uniq -c | sort -rn
