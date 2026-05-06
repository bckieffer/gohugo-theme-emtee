#!/usr/bin/env bash
set -euo pipefail

slug_re='^content/posts/[a-z0-9]+(-[a-z0-9]+)*\.md$'

violations=$(find content/posts -maxdepth 1 -name '*.md' ! -name '_index.md' \
    | grep -vE "$slug_re" || true)

if [[ -n "$violations" ]]; then
    printf 'Slug convention violation(s):\n%s\n' "$violations" >&2
    printf 'Filenames must match: ^[a-z0-9]+(-[a-z0-9]+)*\\.md$\n' >&2
    exit 1
fi
