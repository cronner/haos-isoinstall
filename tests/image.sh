#!/usr/bin/env bash
# tests/image.sh -- checks find_images(), the offline path where the user brings
# the image on a stick instead of downloading it. Runs anywhere: lsblk, findmnt,
# mount, umount, find, stat and numfmt are replaced by stubs driven by a fake
# topology, so the DECISIONS are tested without a USB stick or root.
#
# What reading the code does not prove, and this does: an image built for another
# board must never be offered (writing it would erase a disk and produce nothing
# bootable), the installation target and the boot medium must not be scanned,
# read-only-by-design filesystems must be skipped, a file in a folder must still
# be found, and only the documented file name may be accepted.
#
# Usage: bash tests/image.sh
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
SRC=haos-installer.sh
LOG=/dev/null
fail=0

ko(){ fail=$((fail + 1)); printf '  FAIL  %s\n' "$*"; }

# ---- extract the functions under test --------------------------------------
for fn in classify_image image_version release_image_mounts find_images; do
  chunk=$(awk -v n="$fn" '$0 ~ "^" n "\\(\\)\\{" {f=1} f{print} f&&/^}$/{exit}' "$SRC")
  [ -n "$chunk" ] || { printf '%s not found in %s\n' "$fn" "$SRC"; exit 1; }
  eval "$chunk"
  declare -F "$fn" >/dev/null || { printf '%s did not load\n' "$fn"; exit 1; }
done

HAOS_BOARD="generic-x86-64"     # as set in the installer

# ---- fake topology ---------------------------------------------------------
reset_fakes(){
  declare -gA TRAN=() RM=() FS=() PK=() MNT=() FILES=() SIZE=()
  declare -ga PART_ORDER=()
  TARGET=""
  live_dev=""
  IMG_CANDS=()
  IMG_FOREIGN=()
  IMG_MNTS=()
  IMG_FILE=""
  IMG_MNT=""
}

add_disk(){   # <name> <TRAN> <RM>
  TRAN["$1"]="$2"; RM["$1"]="$3"
}

add_part(){   # <name> <parent> <fstype> <mountpoint|-> [mountpoint we must create]
  PART_ORDER+=("$1")
  PK["$1"]="$2"; FS["$1"]="$3"
  [ "$4" = "-" ] || MNT["$1"]="$4"
  LAST_PART="$1"
  return 0
}

put(){        # <mountpoint> <file> [size]
  FILES["$1"]="${FILES[$1]:-}${FILES[$1]:+$'\n'}$2"
  SIZE["$2"]="${3:-471859200}"
}

# ---- stubs -----------------------------------------------------------------
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
  return 0
}

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

