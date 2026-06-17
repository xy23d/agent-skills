#!/bin/bash
# PostToolUse(Skill): スキル使用を記録する（未使用スキルの退避判断の原データ）
skill=$(jq -r '.tool_input.skill // empty')
if [ -n "$skill" ]; then
  printf '%s\t%s\n' "$(date +%F)" "$skill" >> "$HOME/.claude/skill-usage.log"
fi
