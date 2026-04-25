# TrueNAS Server Documentation

Documentation for the TrueNAS CORE server (`freenas.local` / `192.168.7.195`).

*Last updated: 2026-04-25 — post-maintenance-window: HBA moved to CPU-direct x8, P4800X installed as SLOG+L2ARC, M10 freed for boot, Marvell pulled, Backups now 1× internal + 1× USB.*

## Pages

- [ZPools Overview](ZPools.md) — pool layout, vdevs, SLOG, L2ARC, dataset structure
- [Physical Drive Layout](Physical-Drive-Layout.md) — controller → drive → vdev mapping
- [SAS Expander Configuration](SAS-Expander-Configuration.md) — LSI SAS3008 HBA + Adaptec AEC-82885T fabric
- [Storage Expansion Plan](Storage-Expansion-Plan.md) — completed work and next maintenance window
- [Maintenance Procedures](Maintenance-Procedures.md) — SMART tests, scrubs, snapshots, updates
- [Troubleshooting Guide](Troubleshooting-Guide.md) — diagnostic steps for pool / hardware / performance issues
- [Drive Stress Test](Drive-Stress-Test.md) — sustained I/O drive burn-in
- [Media Services](Media-Services.md) — Plex and related services

## Server specifications

| Field | Value |
|---|---|
| Hostname | freenas.local |
| Management IP | 192.168.7.195 |
| OS | TrueNAS CORE 13.3-U1.2 (FreeBSD 13.3-RELEASE-p4, OpenZFS 2.2.5-1) |
| Motherboard | ASUS WS C246 PRO |
| CPU | Intel Core i3-8100 @ 3.60 GHz (ECC-capable via C246) |
| RAM | 32 GB ECC UDIMM (2× 16 GB, 2 of 4 slots populated) |
| PSU | **Seasonic Prime GX-1300** (installed 2026-04-05, single 12V rail) |

### Storage controllers

| Controller | Role |
|---|---|
| Intel Cannon Lake PCH SATA AHCI | Onboard — only ada0 (the boot disk) remains; all other ada slots empty post-2026-04-25 maintenance |
| LSI SAS3008 (Supermicro AOC-S3008L-L8E, IT mode, `mpr0`) | **Slot 2 — CPU-direct PCIe 3.0 x8 (~7.88 GB/s)**; HBA for the SAS expander fabric |
| Adaptec AEC-82885T (36-port SAS-3 expander) | **Slot 3 (power only)**; hosts da0–da13 (12 Mir1 + 1 Backups + 2 idle) |
| Slot 4 (PCH x4) | **Intel Optane P4800X 750 GB** (`nvd0`) — Mir1 SLOG (16 G partition) + L2ARC (683 G partition) |
| NVMe M.2_1 | Intel Optane 32 GB MEMPEK1J032GAH (`nvd1`) — **idle, planned as new boot device** (see boot-migration runbook) |
| NVMe M.2_2 | empty |
| ~~Marvell 88SE9215~~ | **Removed 2026-04-25**; migrated to spare parts for the P520 Postgres build |

### Network

| Interface | Role |
|---|---|
| mlxen1 (Mellanox ConnectX-3 Pro) | **Primary 10 GbE, 192.168.7.195/24** |
| mlxen0 | Second 10 GbE port on the same card (currently idle) |
| igb0, em0 | Onboard gigabit, unused |
| Default gateway | 192.168.7.1 (MikroTik) |
| DNS | 1.1.1.1, 8.8.8.8, 8.8.4.4 |
| Domain | sonolux.industries |

### Pool summary

