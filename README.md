# bluefin-nix

A custom [bootc](https://bootc-dev.github.io/bootc/) / OCI container image that extends
[Universal Blue's Bluefin-DX](https://projectbluefin.io/) with the
[Determinate Nix](https://determinate.systems/) package manager pre-configured to install on first boot.

## What it does

Fedora 42+ uses composefs, which makes `/` immutable at runtime. This breaks the usual
Nix installation flow, since the installer can no longer create `/nix` on the live system.
This image works around that by:

1. **Creating `/nix`** as an empty mount point baked into the image.
2. **Pre-embedding the Determinate Nix installer** at `/usr/libexec/nix-installer`, so first boot
   does not need to download the installer itself (Nix store packages are still fetched on first boot).
3. **Running the installer once on first boot** via a oneshot systemd service. The installer detects
   the ostree/bootc environment and bind-mounts `/var/lib/nix` (writable) onto `/nix`, then installs
   Nix and enables `nix-daemon.socket`.

The first-boot service is idempotent: it is skipped if Nix is already installed
(guarded by `ConditionPathExists=!/nix/var/nix/profiles/default`).

## Files

| File | Purpose |
| --- | --- |
| `Containerfile` | Builds the image on top of `bluefin-dx:stable`, embeds the installer, and enables the service. |
| `nix-installer-first-boot.service` | Oneshot systemd unit that installs Nix on first boot. |

## Building

```sh
podman build -t bluefin-nix .
```

## Usage

Rebase an existing bootc system onto the built image (after pushing it to a registry):

```sh
sudo bootc switch <registry>/bluefin-nix:latest
```

After the reboot, the first-boot service installs Nix automatically. Once it completes,
`nix` is available in new shells.

## Disclaimer

This is AI-generated slop. The "author" prompted an LLM and copy-pasted the result.
No guarantees are made about correctness, safety, or fitness for any purpose.
If this image bricks your system, deletes your files, or summons something unspeakable,
that is entirely your problem. Use at your own risk.

## Credits

- [Universal Blue](https://universal-blue.org/) for [Bluefin-DX](https://projectbluefin.io/), the base image
- [Determinate Systems](https://determinate.systems/) for the [Nix installer](https://github.com/DeterminateSystems/nix-installer) with bootc/ostree support
- [bootc](https://bootc-dev.github.io/bootc/) for the image-based Linux tooling
