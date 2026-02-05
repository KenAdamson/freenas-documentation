# Storage Expansion Plan

This document outlines the phased approach to stabilizing and expanding storage capacity on the TrueNAS server.

## Current Situation (February 2026)

- **Mir1 ZPool**: ~9.98TB total, ~97% full — ONLINE but critically low on space
- **3 Seagate ST2000LM015 failures**: All from the same 2021 Amazon batch. 4th Seagate (ada6) still running but expected to fail
- **mirror-1**: Running on USB Seagate (temporary) + last Seagate HDD (ada6) — vulnerable
- **mirror-3**: Running on USB WD My Passport (temporary) + WD Red Plus 2TB HDD — stable but slow
- **mirror-6**: 2x WD Red WD10JFCX 1TB 2.5" HDDs — smallest mirrors in the pool
- **HP SAS Expander**: Failing, all pool drives migrated to Intel/Marvell SATA controllers
- **SMART Monitoring**: Configured with temperature thresholds, weekly short tests, monthly long tests

## Phased Expansion Plan

### Phase 1: Stabilize mirror-1 (Ordered)

**Goal**: Get mirror-1 off the dying Seagate and USB drive onto reliable internal storage

**Hardware**: 1x WD Red Plus 8TB (WD80EFPX) — $210 (ordered)

**Steps**:
1. When drive arrives, partition and attach to mirror-1
2. Resilver onto the 8TB drive
3. Keep USB Seagate as temporary 3rd mirror member for safety during transition
4. Once stable, the 8TB drive + ada6 (Seagate) form mirror-1

**Result**: mirror-1 has one trustworthy drive. If ada6 dies, the 8TB WD Red holds the data safely until Phase 2.

### Phase 2: Complete mirror-1 (Next Purchase Window)

**Goal**: Fully replace mirror-1 with WD Red Plus drives

**Hardware**: 1x WD Red Plus 8TB (WD80EFPX) — $210

**Steps**:
1. Attach second 8TB to mirror-1
2. Resilver
3. Detach ada6 (last Seagate) and USB drive from mirror-1
4. mirror-1 is now 2x 8TB WD Red Plus

**Result**: mirror-1 is fully stable on NAS-rated drives. Pool capacity grows as ZFS expands the mirror to use the full 8TB. USB drive freed up.

### Phase 3: Upgrade mirror-3 (When Budget Allows)

**Goal**: Replace USB drive in mirror-3 with proper internal storage

**Hardware**: 2x WD Red Plus 8TB (WD80EFPX) — $420

**Steps**:
1. Attach first 8TB to mirror-3, resilver
2. Attach second 8TB to mirror-3, resilver
3. Detach USB WD My Passport and existing WD Red Plus 2TB from mirror-3
4. mirror-3 is now 2x 8TB WD Red Plus

**Result**: mirror-3 fully internal on NAS-rated drives. Pool capacity grows again. All USB drives removed from pool.

### Future: SAS Expander Replacement

**Goal**: Replace failing HP SAS expander with Adaptec AEC-82885T for proper SAS-3 (12 Gb/s) backhaul

**Hardware**: Adaptec AEC-82885T + SFF-8643 cables

**Steps**: See [SAS Expander Replacement](SAS-Expander-Replacement) for full details. When replaced:
1. Remove TeamGroup T253X2001T SSD (only remaining device on HP expander)
2. Install Adaptec AEC-82885T (direct PCIe power, no riser needed)
3. Migrate drives from Intel/Marvell SATA controllers back to SAS expander path
4. Full 12 Gb/s SAS-3 backhaul to all drives via LSI SAS3008 HBA

### Future: Network Upgrade

**Goal**: Upgrade to 20 Gb/s network with SFP+ NIC

**Notes**: SFP+ NIC installation planned. Will provide 20 Gb/s aggregate network bandwidth. Current pool read throughput (~422 MB/s from cache, striped across 12 drives) is well within 10 GbE capacity. The 20 Gb/s link provides headroom for concurrent workloads (Plex streaming + audio/video editing over SMB).

## Cost Summary

| Phase | Hardware | Cost | Capacity Impact |
|-------|----------|------|-----------------|
| Phase 1 | 1x WD Red Plus 8TB | $210 | Stabilizes mirror-1 |
| Phase 2 | 1x WD Red Plus 8TB | $210 | mirror-1 grows to 8TB |
| Phase 3 | 2x WD Red Plus 8TB | $420 | mirror-3 grows to 8TB |
| **Total** | **4x WD Red Plus 8TB** | **$840** | **+12TB usable capacity** |

## SSD Migration (On Hold)

Mirrors 0, 4, and 5 are already fully SSD (WD Red SA500 / WDS200T1R0A 2TB). An all-SSD pool would eliminate noise, reduce power draw and heat, and improve random IO latency for editing workloads over SMB.

However, the WD Red SA500 SATA SSD line is being discontinued and prices have spiked due to AI data center demand consuming NAND flash supply:
- 1TB WD Red SA500: $288 ($288/TB)
- 2TB WD Red SA500: unavailable
- 8TB WD Red SA500: $850 ($106/TB)

SSD migration is not economical at current pricing. The mechanical drives in mirrors 1, 3, and 6 do not bottleneck the primary workload (Plex streaming, file serving over 10 GbE). For the audio/video editing workload, ZFS striping across all mirrors means the SSD mirrors handle the latency-sensitive random IO while the HDDs contribute sequential bandwidth.

## Seagate ST2000LM015 Failure History

All four drives were 2.5" laptop HDDs (non-NAS rated) purchased from the same Amazon listing in 2021:

| Serial | Failure | Date |
|--------|---------|------|
| (removed) | Dead, pulled from system | Jan 2026 |
| ZDZFEZSH | Dead, pulled from system | Jan 2026 |
| (ada3/faulted) | FAULTED with 185 read / 1.63K write / 568 cksum errors, replaced by USB drive | Feb 2026 |
| ZDZFEZNY (ada6) | Still running, expected to fail | — |

**Lesson learned**: Non-NAS-rated laptop drives from bulk Amazon listings are not suitable for 24/7 NAS operation. All replacements are NAS-rated (WD Red Plus).

## Related Documentation

- [ZPools Overview](ZPools) - Current pool configuration and drive mapping
- [Physical Drive Layout](Physical-Drive-Layout) - Drive locations and connections
- [SAS Expander Replacement](SAS-Expander-Replacement) - Failing expander diagnosis and replacement plan
- [Maintenance Procedures](Maintenance-Procedures) - SMART monitoring, drive replacement procedures

---

*Created: October 15, 2025*
*Last Updated: February 5, 2026*
