# Physical Drive Layout

Current state of drives, controllers, and ZFS vdev membership on the TrueNAS server (192.168.7.195).

*Last updated: 2026-04-24 — post mirror-5 (all-8 TB) and mirror-3 (all-SSD) completion.*

## Hardware summary

- **PSU**: Seasonic Prime GX-1300 (single 12V rail, 6 SATA chains)
- **HBA**: LSI SAS3008 (Supermicro AOC-S3008L-L8E), IT mode, mpr driver
- **SAS Expander**: Adaptec AEC-82885T (36-port SAS-3 12 Gb/s, slot-powered)
- **Uplink**: Dual SFF-8643 cables HBA ↔ expander, all 8 PHYs wide-ported at 12 Gbps
- **Drive cages**: Icy Dock 3.5" 5-bay + legacy IcyDock 2.5"/3.5" cages (see cage mapping below)

## Controller → drive mapping

### Onboard Intel Cannon Lake AHCI

| Device | Model | Size | Role | Vdev |
|---|---|---|---|---|
| ada0 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-0 |
| ada1 | WD Red WD10JFCX (2.5" HDD) | 1 TB | Mir1 | mirror-6 |
| ada2 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-4 |
| ada3 | Samsung 840 EVO (SATA SSD) | 250 GB | Mir1 | **L2ARC cache** |
| ~~ada4~~ | *(empty — drive liberated to mirror-3 as da11 on 2026-04-21)* | — | — | — |
| ada5 | WD Red WD10JFCX (2.5" HDD) | 1 TB | Mir1 | mirror-6 |
| ada6 | Seagate ST500LM021 (2.5" HDD) | 500 GB | **boot-pool** | — |
| nvd0 | Intel Optane MEMPEK1J032GAH (NVMe M.2) | 32 GB | Mir1 | **SLOG** |

### Adaptec AEC-82885T expander (via LSI SAS3008)

| Device | Model | Size | Role | Vdev | Notes |
|---|---|---|---|---|---|
| da0 | WD Red Plus WD80EFPX (3.5" HDD) | 8 TB | Mir1 | mirror-1 | |
| da1 | Seagate IronWolf ST8000VN004 (3.5" HDD) | 8 TB | Mir1 | mirror-1 | |
| da2 | Seagate IronWolf ST8000VN004 (3.5" HDD) | 8 TB | Mir1 | mirror-5 | Installed 2026-04-20 (was da10 until physical move 2026-04-24) |
| da3 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-0 | |
| da4 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-4 | |
| da5 | WDS200T1R0A (SATA SSD) | 2 TB | Mir1 | mirror-3 | Reassigned from mirror-5 to mirror-3 on 2026-04-24 |
| da6 | Seagate IronWolf ST8000VN0022 (3.5" HDD) | 8 TB | Mir1 | mirror-5 | Installed 2026-04-24 (replaces da5's prior mirror-5 role) |
| da11 | WDS200T1R0A (SATA SSD) | 2 TB | Mir1 | mirror-3 | Former ada4, re-inserted on expander 2026-04-21 |

Expander reports as enclosure #2, logical ID `50000d17:017175be`, 25 slots total.

### USB (legacy external)

| Device | Model | Size | Role | Notes |
|---|---|---|---|---|
| da7 | Seagate BUP Slim | 2 TB | Backups mirror-0 | |
| da8 | Seagate Portable | 2 TB | Backups mirror-0 | |

**Retired USB/expander drives (as of 2026-04-24):**
- **WD My Passport** (was da6) — physically unplugged 2026-04-22 after mirror-3 SSD replacement completed.
- **ST2000DM008 Barracuda SMR** (was da9) — detached from Backups 2026-04-23, physically pulled 2026-04-23 (interim stopgap for mirror-3; never needed for its original purpose thanks to the April SSD cascade).
- **WD Red Plus WD20EFPX 2 TB** (was da2) — physically pulled 2026-04-24 after mirror-3 finished rebuilding onto da5. Pending re-attach to Backups as CMR third member.

## Controller split analysis

Pool redundancy is preserved against single-controller failure for most vdevs:

| vdev | Controller A | Controller B | Split? |
|---|---|---|---|
| mirror-0 (SSD) | AHCI (ada0) | Adaptec (da3) | ✓ |
| mirror-1 (HDD 8T) | Adaptec (da0) | Adaptec (da1) | ⚠ both on Adaptec |
| mirror-3 (SSD) | Adaptec (da11) | Adaptec (da5) | ⚠ both on Adaptec |
| mirror-4 (SSD) | AHCI (ada2) | Adaptec (da4) | ✓ |
| mirror-5 (HDD 8T) | Adaptec (da2) | Adaptec (da6) | ⚠ both on Adaptec |
| mirror-6 (HDD 1T) | AHCI (ada1) | AHCI (ada5) | ⚠ both on AHCI |

Single-controller exposure on mirror-1, mirror-3, mirror-5, and mirror-6 is acknowledged but not urgent — controllers have been reliable post-Adaptec install, and mirror-6 is the smallest vdev (candidate for retirement/upgrade). When the new 3.5" enclosure goes in, rebalancing 3.5" mirror halves across enclosures can address enclosure-fault redundancy on mirror-1 and mirror-5.

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
