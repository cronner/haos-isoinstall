#!/usr/bin/env bash
# tests/strings.sh -- checks that need neither root, whiptail nor a disk.
#
# What they guard is what breaks silently in a translation-only edit: a key
# defined in three languages and forgotten in the fourth, a %s dropped from one
# version of a message, an S_ variable used but never set. The ISO build catches
# none of it -- it compiles the script, it does not read it.
#
# Usage: bash tests/strings.sh
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
SRC=haos-installer.sh
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ko(){ fail=$((fail + 1)); printf '  FAIL  %s\n' "$*"; }

# ---- 1. the whole script, then every function on its own -------------------
bash -n "$SRC" || { printf 'syntax error in %s\n' "$SRC"; exit 1; }
printf 'ok    syntax of %s\n' "$SRC"

# Splitting a function out catches an unbalanced brace or quote that the whole
# file happens to tolerate.
awk -v d="$tmp" '
  /^[A-Za-z_][A-Za-z0-9_]*\(\)\{/ { f=$1; sub(/\(\)\{.*/, "", f); out=d "/" f ".sh" }
  out != "" { print > out }
' "$SRC"
nf=0
for f in "$tmp"/*.sh; do
  [ -e "$f" ] || continue
  nf=$((nf + 1))
  bash -n "$f" || ko "function $(basename "$f" .sh) does not parse on its own"
done
[ "$nf" -gt 0 ] || ko "no function could be extracted from $SRC"
printf 'ok    %s functions parse in isolation\n' "$nf"

# ---- 2. the string tables --------------------------------------------------
start=$(grep -n '^set_strings(){' "$SRC" | cut -d: -f1)
[ -n "$start" ] || { printf 'set_strings not found in %s\n' "$SRC"; exit 1; }
end=$(awk -v s="$start" 'NR > s && /^}$/ { print NR; exit }' "$SRC")
sed -n "${start},${end}p" "$SRC" > "$tmp/set_strings.sh"

dump(){
  { printf 'UI_LANG=%s\n' "$1"; cat "$tmp/set_strings.sh"; cat <<'EOS'
set_strings
for v in $(compgen -v | grep '^S_' | LC_ALL=C sort); do
  printf '%s\t%s\n' "$v" "${!v}"
done
EOS
  } > "$tmp/dump.sh"
  bash "$tmp/dump.sh"
}

LANGS="en fr de da xx"          # xx: anything unknown must fall back to English
for l in $LANGS; do
  dump "$l" > "$tmp/$l.txt" || ko "set_strings crashed for UI_LANG=$l"
  [ -s "$tmp/$l.txt" ] || { ko "no string at all for UI_LANG=$l"; continue; }
  empties=$(awk -F'\t' '$2 == "" { print $1 }' "$tmp/$l.txt")
  [ -z "$empties" ] || ko "empty string(s) in $l: $(printf '%s' "$empties" | tr '\n' ' ')"
done

keys_en=$(cut -f1 "$tmp/en.txt")
for l in $LANGS; do
  [ "$l" = en ] && continue
  missing=$(comm -23 <(printf '%s\n' "$keys_en") <(cut -f1 "$tmp/$l.txt" | LC_ALL=C sort))
  extra=$(comm -13 <(printf '%s\n' "$keys_en") <(cut -f1 "$tmp/$l.txt" | LC_ALL=C sort))
  [ -z "$missing" ] || ko "$l is missing: $(printf '%s' "$missing" | tr '\n' ' ')"
  [ -z "$extra" ] || ko "$l defines unknown key(s): $(printf '%s' "$extra" | tr '\n' ' ')"
done

# Same number of %s in every language: one forgotten and printf silently drops
# the value, so whiptail shows a message with a missing word in it.
placeholders(){ awk -F'\t' '{ n = gsub(/%s/, "%s"); print $1 "\t" n }' "$1"; }
placeholders "$tmp/en.txt" > "$tmp/ph-en.txt"
for l in fr de da xx; do
  placeholders "$tmp/$l.txt" > "$tmp/ph-$l.txt"
  diffs=$(diff "$tmp/ph-en.txt" "$tmp/ph-$l.txt" | grep '^[<>]' || true)
  [ -z "$diffs" ] || ko "$l has a different number of %s: $(printf '%s\n' "$diffs" | head -6)"
done

# ---- 3. no string used but never defined -----------------------------------
grep -oE '\$\{?S_[A-Za-z0-9_]+' "$SRC" \
  | sed -E 's/^\$\{?//' | LC_ALL=C sort -u > "$tmp/used.txt"
undefined=$(comm -23 "$tmp/used.txt" <(printf '%s\n' "$keys_en"))
[ -z "$undefined" ] || ko "used but never defined: $(printf '%s' "$undefined" | tr '\n' ' ')"

printf 'ok    %s strings x %s languages, placeholders and definitions consistent\n' \
  "$(printf '%s\n' "$keys_en" | wc -l | tr -d ' ')" \
  "$(printf '%s' "$LANGS" | wc -w | tr -d ' ')"

if [ "$fail" -ne 0 ]; then
  printf '\n%s check(s) failed\n' "$fail"
  exit 1
fi
printf '\nall checks passed\n'
