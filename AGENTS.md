# Repository Agent Instructions

## Workspace Instructions

Read the required [workspace instructions](../../AGENTS.md) before working in this repository. The fixed `KAFKA_PROJECTS_ROOT` layout is required. If the shared file is missing, report a workspace-layout error and stop. The repository-specific rules below supplement and override the shared rules when they conflict.

## Repository Scope

This repository contains the Conversion Data 3.1 extension that enables arbitrary XDTO contracts for Kafka Adapter integrations. Start with [README.md](README.md). Preserve original Russian 1C identifiers and the distinction between adopted Conversion Data objects and repository-owned objects.

`conversion/КД` is the base configuration used to develop and validate this extension. It is not part of this Git repository. Do not change it unless the user explicitly adds it to task scope.

## Repository-Specific Rules

- Use only `conv_edt` for current-state queries, navigation, and every 1C change under `src/**`.
- Do not route this project through `kfk_edt`, `kfk-unit-edt`, `code-metadata-mcp`, or `graph-metadata-mcp`.
- Preserve existing naming conventions and source style within valid `v8std` alternatives.
- Run relevant Conversion Data/XDTO integration checks when the environment is available.
