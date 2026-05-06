#!/usr/bin/env bash
set -euo pipefail

POSTS_DIR="content/posts"
CONTENT_DIR="content"

MONTHS=('' January February March April May June July August September October November December)

[[ -d "$POSTS_DIR" ]] || { printf 'error: %s not found — run from the site root\n' "$POSTS_DIR" >&2; exit 1; }

write_if_changed() {
    local path="$1" content="$2"
    if [[ ! -f "$path" ]] || [[ "$(cat "$path")" != "$content" ]]; then
        printf '%s\n' "$content" > "$path"
    fi
}

# Collect unique YYYY/MM pairs from post front matter
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

for post in "$POSTS_DIR"/*.md; do
    [[ "$(basename "$post")" == "_index.md" ]] && continue
    [[ -f "$post" ]] || continue
    date_str=$(grep -m1 '^date' "$post" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}') || {
        printf 'warning: no parseable date in %s, skipping\n' "$post" >&2
        continue
    }
    printf '%s/%s\n' "${date_str:0:4}" "${date_str:5:2}"
done | sort -u > "$tmp"

# Write stubs for each pair
while IFS='/' read -r year month; do
    month_int=$((10#$month))
    mname="${MONTHS[$month_int]}"

    mkdir -p "$CONTENT_DIR/$year/$month"

    write_if_changed "$CONTENT_DIR/$year/_index.md" \
"+++
title = '$year'
year = $year
+++"

    write_if_changed "$CONTENT_DIR/$year/$month/_index.md" \
"+++
title = '$mname $year'
year = $year
month = $month_int
+++"
done < "$tmp"

# Remove stale month stubs
for month_dir in "$CONTENT_DIR"/[0-9][0-9][0-9][0-9]/[0-9][0-9]; do
    [[ -d "$month_dir" ]] || continue
    year=$(basename "$(dirname "$month_dir")")
    month=$(basename "$month_dir")
    grep -qxF "${year}/${month}" "$tmp" || rm -rf "$month_dir"
done

# Remove stale year stubs
for year_dir in "$CONTENT_DIR"/[0-9][0-9][0-9][0-9]; do
    [[ -d "$year_dir" ]] || continue
    year=$(basename "$year_dir")
    grep -qE "^${year}/" "$tmp" || rm -rf "$year_dir"
done
