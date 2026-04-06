# ZPools Configuration

Current ZFS pool layout on the TrueNAS server (192.168.7.195).

*Last updated: 2026-04-06.*

## Overview

| Pool | Size | Allocated | Free | Capacity | Dedup | Status |
|---|---|---|---|---|---|---|
| Mir1 | 15.4 TB | 13.9 TB | 1.54 TB | **90%** | 1.25x | ONLINE (resilver in progress) |
| Backups | 1.81 TB | 1.44 TB | 381 GB | 79% | 1.00x | ONLINE |
| boot-pool | 448 GB | 3.00 GB | 445 GB | 1% | 1.00x | ONLINE |

## Mir1 (Primary Storage)

**Topology**: 6 mirror vdevs (mirror-2 was removed previously, numbering gap preserved).
**SLOG**: Intel Optane 32GB M.2 (`nvd0`)
**L2ARC**: Samsung 840 EVO 250GB (`ada3`)
**Dedup**: 1.25x (mostly incidental, not actively pursued)

### Vdev layout

| Vdev | Type | Size | Half A | Half B | Notes |
|---|---|---|---|---|---|
| mirror-0 | SSD | 1.82 T | ada0 (WD Red SA500 2T) | da3 (WD Red SA500 2T) | AHCI + Adaptec split ✓ |
| mirror-1 | HDD | 7.28 T | da0 (WD Red Plus 8T) | da1 (IronWolf 8T) | Both on Adaptec |
| mirror-3 | HDD | 1.81 T | da6 → da9 (Barracuda 2T, *resilvering*) | da2 (WD Red Plus 2T) | Interim Barracuda pending 8T upgrade |
| mirror-4 | SSD | 1.82 T | ada2 (WD Red SA500 2T) | da4 (WD Red SA500 2T) | AHCI + Adaptec split ✓ |
| mirror-5 | SSD | 1.82 T | ada4 (WDS200T1R0A 2T) | da5 (WDS200T1R0A 2T) | AHCI + Adaptec split ✓ |
| mirror-6 | HDD | 928 G | ada1 (WD Red 1T 2.5") | ada5 (WD Red 1T 2.5") | Both on AHCI; smallest vdev |

### Support devices

| Role | Device | Model | Notes |
|---|---|---|---|
| SLOG | nvd0 | Intel Optane MEMPEK1J032GAH 32 GB | 11 MB used of 27.3 GB — SLOG is never the bottleneck |
| L2ARC | ada3 | Samsung SSD 840 EVO 250 GB | 1.21 GB used, very cold. Planned replacement: Optane P4800X 750 GB |

### Current status

- **mirror-3 resilver in progress** (started 2026-04-05 23:00 UTC): da9 (Seagate Barracuda ST2000DM008) replacing the USB WD My Passport (da6). Estimated ~3 days at 45.9 MB/s, bottlenecked by reads from the tired USB source.
- Pool is **90% full** — into the ZFS performance cliff zone. Capacity expansion is the main pressure.
- No checksum, read, or write errors outside the resilver target.

### Observations

- The SA500 that was declared dead in March 2026 and triggered a warranty claim turned out to be fine once power delivery was fixed (new PSU). Mirrors 0, 4, and 5 are now all healthy matched SSD pairs again.
- mirror-6 (the two 1 TB 2.5" WD Reds) is both the smallest vdev and the only one entirely on the onboard AHCI controller. It's the natural retirement candidate when the SSD→8 TB spinner arbitrage happens.
- mirror-1 (the 8 TB pair) is entirely on the Adaptec expander, meaning a single expander failure would take both halves down. This is acknowledged but not urgent.

## Backups (External USB)

**Topology**: single mirror, 2x external USB spinners.

| Device | Model | Interface |
|---|---|---|
| da7 | Seagate BUP Slim 2 TB | USB 3.0 |
| da8 | Seagate Portable 2 TB | USB 3.0 |

79% full. Last resilvered 2026-04-05 with 0 errors. Mirror of two of the least-reliable drive form factors in the house, so treat it as a cold copy, not real redundancy. Longer-term this pool needs a real home (internal spinners on the Adaptec).

## boot-pool

**Topology**: single disk.

| Device | Model | Notes |
|---|---|---|
| ada6 | Seagate ST500LM021 500 GB 2.5" HDD | 3 GB used of 448 GB |

A second Intel Optane 32 GB is planned for the M.2_2 slot to replace ada6 as the boot device. Not yet purchased or installed. The migration (create pool on the new device → attach as mirror → detach ada6 → retire the spinner) will happen once the card is in hand.

## Drive → vdev → controller cross-reference

See [Physical Drive Layout](Physical-Drive-Layout.md) for the authoritative controller mapping. Quick summary:

- **Onboard AHCI**: ada0 (mir-0), ada1 (mir-6), ada2 (mir-4), ada3 (L2ARC), ada4 (mir-5), ada5 (mir-6), ada6 (boot)
- **Adaptec expander**: da0–da1 (mir-1), da2 (mir-3), da3 (mir-0), da4 (mir-4), da5 (mir-5), da9 (mir-3 resilver)
- **USB**: da6 (mir-3, being retired), da7+da8 (Backups)
- **NVMe**: nvd0 (SLOG)

## Operational commands

```bash
# Health and resilver status
zpool status

# Capacity and vdev layout
zpool list -v

# Performance
zpool iostat -v 1

# Verify GPTID → device mapping
glabel status
```

## Recent events

**2026-04-06** — Deep audit after PSU swap and Adaptec install. Confirmed:
- Dual uplink to AEC-82885T linked at 8 × 12 Gbps wide port
- All 7 drives visible on expander
- SA500 warranty drama resolved (drive was fine, power was the issue)
- mirror-3 Barracuda resilver in progress

**2026-04-05** — Seasonic Prime GX-1300 PSU installed, Adaptec AEC-82885T expander installed in slot 2, half the pool drives migrated to expander. Mir1 mirror-3 replacement initiated (USB Passport → Barracuda).

**2026-03-23** — Intel Optane 32 GB M.2 SLOG installed with HR10 2280 PRO heatsink. SLOG is operational and thermally stable.

**2026-03-01** — mirror-1 upgraded to 2x 8 TB (WD Red Plus + IronWolf). Optane SLOG ordered.

**2026-01/02** — HP SAS expander diagnosed as failing; pool drives migrated off it temporarily. 3× ST2000LM015 Seagates failed from the same 2021 batch; USB drives pressed into service as interim mirror members.

## Dataset structure

The Mir1 pool carries the following top-level datasets. See `zfs list` for authoritative usage:

- `Mir1/Artists` — music production archives
- `Mir1/Documents`
- `Mir1/Files`
- `Mir1/Music`
- `Mir1/Photography`
- `Mir1/Pictures`
- `Mir1/Projects` — Reaper / audio project files
- `Mir1/media` — Plex media root (movies, tv, audiobooks, games, etc.)
- `Mir1/sonolux`
- `Mir1/proxy-cache`
- `Mir1/.system` — TrueNAS system datasets
- `Mir1/iocage`, `Mir1/jails` — legacy jail storage
