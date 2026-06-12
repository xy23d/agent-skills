#!/bin/bash
# Usage: pr-comments.sh <pr_number>
set -e

NUMBER="$1"

if [ -z "$NUMBER" ]; then
  echo "Usage: pr-comments.sh <pr_number>"
  exit 1
fi

OWNER=$(gh repo view --json owner -q .owner.login)
REPO=$(gh repo view --json name -q .name)

gh api graphql \
  -f owner="$OWNER" \
  -f repo="$REPO" \
  -F number="$NUMBER" \
  -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          comments(first: 5) {
            nodes {
              body
              author { login }
              path
              line
            }
          }
        }
      }
    }
  }
}' | jq -r '
  .data.repository.pullRequest.reviewThreads.nodes
  | map(select(.isResolved == false))
  | if length == 0 then "未解決コメントなし"
    else to_entries[] | "[\(.key + 1)] \(.value.comments.nodes[0].path) (line \(.value.comments.nodes[0].line))\n@\(.value.comments.nodes[0].author.login): \(.value.comments.nodes[0].body)\n---"
    end
'
