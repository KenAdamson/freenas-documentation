# ZPools Configuration

Current ZFS pool layout on the TrueNAS server (192.168.7.195).

*Last updated: 2026-04-25 — post-maintenance: P4800X SLOG+L2ARC live, all Mir1 drives on Adaptec, Backups now CMR+USB.*

## Overview

| Pool | Size | Allocated | Free | Capacity | Dedup | Status |
|---|---|---|---|---|---|---|
| Mir1 | **20.9 TB** | 14.6 TB | 6.32 TB | **69%** | 1.25x | ONLINE |
| Backups | 1.81 TB | 1.30 TB | 523 GB | 71% | 1.00x | ONLINE (2-way: 1× internal CMR + 1× USB) |
| boot-pool | 448 GB | 3.00 GB | 445 GB | 0.7% | 1.00x | ONLINE |

## Mir1 (Primary Storage)

**Topology**: 6 mirror vdevs (mirror-2 was removed previously, numbering gap preserved).
**SLOG**: Intel Optane P4800X 750 GB, 16 G partition (`nvd0p1`)
**L2ARC**: Intel Optane P4800X 750 GB, 683 G partition (`nvd0p2`); ~205 GB warm (~30 % of partition)
**Dedup**: 1.25x (mostly incidental, not actively pursued)

### Vdev layout

| Vdev | Type | Size | Half A | Half B | Notes |
|---|---|---|---|---|---|
| mirror-0 | SSD | 1.82 T | da4 (WD Red SA500 2T) | da12 (WD Red SA500 2T) | Both on Adaptec post-2026-04-25 |
| mirror-1 | HDD | 7.28 T | da0 (WD Red Plus 8T) | da1 (IronWolf VN004 8T) | Both on Adaptec |
| mirror-3 | SSD | 1.81 T | da11 (WDS200T1R0A 2T) | da13 (WDS200T1R0A 2T) | All-SSD as of 2026-04-24. Both on Adaptec |
| mirror-4 | SSD | 1.82 T | da5 (WD Red SA500 2T) | da10 (WD Red SA500 2T) | Both on Adaptec post-2026-04-25 |
| mirror-5 | HDD | 7.28 T | da2 (IronWolf VN004 8T) | da3 (IronWolf VN0022 8T) | All-8 TB as of 2026-04-24. Both on Adaptec |
| mirror-6 | HDD | 928 G | da7 (WD Red 1T 2.5") | da9 (WD Red 1T 2.5") | Migrated from AHCI to Adaptec on 2026-04-25; smallest vdev |

### Support devices

| Role | Device | Model | Notes |
|---|---|---|---|
| SLOG | nvd0p1 | Intel Optane P4800X 750 GB (16 G partition) | <1 MB resident; SLOG is never the bottleneck. PLP-enabled drive — no mirror needed |
| L2ARC | nvd0p2 | Intel Optane P4800X 750 GB (683 G partition) | ~205 GB warm (~30 % of partition); fills steadily under normal media-read workload |
| (idle) | nvd1 | Intel Optane MEMPEK1J032GAH 32 GB | Ex-SLOG, freed 2026-04-25; earmarked for boot-pool migration |

### Current status

- **No resilvers or scrubs in progress.** All mirrors ONLINE, 0 read/write/cksum errors anywhere in the pool.
- **Pool is 69% full.** The 90% performance-cliff pressure is gone — mirror-5's 2 TB→8 TB expansion added ~5.5 TB of capacity.
- Last resilver: mirror-3 da2 → da5, 1.74 TB in 7 h 54 m, 0 errors (2026-04-24).

### Observations

