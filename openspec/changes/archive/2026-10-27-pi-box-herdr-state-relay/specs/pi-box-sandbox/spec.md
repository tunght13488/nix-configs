# Spec Delta

## ADDED Requirements

### Requirement: Herdr agent state reporting through a filtered relay

When `pi-box` runs inside a herdr pane, the sandbox SHALL report Pi's working, blocked, and idle states to herdr through a filtered host-side relay. The sandbox SHALL NOT receive the herdr API socket, and the relay SHALL forward only the two agent state report methods, with the pane id forced to the host pane's.

#### Scenario: Sandboxed pane reports real agent states

- **WHEN** `pi-box` is started in a herdr pane and the sandboxed Pi session begins, works, and blocks on user input
- **THEN** the herdr agent sidebar shows working, blocked, and idle at the matching moments, as it does for a host Pi pane

#### Scenario: Relay forwards only report methods

- **WHEN** a process inside the sandbox connects to the socket path published to it and sends a method other than `pane.report_agent` or `pane.report_agent_session`
- **THEN** the method is not forwarded to herdr and reaches no herdr API

#### Scenario: Herdr API socket is not mounted

- **WHEN** the container's mounts are inspected on a run inside a herdr pane
- **THEN** the herdr API socket path is not present; only the relay socket is available

#### Scenario: Reported session paths are host-valid

- **WHEN** the sandboxed Pi reports its session and the reported path is under `/root/.pi/agent`
- **THEN** herdr records the session path under the host Pi state directory instead

#### Scenario: Outside a herdr pane nothing changes

- **WHEN** `pi-box` runs without the herdr pane environment variables
- **THEN** no relay is started, no herdr environment variables are forwarded, and the sandbox behaves as before this change

### Requirement: Herdr restart resume stays inside the sandbox

When herdr restarts and types the Pi resume command into a restored pane shell that was running `pi-box`, the session SHALL resume inside the sandbox container, not in a host process.

#### Scenario: Restart resume routes through pi-box

- **WHEN** herdr restores a `pi-box` pane and types `pi --session <path under the host Pi state directory>` into the restored herdr-pane shell
- **THEN** the command runs `pi-box` with the same argument, starting a sandboxed session

#### Scenario: Session path is mapped into the container

- **WHEN** the resumed `pi` invocation inside the container receives the host session path argument
- **THEN** the argument points at the corresponding path under `/root/.pi/agent`, where the shared session file is mounted

#### Scenario: Host pi usage is unchanged outside herdr panes

- **WHEN** a user runs `pi` with any arguments in a shell that is not a herdr pane
- **THEN** the real host `pi` binary runs, exactly as before this change
