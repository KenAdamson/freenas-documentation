# Storage Expansion Plan

This document outlines the phased approach to expanding storage capacity on the TrueNAS server to address the current critical storage situation (Mir1 at 98% capacity).

## Current Situation (October 2025)

- **Mir1 ZPool**: 9.98TB total, 9.79TB used (98% full) - **CRITICAL**
- **Available Space**: Only 199GB at pool level, ~71GB at dataset level
- **Interim Solution**: 1.7TB overflow via Backups pool (USB drives) mounted at `/mnt/media/movies_2` and `/mnt/media/temp_2`
- **Bottleneck Drives**: 2x 1TB WD Blue drives (da1, da11) - non-NAS rated, mechanical disks in otherwise all-SSD pool

## Phased Expansion Plan

### Phase 1: Emergency Stopgap (Immediate - October 2025)

**Goal**: Add ~2TB usable capacity quickly using available hardware

**Hardware**:
- 4x 1TB 2.5" SATA drives (spinning rust, available from previous NAS generation)
- Marvell 88SE9215 4-port SATA controller (already installed, currently unused)
- Standard SATA cables

**Implementation**:
1. Connect 4x 1TB SATA drives to the Marvell controller (scbus9/ahci1)
2. Add drives as 2 new mirror vdevs to existing Mir1 ZPool:
   - `mirror-7`: 2x 1TB drives
   - `mirror-8`: 2x 1TB drives
3. **Result**: +2TB usable capacity to Mir1

**Advantages**:
- Immediate capacity increase
- Uses existing hardware
- No additional cost
- Maintains ZFS redundancy with mirrored vdevs
- Mechanical drives are adequate for sequential media storage

**Limitations**:
- Drives are mechanical (slower than SSD pool)
- No SAS expander redundancy (direct SATA connection)
- Lower reliability than NAS-rated drives
- **Interim solution only** - these drives will be migrated in Phase 3

**Post-Phase 1 Capacity**:
- Mir1 ZPool: 9.98TB → 11.98TB total
- Available space: ~2TB additional

### Phase 2: Replace Bottleneck Drives (Q4 2025 / Q1 2026)

**Goal**: Replace non-NAS mechanical drives with proper 2TB SSDs

**Hardware Needed**:
- 2x 2TB NAS-rated 2.5" SATA SSDs
  - Recommended: WD Red SA500 2.5" or similar
  - Cost: ~$100-150 per drive ($200-300 total)

**Drives to Replace**:
- **da1**: WDC WD10JFCX-68N (1TB, WD Blue, non-NAS)
  - Location: Cage 0, Slot 1
  - Mirror: mirror-1 with da4
  - Fanout: 2C Port P2
- **da11**: WDC WD10JFCX-68N (1TB, WD Blue, non-NAS)
  - Location: Cage 0, Slot 5
  - Mirror: mirror-3 with da1
  - Fanout: 6C Port P1

**Implementation**:
1. For each drive:
   ```bash
   # Replace da1 in mirror-1
   zpool offline Mir1 da1
   # Physical: Remove old drive, install new 2TB SSD
   zpool replace Mir1 da1 /dev/da1
   # Wait for resilver to complete

   # Replace da11 in mirror-3
   zpool offline Mir1 da11
   # Physical: Remove old drive, install new 2TB SSD
   zpool replace Mir1 da11 /dev/da11
   # Wait for resilver to complete
   ```

2. ZFS will automatically resilver the new drives from their mirror partners

**Result**: +1TB usable capacity (2x 1TB → 2x 2TB in mirrored configuration)

**Post-Phase 2 Capacity**:
- Mir1 ZPool: 11.98TB → 12.98TB total
- All drives in pool are now SSD
- Eliminated non-NAS drives from primary pool

### Phase 3: Major Expansion - Second HBA & Expander (2026)

**Goal**: Add significant capacity with proper redundancy and future scalability

**Hardware Needed**:
1. **Second SAS HBA**: Supermicro AOC-S3008L-L8E or LSI 9300-8i
   - Cost: ~$70-80 (used market)
   - Provides 8 more SAS lanes with dual uplink capability

2. **Second SAS Expander**: HP 487738-001 or similar 36-port expander
   - Cost: ~$40-50 (used market)
   - Matches existing expander configuration

3. **Cables**:
   - 2x SFF-8643 to SFF-8087 uplink cables (HBA to expander)
   - 3-6x SFF-8087 to SATA fanout cables (expander to drives)
   - Cost: ~$40-60 total

4. **Drive Enclosures**:
   - 2x IcyDock MB326SP-B 6x 2.5" hot-swap cages
   - Cost: ~$200-250 total

5. **Drives**:
   - 12x 2TB or 4TB 2.5" SATA SSDs
   - Cost: Varies based on capacity and sales

**Total Hardware Cost**: ~$400-500 (before drives)

