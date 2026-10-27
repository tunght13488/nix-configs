# Design

## Context

See proposal.md - Why. Verified mechanics this design builds on (herdr v0.9.5 source and this machine):

- Every herdr pane gets `HERDR_ENV=1`, `HERDR_PANE_ID`, `HERDR_SOCKET_PATH` (the JSON API socket, `/home/tung/.config/herdr/herdr.sock`, mode 600), plus `HERDR_BIN_PATH`.
- Pi's herdr extension (installed at `~/.pi/agent/extensions/herdr-agent-state.ts`, v9, rides into the container via the shared `~/.pi/agent` mount) activates only when `HERDR_ENV === "1"` and both socket path and pane id are set. It reports `pane.report_agent` (working/blocked/idle) and `pane.report_agent_session` (session path/id) as JSON lines over a fresh unix-socket connection per send, resolving "delivered" on any response data. It reports only in TUI mode.
- The herdr API socket grants the full JSON API (pane read/input, pane spawn, agent prompt), which is why the sandbox must never receive it directly.
- Herdr's restart-resume for Pi is `pi --session <path|id>`, *typed into the restored pane shell* (host zsh), not a re-exec of the pane command. Host Pi supports `--session <path>`.
- `pi-box` already exports the host-side `HERDR_AGENT=pi` hint (keep) and ends with `exec docker` (must change to run-then-cleanup for the relay).
- The sandboxed Pi sees the session file at `/root/.pi/agent/sessions/...`; the host sees it at `$HOME/.pi/agent/sessions/...`.

## Goals / Non-Goals

**Goals:**

- Exact agent states in herdr for pi-box panes, via the same extension host Pi uses.
- The sandbox's authority stays unchanged: only the two report methods reach herdr.
- Herdr restart-resume of a pi-box pane stays inside the container.

**Non-Goals:**

- Any other herdr API from the sandbox (pane control, agent prompt, reading other panes).
- Non-zsh pane shells: resume routing relies on the zsh wrapper (this machine's shell is zsh/Prezto).
- Non-TUI runs (`pi-box -p ...`): the extension is TUI-gated upstream; the relay simply idles.

## Decisions

### Filtered host-side relay instead of mounting the API socket

The relay is a small host-side unix-socket server (`home-manager/pi-herdr-relay.py`, deployed to `~/.pi/sandbox/`) that accepts a connection, reads one JSON line, and forwards it to the real API socket only when the method is `pane.report_agent` or `pane.report_agent_session`; everything else is dropped. It forces `params.pane_id` to the host pane id, rewrites `agent_session_path` from `/root/.pi/agent/...` to the host state dir, reads one response line, echoes it back, and closes. Socket file created with umask 077.

Alternatives considered: mounting the real API socket (rejected — full herdr control from the sandbox, an indirect path to host secrets through other panes); `socat` byte-pipe (rejected — no method filtering); no bridge at all (rejected — leaves states broken, which is the bug).

### Relay lifecycle inside pi-box

`cmd_run` detects a herdr pane via `${HERDR_ENV:-}${HERDR_PANE_ID:-}${HERDR_SOCKET_PATH:-}` all set. When present: pick host socket path `~/.pi/sandbox/relay-<sanitized pane id>.sock`, unlink stale files, start the relay in the background, wait for the socket file to appear, add `--env HERDR_ENV=1 --env HERDR_PANE_ID=<pane> --env HERDR_SOCKET_PATH=/run/pi-box/herdr-relay.sock` and `--volume <host sock>:/run/pi-box/herdr-relay.sock`, then run docker as a child (no more `exec`) and kill the relay + remove the socket on exit via trap. Outside herdr panes nothing changes.

### Session-path handling on the way in and out

The relay rewrites outgoing reported paths (container view → host view) so herdr stores host-valid session refs. For incoming resume, pi-box maps `--session` arguments starting with the host state dir (`$HOME/.pi/agent/...`) to `/root/.pi/agent/...` in the args it passes to `pi` inside the container. Prefix-only replacement; ids and other arguments pass through untouched.

### Zsh wrapper routes herdr's typed resume command

Since herdr *types* `pi --session <path>` into the restored pane shell, the routing point is the shell. A `pi` zsh function in `home-manager/zsh.nix` checks: `HERDR_ENV=1` (herdr pane) and an argument `--session <value>` whose value is under `$HOME/.pi/agent/` — then `exec pi-box "$@"`; otherwise `exec command pi "$@"`. Outside herdr panes and for every other `pi` invocation the real binary runs, so host usage is unchanged. Alternative considered: changing herdr's resume plan (rejected — upstream code, not ours).

### Keep the existing agent hint and grant set

`HERDR_AGENT=pi` stays (pane identification, since container processes are not in the pane's process group). No new grant class, no new manifest key, no image or template changes: the extension already rides in via the shared `~/.pi/agent` mount.

## Risks / Trade-offs

- [Relay dies mid-run] → States silently degrade to today's screen-manifest behavior; the agent itself is unaffected. Mitigation: trivial relay supervised by pi-box, restarted per run, stale socket unlinked before bind.
- [A relay bug forwards a non-report method] → That is the whole authority boundary. Mitigation: exact allowlist plus forced pane id, exercised by a self-check test of the relay's filter logic.
- [Resume typed into a non-zsh pane shell] → Runs host `pi` (today's behavior). Mitigation: documented limitation; this machine's pane shell is zsh.
- [Path rewrite misfires] → Only exact-prefix replacement of `/root/.pi/agent` (out) and the host state dir (in); anything else is untouched.
- [Multiple pi-box runs in one herdr pane] → Not a real workflow; the per-pane relay path plus unlink-before-bind keeps a rerun working.

## Migration Plan

1. Ship the new/edited files; verify with `make home-build`.
2. User applies `make home`.
3. Verify in a herdr pane: run `pi-box`, watch the sidebar show working/blocked/idle correctly; from inside the sandbox, attempt a non-report API method against the relay socket and confirm it is dropped.
4. Restart-resume check: with a live sandboxed session reported, run `pi --session <host session path>` in a herdr pane and confirm it launches through `pi-box` and resumes inside the container.
5. Rollback: revert the commit and re-apply; no persistent state beyond harmless session refs recorded by herdr.
