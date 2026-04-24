# ZPools Configuration

Current ZFS pool layout on the TrueNAS server (192.168.7.195).

*Last updated: 2026-04-24.*

## Overview

| Pool | Size | Allocated | Free | Capacity | Dedup | Status |
|---|---|---|---|---|---|---|
| Mir1 | **20.9 TB** | 14.6 TB | 6.32 TB | **69%** | 1.25x | ONLINE |
| Backups | 1.81 TB | 1.30 TB | 523 GB | 71% | 1.00x | ONLINE (2-way; SMR member ejected 2026-04-23) |
| boot-pool | 448 GB | 3.00 GB | 445 GB | 0.7% | 1.00x | ONLINE |

## Mir1 (Primary Storage)

**Topology**: 6 mirror vdevs (mirror-2 was removed previously, numbering gap preserved).
**SLOG**: Intel Optane 32GB M.2 (`nvd0`)
**L2ARC**: Samsung 840 EVO 250GB (`ada3`)
**Dedup**: 1.25x (mostly incidental, not actively pursued)

### Vdev layout

| Vdev | Type | Size | Half A | Half B | Notes |
|---|---|---|---|---|---|
| mirror-0 | SSD | 1.82 T | ada0 (WD Red SA500 2T) | da3 (WD Red SA500 2T) | AHCI + Adaptec split ✓ |
| mirror-1 | HDD | 7.28 T | da0 (WD Red Plus 8T) | da1 (IronWolf VN004 8T) | Both on Adaptec |
| mirror-3 | **SSD** | 1.81 T | **da11 (WDS200T1R0A 2T)** | **da5 (WDS200T1R0A 2T)** | **All-SSD as of 2026-04-24. Both on Adaptec.** |
| mirror-4 | SSD | 1.82 T | ada2 (WD Red SA500 2T) | da4 (WD Red SA500 2T) | AHCI + Adaptec split ✓ |
| mirror-5 | **HDD** | **7.28 T** | **da6 (IronWolf VN0022 8T)** | **da2 (IronWolf VN004 8T)** | **All-8 TB as of 2026-04-24. Both on Adaptec.** |
| mirror-6 | HDD | 928 G | ada1 (WD Red 1T 2.5") | ada5 (WD Red 1T 2.5") | Both on AHCI; smallest vdev |

### Support devices

| Role | Device | Model | Notes |
|---|---|---|---|
| SLOG | nvd0 | Intel Optane MEMPEK1J032GAH 32 GB | 11 MB used of 27.3 GB — SLOG is never the bottleneck |
| L2ARC | ada3 | Samsung SSD 840 EVO 250 GB | 1.21 GB used, very cold. Planned replacement: Optane P4800X 750 GB |

### Current status

- **No resilvers or scrubs in progress.** All mirrors ONLINE, 0 read/write/cksum errors anywhere in the pool.
- **Pool is 69% full.** The 90% performance-cliff pressure is gone — mirror-5's 2 TB→8 TB expansion added ~5.5 TB of capacity.
- Last resilver: mirror-3 da2 → da5, 1.74 TB in 7 h 54 m, 0 errors (2026-04-24).

### Observations

- The April 2026 arbitrage cycle produced the largest single-month capacity expansion on Mir1 since the pool's creation. mirror-5 flipped from 1.82 T SSD to 7.28 T HDD; mirror-3 flipped from HDD-with-USB to all-SSD (via the liberated mirror-5 WDS200T1R0As).
- **mirror-1 and mirror-5 both have both halves on the Adaptec expander** — same single-expander-failure concern. The Adaptec has been reliable, and a future arbitrage pass could rebalance if desired.
- **mirror-3 is now all-SSD** — the first vdev where both halves are matched WDS200T1R0A 2 TB SSDs (s/n 233318800197 + 23313Z802364). No more USB drive in a production mirror.
- mirror-6 (the two 1 TB 2.5" WD Reds) is still the smallest vdev and the natural next retirement candidate when the SSD→8 TB spinner arbitrage reaches it.
- **da2 (WD Red Plus 2 TB)** was liberated from mirror-3 on 2026-04-24 — physically out of the chassis, pending re-attach to the Backups pool as the CMR third member.

## Backups (External USB)

**Topology**: 2-way mirror (was 3-way; SMR member ejected 2026-04-23).

| Device | Model | Interface |
|---|---|---|
| da7 | Seagate BUP Slim 2 TB (ST2000LM003) | USB 3.0 |
| da8 | Seagate Portable 2 TB (ST2000LM007) | USB 3.0 |

71% full. Last scrub 2026-04-19 with 0 errors. Mirror of two USB spinners — treat as cold copy, not real redundancy.

**Pending action**: attach the liberated WD Red Plus 2 TB (da2 from the mirror-3 upgrade) as the third mirror member to restore 3-way redundancy with a proper CMR internal drive.

## boot-pool

**Topology**: single disk.

| Device | Model | Notes |
|---|---|---|
| ada6 | Seagate ST500LM021 500 GB 2.5" HDD | 3 GB used of 448 GB |

A second Intel Optane 32 GB is planned for the M.2_2 slot to replace ada6 as the boot device. Not yet purchased or installed. The migration (create pool on the new device → attach as mirror → detach ada6 → retire the spinner) will happen once the card is in hand.

## Drive → vdev → controller cross-reference

See [Physical Drive Layout](Physical-Drive-Layout.md) for the authoritative controller mapping. Quick summary:

- **Onboard AHCI**: ada0 (mir-0), ada1 (mir-6), ada2 (mir-4), ada3 (L2ARC), ada5 (mir-6), ada6 (boot) — *ada4 slot now empty (drive liberated in mirror-5 upgrade and redeployed as da11 on the expander)*
- **Adaptec expander**: da0–da1 (mir-1), da2 (mir-5), da3 (mir-0), da4 (mir-4), da5 (mir-3), da6 (mir-5), da11 (mir-3)
- **USB**: da7+da8 (Backups) — *WD My Passport da6 retired 2026-04-22 after USB replacement completed*
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

**2026-04-24** — mirror-5 completed upgrade to 2× 8 TB pair (da5 WDS200T1R0A SSD → da6 ST8000VN0022 8 TB HDD, 1.79 TB in 6 h 41 m, 0 errors). Liberated da5 SSD then replaced da2 (WD Red Plus HDD) in mirror-3 via autonomous overnight workflow (1.74 TB in 7 h 54 m, 0 errors). **mirror-3 now all-SSD**, **mirror-5 now all-8 TB**. da2 physically pulled for eventual Backups re-attach.

**2026-04-23** — da9 (ST2000DM008 SMR) detached and physically pulled from Backups pool. Backups now runs 2-way on USB members only, awaiting CMR replacement.

**2026-04-22** — mirror-3 USB replacement completed: WD My Passport (da6) retired after da11 WDS200T1R0A SSD resilver (13 h 41 m, 0 errors). USB drive physically unplugged.

**2026-04-20** — mirror-5 first-half upgrade started: ada4 WDS200T1R0A → new Seagate ST8000VN004 IronWolf (initially da10). Resilver completed 12 h 39 m later with 0 errors. Adds ~5.5 TB to Mir1 once both halves done.

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
