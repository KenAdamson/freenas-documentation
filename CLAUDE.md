# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a GitHub Wiki-backed documentation repository for a TrueNAS server (192.168.7.195). All documentation lives as flat Markdown files in the repo root. A GitHub Actions workflow (`.github/workflows/sync-wiki.yml`) automatically syncs `.md` files (excluding `README.md`) to the GitHub Wiki on pushes to `main`.

## Repository Structure

- **Home.md** - Wiki homepage: server specs, network config, pool summary
- **ZPools.md** - ZFS pool configuration, datasets, health status
- **Physical-Drive-Layout.md** - Drive-to-slot mapping, cage layout, ASCII wiring diagrams
- **SAS-Expander-Configuration.md** - HBA, SAS expander, cable specs and pinouts
- **Maintenance-Procedures.md** - SMART tests, scrubs, snapshots, update procedures
- **Troubleshooting-Guide.md** - Diagnostic steps for pool, hardware, and performance issues
- **Storage-Expansion-Plan.md** - 3-phase capacity expansion strategy
- **Drive-Stress-Test.md** - Usage docs for the drive stress test script
- **SAS-Expander-Replacement.md** - Failing expander diagnosis, SMP error data, replacement plan
- **drive-stress-test.sh** - POSIX sh script for sustained I/O testing on FreeBSD (no dependencies)
- **README.md** - Repo description (not synced to wiki)

## Key Conventions

- All wiki pages are **root-level Markdown files** with hyphenated names (e.g., `Physical-Drive-Layout.md`).
- Internal links between pages use the format `[Display Text](Page-Name)` (no `.md` extension) for GitHub Wiki compatibility.
- `README.md` is excluded from wiki sync and serves only as the repo landing page.
- The wiki sync workflow triggers only when `.md` files change on `main`, excluding `README.md` and `.github/**`.

## CI/CD

There are no build, lint, or test commands. The only automation is the GitHub Actions wiki sync workflow, which copies Markdown files to the wiki repo and pushes if changes exist.

## Editing Guidelines

- When adding a new documentation page, create a new root-level `.md` file with a hyphenated name and add a link to it from `Home.md` and `README.md`.
- Tables are used extensively for drive mappings, pool stats, and hardware specs -- maintain consistent table formatting.
- ASCII diagrams in `Physical-Drive-Layout.md` and `SAS-Expander-Configuration.md` use monospace box-drawing; preserve alignment carefully when editing.
