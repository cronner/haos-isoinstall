#!/bin/bash
# build-iso.sh — Builds a beginner-friendly "HAOS installer" live ISO (Debian live-build).
# Includes: non-free network/Wi-Fi firmware (without the GPU/audio blobs), NetworkManager,
# a guided whiptail wizard.
# NB: no --bootloaders / --uefi-secure-boot option: they do not exist in every
#     live-build version (fails on Ubuntu). Pointless anyway, the default already
#     produces an ESP with /EFI/boot/bootx64.efi (checked via fdisk).
# Prerequisites (Debian/Ubuntu, as root): apt install live-build
# Run from a folder containing haos-installer.sh:  sudo ./build-iso.sh
set -euo pipefail

WORK="haos-installer-iso"
[[ -f haos-installer.sh ]] || { echo "haos-installer.sh missing from the current folder"; exit 1; }

# Which image to build. The two differ in ONE file: the configuration the image
# runs with. 'normal' asks every question and can never erase anything on its
# own; 'unattended' carries UNATTENDED=yes and WIPE=yes and starts erasing the
# disk it picks as soon as the boot finishes. Same code, same ISO otherwise, so
# there is one installer to maintain and two ways to run it.
# Either way of asking, because 'sudo ./build-iso.sh unattended' is what a person
# at a keyboard will type, while HAOS_VARIANT is what a CI job can export.
VARIANT="${HAOS_VARIANT:-${1:-normal}}"
case "$VARIANT" in
  normal|unattended) ;;
  *) echo "variant must be normal or unattended (got '$VARIANT')"; exit 1 ;;
esac
# The ISO is a copy of this script, so the MIT notice has to travel with it.
[[ -f LICENSE ]] || { echo "LICENSE missing from the current folder"; exit 1; }
[[ $EUID -eq 0 ]] || { echo "Run as root (live-build requires it)."; exit 1; }

# Resolved before the cd below: live-build works in $WORK, so anything still
# referenced relatively from here on would point into the build tree instead.
SRC="$(pwd)/haos-installer.sh"
DOCSRC="$(pwd)"
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"

# BIOS boot currently only comes from live-build's DEFAULT (syslinux): nothing
# pins it down, so an upstream change could drop it without any error. We
# therefore request it explicitly -- but only if the option exists, since it is
# missing from some versions (see the note at the top of the file: fails on Ubuntu).
BOOTLOADERS_OPT=()
if lb config --help 2>&1 | grep -q -- '--bootloaders'; then
  BOOTLOADERS_OPT=(--bootloaders syslinux,grub-efi)
  echo ">>> --bootloaders supported: BIOS+UEFI boot pinned explicitly."
else
  echo ">>> --bootloaders absent from this live-build version: default kept."
fi

# --iso-volume: the "HAOS Installer" LABEL is SHARED with haos-installer.sh
# (ISO_LABEL constant). The installer uses it to recognise the boot medium and
# exclude it from the target disks -- 'toram' replacing /run/live/medium with a
# tmpfs, that is the only reliable way to identify it. Keep both in step.
lb config \
  ${BOOTLOADERS_OPT[@]+"${BOOTLOADERS_OPT[@]}"} \
  --distribution trixie \
  --architecture amd64 \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --firmware-chroot false \
  --debian-installer none \
  --memtest none \
  --iso-volume "HAOS Installer" \
  --bootappend-live "boot=live components toram locales=en_US.UTF-8 keyboard-layouts=us timezone=Etc/UTC"