**Implementation**:
1. Install second HBA in available PCIe slot (likely the x16 slot)
2. Install second SAS expander in chassis
3. Cable dual uplinks from HBA to expander (8C and 3C ports for redundancy)
4. Install drive cages (may require chassis modification or external enclosure)
5. Connect fanout cables from expander to drive cages
6. Migrate the 4x 1TB SATA drives from Phase 1 to the new cages
   - This converts them from direct SATA to SAS expander connection
   - Provides redundant paths and better integration
7. Add 8 more drives to fill out the cages
8. Create new mirror vdevs and add to Mir1 (or create Mir2 pool)

**Result**: +12-24TB additional capacity (depending on drive sizes chosen)

**Post-Phase 3 Capacity**:
- Option A: Expand Mir1 with new vdevs
  - Mir1 ZPool: 12.98TB → 24.98TB+ total (with 12x 2TB drives)
- Option B: Create new Mir2 pool
  - Keep Mir1 at 12.98TB
  - New Mir2: ~12TB (with 12x 2TB drives in 6 mirrors)
  - Allows separation of workloads and datasets

**Configuration Benefits**:
- Dual HBA setup provides separation and fault isolation
- Each HBA + expander can operate independently
- Maintains dual uplink redundancy on both channels
- Scalable to 24+ drives with proper cabling
- Hot-swap capability with IcyDock cages

## Current Interim Solutions (Active)

While planning the above phases, these solutions are in place:

### Backups Pool Overflow Storage
- **Location**: `/mnt/Backups/movies_02` and `/mnt/Backups/temp_02`
- **Mount Points**:
  - `/mnt/Mir1/media/movies_2` (via nullfs)
  - `/mnt/Mir1/media/temp_2` (via nullfs)
- **Access**: Available through NFS as `/mnt/media/movies_2` and `/mnt/media/temp_2`
- **Capacity**: 1.7TB available
- **Purpose**: Temporary overflow for downloads and media
- **Connection**: USB 3.0 external drives in ZFS mirror
- **Limitation**: 1GbE transfer speed bottleneck

### External Criterion Drive
- **Location**: `/mnt/criterion`
- **Capacity**: 2.8TB XFS (USB 3.0 external drive)
- **Purpose**: Temporary storage for active downloads
- **Status**: Currently being migrated away from to use Backups pool instead

## Timeline Recommendations

| Phase | Target Date | Cost | Capacity Gain | Priority |
|-------|-------------|------|---------------|----------|
| Phase 1: 4x 1TB SATA | Immediate | $0 (existing drives) | +2TB | **URGENT** |
| Phase 2: Replace 1TB drives | Q1 2026 | ~$250 | +1TB | High |
| Phase 3: Second HBA/Expander | Q2-Q3 2026 | ~$400-500 + drives | +12-24TB | Medium |

## Success Metrics

**Phase 1 Success**:
- Mir1 pool drops below 85% capacity
- All active downloads can complete without space issues
- Backups pool can be reserved for actual backups

**Phase 2 Success**:
- All drives in main pool are SSD
- No more non-NAS rated drives in production
- Pool performance improves (no mechanical drive bottleneck)

**Phase 3 Success**:
- Total storage capacity exceeds 20TB usable
- Dual HBA configuration provides better throughput and redundancy
- Phase 1 SATA drives successfully migrated to proper expander connection
- Hot-swap capability fully implemented

## Alternative Considerations

### Option: Replace Phase 1 drives with larger SSDs instead of mechanical
- **Pros**: Better performance, more reliable
- **Cons**: Higher cost (~$400 for 4x 2TB SSDs)
- **Verdict**: Not recommended - mechanical drives adequate for Phase 1 stopgap

### Option: Skip Phase 2, go straight to Phase 3
- **Pros**: Fewer steps, more capacity sooner
- **Cons**: Higher upfront cost, longer timeline for critical relief
- **Verdict**: Not recommended - Phase 1 provides immediate relief at no cost

### Option: Use Backups pool permanently instead of Phase 1
- **Pros**: No hardware work required
- **Cons**: USB 3.0 performance limitations, not integrated into main pool
- **Verdict**: Current approach (using both) is optimal

## Notes

- All phases maintain ZFS redundancy (mirrors)
- Hot-swap procedures documented in Physical-Drive-Layout.md
- Drive replacement procedures documented in Physical-Drive-Layout.md
- Keep stock of spare drives for any failures during transitions
- Test resilver times before committing to large migrations
- Phase 3 may require chassis modifications for additional drive cage mounting

## Related Documentation

- [ZPools Overview](ZPools.md) - Current pool configuration
- [Physical Drive Layout](Physical-Drive-Layout.md) - Drive locations and mappings
- [SAS Expander Configuration](SAS-Expander-Configuration.md) - Current HBA/expander setup
- [Maintenance Procedures](Maintenance-Procedures.md) - Drive replacement procedures

---

*Created: October 15, 2025*
*Last Updated: October 15, 2025*
