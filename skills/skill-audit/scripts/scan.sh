#!/bin/bash
# Usage: scan.sh [targets.md path]
# targets.md を読み、対象Markdownファイルを機械的に収集する。
# include / exclude / lookback_days / max_file_size_kb / max_files をすべて適用し、
# 「path<TAB>更新日<TAB>サイズKB」を更新日の新しい順で出力する。
set -euo pipefail

TARGETS="${1:-$(dirname "$0")/../targets.md}"
if [ ! -f "$TARGETS" ]; then
  echo "targets.md が見つかりません: $TARGETS" >&2
  echo "targets.md.template をコピーして設定してください。" >&2
  exit 1
fi

# "key:" に続く "  - value" の列挙を取り出す
get_list() {
  awk -v key="$1:" '$0==key{f=1;next} f&&/^  - /{sub(/^  - /,"");gsub(/"/,"");print;next} f&&!/^  /{f=0}' "$TARGETS"
}
# "key: value" の単一値を取り出す
get_val() {
  grep -E "^$1:" "$TARGETS" | head -1 | awk '{print $2}'
}

LOOKBACK=$(get_val lookback_days); LOOKBACK=${LOOKBACK:-30}
MAX_KB=$(get_val max_file_size_kb); MAX_KB=${MAX_KB:-256}
MAX_FILES=$(get_val max_files); MAX_FILES=${MAX_FILES:-300}

# exclude glob は部分文字列マッチに落とす（** や * を除去）
EXCLUDES=$(get_list exclude | sed 's/\*//g')

get_list contexts | while read -r dir; do
  if [ ! -d "$dir" ]; then
    echo "skip: $dir (not found)" >&2
    continue
  fi
  find "$dir" -type f -name '*.md' -mtime -"$LOOKBACK" -size -"${MAX_KB}k"
done | while read -r f; do
  skip=0
  while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    case "$f" in *"$pat"*) skip=1; break;; esac
  done <<< "$EXCLUDES"
  if [ "$skip" -eq 0 ]; then
    printf '%s\t%s\t%sKB\n' "$f" "$(date -r "$f" +%F)" "$(( $(stat -c%s "$f") / 1024 ))"
  fi
done | sort -t$'\t' -k2,2r | head -n "$MAX_FILES"