# --- Packages: network firmware + the wizard's tools (see the list) ---
mkdir -p config/package-lists
cat > config/package-lists/haos.list.chroot <<'EOF'
# --- Network firmware only ---
# NB: firmware-realtek ALSO provides the Gigabit Ethernet blobs
#     (rtl_nic/rtl8168*), ubiquitous on cheap PCs and thin clients -> essential.
firmware-realtek
firmware-iwlwifi
firmware-atheros
firmware-brcm80211
# Removed on purpose (text-mode installer, no GPU/audio/TV need):
#   firmware-linux, firmware-linux-nonfree, firmware-misc-nonfree
# --- Tools ---
network-manager
rfkill
wpasupplicant
iw
console-setup
kbd
whiptail
pv
curl
# jq: reads the stable channel (version.home-assistant.io/stable.json), where the
# board key also appears under two sections -> a grep would return the wrong one.
jq
xz-utils
util-linux
efibootmgr
mokutil
dosfstools
parted
# To write the log onto the user's rescue stick: without these packages, an
# exFAT or NTFS stick (the case for most sticks over 32 GB, and Ventoy's default
# format) cannot be mounted at all.
exfatprogs
ntfs-3g
EOF
# --- Guided wizard ---
mkdir -p config/includes.chroot/usr/local/bin
cp "$SRC" config/includes.chroot/usr/local/bin/haos-installer.sh

# --- Licence and guides, inside the image ---
# Anyone who boots this ISO holds a copy of an MIT-licensed work; the notice goes
# where it can be read without unpacking anything. The guides ride along for the
# same reason (and so the credits stay attached to the copy).
DOCDIR=config/includes.chroot/usr/local/share/doc/haos-isoinstall
mkdir -p "$DOCDIR"
cp "$DOCSRC/LICENSE" "$DOCDIR/LICENSE"
for f in README.md BUILDING.md; do
  if [ -f "$DOCSRC/$f" ]; then cp "$DOCSRC/$f" "$DOCDIR/$f"; fi
done
# ... and on the ISO surface itself: readable from a mounted image without
# booting it, and cheap for the build to verify (the chroot copy sits inside
# filesystem.squashfs, where a plain file listing cannot see it).
mkdir -p config/includes.binary
cp "$DOCSRC/LICENSE" config/includes.binary/LICENSE

# The unattended configuration. On the normal image it is the template on the
# ISO surface: every key commented out, so it does nothing until someone copies
# it to a stick and edits it. Under the real name, so copying the file to a
# stick is the whole procedure -- the installer finds it and reports that it sets
# nothing.
#
# The unattended image instead has a live config, and it has to sit INSIDE the
# chroot: find_config() skips the iso9660 partition, since that one carries the
# live system, so a config at the ISO root is readable but never read. The same
# file also goes to the ISO root, so it can be read before it is booted.
mkdir -p config/includes.chroot/etc
if [ "$VARIANT" = unattended ]; then
  [[ -f "$DOCSRC/haos-installer.cfg.unattended" ]] \
    || { echo "haos-installer.cfg.unattended missing from the current folder"; exit 1; }
  cp "$DOCSRC/haos-installer.cfg.unattended" config/includes.chroot/etc/haos-installer.cfg
  cp "$DOCSRC/haos-installer.cfg.unattended" config/includes.binary/haos-installer.cfg
  echo ">>> Variant: unattended -- this image erases a disk without asking."
else
  [[ -f "$DOCSRC/haos-installer.cfg.example" ]] \
    || { echo "haos-installer.cfg.example missing from the current folder"; exit 1; }
  cp "$DOCSRC/haos-installer.cfg.example" config/includes.binary/haos-installer.cfg
  echo ">>> Variant: normal -- every question asked, nothing erased unasked."
fi
# The template always rides along, so the keys can be looked up in a live system
# even when the active config is the baked one.
if [[ -f "$DOCSRC/haos-installer.cfg.example" ]]; then
  cp "$DOCSRC/haos-installer.cfg.example" "$DOCDIR/haos-installer.cfg.example"
fi

# --- Build stamp: the ISO carries no version string of its own. The
# installer shows it on the welcome screen and logs it, so that a bug
# report says WHICH build produced it.
REF=$(echo "${GITHUB_SHA:-}" | cut -c1-7)
[ -n "$REF" ] || REF=$(git rev-parse --short=7 HEAD 2>/dev/null || echo local)
# The variant is part of the stamp: a log or a bug report has to say which of
# the two images produced it, or the first question is always "which ISO?".
VARIANT_NOTE=""
if [ "$VARIANT" = unattended ]; then VARIANT_NOTE=" unattended"; fi   # not &&: 'set -e'
printf 'build %s %s%s\n' "$(date -u +%Y-%m-%d)" "$REF" "$VARIANT_NOTE" \
  > config/includes.chroot/etc/haos-installer-build

