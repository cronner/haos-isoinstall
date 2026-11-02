#!/usr/bin/env bash
# tests/unattended.sh -- checks the decisions unattended mode makes without a
# person in front of the screen. Runs anywhere: logx and lsblk are replaced by
# stubs driven by a fake topology, so no USB stick, disk or root is needed.
#
# What reading the code does not prove, and this does:
#   - a config file written on Windows (CRLF, quoted values, lowercase keys,
#     comments, an unknown key) still yields the right values;
#   - a missing or non-yes WIPE= does not become a yes;
#   - the disk eligibility rules are the same ones the menu uses: the boot
#     medium, the disk holding the image, an iso9660 carrier and a Ventoy stick
#     are never offered, and an internal disk is not flagged as removable;
#   - the config template that ships in the ISO is still inert.
#
# Usage: bash tests/unattended.sh
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
SRC=haos-installer.sh
fail=0

ko(){ fail=$((fail + 1)); printf '  FAIL  %s\n' "$*"; }

# ---- extract the functions under test --------------------------------------
for fn in cfg_clean config_supported_lang default_keymap parse_config_line parse_config_file \
        cfg_has_keys cfg_candidate cfg_medium_disk load_config target_rows; do
  chunk=$(awk -v n="$fn" '$0 ~ "^" n "\\(\\)\\{" {f=1} f{print} f&&/^}$/{exit}' "$SRC")
  [ -n "$chunk" ] || { printf '%s not found in %s\n' "$fn" "$SRC"; exit 1; }
  eval "$chunk"
  declare -F "$fn" >/dev/null || { printf '%s did not load\n' "$fn"; exit 1; }
done

logx(){ :; }                      # the installer logs to a file; not needed here

