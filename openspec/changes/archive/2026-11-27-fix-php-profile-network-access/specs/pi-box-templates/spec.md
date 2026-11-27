# Spec Delta

## ADDED Requirements

### Requirement: PHP templates preserve default outbound HTTPS access
The PHP82 and PHP83 templates SHALL preserve the shared pi-box base's default-allow outbound network behavior for Composer and model-provider HTTPS traffic while retaining their host database settings. With the default base, they SHALL NOT restrict outbound TCP to the MySQL port.

#### Scenario: Model HTTPS remains reachable
- **WHEN** a PHP82 or PHP83 project uses the default pi-box base without a proxy-only network policy and a model client connects to an HTTPS endpoint on TCP port 443
- **THEN** the PHP template does not deny the connection

#### Scenario: Host MySQL remains reachable
- **WHEN** a PHP82 or PHP83 project uses the default pi-box base and connects to host MySQL at `DB_HOST=127.0.0.1`
- **THEN** the database connection remains available without a template-level outbound TCP port restriction

## MODIFIED Requirements

### Requirement: php83 template

The `php83` template SHALL provide what a Laravel 12 project needs on this host — the composer cache and package-registry access it inherits from the shared pi-box base — relying on the host PHP 8.3 toolchain. Its profile SHALL set `DB_HOST=127.0.0.1` so database traffic reaches the host MySQL.

#### Scenario: Laravel 12 project installs on PHP 8.3
- **WHEN** `pi-box init php83` scaffolds a Laravel 12 project and `composer install` runs inside the sandbox
- **THEN** the install succeeds using the host PHP 8.3 with all required extensions loaded

#### Scenario: Host database reachable
- **WHEN** the project's feature tests run inside a sandbox scaffolded from `php83`
- **THEN** the tests connect to the host MySQL without credentials duplicated in the profile
