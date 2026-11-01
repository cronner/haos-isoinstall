# haos-netinstall — install Home Assistant OS on a PC, without a command line

Bootable USB stick that installs **Home Assistant OS** on a PC through a guided
wizard: network setup (Ethernet or Wi-Fi), disk selection, download and writing
of the official image. Nothing to type.

The wizard speaks **English, Danish, German and French**, and sets the matching
keyboard layout (QWERTY, QWERTZ or AZERTY).

The ISO does **not** contain HAOS: the image is downloaded during the
installation ("netinstall" approach). It therefore stays small (**~450 MB**) and
always installs the **latest published version** of Home Assistant OS.

## ⚠️ READ THIS BEFORE ANYTHING ELSE

> ### This tool COMPLETELY ERASES the disk you select.
>
> No recovery is possible. Use it on a **dedicated** machine,
> **with no data worth keeping**.

**Provided as is, with no warranty and no support.**

- **Personal** project, published in the hope that it is useful. Nothing more.
- **No support is provided.** No installation assistance, no promise of an
  answer to issues, no commitment to fix anything, no long-term maintenance, no
  promise of hardware compatibility.
- **No liability** is accepted for data loss, unusable hardware or any other
  damage. See [LICENSE](LICENSE).
- **Not happy with this project? Fork it.** It is an MIT licence, that is what
  it is for. You are free to modify it, improve it, redistribute it and
  maintain it your own way, without asking anyone.

By using this tool, you accept that you alone bear the consequences.

**Unofficial project** — not affiliated with the Open Home Foundation, Nabu Casa
or the Home Assistant project, and neither approved nor supported by them. The
officially supported method is described
[here](https://www.home-assistant.io/installation/generic-x86-64/). For any
problem with **Home Assistant itself**, turn to the Home Assistant community —
not to this repository.

---

# Part 1 — Installing Home Assistant (users)

## What you need

- A PC **dedicated** to Home Assistant — **its disk will be completely erased**
- **32 GB of disk** minimum, **2 GB of RAM** minimum
- A **USB stick** of 1 GB or more (its contents will be erased)
- An **Ethernet cable** — recommended; Wi-Fi is offered as a fallback

It also works in a **virtual machine**: attach the ISO as a virtual CD/DVD
drive, boot UEFI (q35 + OVMF on Proxmox) with Secure Boot disabled, and give
the VM at least a 32 GB virtual disk. Wi-Fi pre-configuration does not apply
there — use a virtual Ethernet adapter instead. This is tested on Proxmox (see
*Test status* below); for a long-lived hypervisor install, the official
`haos_ova` images remain the better fit, as explained in the Part 2 notes.

## Step 1 — Download the ISO

**[⬇️ Download the latest version](https://github.com/cronner/haos-isoinstall/releases/latest)**

Take the `.iso` file from the *Assets* section. The `.sha256` file next to it
lets you check that the download is not corrupted (optional):

```bash
sha256sum -c haos-netinstall-*.iso.sha256
```

## Step 2 — Write the ISO to the USB stick

With one of these tools, your choice:

- **[Balena Etcher](https://etcher.balena.io/)** — the simplest, Windows/macOS/Linux
- **[Rufus](https://rufus.ie/)** — Windows
- **[Ventoy](https://www.ventoy.net/)** — simply copy the `.iso` onto the stick
- **Linux, from the command line**:
  ```bash
  sudo dd if=haos-netinstall-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
  ```
  ⚠️ Check `/dev/sdX` with `lsblk` — a mistake here erases the wrong disk.

## Step 3 — Configure the PC's BIOS/UEFI

This is **the step everybody trips over**. Power on the PC and immediately press
`Del`, `F2`, `F10` or `Esc` (depending on the brand):

1. **Boot mode: UEFI** — not "Legacy", not "CSM"
2. **Secure Boot: DISABLED** ← *mandatory, Home Assistant will not boot otherwise*
3. **USB stick first** in the boot order
4. Save and exit (`F10`)

## Step 4 — Install

Plug in the stick, boot. The wizard starts on its own:

1. Welcome screen and reminders
2. Language and keyboard layout — English, Danish, German or French
3. Network connection — automatic over Ethernet, otherwise Wi-Fi selection
4. **Disk selection** — check the size and model; the current contents are
   displayed before confirmation
5. Download and writing (progress bar) — **do not power off the PC**
6. **Remove the USB stick**, then confirm: the PC reboots straight into Home
   Assistant. The installer runs from memory, so the stick is no longer needed
   at this point.

Lines of text scroll by during boot: that is normal, it has not crashed.

## Step 5 — First boot

Leave the network cable plugged in and **wait 2 to 5 minutes**: Home Assistant
finishes its installation, the screen may look frozen. Then, from another
device on the same network:

```
http://homeassistant.local
```

If that address does not answer, use the IP address shown on the PC's screen:
`http://<ip-address>`

> Since Home Assistant Core 2026.8, new installations listen on port 80 instead
> of 8123. If your installation is older, add `:8123` to the address.

## If something goes wrong

| Symptom | Likely cause |
|---|---|
| The stick does not boot | Secure Boot still enabled, or Legacy/CSM mode instead of UEFI |
| Home Assistant does not boot after installation | Secure Boot still enabled; on a physical PC, SATA mode set to RAID/Intel RST instead of **AHCI** |
| Wi-Fi works during the install but HA is offline afterwards | The Wi-Fi card is not included in Home Assistant OS (narrower firmware coverage than the installer). Use Ethernet. |
| Installation interrupted while writing | The Internet connection dropped during the download. The wizard gives up after 30 s without throughput and says so; starting the installation over from scratch is safe |
| Installation failed | A log is written to `/tmp/haos-install.log`. The wizard offers to copy it to the stick (reformatted), to another USB stick, or to display it on screen. It then powers the PC off |

**Wi-Fi coverage**: Intel, Realtek, Atheros and Broadcom. Ethernet remains the
reliable path. The installation log gives the exact driver of your card and the
`key-mgmt` used: that is what to look at if Home Assistant stays offline.

**Wi-Fi handover to Home Assistant** — the wizard copies the network profile you
just used into the image, including one created through manual configuration
(`nmtui`): hidden SSID, static IP and WPA3 are therefore carried over as they
are. Two exceptions, reported on screen rather than left unsaid: a
**corporate network with certificates** (802.1X with certificate files) cannot
be handed over, since those files do not exist in Home Assistant; and a profile
whose password is not stored in the file cannot be either. In those cases
nothing is written — better that than a network that never comes up — and the
configuration is done afterwards from the Home Assistant console, or over an
Ethernet cable.

### Test status

| | |
|---|---|
| Proxmox (q35 + OVMF, Secure Boot disabled) | ✅ |
| Physical PC (Dell Inspiron, Wi-Fi) | ✅ |
| Hyper-V / VirtualBox | ❌ not applicable — see the technical notes |

---

# Part 2 — Building the ISO yourself (advanced users)

Unnecessary if you downloaded the ISO above. Useful for auditing, modifying or
adapting the installer.

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

On Proxmox, a test VM:

- **BIOS: OVMF (UEFI)** — mandatory
- **Machine: q35**
- **EFI Disk without "Pre-Enroll keys"** — otherwise Secure Boot rejects HAOS
  (`Access Denied` on `bootx64.efi`)
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
- **Why not in a virtual machine?** Home Assistant provides images **dedicated**
  to hypervisors (`haos_ova` build: `.qcow2`, `.vmdk`, `.vhdx`, `.vdi`, `.ova`).
  This ISO writes the `generic-x86-64` image, meant for bare metal. Use the
  official artefact for your hypervisor.
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
