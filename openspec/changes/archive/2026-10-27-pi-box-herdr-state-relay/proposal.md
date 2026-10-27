# Proposal

## Why

Pi panes started with `pi-box` are recognized by herdr as the Pi agent (the wrapper exports the host-side `HERDR_AGENT` hint), but herdr cannot see the agent's real state: the Pi extension's reporting channel is severed by the container boundary, because the container never receives herdr's `HERDR_ENV`/`HERDR_PANE_ID` environment or the herdr API socket. The pane falls back to the Pi screen manifest, which only knows "working" — blocked, idle, and done states are missing or wrong. A second gap: herdr's restart-resume types `pi --session <path>` into the restored pane shell, which would run the agent on the host, outside the sandbox the pane was launched in.

## What Changes

- Add a per-run host-side relay that exposes a restricted unix socket to the sandbox: it forwards only `pane.report_agent` and `pane.report_agent_session` to herdr's API socket, forces the pane id to the host pane's, and rewrites reported session paths from the container view (`/root/.pi/agent/...`) to the host view so herdr stores host-valid session references.
- `pi-box` detects the herdr pane environment and, when present, forwards `HERDR_ENV=1`, `HERDR_PANE_ID`, and a relay-socket `HERDR_SOCKET_PATH` into the container; otherwise behavior is unchanged.
- `pi-box` maps `--session` arguments that point into the host Pi state directory to the container path when passing them into the container, so a resumed session is addressed correctly inside the sandbox.
- Add a herdr-pane-scoped zsh wrapper that routes herdr's restart-resume command (`pi --session <path under ~/.pi/agent>`) through `pi-box`, keeping the resumed agent inside the sandbox. Outside herdr panes, and for all other `pi` invocations, the wrapper delegates to the real `pi`.
- Deploy the relay script via the existing `home-manager/pi-sandbox.nix` module and add `python3` to the wrapper's runtime inputs (host side only).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pi-box-sandbox`: adds two requirements — a filtered relay that lets sandboxed Pi report working/blocked/idle state to herdr without exposing the herdr API surface, and herdr restart-resume of a sandboxed Pi session that stays inside the container.

## Impact

- **Code**: `home-manager/pi-box.sh` (relay lifecycle, env forwarding, socket mount, `--session` path mapping), `home-manager/pi-sandbox.nix` (deploy relay script, runtime inputs), new `home-manager/pi-herdr-relay.py`, `home-manager/zsh.nix` (the herdr-pane-scoped `pi` wrapper).
- **Specs**: delta to `openspec/specs/pi-box-sandbox/spec.md`.
- **Docs**: `AGENTS.md` — document herdr state reporting and restart-resume for sandboxed Pi.
- **Dependencies**: none new (relay uses the host's `python3`, already available via the existing Python toolchain).
- **Behavior**: unchanged when `pi-box` runs outside a herdr pane; inside a herdr pane the agent's states appear correctly in the agent sidebar, and a herdr restart resumes the session inside the container.
