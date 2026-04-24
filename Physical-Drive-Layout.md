# Physical Drive Layout

Current state of drives, controllers, and ZFS vdev membership on the TrueNAS server (192.168.7.195).

*Last updated: 2026-04-06 — post-PSU swap and AEC-82885T install.*

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
| ada4 | WD Red SA500 / WDS200T1R0A (SATA SSD) | 2 TB | Mir1 | mirror-5 |
| ada5 | WD Red WD10JFCX (2.5" HDD) | 1 TB | Mir1 | mirror-6 |
| ada6 | Seagate ST500LM021 (2.5" HDD) | 500 GB | **boot-pool** | — |
| nvd0 | Intel Optane MEMPEK1J032GAH (NVMe M.2) | 32 GB | Mir1 | **SLOG** |

### Adaptec AEC-82885T expander (via LSI SAS3008)

| Device | Model | Size | Role | Vdev | Expander slot |
|---|---|---|---|---|---|
| da0 | WD Red Plus WD80EFPX (3.5" HDD) | 8 TB | Mir1 | mirror-1 | 4 |
| da1 | Seagate IronWolf ST8000VN004 (3.5" HDD) | 8 TB | Mir1 | mirror-1 | 5 |
| da2 | WD Red Plus WD20EFPX (3.5" HDD) | 2 TB | Mir1 | mirror-3 | 7 |
| da3 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-0 | 9 |
| da4 | WD Red SA500 (SATA SSD) | 2 TB | Mir1 | mirror-4 | 10 |
| da5 | WD Red SA500 / WDS200T1R0A (SATA SSD) | 2 TB | Mir1 | mirror-5 | 11 |
| da9 | Seagate ST2000DM008 Barracuda (3.5" HDD) | 2 TB | Mir1 | mirror-3 *(resilvering, replacing da6)* | 8 |

Expander reports as enclosure #2, logical ID `50000d17:017175be`, 25 slots total.

### USB (legacy external)

| Device | Model | Size | Role | Notes |
|---|---|---|---|---|
| da6 | WD My Passport | 2 TB | Mir1 mirror-3 | **Being replaced by da9.** Will detach after resilver. |
| da7 | Seagate BUP Slim | 2 TB | Backups mirror-0 | |
| da8 | Seagate Portable | 2 TB | Backups mirror-0 | |

## Controller split analysis

Pool redundancy is preserved against single-controller failure for most vdevs:

| vdev | Controller A | Controller B | Split? |
|---|---|---|---|
| mirror-0 (SSD) | AHCI (ada0) | Adaptec (da3) | ✓ |
| mirror-1 (HDD 8T) | Adaptec (da0) | Adaptec (da1) | ⚠ both on Adaptec |
| mirror-3 (HDD 2T) | USB (da6 → Adaptec da9) | Adaptec (da2) | ⚠ after resilver, both Adaptec |
| mirror-4 (SSD) | AHCI (ada2) | Adaptec (da4) | ✓ |
| mirror-5 (SSD) | AHCI (ada4) | Adaptec (da5) | ✓ |
| mirror-6 (HDD 1T) | AHCI (ada1) | AHCI (ada5) | ⚠ both on AHCI |

Single-controller exposure on mirror-1, mirror-3 (after resilver), and mirror-6 is acknowledged but not urgent — the controllers are all reliable, and mirror-6 is the smallest vdev anyway (candidate for retirement/upgrade).

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
