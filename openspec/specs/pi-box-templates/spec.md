# pi-box-templates Specification

## Purpose

Defines the pi-box template catalog: the toolchain templates shipped with pi-box, where they live, and what each one provides.

## Requirements

### Requirement: Template catalog under the sandbox directory

Templates SHALL live in `~/.pi/sandbox/templates/<name>/`, deployed declaratively by home-manager from the `home-manager/pi-box-templates/` directory in the configuration repository. Every template SHALL provide a `Dockerfile.pi` and MAY provide a `pi-box.toml`.

#### Scenario: Shipped templates are deployed
- **WHEN** home-manager has been applied
- **THEN** `~/.pi/sandbox/templates/` contains `php83`, `php82`, `java8`, `node22`, and `default`, each with a `Dockerfile.pi`

#### Scenario: Templates are versioned with the configuration
- **WHEN** a template file is changed in `home-manager/pi-box-templates/` and home-manager is applied
- **THEN** the deployed template reflects the change

### Requirement: php83 template

The `php83` template SHALL build a project image on top of the shared base that provides PHP 8.3 from the sury.org repository together with composer and the extensions bcmath, cli, curl, dom, gd, mbstring, mysql, soap, xml, and zip. Its manifest SHALL set `DB_HOST=host.docker.internal` so database traffic reaches the host MySQL.

#### Scenario: Laravel 12 project installs on PHP 8.3
- **WHEN** `pi-box init php83` scaffolds a Laravel 12 project and `composer install` runs inside the sandbox
- **THEN** the install succeeds on PHP 8.3 with all required extensions loaded

#### Scenario: Host database reachable
- **WHEN** the project's feature tests run inside a sandbox scaffolded from `php83`
- **THEN** the tests connect to the host MySQL without credentials duplicated in the manifest

### Requirement: php82 template

The `php82` template SHALL build a project image on top of the shared base that provides PHP 8.2 from the sury.org repository with the same extension set as `php83`, and SHALL ship the same `DB_HOST` manifest.

#### Scenario: PHP 8.2 project installs
- **WHEN** `pi-box init php82` scaffolds a project whose composer requires PHP ^8.2 and `composer install` runs inside the sandbox
- **THEN** the install succeeds on PHP 8.2

#### Scenario: Extension parity with php83
- **WHEN** the loaded extensions of a `php82` image are inspected
- **THEN** the bcmath, cli, curl, dom, gd, mbstring, mysql, soap, xml, and zip extensions are present

### Requirement: java8 template

The `java8` template SHALL build a project image on top of the shared base that provides a Java 8 JDK and Maven 3.6.3 on PATH, with `JAVA_HOME` pointing at the JDK. Its manifest SHALL declare a named Docker volume for the Maven local repository so downloaded dependencies persist across sandbox runs.

#### Scenario: Toolchain reports the pinned versions
- **WHEN** `mvn -version` runs inside a sandbox scaffolded from `java8`
- **THEN** it reports Maven 3.6.3 running on a Java 8 JDK

#### Scenario: Maven cache survives runs
- **WHEN** a second sandbox run executes `mvn test` after a first run downloaded the dependencies
- **THEN** dependencies already in the named volume are reused and are not re-downloaded

### Requirement: node22 template

The `node22` template SHALL build a project image on top of the shared base that provides Node 22 (at least 22.19, so the pinned Pi agent still runs) and yarn classic 1.22.x on PATH.

#### Scenario: Node 22 and yarn available
- **WHEN** `node --version` and `yarn --version` run inside a sandbox scaffolded from `node22`
- **THEN** node reports a 22.x version and yarn reports 1.22.x

#### Scenario: Pi still starts on Node 22
- **WHEN** `pi-box` starts a sandbox scaffolded from `node22`
- **THEN** the Pi agent launches successfully on the Node 22 runtime

### Requirement: default template

The `default` template SHALL reproduce the current generic scaffold: a `Dockerfile.pi` whose toolchain instructions are commented examples, and the generic `pi-box.toml` with empty grants.

#### Scenario: Bare init uses the default template
- **WHEN** `pi-box init` runs without a template name in a project without scaffold files
- **THEN** the written files match the generic scaffold of today

### Requirement: nix-configs template provides the repository toolchain
The `nix-configs` template SHALL provide the tools needed to run this repository's non-human Makefile targets inside pi-box, while retaining the existing OpenSpec CLI.

#### Scenario: Project commands are available
- **WHEN** a project is scaffolded with `pi-box init nix-configs` and launched
- **THEN** `make`, `find`, `xargs`, `nproc`, a Nix CLI with `nix-command` and `flakes`, `nh`, `nixos-rebuild`, `nixpkgs-fmt`, and `openspec` are available in the sandbox

#### Scenario: Allowed targets use the sandbox workspace
- **WHEN** `make format`, `make home-build`, `make os-build`, or `make update` runs from the project root
- **THEN** the target runs inside pi-box and workspace changes are visible on the host

### Requirement: nix-configs template persists a private Nix store
The `nix-configs` template SHALL persist its Nix store across pi-box runs in a named Docker volume and SHALL NOT mount or use the host Nix store or daemon.

#### Scenario: Store survives container removal
- **WHEN** a later pi-box run uses the same project volume
- **THEN** Nix store paths from an earlier run remain available

#### Scenario: Host Nix is not exposed
- **WHEN** the sandbox runs from the `nix-configs` template
- **THEN** the host Nix store and daemon socket are not mounted in the container

### Requirement: nix-configs template keeps Nix build sandboxing enabled
The `nix-configs` template SHALL keep Nix's build sandbox enabled with sandbox fallback disabled, and SHALL declare the sandbox privileges that Nix requires to create its build namespaces, so builds run hermetic instead of silently degrading.

#### Scenario: Sandboxed build succeeds
- **WHEN** a derivation is built inside the sandbox from this template
- **THEN** the build completes with Nix sandboxing enabled

#### Scenario: Missing privileges fail instead of degrading
- **WHEN** the sandbox runs without the required privileges
- **THEN** Nix reports that sandboxing is unsupported rather than building unsandboxed

### Requirement: nix-configs pi-box instructions distinguish human-only targets
The project instructions SHALL mark `make os`, `make os-boot`, `make home`, `make clean`, and `make os-test` as human-only, and permit Pi to invoke the other Makefile targets. This policy SHALL be instruction-only, without Makefile target gating.

#### Scenario: Pi follows the target policy
- **WHEN** Pi reads the project instructions before using the Makefile
- **THEN** the five human-only targets are identified and the remaining targets are available for Pi to invoke
