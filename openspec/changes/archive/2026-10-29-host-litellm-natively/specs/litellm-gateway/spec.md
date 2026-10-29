# Spec Delta

## Purpose

Provides a locally hosted LiteLLM API and Admin UI for the VM, with provider and model configuration persisted in PostgreSQL and exposed through the existing HTTPS reverse proxy.

## ADDED Requirements

### Requirement: LiteLLM is available through the local HTTPS gateway
The system SHALL expose LiteLLM's OpenAI-compatible API and Admin UI at `https://litellm.vm.local` while keeping the LiteLLM listener bound to loopback.

#### Scenario: API and Admin UI use the HTTPS vhost
- **WHEN** a client calls an OpenAI-compatible endpoint or opens the Admin UI through `https://litellm.vm.local`
- **THEN** nginx serves the request over HTTPS and forwards it to the loopback-only LiteLLM service

### Requirement: Streaming responses pass through nginx
The reverse proxy SHALL forward streamed LiteLLM responses without buffering them until completion or terminating long-running requests prematurely.

#### Scenario: Client receives a streamed completion
- **WHEN** a client requests a streamed completion through the HTTPS vhost
- **THEN** response events reach the client as LiteLLM emits them and the connection remains open until the response completes

### Requirement: LiteLLM state persists in local PostgreSQL
The system SHALL store LiteLLM's database-backed state in a dedicated PostgreSQL database reachable only over loopback, with trust authentication restricted to loopback connections.

#### Scenario: Database-backed state survives a service restart
- **WHEN** LiteLLM writes a model or credential record and the service restarts
- **THEN** the record remains available from PostgreSQL after startup

### Requirement: Administrators can manage models through the UI
An authenticated administrator SHALL be able to add, edit, and remove database-backed model deployments and provider credentials through the Admin UI without rebuilding NixOS or restarting LiteLLM.

#### Scenario: First model is added after deployment
- **WHEN** LiteLLM is deployed without a static model list and an administrator adds a model through the UI
- **THEN** the model is persisted in PostgreSQL and becomes available to API clients without a NixOS rebuild or service restart

### Requirement: LiteLLM secrets stay out of the Nix store
The system SHALL provide the admin master key and a stable credential-encryption salt as runtime secrets, and SHALL keep provider credentials stored by LiteLLM encrypted at rest.

#### Scenario: Stored provider credentials remain usable after restart
- **WHEN** LiteLLM restarts with the same runtime secrets
- **THEN** it can decrypt and use provider credentials saved through the Admin UI, and the secret values are absent from the Nix store

### Requirement: Database schema setup gates LiteLLM readiness
LiteLLM SHALL initialize or update its PostgreSQL schema before it is considered ready, and SHALL fail startup rather than report healthy when schema setup fails.

#### Scenario: Database schema setup fails
- **WHEN** LiteLLM cannot connect to PostgreSQL or complete schema setup
- **THEN** the service does not become ready and reports the startup failure
