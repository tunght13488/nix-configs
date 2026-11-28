# Design

## Context

See `proposal.md` for motivation and `specs/orca-app/spec.md` for behavior.

- `pkgs/orca.nix` packages Orca v1.4.279 and exposes its Linux CLI as `orca-ide`; `home-manager/ai.nix` already installs the package.
- Home Manager already manages user systemd units and starts changed units during activation. NixOS defines user `tung`; lingering is currently unmanaged. Tailscale is enabled in `nixos/tailscale.nix`.
- `nixos/configuration.nix` globally allows TCP ports 1024–49151, which includes Orca's documented service port 6768.
- Orca's [headless server docs](https://orca.dev/docs/remote-servers#orca-serve-as-a-service) document a Linux systemd user service running `orca serve --supervise --no-pairing`. The supervisor retries with increasing delays. Linux user services stop at logout unless lingering is enabled. The [headless setup docs](https://orca.dev/docs/ways-to-run#at-a-glance) use a Tailscale-reachable pairing address and warn against forwarding the Orca port directly to the public Internet.

## Goals / Non-Goals

**Goals:**

- Keep the Orca runtime headless and user-owned, with no GUI or login requirement.
- Start it through the user's systemd manager at boot, survive logout, and recover from runtime failures using Orca's supervisor.
- Make the fixed service port reachable through Tailscale without opening it on other network interfaces.

**Non-Goals:**

- Automate client pairing or store pairing links/secrets in Nix. Pairing remains a one-time operation outside the service.
- Start the Orca desktop GUI or run its server-sharing mode concurrently with `orca serve`.
- Replace the existing Orca package or add a separate server package unless the pinned CLI lacks the documented server commands.

## Decisions

1. **Declare a Home Manager user service instead of running Orca's service installer imperatively.** Use the installed `orca-ide` executable with `serve --supervise --no-pairing --port 6768`, wanted by the user manager's default target. This matches Orca's documented service process while keeping the unit in the Nix configuration. `--supervise` handles Orca runtime failures; the systemd unit manages boot and the supervisor process. Include the Home Manager profile and system paths in the unit environment because headless Orca launches agent CLIs from the server's `PATH`. The alternative, `orca-ide serve service install --port 6768`, writes a unit outside Home Manager and could drift from the declared configuration.

2. **Enable lingering declaratively for `tung`.** Set the NixOS user's linger option so the user manager starts at boot and is not stopped on logout. This is the declarative equivalent of `loginctl enable-linger tung`; relying on that imperative command alone would not make the behavior reproducible.

3. **Use port 6768 only through Tailscale.** Keep the documented fixed port, remove 6768 from the existing global TCP range by splitting that range around the port, and allow 6768 on `tailscale0`. This preserves the other globally allowed ports while avoiding exposure of the Orca listener on non-Tailscale interfaces. Do not add public port forwarding.

4. **Keep pairing separate from the service.** The persistent unit uses `--no-pairing`, so it does not print a client pairing link into service logs. Pair once using Orca's documented foreground `serve --pairing-address <Tailscale-hostname-or-IP>` flow while the service is stopped, then start the unit. The pairing address advertises where a client should connect; it is not a bind-interface setting. Do not place pairing credentials in the Nix store.

5. **Use the Linux CLI name `orca-ide`.** The package exposes this alias because nixpkgs' `orca` is the GNOME screen reader. Do not shadow that package.

## Risks / Trade-offs

- [The pinned v1.4.279 CLI may not support all documented `serve` flags] → Verify the packaged CLI before relying on them; update the existing version and hash only if required.
- [A lingering user manager runs user services without a login] → Limit this behavior to `tung` and keep the Orca unit narrowly scoped.
- [Agent CLIs may be absent from a minimal systemd environment] → Put the Home Manager profile and system binaries on the unit's `PATH`, then verify the service can launch the installed CLI tools.
- [The server port is reachable only while Tailscale is up and the client is paired] → Use the server's existing tailnet address and verify the connection from a tailnet client.
- [The desktop app and headless server may conflict if both advertise the same host] → Do not enable desktop server sharing while the headless service is active.
- [Orca's supervisor stops retrying after repeated failures] → Treat recovery as bounded retry behavior, not a guarantee against persistent failures; inspect the service status and logs when it gives up.

## Migration Plan

1. Declare the Home Manager user service, enable `tung` lingering, and restrict the port to `tailscale0` while preserving the rest of the current firewall range.
2. Verify with `make home-build` and `make os-build`. A human applies the generations, then pairs a client once over Tailscale and checks that the user service remains active through logout and reboot.
3. Roll back by removing the Home Manager service and port-specific firewall rule, restoring the original global TCP range, and disabling `tung` lingering. Keep the Orca package installed.
