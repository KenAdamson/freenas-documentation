# TrueNAS Server Documentation

Documentation for the TrueNAS CORE server (`freenas.local` / `192.168.7.195`).

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
| OS | TrueNAS CORE 13.3-RELEASE-p4 |
| Motherboard | ASUS WS C246 PRO |
| CPU | Intel Core i3-8100 @ 3.60 GHz (ECC-capable via C246) |
| RAM | 32 GB ECC UDIMM (2× 16 GB, 2 of 4 slots populated) |
| PSU | **Seasonic Prime GX-1300** (installed 2026-04-05, single 12V rail) |

### Storage controllers

| Controller | Role |
|---|---|
| Intel Cannon Lake PCH SATA AHCI | Onboard ada0–ada6 (half the pool + L2ARC + boot) |
| LSI SAS3008 (Supermicro AOC-S3008L-L8E, IT mode, `mpr0`) | Slot 3 — HBA for the SAS expander fabric |
| Adaptec AEC-82885T (36-port SAS-3 expander) | Slot 2 (power only), da0–da5 + da9 |
| NVMe M.2_1 | Intel Optane 32 GB — Mir1 SLOG |
| NVMe M.2_2 | empty (planned: second Intel Optane 32 GB for boot) |

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
| Mir1 | 15.4 TB | 13.9 TB (90%) | 1.54 TB | ONLINE *(mirror-3 resilver in progress)* |
| Backups | 1.81 TB | 1.44 TB (79%) | 381 GB | ONLINE |
| boot-pool | 448 GB | 3.00 GB | 445 GB | ONLINE (on ada6 500 GB 2.5" spinner; Optane replacement planned) |

See [ZPools](ZPools.md) for the full vdev layout.

## Recent changes

- **2026-04-06** — Deep audit after the prior night's hardware work. Confirmed dual-uplink wide port at 8 × 12 Gbps from LSI to Adaptec; rewrote Physical-Drive-Layout, SAS-Expander-Configuration, ZPools, and Storage-Expansion-Plan to reflect post-install state. Deleted stale SAS-Expander-Replacement page (work complete).
- **2026-04-05** — **Seasonic Prime GX-1300 PSU** installed. **Adaptec AEC-82885T expander** installed and connected via dual SFF-8643 uplink to the LSI HBA. Seven pool drives migrated onto the expander. mirror-3 replacement initiated (USB WD My Passport → Seagate Barracuda interim). SA500 previously thought dead (mirror-4 warranty drama) turned out to be fine — the problem was power delivery, not the drive.
- **2026-03-23** — Optane 32 GB SLOG installed with Thermalright HR10 2280 PRO heatsink. Side-exhaust fan array + foamcore top seal; SMART thresholds at 40 °C info / 55 °C critical.
- **2026-03-01** — mirror-1 upgraded to 2× 8 TB (WD Red Plus + IronWolf). Optane SLOG ordered.
- **2026-01/02** — HP SAS expander diagnosed as failing; pool drives temporarily migrated to onboard Intel/Marvell SATA. Three ST2000LM015 Seagates failed from the same 2021 batch.

## Alerts

⚠️ **Mir1 at 90%** — in ZFS's performance-cliff zone. Capacity expansion via SSD→8 TB spinner arbitrage is the main pressure. See [Storage Expansion Plan](Storage-Expansion-Plan.md).

⚠️ **mirror-3 resilver in progress** — Seagate Barracuda ST2000DM008 replacing USB WD My Passport. Bottlenecked by reads from the tired USB source (~45 MB/s, ~3 days to completion).

ℹ️ **Backups pool is 2× USB spinners.** Treat as a cold copy, not real redundancy. Longer-term this pool wants internal spinners on the Adaptec.

ℹ️ **LSI HBA is slot-limited** to PCIe 3.0 x4 in slot 3. Planned slot swap with the Adaptec (which only needs power) will restore full x8. Next maintenance window.

---

*Last updated: 2026-04-06.*
