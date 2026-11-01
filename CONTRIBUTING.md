# Contributing

This project is maintained in free time, **with no commitment to support or to
responding quickly**. That said, contributions are welcome.

## Bug reports

Issues exist to **document problems for other people**, not to obtain guaranteed
help. An issue may go unanswered or be closed without follow-up.

For a report to be useful, state:

- the **hardware** (PC model, storage controller, Wi-Fi card via `lspci -nn`);
- the boot mode (**UEFI** or legacy) and the **Secure Boot** state;
- the ISO version and the installed HAOS version;
- the contents of `/tmp/haos-install.log` if the installation failed.

Problems with **Home Assistant itself** (and not with the installer) belong to
the Home Assistant community, not to this repository.

## Pull requests

Welcome, with no promise of merge or of a timeline. Please:

- keep the scripts **POSIX-compatible bash**, with no new dependency unless
  really necessary (every package makes the ISO bigger);
- check with `bash -n` and `shellcheck`;
- test **at minimum** in a UEFI VM (Proxmox q35 + OVMF, Secure Boot disabled) and
  state what was tested — or what was not;
- one PR = one topic.

## Disagree with this project's choices?

**Fork it.** The MIT licence is made for that: take the code, change whatever you
want, redistribute it under your own name. No permission needed. It is often
faster and more satisfying than a debate in an issue.
