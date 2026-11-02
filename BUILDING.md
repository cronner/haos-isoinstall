# Building the ISO yourself

Everything in this file is about producing the ISO: building it, customising it,
auditing it. To **install** Home Assistant OS, the guide is
[README.md](README.md) — nothing here is needed for that.

| File | Role |
|---|---|
| `build-iso.sh` | Builds the ISO (run it on a build machine) |
| `haos-installer.sh` | The wizard, embedded in the ISO and started at boot |

## 1. Where to build

`live-build` needs `chroot`, `loop` devices and `/proc`, `/sys`, `/dev`
mounts. That constrains the environment.

| Environment | Verdict |
|---|---|
| **Debian VM** (on Proxmox) | ✅ **Recommended** — isolated, disposable, nothing to clean up |
| Proxmox host directly | ⚠️ Technically possible (it is a Debian) but **not advised**: it installs packages and leaves orphaned mounts on failure, on the production hypervisor |
| **Unprivileged** LXC | ❌ Does not work (no `loop`, `debootstrap` blocked) |
| **Privileged** LXC | ⚠️ Possible with `nesting=1`, `fuse=1` and `loop` access — fragile |
| Physical Ubuntu / Debian | ✅ Works too |
| GitHub Actions | ✅ See `.github/workflows/build-iso.yml` (privileged Debian container) |

> **No particular distribution is required**: any recent Debian or Ubuntu will
> do. The only real constraint is `debootstrap` (§2.2).

A minimal build VM: **2 vCPU**, **4 GB RAM**, **20 GB disk**, Internet access
(Debian mirrors + GitHub).

## 2. Building

### 2.1 Prerequisites

```bash
sudo apt update
sudo apt install live-build
```

### 2.2 Check the target

`build-iso.sh` builds a **Debian 13 (trixie)**. The local `debootstrap` must
know about it:

```bash
ls /usr/share/debootstrap/scripts/ | grep trixie
```

- **Nothing is printed** (typical on Debian 12 / Proxmox VE 8) → either replace
  `--distribution trixie` with `--distribution bookworm` in `build-iso.sh`, or
  install a recent `debootstrap` from backports.
- **`trixie` appears** (Debian 13 / Proxmox VE 9) → nothing to do.

### 2.3 Run it

Both scripts in the same folder, then:

```bash
chmod +x build-iso.sh
sudo ./build-iso.sh
```

The build takes **15 to 40 minutes** and produces
`haos-installer-iso/live-image-amd64.hybrid.iso` (~450 MB). The script starts
from a clean folder on every run.

The boot timeouts that were applied are displayed **within the first seconds**:
if the list is empty, there is no point waiting for the end.

### 2.4 If something goes wrong

```bash
cd haos-installer-iso
sudo lb clean --purge            # full cleanup before running again
mount | grep haos-installer-iso  # orphaned mounts after an interruption?
```

## 3. Testing without a USB stick

A test VM on any QEMU/KVM hypervisor does the job; the names below are Proxmox's,
and every other one has the same three knobs (UEFI, Secure Boot off, 32 GB).

- **BIOS/firmware: OVMF (UEFI)** — mandatory
- **Machine: q35** (Proxmox; the default on most others)
- **EFI Disk without "Pre-Enroll keys"** (Proxmox) — otherwise Secure Boot
  rejects HAOS (`Access Denied` on `bootx64.efi`); on Unraid and virt-manager
  there is no separate EFI disk, the firmware setting alone decides
- A disk of **32 GB minimum**

That validates the wizard, the disk selection, the download and the writing.
**Wi-Fi**, on the other hand, requires a physical machine.

## 4. Customisation

**Version resolution** — after the network configuration,
`resolve_version()` queries the Home Assistant stable channel
(`version.home-assistant.io/stable.json`, `hassos` key of the `generic-x86-64`
board map). It is the same source as the Supervisor: it reflects channel
demotions, unlike the GitHub API, which is used as a fallback when the first is
unreachable. If both fail, the installation stops with an explicit error: no
version is hard-coded. That is deliberate — a fallback constant would only help
if both sources were unreachable *while* downloading the image works, and it
would have to be refreshed for every HAOS release.

