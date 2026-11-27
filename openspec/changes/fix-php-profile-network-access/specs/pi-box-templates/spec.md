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
