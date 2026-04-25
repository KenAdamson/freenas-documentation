# Physical Drive Layout

Current state of drives, controllers, and ZFS vdev membership on the TrueNAS server (192.168.7.195).

*Last updated: 2026-04-25 — post-maintenance-window: mirror-6 + remaining AHCI halves migrated onto the Adaptec; only ada0 (boot) remains on AHCI.*

## Hardware summary

- **PSU**: Seasonic Prime GX-1300 (single 12V rail, 6 SATA chains)
- **HBA**: LSI SAS3008 (Supermicro AOC-S3008L-L8E), IT mode, mpr driver — slot 2 CPU-direct PCIe 3.0 x8
- **SAS Expander**: Adaptec AEC-82885T (36-port SAS-3 12 Gb/s, slot-powered) — slot 3 (power only)
- **Uplink**: Dual SFF-8643 cables HBA ↔ expander, all 8 PHYs wide-ported at 12 Gbps
- **NVMe**: Intel Optane P4800X 750 GB (`nvd0`, slot 4) — Mir1 SLOG + L2ARC; Intel Optane M10 32 GB (`nvd1`, M.2_1) — idle, planned for boot
- **Drive cages**: Icy Dock 3.5" 5-bay + legacy IcyDock 2.5"/3.5" cages (see cage mapping below)

## Controller → drive mapping

### Onboard Intel Cannon Lake AHCI