**Pinning a HAOS version** — replace the body of `resolve_version()` with a
hard-coded `HAOS_VERSION`; `IMG_URL` follows from it automatically.

**Adding packages** — the `config/package-lists/haos.list.chroot` block of
`build-iso.sh`. Every package makes the ISO bigger.

**Broader hardware coverage** — remaster an **Ubuntu** with
[Cubic](https://github.com/PJ-Singh-001/Cubic) and inject `haos-installer.sh`
into it, reusable as it is.

## 5. Technical notes

- **Why not the Debian installer (d-i)?** HAOS is a complete disk image
  (GPT + A/B system partitions), not a set of packages. `d-i` knows how to
  partition and install a Debian, not how to write a raw image. Hence the choice
  of a minimal live system + a purpose-built wizard.
- **Why prefer the official VM image over this ISO?** Home Assistant provides
  images **dedicated** to hypervisors (`haos_ova` build: `.qcow2`, `.vmdk`,
  `.vhdx`, `.vdi`, `.ova`). This ISO writes the `generic-x86-64` image, meant for
  bare metal. It does boot and install in a QEMU/KVM VM (Proxmox, Unraid,
  virt-manager, Incus), but the official artefact is what Home Assistant
  supports there, so use it for anything long-lived.
  A frequent special case: a hypervisor that only accepts ISOs **when creating**
  a VM — Synology VMM, typically. The restriction only applies to creation: on
  **import**, VMM accepts disk images (`.img`, `.vmdk`, `.vdi`, `.vhd`, `.vhdx`,
  `.qcow2`). So import `haos_ova-*` rather than going through an installer.
- **Hardware without UEFI** — HAOS requires UEFI and GPT: that is a constraint
  of the official image, not of this ISO. On a machine that can only boot in
  Legacy/CSM, no HAOS installation is possible. The only alternative is a
  *Supervised* installation on Debian, a method far less supported by Home
  Assistant (an "unsupported" banner as soon as the OS deviates, and system
  maintenance on your hands).
- **Apple Silicon Mac — do not try.** Those machines have no UEFI (Apple's own
  iBoot chain), their internal SSD is not a standard NVMe drive, and the HAOS
  kernel ships no Apple Silicon driver. Above all: completely erasing the disk
  takes away the Mac's ability to boot anything at all, recovery going through a
  DFU restore from another Mac. To run HAOS on an ARM Mac, use a VM (UTM) and
  the `haos_generic-aarch64` image — without this ISO, which is amd64.
- **Log, and a reusable stick** — the log records the installation decisions
  (version chosen and its source, network hardware and driver, Wi-Fi band and
  encryption, target disk, verification result, UEFI/Secure Boot state) and
  never contains the Wi-Fi password.

  At the end of the run — whether the installation succeeded or failed — the
  wizard offers to **reformat the stick as a single FAT32 partition** covering
  the whole device, and drops the log onto it. The stick then becomes an
  ordinary USB stick again, something **Windows cannot do on its own** on a
  stick written by Etcher: the isohybrid layout confuses its formatting tool,
  and you have to go through `diskpart` in an administrator PowerShell. The
  confirmation screen warns that the installer will be erased — the stick will
  have to be written again to reinstall. Declining has no consequence.

  If you decline, or if the reformat fails, copying to another USB stick and
  displaying the log on screen to photograph it remain available.

  > A dedicated partition embedded in the ISO was tried and then abandoned:
  > **Windows 11 only exposes the first partition of a removable medium**
  > (Windows 10 could handle several since the Creators Update), and the first
  > partition has to carry the ISO9660 filesystem for BIOS boot. It therefore
  > stayed invisible without manually assigning a drive letter.

- **The Ventoy case** — Ventoy does not write the ISO to the stick: it leaves it
  as a file on its exFAT partition and exposes it at boot as a *device-mapper*
  device (`/dev/dm-0`). Two consequences, both handled:
  - the Ventoy stick is **never** offered as a target disk. The boot medium is
    resolved by walking back from `dm-0` to the physical disk via
    `/sys/block/dm-*/slaves/`, and any disk carrying a partition labelled
    `VTOYEFI` is skipped as a precaution;
  - its exFAT partition is **claimed** by that mapping, hence not writable: the
    log cannot be copied there. The wizard detects this and asks you to unplug
    and replug the stick — which releases the partition — before trying again.
    Since the installer runs from memory, unplugging it is harmless.
- **Data partition** — no need to enlarge it: HAOS automatically extends its
  `hassos-data` partition to the size of the disk on first boot.
- **Prior erasure** — the wizard wipes signatures and GPT tables (start and end
  of the disk) before writing. Deliberate: on a disk carrying an older OS,
  HAOS's automatic resize can fail.
- **Secure Boot** — HAOS does not support it. Since disabling it is necessary
  anyway, the ISO does not need to be signed.
- **Embedded firmware** — only **network** firmware is included (Realtek,
  Intel, Atheros, Broadcom). `--firmware-chroot` is disabled: otherwise
  `live-build` pulls in every `firmware-*` package from the archive, including
  GPU/audio blobs that are useless to a text-mode installer (851 MB → 450 MB).
  ⚠️ `firmware-realtek` also provides the Gigabit **Ethernet** blobs
  (`rtl_nic/rtl8168*`): do not remove it thinking you are only dropping Wi-Fi.
- **Boot timeout** — `live-build` templates define none for GRUB, and
  `timeout 0` means "wait forever" for isolinux. Since the menu stays invisible
  on some screens, `build-iso.sh` forces `timeout=1` +
  `timeout_style=hidden` via `config/bootloaders/`.
- **`toram`** — the live system is copied to RAM at boot, so the USB stick can
  be removed at any time. Cost: slower boot (~450 MB to copy) and ~2 GB of RAM.
  Remove `toram` from `--bootappend-live` on very low-spec machines.
- **No `quiet`** — the kernel log scrolls by on purpose, just as HAOS itself
  does: it is the only sign of life while waiting, and a usable screen when
  filing a bug report.
- **Wi-Fi pre-configuration (wireless installation)** — after writing, if the
  installation was done over Wi-Fi, the wizard places a NetworkManager profile
  in `CONFIG/network/my-network` on the `hassos-boot` partition, which HAOS
  imports on first boot (minimal profile, **without `interface-name`**: that
  field, copied as is from the live system, locks the profile to a card that
  does not exist on the HAOS side). **Important limitation:** this only works if
  the Wi-Fi card is supported by HAOS. Its firmware coverage is narrower than
  the installer's (which is Debian-based): a card that works during the install
  may be missing under HAOS (`Direct firmware load ... failed`). There is **no
  way to inject the missing firmware from the installer** — HAOS uses no initrd,
  the driver loads too early for firmware dropped in afterwards to be read. The
  only route is to have the firmware added to HAOS's `linux-firmware` package
  (upstream, when the image is built). Ethernet therefore remains recommended.

---

## Origin and credits

This is a fork of **[PocketFR/haos-netinstall](https://github.com/PocketFR/haos-netinstall)**
by Sébastien CANAT. The wizard, the build script and the documentation started
there, and `LICENSE` keeps his copyright notice next to this fork's — that is
what the MIT licence requires, and it is simply true.

What this fork changes: the wizard and this README are in English, and the
wizard also speaks 13 other languages (Czech, Danish, Dutch, Finnish, French,
German, Italian, Norwegian, Polish, Portuguese, Russian, Spanish, Swedish) with
matching keyboard layouts; the image is downloaded and
integrity-checked **before** a disk is erased, and an interrupted download
resumes; a disk is only erased after typing `YES`; the closing reformat step is
offered only on a medium that can actually be reformatted; the ISO is named after
this repository; and CI checks the string tables on every push.

Home Assistant OS itself is downloaded at run time from the Open Home Foundation
and is not covered by this licence — see `LICENSE` for the details.

## License

[MIT](LICENSE) for the scripts in this repository.

Debian, the non-free firmwares and Home Assistant OS remain subject to their
respective licences — see the details in the [LICENSE](LICENSE) file.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues document problems; they are not a
support queue.

## Sources

- [Home Assistant — Generic x86-64 installation](https://www.home-assistant.io/installation/generic-x86-64/)
- [Home Assistant OS — releases](https://github.com/home-assistant/operating-system/releases)
- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/)
