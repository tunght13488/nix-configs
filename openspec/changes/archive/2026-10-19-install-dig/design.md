# Design

## Context

See proposal.md - Why. The home-manager configuration already has established per-tool modules (`home-manager/terminal.nix` holds small terminal utilities like `unzip` and `pv`), and the `myip` alias in `home-manager/zsh.nix` already references `dig`. Nothing in `nixos/` needs this tool, so the change is user-level only.

## Goals / Non-Goals

**Goals:**
- Make `dig` available to the `tung` user via home-manager.
- Keep the change confined to home-manager; no NixOS system packages.

**Non-Goals:**
- No DNS server or system resolver changes.
- No changes to zsh aliases or their spec.

## Decisions

**1. Package: `pkgs.dnsutils` from stable nixpkgs (26.05)**
Provides `dig`, `host`, and `nslookup` without the BIND server binaries.
- Alternatives considered:
  - Full `pkgs.bind` — installs `named` and other server components; more than needed.
  - `pkgs.unstable.dnsutils` — no reason to pull from unstable; the stable version is fine.

**2. Location: `home-manager/terminal.nix` `home.packages`**
Small interactive terminal utility, matching the existing `unzip`/`pv` entries there rather than the main application list in `home.nix`.
- Alternatives considered:
  - `home-manager/home.nix` main package list — works, but mixes a small utility into the major-application list.
  - New dedicated module — unnecessary ceremony for a single package.

**3. No alias or shell config changes**
The `myip` alias already exists; installing `dig` is all that's needed.

## Risks / Trade-offs

- [Home-manager rebuild conflict or package build failure] → Verify with `make home-build` before asking the user to switch.
- [Network-dependent validation] → `dig` scenarios need internet access; validation steps use a well-known domain (`example.com`), which requires connectivity.