| Device | Model | Size | Role | Vdev | Notes |
|---|---|---|---|---|---|
| ada0 | Seagate ST500LM021 (2.5" HDD) | 500 GB | **boot-pool** | — | Same physical drive that was `ada6` pre-maintenance; now sole AHCI device, so renumbered to ada0. Migration to nvd1 Optane is drafted. |

All other AHCI ports are empty post-2026-04-25. The 1 TB WD Reds (formerly ada1/ada5), the SA500 SSDs (formerly ada0/ada2), and the Samsung 840 EVO (formerly ada3) all moved to the Adaptec expander during the maintenance window.

### NVMe

| Device | Model | Size | Role | Slot | Notes |
|---|---|---|---|---|---|
| nvd0 | Intel Optane P4800X (NVMe AIC) | 750 GB | Mir1 SLOG + L2ARC | Slot 4 (Gen3 x4) | Partitioned: `nvd0p1` (16 G freebsd-zfs) = SLOG; `nvd0p2` (683 G freebsd-zfs) = L2ARC |
| nvd1 | Intel Optane MEMPEK1J032GAH (NVMe M.2) | 32 GB | (idle) | M.2_1 | Ex-Mir1-SLOG, freed in maintenance window. Earmarked for boot-pool migration; currently unpartitioned. |

### Adaptec AEC-82885T expander (via LSI SAS3008)

| Device | Model | Size | Role | Vdev | Notes |
|---|---|---|---|---|---|
| da0 | WD Red Plus WD80EFPX (3.5" HDD) | 8 TB | Mir1 | mirror-1 | s/n WD-RD3EPHKG |
| da1 | Seagate IronWolf ST8000VN004 (3.5" HDD) | 8 TB | Mir1 | mirror-1 | s/n WSD7VL7A |
| da2 | Seagate IronWolf ST8000VN004 (3.5" HDD) | 8 TB | Mir1 | mirror-5 | s/n WSD1C7H5 |
| da3 | Seagate IronWolf ST8000VN0022 (3.5" HDD) | 8 TB | Mir1 | mirror-5 | s/n ZA1BFXBR |
| da4 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-0 | s/n 2448HBD00027 |
| da5 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-4 | s/n 24114M4A1F07 |
| da6 | Samsung SSD 840 EVO (SATA SSD) | 250 GB | (idle) | — | **Detached as L2ARC 2026-04-25**; physically still attached, awaiting bay reclamation |
| da7 | WD Red WD10JFCX (2.5" HDD) | 1 TB | Mir1 | mirror-6 | Migrated from AHCI in 2026-04-25 maintenance window |
| da8 | WD Red Plus WD20EFPX (3.5" HDD) | 2 TB | Backups | mirror-0 | s/n WD-WX22DA5964LF; new internal CMR member added 2026-04-25 |
| da9 | WD Red WD10JFCX (2.5" HDD) | 1 TB | Mir1 | mirror-6 | Migrated from AHCI in 2026-04-25 maintenance window |
| da10 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-4 | s/n 24114M4A1F14 |
| da11 | WDC WDS200T1R0A (SATA SSD) | 2 TB | Mir1 | mirror-3 | s/n 23313Z802364 |
| da12 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-0 | s/n 2448HBD00072 |
| da13 | WDC WDS200T1R0A (SATA SSD) | 2 TB | Mir1 | mirror-3 | s/n 233318800197 |

Expander reports as enclosure #2, logical ID `50000d17:017175be`. 14 drives currently live behind it (12 Mir1 + 1 Backups + 1 retired-but-attached 840 EVO).

### USB (legacy external)

| Device | Model | Size | Role | Notes |
|---|---|---|---|---|
| da14 | Seagate BUP Slim ST2000LM003 | 2 TB | (idle) | s/n S32WJ9DF700679 — detached from Backups 2026-04-25 (worn, 1.03M load cycles); physically still plugged in, awaiting unplug |
| da15 | Seagate Portable ST2000LM007 | 2 TB | Backups | mirror-0 | s/n ZDZ9FEF1 — sole remaining USB member of Backups |

**Retired USB/expander drives (as of 2026-04-25):**
- **WD My Passport** — physically unplugged 2026-04-22 after mirror-3 SSD replacement completed.
- **ST2000DM008 Barracuda SMR** — detached from Backups 2026-04-23, physically pulled 2026-04-23 (interim stopgap for mirror-3; never needed thanks to the April SSD cascade).
- **WD Red Plus WD20EFPX 2 TB** (the one that was the prior mirror-3 half) — was pulled 2026-04-24, re-installed internally as `da8` on the expander 2026-04-25, replaced the BUP Slim in Backups via 4 h 8 m resilver. Same drive, new bay.

## Controller split analysis

Post-2026-04-25 maintenance, every Mir1 vdev sits entirely behind the Adaptec expander:

| vdev | Half A | Half B | Split? |
|---|---|---|---|
| mirror-0 (SSD) | Adaptec (da4) | Adaptec (da12) | ⚠ both on Adaptec |
| mirror-1 (HDD 8T) | Adaptec (da0) | Adaptec (da1) | ⚠ both on Adaptec |
| mirror-3 (SSD) | Adaptec (da11) | Adaptec (da13) | ⚠ both on Adaptec |
| mirror-4 (SSD) | Adaptec (da5) | Adaptec (da10) | ⚠ both on Adaptec |
| mirror-5 (HDD 8T) | Adaptec (da2) | Adaptec (da3) | ⚠ both on Adaptec |
| mirror-6 (HDD 1T) | Adaptec (da7) | Adaptec (da9) | ⚠ both on Adaptec |
| Backups mirror-0 | Adaptec (da8, internal CMR) | USB (da15) | ✓ controller-split, but USB is a different class of risk |

Mir1 is now uniformly single-expander-exposed. The AEC-82885T has been reliable since the 2026-04-05 install; if it fails, every Mir1 vdev loses one half simultaneously and the pool stays online (mirrors). The new 5-bay 3.5" enclosure (acquired, not yet installed) is the path to rebalancing — splitting some 3.5" mirror halves onto a separate SAS chain to give true expander-fault tolerance.

## Drive replacement procedure

1. Identify the failing drive from `zpool status` output (e.g., `da2`).
2. Look it up in the tables above to confirm which controller and expander slot it lives on.
3. Use `sas3ircu 0 display | less` to cross-reference the SAS address and slot number for the expander.
4. Blink the drive LED by generating read activity:
   ```bash
   dd if=/dev/daX of=/dev/null bs=1M count=10240
   ```
5. Physically replace the drive.
6. Run `zpool replace Mir1 <old-gptid> /dev/daX` to begin the resilver.
7. After resilver completes, verify with `zpool status`.

## Maintenance notes

- ZFS tracks drives internally by GPTID, not by `ada#`/`da#` names. Device names can shift after reboots or drive events.
- When in doubt, match the GPTID shown in `zpool status` against `glabel status` to find the underlying partition.
- The AEC-82885T is transparent to the OS — all bus enumeration and management happens through the LSI HBA via the `mpr` driver. See the [SAS Expander Configuration](SAS-Expander-Configuration.md) page for uplink and enclosure details.