- The April 2026 arbitrage cycle produced the largest single-month capacity expansion on Mir1 since the pool's creation. mirror-5 flipped from 1.82 T SSD to 7.28 T HDD; mirror-3 flipped from HDD-with-USB to all-SSD (via the liberated mirror-5 WDS200T1R0As).
- **All Mir1 vdevs are now single-expander-exposed** post-2026-04-25 maintenance — every drive is on the Adaptec. The AEC-82885T has been reliable since the 2026-04-05 install. A future arbitrage pass plus the new 5-bay enclosure can rebalance some HDD halves onto a separate SAS chain when both are available.
- **mirror-3 is now all-SSD** — the first vdev where both halves are matched WDS200T1R0A 2 TB SSDs (s/n 233318800197 + 23313Z802364). No more USB drive in a Mir1 mirror.
- mirror-6 (the two 1 TB 2.5" WD Reds) is still the smallest vdev and the natural next retirement candidate when the SSD→8 TB spinner arbitrage reaches it. It's now on the Adaptec rather than AHCI, so retirement also frees expander bays rather than AHCI ports.
- **WD Red Plus 2 TB** liberated from mirror-3 on 2026-04-24 went directly to Backups as `da8` on 2026-04-25 — internal CMR replacement for the worn BUP Slim USB.

## Backups

**Topology**: 2-way mirror — 1× internal CMR + 1× USB. Materially better than the all-USB state; loss of the USB member degrades to a healthy internal mirror leg, not "two USB chains both fail at once."

| Device | Model | Interface |
|---|---|---|
| da8 | WD Red Plus WD20EFPX 2 TB | SATA via Adaptec expander (internal CMR) |
| da15 | Seagate Portable ST2000LM007 2 TB | USB 3.0 |

71% full. Last scrub 2026-04-19 with 0 errors. Last resilver 2026-04-25 (BUP Slim → WD Red Plus, 4 h 8 m, 0 errors).

**Idle but still attached**: Seagate BUP Slim ST2000LM003 (`da14`, s/n S32WJ9DF700679) — detached from Backups 2026-04-25 (Load_Cycle_Count was 1.03 M, ~172 % of spec), still physically plugged in, awaiting unplug.

## boot-pool

**Topology**: single disk.

| Device | Model | Notes |
|---|---|---|
| ada0 | Seagate ST500LM021 500 GB 2.5" HDD | 3 GB used of 448 GB. Same physical disk as the old `ada6`; renumbered when the rest of AHCI was vacated in the 2026-04-25 maintenance |

The freed M10 Optane (`nvd1`) is the migration target. TrueNAS's `boot.attach` won't work because the M10 is too small for its standard EFI + 16 G swap + full-size ZFS layout, so the migration uses `zfs send | zfs recv` into a fresh small pool on the M10, then a one-time pool-rename swap from rescue media. Drafted procedure at `/mnt/media/freenas-boot-migration-runbook.md`.

## Drive → vdev → controller cross-reference

See [Physical Drive Layout](Physical-Drive-Layout.md) for the authoritative controller mapping. Quick summary:

- **Onboard AHCI**: ada0 (boot only) — all other AHCI ports vacated 2026-04-25
- **Adaptec expander (Mir1)**: da0+da1 (mir-1), da2+da3 (mir-5), da4+da12 (mir-0), da5+da10 (mir-4), da7+da9 (mir-6), da11+da13 (mir-3)
- **Adaptec expander (Backups)**: da8 (internal CMR member)
- **Adaptec expander (idle)**: da6 (Samsung 840 EVO 250 GB, ex-L2ARC, awaiting physical pull)
- **USB**: da15 (Backups Portable) — *BUP Slim da14 detached 2026-04-25, awaiting unplug*
- **NVMe**: nvd0p1 (Mir1 SLOG), nvd0p2 (Mir1 L2ARC); nvd1 idle (boot migration target)

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

**2026-04-25** — **Maintenance window.** Physical slot swap (LSI from chipset x4 in slot 3 to CPU-direct x8 in slot 2; Adaptec demoted to slot 3, power only). Intel Optane P4800X 750 GB installed in slot 4, partitioned 16 G SLOG + 683 G L2ARC; old M10 SLOG and Samsung 840 EVO L2ARC removed from Mir1. M10 (`nvd1`) idle, earmarked for boot. 840 EVO physically still attached as `da6`, awaiting bay reclamation. Marvell 88SE9215 card pulled. Remaining AHCI drives (the 1 TB WD Red 2.5" pair, both SA500s, 840 EVO, the boot disk) all migrated to the Adaptec — only `ada0` (boot) remains on AHCI. Backups BUP Slim USB replaced with the previously-liberated WD Red Plus 2 TB internal CMR (4 h 8 m resilver, 0 errors). Persistent L2ARC tunables set via `tunable.update`.

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
