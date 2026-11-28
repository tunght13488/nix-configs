# Spec Delta

## ADDED Requirements

### Requirement: Orca headless server runs independently of interactive sessions
The configuration SHALL start Orca's headless server at system boot and keep it running without a graphical session or an interactive login.

#### Scenario: System boots without a user login
- **WHEN** the system finishes booting and `tung` has not logged in
- **THEN** the Orca server is running and available to paired clients

#### Scenario: User logs out
- **WHEN** `tung` logs out while the system remains running
- **THEN** the Orca server remains available

### Requirement: Orca server recovers from process failures
The service SHALL use Orca's supervisor behavior to recover from server-process failures without a rapid restart loop.

#### Scenario: Server process exits unexpectedly
- **WHEN** the Orca server process exits because of a transient failure
- **THEN** the supervisor retries starting it with increasing delays

### Requirement: Orca server access uses a trusted private network
Remote clients SHALL reach the Orca server over the existing Tailscale network, and this change SHALL NOT configure public Internet port forwarding for the server.

#### Scenario: Paired client connects over Tailscale
- **WHEN** a paired Orca client connects using the server's Tailscale address
- **THEN** it can reach the headless server

#### Scenario: No public port forwarding is added
- **WHEN** the service configuration is applied
- **THEN** no public Internet port-forwarding rule is added for the Orca server
