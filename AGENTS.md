# Repository Agent Instructions

Apply the required [workspace instructions](../../AGENTS.md). The rules below are this repository's delta and override shared rules on conflict.

## Repository Scope

This repository contains the Conversion Data 3.1 extension that enables arbitrary XDTO contracts for Kafka Adapter integrations. Preserve Russian 1C identifiers, the distinction between adopted Conversion Data objects and repository-owned objects, and established style within valid 1C standards.

`conversion/КД` is the base configuration used to develop and validate this extension. It is outside this Git repository; do not change it unless the user explicitly adds it to scope.

## Repository-Specific Rules

- Run relevant Conversion Data/XDTO integration checks when the environment is available.