# Emulates: find <dir> -maxdepth 2 -type f -iname '*.img.xz'
find(){
  local a dir="" f
  for a in "$@"; do case "$a" in /mnt/*|/media/*) dir="$a";; esac; done
  [ -n "$dir" ] || return 0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "${f,,}" in *.img.xz) printf '%s\n' "$f" ;; esac
  done <<< "${FILES[$dir]:-}"
}

stat(){
  local f="${*: -1}"
  if [ "${1:-}" = "-c%s" ]; then printf '%s\n' "${SIZE[$f]:-0}"; else return 1; fi
}

numfmt(){ printf '%s' "${*: -1}"; }
logx(){ :; }

# ---- helpers ---------------------------------------------------------------
scan(){                      # <what> <expected rc: found|none>
  local what="$1" want="$2" rc=0
  find_images || rc=$?
  if [ "$want" = found ]; then
    [ "$rc" -eq 0 ] || ko "$what: expected a usable image, find_images returned $rc"
  else
    [ "$rc" -ne 0 ] && [ "${#IMG_CANDS[@]}" -eq 0 ] || ko "$what: should have found nothing, got ${IMG_CANDS[*]:-}"
  fi
}

cands(){ printf '%s\n' "${IMG_CANDS[@]:-}"; }

# ---- 1. classify_image(): the name decides ---------------------------------
expect_class(){               # <filename> <expected verdict>
  local got
  got=$(classify_image "$1")
  [ "$got" = "$2" ] || ko "classify_image($1): expected '$2', got '$got'"
}
expect_class "haos_generic-x86-64-16.2.img.xz" ok
expect_class "haos_generic-x86_64-16.2.img.xz" ok           # renamed by hand: same board
expect_class "HAOS_GENERIC-X86_64-16.2.IMG.XZ" ok          # case must not matter
expect_class "haos_rpi4-64-16.2.img.xz" board:rpi4-64
expect_class "haos_odroid-c2-16.2.img.xz" board:odroid-c2
expect_class "haos_generic-aarch64-16.2.img.xz" board:generic-aarch64
expect_class "backup.img.xz" no
expect_class "haos_generic-x86-64-16.2.img" no             # not .xz: cannot be checked
expect_class "haos_generic-x86-64-16.2.img.xz.part" no

# ---- 2. image_version() ----------------------------------------------------
expect_ver(){                 # <filename> <expected>
  local got
  got=$(image_version "$1")
  [ "$got" = "$2" ] || ko "image_version($1): expected '$2', got '$got'"
}
expect_ver "haos_generic-x86-64-16.2.img.xz" "16.2"
expect_ver "haos_generic-x86_64-16.2.img.xz" "16.2"        # renamed by hand
expect_ver "haos_generic-x86-64-17.0.img.xz" "17.0"
expect_ver "haos_rpi4-64-16.2.img.xz" ""

# ---- 3. a stick with the right image is found and mounted read-only -------
reset_fakes
add_disk sda sata 0; add_part sda1 sda ext4 /
add_disk sdb usb 1;  add_part sdb1 sdb vfat -
put /mnt/img1 "/mnt/img1/haos_generic-x86-64-16.2.img.xz"
scan "usb stick with the right image" found
[ "${#IMG_CANDS[@]}" -eq 1 ] || ko "expected one candidate, got ${#IMG_CANDS[@]}"
case "$(cands)" in
  "/mnt/img1/haos_generic-x86-64-16.2.img.xz|/mnt/img1|471859200") ;;
  *) ko "candidate record is wrong: $(cands)" ;;
esac
[ "${IMG_MNTS[*]:-}" = "/mnt/img1" ] || ko "IMG_MNTS should list the mount we made, got '${IMG_MNTS[*]:-}'"

# ---- 4. an image for another board is refused, and reported --------------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb vfat -
put /mnt/img1 "/mnt/img1/haos_rpi4-64-16.2.img.xz"
scan "image built for a Raspberry Pi" none
case "${IMG_FOREIGN[*]:-}" in
  *"haos_rpi4-64-16.2.img.xz (rpi4-64)"*) ;;
  *) ko "IMG_FOREIGN should name the board, got '${IMG_FOREIGN[*]:-}'" ;;
esac

# ---- 5. the good one is offered even when a wrong one sits next to it -----
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb vfat -
put /mnt/img1 "/mnt/img1/haos_rpi5-64-16.2.img.xz"
put /mnt/img1 "/mnt/img1/haos_generic-x86-64-16.0.img.xz"
scan "mixed stick" found
[ "${#IMG_CANDS[@]}" -eq 1 ] || ko "mixed stick: expected 1 candidate, got ${#IMG_CANDS[@]}"
[ "${#IMG_FOREIGN[@]}" -eq 1 ] || ko "mixed stick: expected 1 refusal, got ${#IMG_FOREIGN[@]}"

# ---- 6. several versions: all offered, so the user can choose ------------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb exfat -
put /mnt/img1 "/mnt/img1/haos_generic-x86-64-15.2.img.xz" 400000000
put /mnt/img1 "/mnt/img1/haos_generic-x86-64-16.2.img.xz" 471859200
scan "two versions" found
[ "${#IMG_CANDS[@]}" -eq 2 ] || ko "two versions: expected 2 candidates, got ${#IMG_CANDS[@]}"

# ---- 7. the installation target is never scanned -------------------------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb vfat -
TARGET=/dev/sdb
put /mnt/img1 "/mnt/img1/haos_generic-x86-64-16.2.img.xz"
scan "target disk" none

# ---- 8. nor is the boot medium -------------------------------------------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb vfat -
live_dev=sdb
put /mnt/img1 "/mnt/img1/haos_generic-x86-64-16.2.img.xz"
scan "boot medium" none

# ---- 9. read-only-by-design filesystems are skipped, not mounted ---------
reset_fakes
add_disk sdb usb 1
add_part sdb1 sdb iso9660 -
add_part sdb2 sdb udf -
put /mnt/img1 "/mnt/img1/haos_generic-x86-64-16.2.img.xz"
scan "iso9660 + udf" none
[ -z "${IMG_MNTS[*]:-}" ] || ko "nothing should have been mounted, got '${IMG_MNTS[*]:-}'"

# ---- 10. an internal disk is never searched ------------------------------
reset_fakes
add_disk sda sata 0; add_part sda1 sda ext4 -
put /mnt/img1 "/mnt/img1/haos_generic-x86-64-16.2.img.xz"
scan "internal disk" none

# ---- 11. a file in a folder is found by the caller's own mount -----------
reset_fakes
add_disk sdb usb 1; add_part sdb1 sdb vfat /media/user/stick
put /media/user/stick "/media/user/stick/HAOS/haos_generic-x86-64-16.2.img.xz"
scan "image in a folder, already mounted" found
[ -z "${IMG_MNTS[*]:-}" ] || ko "an already-mounted stick must not be recorded as mounted by us"

# ---- 12. release_image_mounts() keeps only the chosen mount --------------
reset_fakes
IMG_MNTS=(/mnt/img1 /mnt/img2)
release_image_mounts /mnt/img2
[ "${IMG_MNTS[*]:-}" = "/mnt/img2" ] || ko "release_image_mounts must keep the chosen mount, got '${IMG_MNTS[*]:-}'"
release_image_mounts ""
[ -z "${IMG_MNTS[*]:-}" ] || ko "release_image_mounts '' must release everything"

if [ "$fail" -ne 0 ]; then
  printf '\n%s check(s) failed\n' "$fail"
  exit 1
fi
printf 'ok    find_images: right board accepted, other boards refused and named,\n'
printf '      target/boot medium/internal/iso9660 skipped, folders searched,\n'
printf '      mounts recorded and released\n'
printf '\nall checks passed\n'