# ---- stubs for the parts load_config() talks to ----------------------------
# find_config() mounts media; what is under test is the decision it feeds, so it
# is replaced by a fixed answer. die() would power the machine off, so here it
# only records what it was told. set_strings()/apply_keymap() need a terminal.
CFG_NEXT=""
find_config(){ [ -n "$CFG_NEXT" ] && { CFG_FILE="$CFG_NEXT"; CFG_MNT=$(dirname "$CFG_NEXT"); return 0; }; return 1; }
die(){ DIE_MSG="$1"; }
set_strings(){ :; }
apply_keymap(){ KEYMAP_USED="$1|$2"; }
DIE_MSG=""; KEYMAP_USED=""
UI_LANG="en"
LOG=/dev/null
S_UNAT_NOWIPE="no-wipe:%s"
S_TITLE="t"
HAOS_CMDLINE=""""

# ---- stubs -----------------------------------------------------------------
declare -a DISKS=()
declare -A FSTYPE=() LABEL=() SIZE=() MODEL=() VENDOR=() TRAN=() RM=()

lsblk(){
  local args="$*" last="${*: -1}" dev d
  dev=${last#/dev/}
  case "$args" in
    *NAME,TYPE*)
      for d in ${DISKS[@]+"${DISKS[@]}"}; do printf '%s disk\n' "$d"; done
      return 0 ;;
  esac
  case "$args" in
    *FSTYPE*)  [ -n "${FSTYPE[$dev]:-}" ] && printf '%s\n' "${FSTYPE[$dev]}";  return 0 ;;
    *LABEL*)   [ -n "${LABEL[$dev]:-}" ]  && printf '%s\n' "${LABEL[$dev]}";   return 0 ;;
    *SIZE*)    printf '%s\n' "${SIZE[$dev]:-128G}";   return 0 ;;
    *MODEL*)   printf '%s\n' "${MODEL[$dev]:-SomeDisk}"; return 0 ;;
    *VENDOR*)  printf '%s\n' "${VENDOR[$dev]:-ACME}"; return 0 ;;
    *TRAN*)    printf '%s\n' "${TRAN[$dev]:-sata}";   return 0 ;;
    *HOTPLUG*) printf '0\n'; return 0 ;;
    *RM*)      printf '%s\n' "${RM[$dev]:-0}";        return 0 ;;
    *ROTA*)    printf '0\n'; return 0 ;;
  esac
  return 1
}

# The installer declares its own defaults on one line each, just before it
# starts. Taking them from there instead of keeping a list here means a key that
# is used but never declared -- fatal under 'set -u', which is how unattended
# mode could die on the ISO while this test stayed green -- fails here instead.
DECLS=$(grep -E '^(UNATTENDED|CFG_[A-Z_]+|TARGET|IMG_URL|WIFI_[A-Z_]+)=' "$SRC")

reset(){
  DISKS=(); FSTYPE=(); LABEL=(); SIZE=(); MODEL=(); VENDOR=(); TRAN=(); RM=()
  eval "$DECLS"                  # the same empty defaults the real script starts with
  live_dev=""; IMG_DISK=""
}

# Prints the /dev/name field of every record target_rows() emits.
devs(){ target_rows | cut -f1 | tr '\n' ' '; }

# ---- 1. a config file written on Windows -----------------------------------
reset
tmp=$(mktemp -d)
printf 'UNATTENDED=yes\r\nWIPE=yes\r\nDISK=/dev/nvme0n1\r\nLANG=da\r\n' > "$tmp/haos-installer.cfg"
parse_config_file "$tmp/haos-installer.cfg"
[ "$CFG_UNATTENDED" = "yes" ] || ko "UNATTENDED with CRLF not read (got '$CFG_UNATTENDED')"
[ "$CFG_WIPE" = "yes" ]       || ko "WIPE with CRLF not read (got '$CFG_WIPE')"
[ "$CFG_DISK" = "/dev/nvme0n1" ] || ko "DISK kept a CR (got '$CFG_DISK')"
[ "$CFG_LANG" = "da" ]        || ko "LANG not read (got '$CFG_LANG')"

# ---- 2. comments, blanks, spaces, quotes, lowercase, unknown keys ----------
reset
cat > "$tmp/c2.cfg" <<'EOF'
# written for the mini-pc in the basement
   UNATTENDED = yes

  wipe=yes
DISK="/dev/sda"
IMAGE = "haos_generic-x86-64-18.1.img.xz"
LANG=da
KEYBOARD=dk
POWEROFF=yes
STREAM=yes
FORMAT=yes
NONSENSE=whatever
this line has no equals sign
EOF
parse_config_file "$tmp/c2.cfg"
[ "$CFG_UNATTENDED" = "yes" ] || ko "spaced UNATTENDED not read"
[ "$CFG_WIPE" = "yes" ]       || ko "lowercase wipe= not normalised"
[ "$CFG_DISK" = "/dev/sda" ]  || ko "quotes not stripped from DISK (got '$CFG_DISK')"
[ "$CFG_IMAGE" = "haos_generic-x86-64-18.1.img.xz" ] || ko "IMAGE quotes not stripped (got '$CFG_IMAGE')"
[ "$CFG_KEYMAP" = "dk" ]      || ko "KEYBOARD not read"
[ "$CFG_POWEROFF" = "yes" ]   || ko "POWEROFF not read"
[ "$CFG_STREAM" = "yes" ]     || ko "STREAM not read"
[ "$CFG_FORMAT" = "yes" ]     || ko "FORMAT not read"

# ---- 3. a missing or sloppy WIPE= must never become a yes ------------------
reset
printf 'UNATTENDED=yes\nDISK=/dev/sda\n' > "$tmp/c3.cfg"
parse_config_file "$tmp/c3.cfg"
[ -z "$CFG_WIPE" ] || ko "WIPE must stay empty when absent, got '$CFG_WIPE'"

reset
printf 'UNATTENDED=yes\nWIPE=maybe\nWIPE=1\n' > "$tmp/c4.cfg"
parse_config_file "$tmp/c4.cfg"
[ "$CFG_WIPE" = "yes" ] || ko "WIPE=1 should be accepted as yes, got '$CFG_WIPE'"

reset
printf 'UNATTENDED=yes\nWIPE=maybe\n' > "$tmp/c5.cfg"
parse_config_file "$tmp/c5.cfg"
[ -z "$CFG_WIPE" ] || ko "WIPE=maybe must be ignored, got '$CFG_WIPE'"

# ---- 4. OFF must be respected, not treated as "set" ------------------------
reset
printf 'UNATTENDED=yes\nWIPE=yes\nPOWEROFF=no\nSTREAM=0\nFORMAT=false\n' > "$tmp/c6.cfg"
parse_config_file "$tmp/c6.cfg"
[ -z "$CFG_POWEROFF" ] || ko "POWEROFF=no must clear it, got '$CFG_POWEROFF'"
[ -z "$CFG_STREAM" ]   || ko "STREAM=0 must clear it, got '$CFG_STREAM'"
[ -z "$CFG_FORMAT" ]   || ko "FORMAT=false must clear it, got '$CFG_FORMAT'"

# ---- 5. language helpers ---------------------------------------------------
[ "$(default_keymap da)" = "dk" ] || ko "da must map to dk"
[ "$(default_keymap cs)" = "cz" ] || ko "cs must map to cz"
[ "$(default_keymap sv)" = "se" ] || ko "sv must map to se"
[ "$(default_keymap de)" = "de" ] || ko "de must map to de"
[ "$(default_keymap en)" = "us" ] || ko "en must map to us"
config_supported_lang da || ko "da must be a supported language"
config_supported_lang xx && ko "xx must not be a supported language"

# ---- 6. disk eligibility: the boot medium and the image disk are out -------
reset
DISKS=(sda sdb); TRAN[sda]=sata; TRAN[sdb]=usb; RM[sdb]=1
live_dev=sdb
[ "$(devs)" = "/dev/sda " ] || ko "boot medium offered as target: '$(devs)'"

reset
DISKS=(sda sdb); TRAN[sdb]=usb; RM[sdb]=1
IMG_DISK=sdb
[ "$(devs)" = "/dev/sda " ] || ko "image-carrying disk offered as target: '$(devs)'"

# ---- 6b. the stick that only carries the config is a medium, not a target ---
# Otherwise a 64 MB stick next to the SSD reads as "two eligible disks" and an
# otherwise ready machine refuses to install.
reset
DISKS=(sda sdb); TRAN[sda]=sata; TRAN[sdb]=usb; RM[sdb]=1
CFG_DISK_DEV=sdb
[ "$(devs)" = "/dev/sda " ] || ko "config stick offered as target: '$(devs)'"

# ---- 7. a disk carrying an iso9660 or a Ventoy stick is never a target -----
reset
DISKS=(sda sdb sdc); TRAN[sdb]=usb; RM[sdb]=1; TRAN[sdc]=usb; RM[sdc]=1
FSTYPE[sdb]="iso9660"
LABEL[sdc]="VTOYEFI"
[ "$(devs)" = "/dev/sda " ] || ko "iso9660/Ventoy carrier offered as target: '$(devs)'"

# ---- 8. the removable flag survives into the record ------------------------
reset
DISKS=(sda sdb); TRAN[sda]=sata; TRAN[sdb]=usb; RM[sdb]=1
[ "$(target_rows | awk -F'\t' '$1=="/dev/sda"{print $6}')" = "0" ] || ko "internal disk flagged removable"
[ "$(target_rows | awk -F'\t' '$1=="/dev/sdb"{print $6}')" = "1" ] || ko "USB disk not flagged removable"

# ---- 9. the record carries what the menu shows -----------------------------
reset
DISKS=(sda); SIZE[sda]="465.8G"; MODEL[sda]="Samsung SSD"; VENDOR[sda]="ATA"
rec=$(target_rows)
[ "$(printf '%s' "$rec" | cut -f2)" = "465.8G" ]        || ko "size missing from the record: '$rec'"
[ "$(printf '%s' "$rec" | cut -f4)" = "SSD" ]           || ko "SSD/HDD column missing: '$rec'"
[ "$(printf '%s' "$rec" | cut -f5)" = "ATA Samsung SSD" ] || ko "vendor/model missing: '$rec'"

# ---- 10. the consent gate: no WIPE=yes, no unattended run ------------------
reset
printf 'UNATTENDED=yes\nDISK=/dev/sda\n' > "$tmp/c10.cfg"
CFG_NEXT="$tmp/c10.cfg"; DIE_MSG=""; : > "$tmp/cmd10"; HAOS_CMDLINE="$tmp/cmd10"
load_config
[ -n "$DIE_MSG" ] || ko "missing WIPE=yes must stop the run"
case "$DIE_MSG" in *"c10.cfg"*) ;; *) ko "the refusal must name the config file, got '$DIE_MSG'" ;; esac
[ "$UNATTENDED" = "yes" ] || ko "UNATTENDED should be yes when the file says so"
CFG_NEXT=""; DIE_MSG=""; HAOS_CMDLINE=""

# ---- 11. a file without UNATTENDED=yes leaves the wizard alone -------------
reset
printf 'WIPE=yes\nDISK=/dev/sda\n' > "$tmp/c11.cfg"
CFG_NEXT="$tmp/c11.cfg"; DIE_MSG=""; UNATTENDED=""
load_config
[ -z "$UNATTENDED" ] || ko "UNATTENDED must stay empty without UNATTENDED=yes"
[ -z "$DIE_MSG" ] || ko "nothing should be refused without UNATTENDED=yes, got '$DIE_MSG'"
CFG_NEXT=""

# ---- 12. the command line wins over the file, and can stand alone ----------
reset
printf 'UNATTENDED=yes\nWIPE=yes\nDISK=/dev/sda\nLANG=da\n' > "$tmp/c12.cfg"
printf 'quiet haos.disk=/dev/sdb\n' > "$tmp/cmd12"
CFG_NEXT="$tmp/c12.cfg"; DIE_MSG=""; HAOS_CMDLINE="$tmp/cmd12"
load_config
[ "$CFG_DISK" = "/dev/sdb" ] || ko "command line must win over the file, got '$CFG_DISK'"
[ "$UI_LANG" = "da" ] || ko "LANG=da not applied (got '$UI_LANG')"
[ "$KEYMAP_USED" = "dk|" ] || ko "Danish must set layout dk, got '$KEYMAP_USED'"

reset
printf 'quiet haos.unattended=yes haos.wipe=yes haos.disk=/dev/nvme0n1 haos.lang=sv\n' > "$tmp/cmd13"
CFG_NEXT=""; DIE_MSG=""; UI_LANG="en"; HAOS_CMDLINE="$tmp/cmd13"
load_config
[ "$UNATTENDED" = "yes" ] || ko "haos.unattended=yes on the cmdline must activate it"
[ "$CFG_DISK" = "/dev/nvme0n1" ] || ko "haos.disk not read (got '$CFG_DISK')"
[ "$UI_LANG" = "sv" ] || ko "haos.lang not applied (got '$UI_LANG')"
[ -z "$DIE_MSG" ] || ko "a complete cmdline must not be refused, got '$DIE_MSG'"

# ---- 13. an unsupported LANG falls back to English instead of breaking -----
reset
printf 'UNATTENDED=yes\nWIPE=yes\nLANG=xx\n' > "$tmp/c14.cfg"
CFG_NEXT="$tmp/c14.cfg"; DIE_MSG=""; UI_LANG="en"; HAOS_CMDLINE=""
load_config
[ "$UI_LANG" = "en" ] || ko "unsupported LANG must keep English, got '$UI_LANG'"
[ -z "$DIE_MSG" ] || ko "unsupported LANG must not stop the run"
CFG_NEXT=""

# ---- 14. the template on the ISO sets nothing -------------------------------
# build-iso.sh puts haos-installer.cfg.example on the ISO surface under the real
# name, so find_config() finds it on every boot of the image. A template that
# grew an active WIPE=yes would turn the normal installer into a disk wiper, and
# nobody would have been asked twice.
reset
TPL=haos-installer.cfg.example
if [ ! -r "$TPL" ]; then
  ko "shipped template missing: $TPL"
else
  parse_config_file "$TPL"
  [ -z "$CFG_UNATTENDED$CFG_WIPE$CFG_DISK$CFG_IMAGE$CFG_LANG$CFG_KEYMAP$CFG_POWEROFF$CFG_STREAM$CFG_FORMAT" ] \
    || ko "the shipped template must set nothing, got UNATTENDED='$CFG_UNATTENDED' WIPE='$CFG_WIPE' DISK='$CFG_DISK'"
  # ... and it must not count as a config at all, or it would end the search
  # before a real file on another partition is reached.
  cfg_has_keys "$TPL" && ko 'the shipped template must not read as a config'
  printf '#DISK=/dev/sda\n#WIPE=yes\n' > "$tmp/commented.cfg"
  cfg_has_keys "$tmp/commented.cfg" && ko 'an all-commented file must not read as a config'
  printf 'DISK=/dev/sda\n' > "$tmp/active.cfg"
  cfg_has_keys "$tmp/active.cfg" || ko 'a file with one active key must read as a config'
  printf 'WIPE=n\n' > "$tmp/typo.cfg"
  cfg_has_keys "$tmp/typo.cfg" || ko 'a file with only a worthless key still asks for something'
  CFG_EMPTY=""; CFG_FILE=""
  cfg_candidate "$tmp/commented.cfg" && ko 'cfg_candidate must refuse an empty file'
  [ "$CFG_FILE" = "" ] || ko "cfg_candidate must not set CFG_FILE for an empty file, got '$CFG_FILE'"
  cfg_candidate "$tmp/active.cfg" || ko 'cfg_candidate must accept a file with keys'
  [ "$CFG_FILE" = "$tmp/active.cfg" ] || ko "cfg_candidate picked the wrong file: '$CFG_FILE'"
  [ "$CFG_MNT" = "$tmp" ] || ko "cfg_candidate set the wrong mount point: '$CFG_MNT'"
  # ... and the build has to actually ship it, or the guard above guards air.
  grep -q 'haos-installer.cfg.example' build-iso.sh \
    || ko 'build-iso.sh does not copy the template into the ISO'
fi

# ---- 15. every key the script reads is declared (see DECLS above) ----------
# 'set -u' is on in the script: a CFG_* key read but never declared stops the
# wizard dead -- on the ISO that is a service that restarts into the same error,
# with no menu at all. Nothing here would have noticed before.
for v in $(grep -oE '\$\{?(CFG_[A-Z_]+|UNATTENDED)\b' "$SRC" | tr -d '${' | sort -u); do
  grep -qE "^$v=" "$SRC" || ko "$v is read but never declared: 'set -u' would end the run"
done
[ -n "$DECLS" ] || ko "no declarations extracted from $SRC"

rm -rf "$tmp"

if [ "$fail" -ne 0 ]; then
  printf '\n%s check(s) failed\n' "$fail"
  exit 1
fi

printf 'ok    unattended: CRLF, quotes, lowercase and unknown keys handled, WIPE\n'
printf '      never assumed, consent gate stops a config without it, cmdline wins\n'
printf '      over the file, language keys right, and the same disk exclusions\n'
printf '      as the menu (boot medium, image disk, config stick, iso9660, Ventoy).\n'
printf '      The template shipped in the ISO sets nothing.\n'
printf '\nall checks passed\n'
