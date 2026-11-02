#!/usr/bin/env bash
# tests/stage.sh -- checks find_stage_dir(), the medium the image is staged on when
# RAM is too small. It runs on any machine: lsblk, findmnt, df, mount, umount and
# touch are replaced by stubs driven by a fake topology, so the DECISIONS are
# tested without a USB stick, root or a Linux block layer.
#
# What is worth testing here is exactly what reading the code does not prove: the
# target disk, the boot medium, a read-only-by-design filesystem, a medium that is
# too small and a read-only mount must all be refused, and only a writable
# removable partition with room must win.
#
# Usage: bash tests/stage.sh
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
SRC=haos-installer.sh
LOG=/dev/null
fail=0

ko(){ fail=$((fail + 1)); printf '  FAIL  %s\n' "$*"; }

# ---- extract the function under test ---------------------------------------
chunk=$(awk '/^find_stage_dir\(\)\{/{f=1} f{print} f&&/^\}$/{exit}' "$SRC")
[ -n "$chunk" ] || { printf 'find_stage_dir not found in %s\n' "$SRC"; exit 1; }
eval "$chunk"
declare -F find_stage_dir >/dev/null || { printf 'find_stage_dir did not load\n'; exit 1; }

# ---- fake topology ---------------------------------------------------------
reset_fakes(){
  declare -gA TRAN=() RM=() FS=() PK=() MNT=() AVAIL=() RO=()
  declare -ga PART_ORDER=()
  TARGET=""
  live_dev=""
  LAST_MOUNTED=""
  STAGE_DIR=""
  STAGE_MNT=""
}

add_disk(){   # <name> <TRAN> <RM>
  TRAN["$1"]="$2"; RM["$1"]="$3"
}

add_part(){   # <name> <parent> <fstype> <avail KB> <mountpoint|-> <ro?>
  PART_ORDER+=("$1")
  PK["$1"]="$2"; FS["$1"]="$3"; AVAIL["$1"]="$4"
  [ "$5" = "-" ] || MNT["$1"]="$5"
  [ "${6:-}" = "ro" ] && RO["$1"]=1
  return 0
}

# ---- stubs, so the function sees the fake topology -------------------------
lsblk(){
  local args="$*" dev="${*: -1}" p
  dev="${dev#/dev/}"
  case "$args" in
    *PKNAME*)    printf '%s\n' "${PK[$dev]:-}" ;;
    *TRAN*)      printf '%s\n' "${TRAN[${PK[$dev]:-$dev}]:-}" ;;
    *RM*)        printf '%s\n' "${RM[${PK[$dev]:-$dev}]:-}" ;;
    *FSTYPE*)    printf '%s\n' "${FS[$dev]:-}" ;;
    *NAME,TYPE*) for p in ${PART_ORDER[@]+"${PART_ORDER[@]}"}; do printf '%s part\n' "$p"; done ;;
  esac
}

findmnt(){
  local a d=""
  for a in "$@"; do case "$a" in /dev/*) d="${a#/dev/}";; esac; done
  printf '%s\n' "${MNT[$d]:-}"
}

mount(){
  local a src="" mp=""
  for a in "$@"; do
    case "$a" in /dev/*) src="${a#/dev/}";; esac
    case "$a" in /mnt/*|/media/*) mp="$a";; esac
  done
  [ -n "$mp" ] || return 1
  MNT["$src"]="$mp"
  LAST_MOUNTED="$src"
  return 0
}

# Must really drop the mount: a refused medium that kept its mountpoint would
# poison the lookup for the next candidate.
umount(){
  local a k
  for a in "$@"; do
    for k in "${!MNT[@]}"; do
      [ "${MNT[$k]}" = "$a" ] && unset 'MNT[${k}]'
    done
  done
  return 0
}

mkdir(){ return 0; }

dev_for_path(){
  local p="$1" k
  for k in "${!MNT[@]}"; do
    case "$p" in "${MNT[$k]}/"*) printf '%s' "$k"; return 0 ;; esac
  done
  return 1
}

touch(){
  local d
  d=$(dev_for_path "$1" || true)
  [ -n "$d" ] && [ -n "${RO[$d]:-}" ] && return 1
  return 0
}

df(){
  local last="${*: -1}" k dev=""
  for k in "${!MNT[@]}"; do [ "${MNT[$k]}" = "$last" ] && dev="$k"; done
  [ -n "$dev" ] || dev="$LAST_MOUNTED"
  printf 'Filesystem\n%s\n' "${AVAIL[$dev]:-0}"
}

logx(){ :; }

NEED=900000        # ~900 MB in KB, what a ~450 MB image asks for

expect_dir(){     # <what> <expected dir or "none">
  local what="$1" want="$2" rc=0
  find_stage_dir "$NEED" || rc=$?
  if [ "$want" = none ]; then
    [ "$rc" -ne 0 ] && [ -z "$STAGE_DIR" ] || ko "$what: should have been refused, got '${STAGE_DIR}'"
  else
    [ "$rc" -eq 0 ] && [ "$STAGE_DIR" = "$want" ] || ko "$what: expected '$want', got rc=$rc dir='${STAGE_DIR}'"
  fi
}

# ---- 1. an internal disk is never a staging medium -------------------------
reset_fakes
add_disk sda sata 0
add_part sda1 sda ext4 200000000 / -
expect_dir "internal disk" none

# ---- 2. a USB stick with room is picked, via a mount we make ourselves -----
reset_fakes
add_disk sda sata 0; add_part sda1 sda ext4 200000000 / -
add_disk sdb usb 1;  add_part sdb1 sdb vfat 8000000 - -
expect_dir "usb stick with room" /mnt/stage
[ "$STAGE_MNT" = /mnt/stage ] || ko "usb stick: STAGE_MNT should record the mount we made (got '${STAGE_MNT}')"

# ---- 3. an already-mounted partition is used as-is, never unmounted --------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb ext4 8000000 /media/user/stick -
expect_dir "already mounted" /media/user/stick
[ -z "$STAGE_MNT" ] || ko "already mounted: STAGE_MNT must stay empty (got '${STAGE_MNT}')"

# ---- 4. the installation target is refused even if it is a USB disk --------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb vfat 8000000 - -
TARGET=/dev/sdb
expect_dir "target disk" none

# ---- 5. the boot medium is refused ----------------------------------------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb vfat 8000000 - -
live_dev=sdb
expect_dir "boot medium" none

# ---- 6. iso9660/udf are read-only by design, so never candidates ----------
reset_fakes
add_disk sdb usb 1
add_part sdb1 sdb iso9660 8000000 - -
add_part sdb2 sdb udf 8000000 - -
expect_dir "iso9660 + udf" none

# ---- 7. not enough room ---------------------------------------------------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb vfat 100000 - -
expect_dir "medium too small" none

# ---- 8. mounted read-only: the write test fails, so it is skipped ---------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb vfat 8000000 - ro
expect_dir "read-only medium" none

# ---- 9. a too-small first partition must not hide a good second one ------
reset_fakes
add_disk sdb usb 1
add_part sdb1 sdb vfat 100000 - -              # too small
add_part sdb2 sdb exfat 8000000 - -            # fits
expect_dir "second partition fits" /mnt/stage

# ---- 10. no partition at all ---------------------------------------------
reset_fakes
add_disk sdb usb 1
expect_dir "no partitions" none

if [ "$fail" -ne 0 ]; then
  printf '\n%s check(s) failed\n' "$fail"
  exit 1
fi
printf 'ok    find_stage_dir: internal, target, boot medium, iso9660/udf, too small,\n'
printf '      read-only and choice order all behave\n'
printf '\nall checks passed\n'
