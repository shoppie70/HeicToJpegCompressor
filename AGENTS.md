# AGENTS.md

## Project

ImageDrop is a minimal native macOS image conversion utility built with SwiftUI and Apple frameworks.

Before changing behavior, read:

- `README.md`
- `docs/SPECIFICATION.md`

The specification is authoritative for v1 unless the user explicitly revises it.

## Engineering constraints

- Prefer SwiftUI, ImageIO, Core Graphics, Vision, AppKit, and Foundation.
- Avoid third-party dependencies unless there is a concrete requirement that Apple frameworks cannot satisfy cleanly.
- Keep image-processing logic independent from SwiftUI views and directly testable.
- Do not introduce Clean Architecture layers, repositories, DI containers, coordinators, generic abstractions, or future-proof infrastructure without a present need.
- Source image files must never be modified or overwritten.
- Batch failures must be isolated per file.
- Automatic rotation is heuristic and must be conservative: when uncertain, do not rotate.

## Git workflow

- Do implementation work on a feature branch, not directly on `main`.
- Use small, coherent commits with conventional-style messages when practical.
- Do not rewrite published history unless explicitly requested.
- Before finishing a task, review the diff for accidental generated files, credentials, local paths, and unrelated changes.

## Public repository safety

This repository is public.

Never commit:

- API keys, access tokens, passwords, cookies, or credentials
- signing certificates or provisioning profiles
- personal names, addresses, email addresses, phone numbers, account identifiers, or other private user data
- private photos or sample images containing personal information
- absolute local filesystem paths containing usernames or other machine-specific identifiers
- `.env` files or machine-specific configuration
- Xcode user data, DerivedData, or build artifacts

If a test fixture is required, generate synthetic / non-personal fixture data or document how the developer can provide a local untracked fixture.

## Validation

For implementation work:

- Build the macOS target.
- Run available tests.
- Add focused tests around deterministic conversion logic where practical.
- Specifically verify filename collision behavior, resize calculations, settings defaults, source-file preservation, and orientation handling.

When Vision heuristics cannot be deterministically validated in unit tests, keep the heuristic isolated and document any manual validation required.