# --- NetworkManager manages every interface (otherwise it conflicts with live-config) ---
mkdir -p config/includes.chroot/etc/NetworkManager/conf.d
cat > config/includes.chroot/etc/NetworkManager/conf.d/10-live.conf <<'EOF'
[main]
plugins=keyfile
[keyfile]
unmanaged-devices=none
EOF

# --- Service: starts the wizard at boot, full screen on tty1 ---
mkdir -p config/includes.chroot/etc/systemd/system
cat > config/includes.chroot/etc/systemd/system/haos-installer.service <<'EOF'
[Unit]
Description=Home Assistant OS guided installer
After=NetworkManager.service systemd-user-sessions.service
Wants=NetworkManager.service
Conflicts=getty@tty1.service
Before=getty@tty1.service

[Service]
Type=idle
Environment=TERM=linux
StandardInput=tty
StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
ExecStart=/usr/local/bin/haos-installer.sh
TimeoutStartSec=0
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# --- Hook: executable bit + enabling services ---
mkdir -p config/hooks/live
cat > config/hooks/live/9000-haos.hook.chroot <<'EOF'
#!/bin/sh
set -e
chmod +x /usr/local/bin/haos-installer.sh
systemctl enable NetworkManager.service
systemctl enable haos-installer.service
systemctl set-default multi-user.target
EOF
chmod +x config/hooks/live/9000-haos.hook.chroot

# --- Boot menu timeouts ---
# Official live-build mechanism: any directory present in config/bootloaders/
# replaces the template from /usr/share/live/build/bootloaders/.
#   - isolinux/syslinux: "timeout 0" means WAIT FOREVER (classic trap),
#     the unit is 1/10 s -> 10 = 1 second.
#   - grub: the templates define no timeout -> GRUB waits forever.
#     On some screens (old laptops) the menu does not even show up: black screen
#     and the user has to press Enter blindly. Hence timeout_style=hidden.
# NB: lb config already creates an EMPTY config/bootloaders/. A "cp -r src dst"
#     would create dst/bootloaders/ instead of filling it -> we copy the CONTENT (src/.).
mkdir -p config/bootloaders
cp -r /usr/share/live/build/bootloaders/. config/bootloaders/

for f in config/bootloaders/isolinux/isolinux.cfg \
         config/bootloaders/syslinux/syslinux.cfg \
         config/bootloaders/extlinux/extlinux.conf; do
  [ -f "$f" ] && sed -i 's/^timeout 0$/timeout 10/' "$f"
done

# GRUB: inject the timeout into every .cfg of the template
for f in config/bootloaders/grub-pc/*.cfg config/bootloaders/grub-efi/*.cfg; do
  [ -f "$f" ] || continue
  grep -q '^set timeout=' "$f" \
    && sed -i 's/^set timeout=.*/set timeout=1/' "$f" \
    || sed -i '1i set timeout=1\nset timeout_style=hidden' "$f"
done

echo ">>> Timeouts applied:"
grep -rn '^timeout \|^set timeout' config/bootloaders/ || echo "  (none - check this)"

echo ">>> Build (access to the Debian mirrors required)..."
lb build

ISO=$(ls -1 live-image-*.iso 2>/dev/null | head -1)
[ -n "$ISO" ] || { echo ">>> ISO: failed"; exit 1; }

# NB: no partition dedicated to the logs in the ISO. A third partition was
# indeed tried (FAT16 added by 'xorriso -append_partition'), but Windows 11 only
# exposes the FIRST partition of a removable medium: it stayed invisible there
# without manual work in disk management. And the 1st partition cannot be used,
# it has to carry the ISO9660 filesystem for BIOS boot.
# The installer now offers to reformat the whole stick as FAT32 and drop the log
# onto it, which also makes it reusable -- Windows cannot reformat an Etcher-written
# stick on its own.
echo ">>> ISO: $ISO  ($(du -h "$ISO" | cut -f1))  variant=$VARIANT"
echo ">>> Partitions:"
fdisk -l "$ISO" 2>/dev/null | tail -6 || true
