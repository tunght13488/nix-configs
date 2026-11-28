# Tasks

## 1. Declare the Orca headless user service

- [ ] 1.1 Verify the pinned `orca-ide` CLI supports `serve --supervise`, `--no-pairing`, and `--port`; if not, update the existing package pin and hash, then verify `nix build .#orca-app` succeeds.
- [ ] 1.2 Add the Home Manager `orca-server` user unit using the verified CLI, enable it from the user manager's default target, and provide the Home Manager/system `PATH`; verify `make home-build` succeeds and the generated unit invokes `orca-ide serve --supervise --no-pairing --port 6768`.

## 2. Persist the service and restrict its network access

- [ ] 2.1 Enable declarative lingering for user `tung`; verify `nix eval --no-write-lock-file .#nixosConfigurations.nixos-vmware.config.users.users.tung.linger` evaluates to `true`.
- [ ] 2.2 Remove TCP port 6768 from the global allowed range and allow it only on `tailscale0`; verify the evaluated firewall keeps the other ports unchanged and `make os-build` succeeds.

## 3. Verify the deployed headless server

- [ ] 3.1 After a human applies the Home Manager and NixOS generations, pair one client over Tailscale using Orca's documented foreground pairing flow; verify the client reaches the service on port 6768.
- [ ] 3.2 Reboot without logging in, then log out and trigger one transient server-process failure; verify the user service remains active, the supervisor retries, and the port is reachable from Tailscale but not from other interfaces.
