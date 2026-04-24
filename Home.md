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
| OS | TrueNAS CORE 13.3-U1.2 (FreeBSD 13.3-RELEASE-p4, OpenZFS 2.2.5-1) |
| Motherboard | ASUS WS C246 PRO |
| CPU | Intel Core i3-8100 @ 3.60 GHz (ECC-capable via C246) |
| RAM | 32 GB ECC UDIMM (2× 16 GB, 2 of 4 slots populated) |
| PSU | **Seasonic Prime GX-1300** (installed 2026-04-05, single 12V rail) |

### Storage controllers

| Controller | Role |
|---|---|
| Intel Cannon Lake PCH SATA AHCI | Onboard ada0–ada6 (half the pool + L2ARC + boot) |
| LSI SAS3008 (Supermicro AOC-S3008L-L8E, IT mode, `mpr0`) | Slot 3 — HBA for the SAS expander fabric |
| Adaptec AEC-82885T (36-port SAS-3 expander) | Slot 2 (power only), da0–da6 + da11 (8 pool drives) |
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
| Mir1 | **20.9 TB** | 14.6 TB (**69%**) | 6.32 TB | ONLINE — mirror-3 all-SSD, mirror-5 all-8 TB |
| Backups | 1.81 TB | 1.30 TB (71%) | 523 GB | ONLINE (2-way — SMR member ejected 2026-04-23) |
| boot-pool | 448 GB | 3.00 GB | 445 GB | ONLINE (on ada6 500 GB 2.5" spinner; Optane replacement planned) |

See [ZPools](ZPools.md) for the full vdev layout.

## Recent changes

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

ℹ️ **Backups pool is 2-way** and both halves are USB spinners. Treat as cold copy, not real redundancy. **Reattach of the liberated WD Red Plus 2 TB is the next action** — restores 3-way with a CMR internal member.

ℹ️ **mirror-1 and mirror-5 both have both halves on the Adaptec** — single-expander-failure exposure. Acknowledged; the AEC-82885T has been rock-solid since April 2026 install. Next arbitrage cycle on other mirrors can rebalance.

ℹ️ **LSI HBA is slot-limited** to PCIe 3.0 x4 in slot 3. Planned slot swap with the Adaptec (which only needs power) will restore full x8. Next maintenance window.

---

*Last updated: 2026-04-24.*
