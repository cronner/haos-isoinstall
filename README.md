# haos-isoinstall — install Home Assistant OS on a PC, without a command line

[![Checks](https://github.com/cronner/haos-isoinstall/actions/workflows/checks.yml/badge.svg)](https://github.com/cronner/haos-isoinstall/actions/workflows/checks.yml)
[![Build ISO](https://github.com/cronner/haos-isoinstall/actions/workflows/build-iso.yml/badge.svg)](https://github.com/cronner/haos-isoinstall/actions/workflows/build-iso.yml)

Bootable USB stick that installs **Home Assistant OS** on a PC through a guided
wizard: network setup (Ethernet or Wi-Fi), disk selection, download and writing
of the official image. Nothing to type.

**Quick start** — download the ISO from [Releases] and check it
(`sha256sum -c *.iso.sha256`), write it to a USB stick with Etcher or Rufus (not
by copying the file), turn **Secure Boot off** and SATA to **AHCI** in the BIOS,
boot the stick and follow the wizard. Everything below is detail.

**Contents:** [What you need](#what-you-need) · [1 Download](#step-1--download-the-iso)
· [2 Write the stick](#step-2--write-the-iso-to-the-usb-stick)
· [3 BIOS](#step-3--configure-the-pcs-biosuefi) · [Screens](#what-it-looks-like) · [4 Install](#step-4--install)
· [When RAM is short](#when-ram-is-short--the-image-is-staged-on-a-usb-stick)
· [5 First boot](#step-5--first-boot) · [Troubleshooting](#if-something-goes-wrong)
· [Building it yourself](BUILDING.md)

The wizard speaks **14 languages**. You pick the language, and its keyboard
layout is applied automatically — one line, nothing to match up:

| Language | Keyboard layout set automatically |
| -------- | --------------------------------- |
| English | QWERTY (United States) |
| Danish | QWERTY (Denmark) |
| Czech | QWERTZ (Czechia) |
| Dutch | QWERTY (Netherlands) |
| Finnish | QWERTY (Finland) |
| French | AZERTY (France) |
| German | QWERTZ (Germany) |
| Italian | QWERTY (Italy) |
| Norwegian | QWERTY (Norway) |
| Polish | QWERTY (Poland) |
| Portuguese | QWERTY (Portugal) |
| Russian | YTsUKEN (Russia) |
| Spanish | QWERTY (Spain) |
| Swedish | QWERTY (Sweden) |

A layout belongs to the keyboard, not to the language, so the last line of the
menu — *Keyboard layout only (another country)* — holds the full set of pairs:
QWERTY (United Kingdom) and QWERTZ (Germany) for English, AZERTY (Belgium),
QWERTZ (Switzerland), QWERTY (Canada) and QWERTY (United States) for French, and
QWERTZ (Switzerland) for German. Nobody else ever sees that line.

Menu labels stay in plain ASCII so they remain readable on the text console; the
translated messages themselves use the language's own characters. A language code
that is not in the table falls back to English and US QWERTY.

The ISO does **not** contain HAOS: the image is downloaded during the
installation ("network install" approach). It therefore stays small (**~450 MB**) and
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

# Installing Home Assistant

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
`haos_ova` images remain the better fit, as explained in [the technical notes](BUILDING.md#5-technical-notes).

## Step 1 — Download the ISO

**[⬇️ Download the latest version](https://github.com/cronner/haos-isoinstall/releases/latest)**

Take the `.iso` file from the *Assets* section. The `.sha256` file next to it
lets you check that the download is not corrupted (optional):

```bash
sha256sum -c haos-isoinstall-*.iso.sha256
```

## Step 2 — Write the ISO to the USB stick

With one of these tools, your choice:

- **[Balena Etcher](https://etcher.balena.io/)** — the simplest, Windows/macOS/Linux
- **[Rufus](https://rufus.ie/)** — Windows
- **[Ventoy](https://www.ventoy.net/)** — simply copy the `.iso` onto the stick
- **Linux, from the command line**:
  ```bash
  sudo dd if=haos-isoinstall-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
  ```
  ⚠️ Check `/dev/sdX` with `lsblk` — a mistake here erases the wrong disk.

## Step 3 — Configure the PC's BIOS/UEFI

This is **the step everybody trips over**. Power on the PC and immediately press
`Del`, `F2`, `F10` or `Esc` (depending on the brand):

1. **Boot mode: UEFI** — not "Legacy", not "CSM"
2. **Secure Boot: DISABLED** ← *mandatory, Home Assistant will not boot otherwise*
3. **SATA mode: AHCI** — not "RAID", not "Intel RST". With RST the disk is
   hidden from the installer, and Home Assistant will not find it afterwards
4. **Fast Boot: OFF** — recommended: it makes the first boot from the stick
   unreliable on some firmware
5. **USB stick first** in the boot order
6. **"Power on after power loss" / "AC recovery": ON** — recommended: a Home
   Assistant box that stays off after a power cut is a box you have to go and
   switch on by hand, every time
7. Save and exit (`F10`)

Once Home Assistant boots on its own, put the **internal disk first** in the boot
order again. The wizard does recreate a `HAOS` UEFI entry, but the stick would
otherwise keep priority and start the installer again.

## What it looks like

Text mock-ups of the real screens, so you know what to expect. The wording is
the wizard's own; only the disk details are made up.

**1. Language** — one line per language, and the keyboard layout is applied with
it, so there is nothing to match up. The last line opens the full set of layouts
for keyboards that do not match their language (a US keyboard with French,
British English, Swiss German).

```
┌─ Language & keyboard ──────────────────────────────────────────────────┐
│ Choose your language. Its keyboard layout is set automatically.        │
│                                                                        │
│ The last line is for a keyboard from another country.                  │
│                                                                        │
│ ▶ English    — QWERTY   (United States)                                │
│   Dansk      — QWERTY   (Denmark)                                      │
│   Cestina    — QWERTZ   (Czechia)                                      │
│   Nederlands — QWERTY   (Netherlands)                                  │
│   Suomi      — QWERTY   (Finland)                                      │
│   French     — AZERTY   (France)                                       │
│   Deutsch    — QWERTZ   (Germany)                                      │
│   Italiano   — QWERTY   (Italy)                                        │
│   Norsk      — QWERTY   (Norway)                                       │
│   Polski     — QWERTY   (Poland)                                       │
│   Portugues  — QWERTY   (Portugal)                                     │
│   Russkiy    — YTsUKEN  (Russia)                                       │
│   Espanol    — QWERTY   (Spain)                                        │
│   Svenska    — QWERTY   (Sweden)                                       │
│   Keyboard layout only (another country)                               │
│                                                                        │
│                          <Ok>       <Cancel>                           │
└────────────────────────────────────────────────────────────────────────┘
```

**3. Disk** — the current contents are listed above the question, and the answer
has to be typed, so a button cannot erase a disk by accident.

```
┌─ ⚠  FINAL CONFIRMATION  [4/6] ─────────────────────────────────────────┐
│ Disk /dev/sda will be COMPLETELY ERASED.                               │
│                                                                        │
│ Current contents detected:                                             │
│    sda                                                                 │
│    ├─sda1     512M  vfat                                               │
│    └─sda2     460G  ext4                                               │
│                                                                        │
│ Type YES (in capitals) to erase it and install                         │
│ Home Assistant OS.                                                     │
│ Any other answer stops here, with nothing erased.                      │
│                                                                        │
│ YES                                                                    │
│                                                                        │
│                          <Ok>       <Cancel>                           │
└────────────────────────────────────────────────────────────────────────┘
```

**4. Download** — with too little RAM the image is staged on a USB stick instead,
and the dialog says so before anything is touched.

```
┌─ ⚠  WARNING  [5/6] ────────────────────────────────────────────────────┐
│ Not enough free memory to hold the image in RAM (429M).                │
│                                                                        │
│ No writable stick or external disk with that much free space           │
│ was found.                                                             │
│                                                                        │
│ Plug one in and choose Retry: the image is downloaded there            │
│ and checked BEFORE anything is erased.                                 │
│                                                                        │
│ "Write in one pass" instead erases the target disk first:              │
│ a network drop after that leaves an empty disk.                        │
│                                                                        │
│                   <Retry>       <Write in one pass>                    │
└────────────────────────────────────────────────────────────────────────┘
```

The whole sequence, and the one line that matters in it:

![Wizard flow: language, network, disk, download and check, erase and write, verify, reboot — the disk is untouched until the download has been checked](docs/flow.svg)

Everything above the red line can fail without costing you anything. Everything
below it has already erased the disk.

Real screenshots would have to come from a virtual machine: boot the ISO at 80×24
and capture each step. The mock-ups above are checked by hand whenever the wording
changes; screenshots would have to be checked too, which is why there are none yet.

## Step 4 — Install

Plug in the stick, boot. The wizard starts on its own:

1. Welcome screen and reminders
2. Language — 14 languages, each with its keyboard layout applied (table above)
3. Network connection — automatic over Ethernet, otherwise Wi-Fi selection
4. **Disk selection** — check the size and model; the current contents are
   displayed, and you must type `YES` to confirm (anything else stops)
5. Download and integrity check, **then** erasing and writing — each with its
   own progress bar (percentage, rate, ETA). The image is fetched and verified
   before the disk is touched, so a network failure leaves the disk intact, and
   an interrupted download resumes instead of starting over.
   On a machine with too little RAM the image is staged on a USB stick instead —
   see *When RAM is short* below.
   **Do not power off the PC**
6. **Remove the USB stick**, then confirm: the PC reboots straight into Home
   Assistant. The installer runs from memory, so the stick is no longer needed
   at this point.

Lines of text scroll by during boot: that is normal, it has not crashed.

## When RAM is short — the image is staged on a USB stick

The wizard keeps the downloaded image off the target disk until it has been
checked, so a failed download cannot cost you a disk. That needs room for the
compressed image (~430 MB) plus headroom — about twice its size in free memory,
because it stages it in RAM, and `/tmp` is a tmpfs, half of RAM by default.

Below that, the wizard does not silently drop the guarantee:

1. It says how much memory is free and asks for a **writable USB stick or
external disk** with at least as much free space (FAT32, exFAT, NTFS and ext4 all
work), then offers **Retry**.
2. Once one is found it shows the exact path it will use, downloads there,
checks the file against the image's `.xz` checksums, and only then erases the
disk.
3. The file is deleted from the medium and the medium unmounted again once the
write is done, so a stick you plugged in for this is left as you gave it.

It never uses the installer stick itself: that one carries a read-only ISO9660
filesystem, and writing there would mean reformatting it — destroying the only
way back into the installer before Home Assistant is installed. The installation
disk and the boot medium are excluded too; only USB or external media qualify.

With no such medium, the last button is **Write in one pass**: the target disk is
erased first and the download and the writing happen in one stream, so a network
drop at that point leaves an empty disk. The dialog spells that out before you
pick it.

The choice of medium — what qualifies and what must be refused — is tested by
`tests/stage.sh` (internal disk, installation disk, boot medium,
ISO9660/UDF, too little room, read-only mount, and which candidate wins).

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
| No disk appears in the wizard | SATA mode set to RAID / Intel RST, which hides the disk from the installer. Set **AHCI** (step 3) |
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
| Hyper-V / VirtualBox | ❌ not applicable — [see the technical notes](BUILDING.md#5-technical-notes) |

## Building it yourself

Auditing, modifying or building the ISO from source — with the technical notes,
the credits and the licence — lives in **[BUILDING.md](BUILDING.md)**. None of it
is needed to install Home Assistant.

This project is MIT-licensed: see [LICENSE](LICENSE).