| Pool | Size | Used | Free | Status |
|---|---|---|---|---|
| Mir1 | **20.9 TB** | 14.6 TB (**69%**) | 6.32 TB | ONLINE — SLOG+L2ARC on P4800X partitions; 205 G of L2ARC warm |
| Backups | 1.81 TB | 1.30 TB (71%) | 523 GB | ONLINE (2-way — 1× internal CMR WD Red Plus + 1× USB Seagate Portable) |
| boot-pool | 448 GB | 3.00 GB | 445 GB | ONLINE (on ada6 500 GB 2.5" spinner; Optane replacement planned) |

See [ZPools](ZPools.md) for the full vdev layout.

## Recent changes

- **2026-04-25** — **Maintenance window executed.** Physical slot swap: LSI SAS3008 moved from slot 3 (chipset x4) to slot 2 (CPU-direct x8); Adaptec AEC-82885T demoted to slot 3 (power only). HBA upstream now x8 PCIe 3.0 (~7.88 GB/s), confirmed via `mprutil show adapter`. Intel Optane P4800X 750 GB installed in slot 4, partitioned as 16 G SLOG + 683 G L2ARC; old M10 SLOG and Samsung 840 EVO L2ARC retired. Marvell 88SE9215 card pulled (no drives behind it; reserved for P520 Postgres build). All 1 TB 2.5" WD Reds (mirror-6) and remaining SA500/HDD AHCI drives migrated onto the Adaptec — only ada0 (boot disk) remains on AHCI. Backups pool's BUP Slim USB replaced with internal WD Red Plus 2 TB (4 h 8 m resilver, 0 errors), so Backups is now 1× internal CMR + 1× USB. M10 Optane (now `nvd1`, freed from SLOG duty) is idle; planned for boot-pool migration — see `freenas-boot-migration-runbook.md` on `/mnt/media`.
- **2026-04-24** — mirror-5 fully upgraded to 2× 8 TB IronWolves (da6 VN0022 + da2 VN004, 6 h 41 m resilver, 0 errors). mirror-3 became all-SSD (da11 + da5, both WDS200T1R0A; 7 h 54 m resilver of the second half, 0 errors). da2 (liberated WD Red Plus 2 TB, ~1,843 PoH) physically pulled, pending re-attach to Backups. Marvell 88SE9215 card has no drives — ready for P520 migration.
- **2026-04-23** — **da9 (SMR ST2000DM008) detached and pulled from Backups.** Backups now runs 2-way on the two USB members (da7/da8) while awaiting the liberated WD Red Plus as the CMR third member.
- **2026-04-21/22** — mirror-3 first resilver: USB WD My Passport (da6) → WDS200T1R0A SSD (da11, s/n 233318800197; this is the drive that was ada4 in mirror-5, moved to the expander). 13 h 41 m, 0 errors. **USB drive finally out of production.**
- **2026-04-20/21** — mirror-5 first resilver: ada4 WDS200T1R0A → new Seagate ST8000VN004 IronWolf (da10 at the time). 12 h 39 m, 0 errors. mirror-5's 2 TB→8 TB expansion begins; adds ~5.5 TB of free space to Mir1.
- **2026-04-06** — Deep audit after the prior night's hardware work. Confirmed dual-uplink wide port at 8 × 12 Gbps from LSI to Adaptec; rewrote Physical-Drive-Layout, SAS-Expander-Configuration, ZPools, and Storage-Expansion-Plan to reflect post-install state. Deleted stale SAS-Expander-Replacement page (work complete).
- **2026-04-05** — **Seasonic Prime GX-1300 PSU** installed. **Adaptec AEC-82885T expander** installed and connected via dual SFF-8643 uplink to the LSI HBA. Seven pool drives migrated onto the expander. mirror-3 replacement initiated (USB WD My Passport → Seagate Barracuda interim). SA500 previously thought dead (mirror-4 warranty drama) turned out to be fine — the problem was power delivery, not the drive.
- **2026-03-23** — Optane 32 GB SLOG installed with Thermalright HR10 2280 PRO heatsink. Side-exhaust fan array + foamcore top seal; SMART thresholds at 40 °C info / 55 °C critical.
- **2026-03-01** — mirror-1 upgraded to 2× 8 TB (WD Red Plus + IronWolf). Optane SLOG ordered.
- **2026-01/02** — HP SAS expander diagnosed as failing; pool drives temporarily migrated to onboard Intel/Marvell SATA. Three ST2000LM015 Seagates failed from the same 2021 batch.

## Alerts

ℹ️ **Mir1 at 69%** — performance-cliff pressure resolved by the April 2026 arbitrage (mirror-5 SSD→8 TB). Pool has 6.32 TB free. Continue the arbitrage at leisure; not urgent.

ℹ️ **Backups pool is 2-way** with one internal CMR member and one USB spinner. Materially better than the all-USB state — losing the USB drive degrades to a single internal member, no longer a "two USB chains both fail" scenario.

ℹ️ **All Mir1 drives are on the Adaptec expander** — single-expander-failure exposure for every vdev. The AEC-82885T has been reliable since the 2026-04-05 install. The new 5-bay 3.5" enclosure (acquired, not yet installed) can host a second SAS chain to rebalance once it's in.

ℹ️ **Boot-pool still on the Seagate ST500LM021** (now `ada0`, the only AHCI device left). Migration to the M10 Optane is drafted — see `/mnt/media/freenas-boot-migration-runbook.md` on the share.

ℹ️ **HBA temperature** runs ~84 °C under sustained load post-slot-swap (was ~76 °C in slot 3). Within SAS3008 thermal envelope but worth watching; the new slot may have less direct airflow. Consider a card-mounted fan upgrade if it climbs further.

---

*Last updated: 2026-04-25.*
