---
type: ADR
title: Source-kit validation Makefile
description: Use a Makefile to consolidate validation checks for the source kit.
tags: [makefile, validation]
timestamp: 2026-07-05T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted

# Context

The kit has multiple moving pieces: docs, scripts, settings JSON, install instructions, hooks, and temp-repo behavior.

Manual validation is easy to forget after structural changes.

# Decision

Add a source-repo `Makefile` with `make test` as the main validation command.

The Makefile runs syntax checks, optional ShellCheck linting, JSON validation, stale-reference and local-path scans, Markdown link checks, source-kit OKF stale mapping checks, install simulations, idempotency checks, hook checks, and helper command smoke tests.

# Consequences

Maintainers have one command before publishing changes.

The Makefile is not part of the target repo installation contract. Target repos own stricter OKF document-schema checks when their docs need them.

Test coverage remains lightweight and local. It does not require network access or external dependencies beyond common shell tooling, Git, Python, and ripgrep. ShellCheck adds lint coverage when installed.
