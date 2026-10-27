# Tasks

## 1. Relay script

- [ ] 1.1 Create `home-manager/pi-herdr-relay.py`: unix-socket server that forwards only `pane.report_agent` and `pane.report_agent_session` to the herdr API socket, forces `pane_id` to the host pane's, rewrites `agent_session_path` from `/root/.pi/agent/...` to the host state dir, echoes one response line, and creates its socket with umask 077. Verify with a self-check: a test invoking the filter/rewrite functions shows an allowed method forwarded, a non-report method dropped, and the path rewrite applied
- [ ] 1.2 Verify the relay end-to-end in isolation: start it against a dummy listener socket, send one allowed and one blocked JSON line, and confirm the dummy receives exactly the allowed line with the rewritten path and forced pane id

## 2. pi-box wrapper wiring

- [ ] 2.1 In `home-manager/pi-box.sh` `cmd_run`, when `HERDR_ENV`, `HERDR_PANE_ID`, and `HERDR_SOCKET_PATH` are all set: unlink any stale relay socket, start the relay, wait for the socket file, add the forwarded env vars and the relay socket mount, run docker as a child instead of `exec`, and kill the relay plus remove the socket on exit. Verify with `make home-build` and a scratch run outside herdr confirming the unchanged path still works
- [ ] 2.2 Map `--session` arguments starting with the host Pi state directory to `/root/.pi/agent/...` in the args passed to `pi` inside the container; other arguments pass through untouched. Verify with a bash-level check of the mapping function on both path and non-path arguments

## 3. Home-manager module

- [ ] 3.1 In `home-manager/pi-sandbox.nix`, deploy `pi-herdr-relay.py` to `~/.pi/sandbox/` via `home.file` and add `python3` to the wrapper's `runtimeInputs`. Verify `make home-build` succeeds

## 4. Zsh resume wrapper

- [ ] 4.1 In `home-manager/zsh.nix`, add a `pi` function that routes to `pi-box "$@"` only when `HERDR_ENV=1` and an argument is `--session <path under $HOME/.pi/agent/>`; all other invocations exec the real `pi`. Verify by sourcing the generated zshrc in `zsh -c` with and without `HERDR_ENV`, asserting which binary each invocation resolves to
- [ ] 4.2 Verify host `pi` behavior is unchanged: with `HERDR_ENV` unset, `pi --session <path>`, `pi -p "hi"`, and plain `pi` all resolve to the real binary

## 5. Documentation

- [ ] 5.1 Update `AGENTS.md`: herdr state reporting for sandboxed Pi (working/blocked/idle through the relay), restart-resume staying inside the sandbox, and the never-mounted API socket. Verify the documented commands read as written

## 6. Integration verification

- [ ] 6.1 In a herdr pane, run `pi-box`, work a session to blocked state, and confirm the agent sidebar shows working, blocked, and idle at the matching moments
- [ ] 6.2 From inside the sandbox, connect to the published relay socket and send a non-report method (e.g. `pane.read`); confirm it is dropped and herdr receives nothing
- [ ] 6.3 With a live reported session, run `pi --session <host session path>` in a herdr pane and confirm it launches through `pi-box`, maps the path, and resumes the session inside the container

## Workflow follow-up

- Ask the user to run `make home` to activate, then re-run the verifications that depend on activation (deployed relay script, zsh wrapper).
- Archive the change after review: `openspec archive pi-box-herdr-state-relay`.
