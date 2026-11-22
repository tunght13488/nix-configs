# Spec Delta

## MODIFIED Requirements

### Requirement: Template catalog under the sandbox directory

Templates SHALL live in `~/.pi/sandbox/templates/<name>/`, deployed declaratively by home-manager from the `home-manager/pi-box-templates/` directory in the configuration repository. Every template SHALL provide a `pi-box.toml` manifest; a template MAY provide a nono profile fragment the wrapper merges into the generated session profile.

#### Scenario: Shipped templates are deployed
- **WHEN** home-manager has been applied
- **THEN** `~/.pi/sandbox/templates/` contains `php83`, `php82`, `java8`, `node22`, `nix-configs`, `knowledge-assistant`, and `default`, each with a `pi-box.toml`

#### Scenario: Templates are versioned with the configuration
- **WHEN** a template file is changed in `home-manager/pi-box-templates/` and home-manager is applied
- **THEN** the deployed template reflects the change

### Requirement: php83 template

The `php83` template SHALL provide the grants a Laravel 12 project needs on this host: the workspace, the package registries needed by composer, and the localhost MySQL port, relying on the host PHP 8.3 toolchain. Its manifest SHALL set `DB_HOST=127.0.0.1` so database traffic reaches the host MySQL.

#### Scenario: Laravel 12 project installs on PHP 8.3
- **WHEN** `pi-box init php83` scaffolds a Laravel 12 project and `composer install` runs inside the sandbox
- **THEN** the install succeeds using the host PHP 8.3 with all required extensions loaded

#### Scenario: Host database reachable
- **WHEN** the project's feature tests run inside a sandbox scaffolded from `php83`
- **THEN** the tests connect to the host MySQL without credentials duplicated in the manifest

### Requirement: php82 template

The `php82` template SHALL provide the same grants as `php83` for projects whose composer requires PHP ^8.2, relying on the host PHP 8.2 toolchain, and SHALL ship the same `DB_HOST` manifest.

#### Scenario: PHP 8.2 project installs
- **WHEN** `pi-box init php82` scaffolds a project whose composer requires PHP ^8.2 and `composer install` runs inside the sandbox
- **THEN** the install succeeds on the host PHP 8.2

#### Scenario: Extension parity with php83
- **WHEN** the loaded extensions of the host PHP 8.2 are inspected
- **THEN** the bcmath, cli, curl, dom, gd, mbstring, mysql, soap, xml, and zip extensions are present

### Requirement: java8 template

The `java8` template SHALL provide the grants a Java 8 project needs on this host, relying on the project's devShell for the Java 8 JDK and Maven 3.6.3. Its manifest SHALL grant the host Maven local repository so downloaded dependencies persist across sandbox runs.

#### Scenario: Toolchain reports the pinned versions
- **WHEN** `mvn -version` runs inside a sandbox scaffolded from `java8`
- **THEN** it reports Maven 3.6.3 running on a Java 8 JDK from the project toolchain

#### Scenario: Maven cache survives runs
- **WHEN** a second sandbox run executes `mvn test` after a first run downloaded the dependencies
- **THEN** dependencies already in the host Maven local repository are reused and are not re-downloaded

### Requirement: node22 template

The `node22` template SHALL provide the grants a Node project needs on this host, relying on the project's devShell for Node 22 (at least 22.19, so the pinned Pi agent still runs) and yarn classic 1.22.x.

#### Scenario: Node 22 and yarn available
- **WHEN** `node --version` and `yarn --version` run inside a sandbox scaffolded from `node22`
- **THEN** node reports a 22.x version and yarn reports 1.22.x

#### Scenario: Pi still starts on Node 22
- **WHEN** `pi-box` starts a sandbox scaffolded from `node22`
- **THEN** the Pi agent launches successfully on the Node 22 runtime

### Requirement: default template

The `default` template SHALL reproduce the current generic scaffold: a `pi-box.toml` with empty grants and no profile fragment.

#### Scenario: Bare init uses the default template
- **WHEN** `pi-box init` runs without a template name in a project without scaffold files
- **THEN** the written manifest matches the generic scaffold of today

### Requirement: nix-configs template provides the repository toolchain
The `nix-configs` template SHALL provide the grants needed to run this repository's non-human Makefile targets inside pi-box, relying on the host Nix toolchain, while retaining the existing OpenSpec CLI.

#### Scenario: Project commands are available
- **WHEN** a project is scaffolded with `pi-box init nix-configs` and launched
- **THEN** `make`, a Nix CLI with `nix-command` and `flakes`, `nh`, `nixos-rebuild`, `nixpkgs-fmt`, and `openspec` are available in the sandbox

#### Scenario: Allowed targets use the sandbox workspace
- **WHEN** `make format`, `make home-build`, `make os-build`, or `make update` runs from the project root
- **THEN** the target runs inside pi-box and workspace changes are visible on the host

### Requirement: nix-configs template keeps Nix build sandboxing enabled
The `nix-configs` template SHALL keep Nix's build sandbox enabled with sandbox fallback disabled, and its profile SHALL permit the namespace creation Nix requires for build sandboxing, so builds run hermetic instead of silently degrading.

#### Scenario: Sandboxed build succeeds
- **WHEN** a derivation is built inside the sandbox from this template
- **THEN** the build completes with Nix sandboxing enabled

#### Scenario: Missing privileges fail instead of degrading
- **WHEN** the sandbox cannot provide the required namespace support
- **THEN** Nix reports that sandboxing is unsupported rather than building unsandboxed

### Requirement: knowledge-assistant template provides Mermaid linting
The `knowledge-assistant` template SHALL make the pinned `mmdlint` CLI available for validating Mermaid blocks in Markdown files in the project workspace, without requiring a separate project-level install.

#### Scenario: Validate Mermaid Markdown in a scaffolded workspace
- **WHEN** a project is scaffolded with `pi-box init knowledge-assistant` and `mmdlint docs/PROJECT.md` runs inside its sandbox
- **THEN** the CLI is available and validates the Mermaid blocks in that workspace file

## REMOVED Requirements

### Requirement: nix-configs template persists a private Nix store
**Reason**: The sandboxed session is host-native and uses the host Nix store and daemon; the named Docker volume for the private store is no longer needed.
**Migration**: Drop the `pi-nix-configs-nix` Docker volume once the template is replaced.
