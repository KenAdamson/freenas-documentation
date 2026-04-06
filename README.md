# TrueNAS Server Documentation

This repository contains the documentation for the TrueNAS CORE server at `freenas.local` (192.168.7.195). It is designed to be consumed as a GitHub Wiki — a GitHub Actions workflow (`.github/workflows/sync-wiki.yml`) mirrors the Markdown files here into the wiki on push.

## Pages

- [Home](Home.md) — server overview, specs, recent changes
- [ZPools Overview](ZPools.md) — ZFS pool configuration, vdev layout, datasets
- [Physical Drive Layout](Physical-Drive-Layout.md) — controller → drive → vdev mapping
- [SAS Expander Configuration](SAS-Expander-Configuration.md) — LSI SAS3008 HBA + Adaptec AEC-82885T fabric
- [Storage Expansion Plan](Storage-Expansion-Plan.md) — completed work and next maintenance window
- [Maintenance Procedures](Maintenance-Procedures.md) — SMART tests, scrubs, snapshots, updates
- [Troubleshooting Guide](Troubleshooting-Guide.md) — diagnostics for pool / hardware / performance
- [Drive Stress Test](Drive-Stress-Test.md) — sustained I/O burn-in script
- [Media Services](Media-Services.md) — Plex stack and adjacent services

## Viewing as a wiki

After pushing to GitHub:

1. Go to the repository on GitHub.
2. Click the **Wiki** tab.
3. Pages are published automatically by the sync workflow.

## Editing locally

```bash
git clone <repo>
# edit Markdown files
git commit -am "update docs"
git push
```

The workflow triggers on changes to `.md` files on `main`, excluding `README.md` and `.github/**`.

---

*Last updated: 2026-04-06.*
