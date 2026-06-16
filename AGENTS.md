# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A [bootc](https://bootc-dev.github.io/bootc/) OCI container image that layers on top of
[Universal Blue's Bluefin-DX](https://projectbluefin.io/) to pre-install
[Determinate Nix](https://determinate.systems/) on first boot.

The core problem it solves: Fedora 42+ uses composefs, making `/` immutable at runtime.
The Nix installer cannot create `/nix` on a live system, so `/nix` must be baked into the image
as an empty mount point, and the actual installation deferred to a first-boot systemd service.

## Files

| File | Purpose |
| --- | --- |
| `Containerfile` | Builds the image; creates `/nix`, embeds the installer binary, enables the service |
| `nix-installer-first-boot.service` | Oneshot systemd unit; installs Nix on first boot, idempotent via `ConditionPathExists` |

## Branching and commits

- `main` is protected -- all changes must go through feature branches and PRs.
- Commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) standard (e.g. `feat:`, `fix:`, `chore:`).

## Build and usage

```sh
# Build the image locally
podman build -t bluefin-nix .

# Lint the container (also runs automatically at the end of the Containerfile build)
bootc container lint

# Rebase a running bootc system onto this image (after pushing to a registry)
sudo bootc switch <registry>/bluefin-nix:latest
```

## CI/CD

The GitHub Actions workflow (`.github/workflows/build.yml`) builds and pushes to `ghcr.io/blj-magenta/bluefin-nix` using `GITHUB_TOKEN` -- no extra secrets needed. Triggers on pushes to `main` and the daily schedule (`0 4 * * *`), pushing `latest` + `sha-<short-sha>` tags.

## Key design constraints

- **`/nix` must exist in the image** -- it cannot be created at runtime because composefs makes `/` read-only. Any change that removes the `mkdir /nix` step will break the first-boot installer.
- **The installer binary is embedded** -- `Containerfile` downloads `/usr/libexec/nix-installer` at build time so the image has no runtime dependency on `install.determinate.systems` beyond the Nix store packages themselves.
- **The first-boot service is idempotent** -- guarded by `ConditionPathExists=!/nix/var/nix/profiles/default`; do not remove this guard.
- **`bootc container lint` must pass** -- enforced as the last `RUN` step in `Containerfile`. Keep it there.

## Architecture notes

The installer runs as a privileged oneshot service (`After=network-online.target`). In an ostree/bootc environment, Determinate Nix auto-detects the host type and:
1. Creates `/var/lib/nix` (writable persistent storage across image updates)
2. Generates and activates a `nix.mount` unit that bind-mounts `/var/lib/nix` onto `/nix`
3. Installs Nix into the now-writable `/nix`
4. Enables `nix-daemon.socket`
