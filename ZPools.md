# ZPools Configuration

This page documents all ZPools configured on the TrueNAS server, including their mirrors and individual drives.

## ZPool Overview

| ZPool Name | Size | Allocated | Free | Capacity | Dedup | Status | Last Resilver | Purpose |
|------------|------|-----------|------|----------|-------|--------|---------------|---------|
| Mir1       | 9.98TB | 9.78TB | ~200GB | 97% | 1.25x | ONLINE | Feb 4, 2026 (1.78T, 0 errors) | Primary data storage |
| Backups    | 1.81TB | 67GB | 1.75TB | 3% | 1.00x | ONLINE | Aug 11, 2025 | External USB backup storage |
| freenas-boot | 55.5GB | 20.3GB | 35.2GB | 36% | 1.00x | ONLINE | Apr 9, 2025 | System boot pool |

## Detailed ZPool Configuration

### Mir1 (Primary Storage)

**Configuration**: 6 mirror vdevs with 2 drives each, plus L2ARC cache
**Size**: 9.98TB total (~97% capacity)
**Deduplication Ratio**: 1.25x
**Status**: ONLINE
**Last Resilver**: Completed Wed Feb 4 10:54:17 2026 (resilvered 1.78T in 13:14:39, 0 errors)

**Current Drive Topology**:
- **Mirrors 0, 4, 5**: WD Red SA500 / WDS200T1R0A 2TB SATA SSDs (fully solid-state)
- **Mirror 1**: 1x USB Seagate (temporary) + 1x ST2000LM015 Seagate 2TB HDD (last surviving Seagate, expected to fail)
- **Mirror 3**: 1x USB WD My Passport (temporary) + 1x WD Red Plus WD20EFPX 2TB 3.5" HDD
- **Mirror 6**: 2x WD Red WD10JFCX 1TB 2.5" HDDs

**Current Issues**:
- Pool remains at ~97% capacity
- mirror-1 and mirror-3 each have one USB drive as a temporary member
- mirror-1's Seagate ST2000LM015 is the last of a batch of 4 that all failed; expected to die soon
- mirror-6 has 1TB drives (smallest mirrors in the pool)
- 1x 8TB WD Red Plus ordered to begin replacing mirror-1's temporary drives

**Recent Events (January-February 2026)**:
- HP SAS expander diagnosed as failing; all pool drives migrated to Intel/Marvell SATA controllers
- 3x Seagate ST2000LM015 2TB drives failed (from same 2021 Amazon batch)
- USB drives pressed into emergency service for mirror-1 and mirror-3
- SMART monitoring configured with proper thresholds and scheduled tests

#### mirror-0 (SSD)
| Drive | Device | Model | State | Read | Write | Cksum |
|-------|--------|-------|-------|------|-------|-------|
| gptid/4f7b78d1-d17d-11ef-8a75-b496913a6fde | ada1 | WD Red SA500 2TB SSD | ONLINE | 0 | 0 | 0 |
| gptid/4cffd486-d1af-11ef-8a75-b496913a6fde | ada11 | WD Red SA500 2TB SSD | ONLINE | 0 | 0 | 0 |

#### mirror-1 (HDD + USB, temporary)
| Drive | Device | Model | State | Read | Write | Cksum |
|-------|--------|-------|-------|------|-------|-------|
| da5p1 | da4 (USB) | Seagate BUP Slim (USB 3.0) | ONLINE | 0 | 0 | 0 |
| gptid/5a9d8d43-9778-11eb-bb15-d45d643eabc1 | ada6 | ST2000LM015 Seagate 2TB HDD | ONLINE | 0 | 0 | 0 |

#### mirror-3 (HDD + USB, temporary)
| Drive | Device | Model | State | Read | Write | Cksum |
|-------|--------|-------|-------|------|-------|-------|
| gptid/e867be29-ed8c-11f0-9c07-b496913a6fde | da3 (USB) | WD My Passport (USB 3.0) | ONLINE | 0 | 0 | 0 |
| ada8p2 | ada7 | WD Red Plus WD20EFPX 2TB 3.5" HDD | ONLINE | 0 | 0 | 0 |

#### mirror-4 (SSD)
| Drive | Device | Model | State | Read | Write | Cksum |
|-------|--------|-------|-------|------|-------|-------|
| gptid/4b17ad79-13e6-11ef-af29-b496913a6fde | ada2 | WD Red SA500 2TB SSD | ONLINE | 0 | 0 | 0 |
| gptid/f613b9f9-1407-11ef-af29-b496913a6fde | ada10 | WD Red SA500 2TB SSD | ONLINE | 0 | 0 | 0 |

#### mirror-5 (SSD)
| Drive | Device | Model | State | Read | Write | Cksum |
|-------|--------|-------|-------|------|-------|-------|
| gptid/b9bb4736-6a05-11ee-8632-b496913a6fde | ada9 | WDC WDS200T1R0A 2TB SSD | ONLINE | 0 | 0 | 0 |
| gptid/7e75d4d4-69eb-11ee-8632-b496913a6fde | ada0 | WDC WDS200T1R0A 2TB SSD | ONLINE | 0 | 0 | 0 |

#### mirror-6 (HDD)
| Drive | Device | Model | State | Read | Write | Cksum |
|-------|--------|-------|-------|------|-------|-------|
| gptid/53cb5f22-14a9-11f0-ae6a-b496913a6fde | ada8 | WD Red WD10JFCX 1TB 2.5" HDD | ONLINE | 0 | 0 | 0 |
| gptid/53c00b9b-14a9-11f0-ae6a-b496913a6fde | ada3 | WD Red WD10JFCX 1TB 2.5" HDD | ONLINE | 0 | 0 | 0 |

#### L2ARC Cache
| Drive | Device | Model | State | Read | Write | Cksum |
|-------|--------|-------|-------|------|-------|-------|
| gptid/21b92d71-98b9-11eb-8ea4-d45d643eabc1 | ada5 | Samsung SSD 840 EVO 250GB | ONLINE | 0 | 0 | 0 |

#### Non-Pool Drive on SAS Expander
| Device | Model | Notes |
|--------|-------|-------|
| da0 | TEAM T253X2001T 1TB SSD | Connected via failing HP SAS expander. Not in any pool. Windows partition table. To be removed during expander replacement. |

### Backups (External USB Storage)

**Configuration**: 1 mirror vdev with 2 USB drives
**Size**: 1.81TB total (67GB used, 1.75TB free, 3% capacity)
**Deduplication Ratio**: 1.00x
**Status**: ONLINE
**Last Scrub**: Completed on Mon Aug 11 05:22:16 2025 (resilvered 108K in 00:00:01 with 0 errors)
**Purpose**: External USB backup storage, currently used for interim overflow storage

#### mirror-0
| Drive | State | Read Errors | Write Errors | Checksum Errors |
|-------|-------|-------------|--------------|-----------------|
| gptid/3c181d7a-7640-11f0-80f9-b496913a6fde | ONLINE | 0 | 0 | 0 |
| gptid/3c937477-7640-11f0-80f9-b496913a6fde | ONLINE | 0 | 0 | 0 |

**Interim Storage Configuration (October 2025)**:
- Created `/mnt/Backups/movies_02` directory for overflow movie storage
- Mounted via nullfs to `/mnt/Mir1/media/movies_2` to provide seamless access through existing NFS share
- Mount persists across reboots via `/etc/fstab` entry
- Accessible on NFS clients as `/mnt/media/movies_2` with 1.7TB available space
- **This is a temporary solution until da1 and da11 are replaced with 2TB drives**

### freenas-boot (System Boot Pool)

**Configuration**: Single disk
**Size**: 55.5GB total (20.3GB used, 35.2GB free, 36% capacity)
**Deduplication Ratio**: 1.00x
**Fragmentation**: 3%
**Status**: ONLINE
**Last Scrub**: Completed on Wed Apr 9 03:46:06 2025 (repaired 0B in 00:01:06 with 0 errors)
**Note**: Some supported features are not enabled on the pool. The pool can still be used, but some features are unavailable. Enable all features using 'zpool upgrade'.

| Drive | State | Read Errors | Write Errors | Checksum Errors |
|-------|-------|-------------|--------------|-----------------|
| ada0p2 | ONLINE | 0 | 0 | 0 |

## ZPool Health Status

To check the current status of all ZPools, run:

```bash
zpool status
```

## ZPool Size and Allocation

To view size and allocation information for all ZPools, run:

```bash
zpool list
```

## ZFS Datasets

The TrueNAS server has the following dataset structure:

### Mir1 Datasets

| Dataset | Used | Available | Referenced | Mount Point | Purpose |
|---------|------|-----------|------------|-------------|---------|
| Mir1 | 9.84TB | 71GB | 396KB | /mnt/Mir1 | Root dataset |
| Mir1/Artists | 3.1TB | 71GB | 3.1TB | /mnt/Mir1/Artists | Artist files (98% full) |
| Mir1/Documents | 128KB | 71GB | 128KB | /mnt/Mir1/Documents | Document storage |
| Mir1/Files | 850GB | 71GB | 850GB | /mnt/Mir1/Files | General file storage (92% full) |
| Mir1/Music | 19MB | 71GB | 19MB | /mnt/Mir1/Music | Music files |
| Mir1/Photography | 245GB | 71GB | 245GB | /mnt/Mir1/Photography | Photography files |
| Mir1/Pictures | 172KB | 71GB | 172KB | /mnt/Mir1/Pictures | Picture storage |
| Mir1/Projects | 36GB | 71GB | 36GB | /mnt/Mir1/Projects | Project files |
| Mir1/media | 5.63TB | 71GB | 5.63TB | /mnt/Mir1/media | Media storage (99% full) |
| Mir1/media/movies_2 | - | 1.7TB | - | /mnt/Mir1/media/movies_2 | **Nullfs mount to /mnt/Backups/movies_02** (interim overflow) |
| Mir1/sonolux | 88KB | 71GB | 88KB | /mnt/Mir1/sonolux | Sonolux data |
| Mir1/proxy-cache | 348KB | 71GB | 348KB | /mnt/Mir1/proxy-cache | Proxy cache |

#### Jail Datasets

| Dataset | Used | Available | Referenced | Mount Point | Purpose |
|---------|------|-----------|------------|-------------|---------|
| Mir1/iocage | 3.41GB | 1019GB | 65.5MB | /mnt/Mir1/iocage | iocage jail management |
| Mir1/jails | 2.99GB | 1019GB | 54.9MB | /mnt/Mir1/jails | Jail storage |

#### System Datasets

| Dataset | Used | Available | Referenced | Mount Point | Purpose |
|---------|------|-----------|------------|-------------|---------|
| Mir1/.system | 622MB | 1019GB | 120KB | legacy | System data |
| Mir1/.system/configs-* | 44.1MB | 1019GB | 43.1MB | legacy | System configurations |
| Mir1/.system/cores | 352KB | 1024MB | 96KB | legacy | Core dumps |
| Mir1/.system/rrd-* | 565MB | 1019GB | 39.0MB | legacy | RRD statistics |
| Mir1/.system/samba4 | 2.18MB | 1019GB | 252KB | legacy | Samba configuration |
| Mir1/.system/services | 96KB | 1019GB | 96KB | legacy | Services data |
| Mir1/.system/syslog-* | 9.46MB | 1019GB | 5.46MB | legacy | System logs |
| Mir1/.system/webui | 96KB | 1019GB | 96KB | legacy | Web UI data |

### freenas-boot Datasets

The boot pool contains multiple boot environments for TrueNAS system updates:

| Dataset | Used | Available | Referenced | Mount Point | Notes |
|---------|------|-----------|------------|-------------|-------|
| freenas-boot | 20.3GB | 33.5GB | 64KB | none | Boot pool |
| freenas-boot/ROOT | 20.2GB | 33.5GB | 29KB | none | Boot environments |
| freenas-boot/ROOT/13.0-U6.7 | 20.2GB | 33.5GB | 1.30GB | / | Current boot environment |
| freenas-boot/grub | 7.17MB | 33.5GB | 7.17MB | legacy | Boot loader |

The boot pool contains multiple boot environments from previous TrueNAS versions, allowing for rollback if needed. The current active boot environment is 13.0-U6.7.

### Backups Datasets

| Dataset | Used | Available | Referenced | Mount Point | Purpose |
|---------|------|-----------|------------|-------------|---------|
| Backups | 67GB | 1.69TB | 96KB | /mnt/Backups | Root dataset |
| Backups/korbin | 67GB | 1.69TB | 67GB | /mnt/Backups/korbin | Korbin's backup data |
| Backups/movies_02 | minimal | 1.69TB | minimal | /mnt/Backups/movies_02 | Interim overflow storage for movies |

**Note**: `Backups/movies_02` is mounted via nullfs to `/mnt/Mir1/media/movies_2` and is accessible through the existing NFS share at `/mnt/media/movies_2` on NFS clients.

To view the complete dataset structure, run:

```bash
zfs list
```

## ZPool Performance Statistics

To view performance statistics for all ZPools, run:

```bash
zpool iostat -v
```

---

## Drive Controller Topology

Since January 2026, all pool drives have been migrated off the failing HP SAS expander onto direct SATA controllers:

| Controller | Bus | Drives | Notes |
|------------|-----|--------|-------|
| Intel Cannon Lake PCH SATA | scbus1-8, scbus10 | ada0-ada6 | Onboard, 6 Gb/s per port |
| Marvell 88SE9215 | scbus12-13 | ada7-ada12 | PCIe, 3 direct ports + 1 port multiplier (5 ports) |
| HP SAS Expander (via LSI HBA) | scbus0 | da0 only | Failing. Only non-pool TeamGroup SSD remains connected |
| USB | scbus14-17 | da1-da4 | Temporary pool members (da3 in mirror-3, da4 in mirror-1) |

**Note**: Device names (ada#, da#) may shift across reboots or drive events. ZFS tracks drives by GPTID internally. The device names shown in `zpool status` reflect the name at the time the drive was added or last replaced.

## Recent Updates

**February 4, 2026**:
- Pool is ONLINE after series of drive failures and resilvers
- 3x Seagate ST2000LM015 drives failed and removed (from same 2021 batch)
- Faulted ada3 (Seagate) replaced by USB Seagate in mirror-1 via `zpool replace`
- USB WD My Passport serving as temporary member of mirror-3
- All drives migrated off failing HP SAS expander to Intel/Marvell SATA
- SMART monitoring configured: temperature thresholds, weekly short tests, monthly long tests
- 1x 8TB WD Red Plus WD80EFPX ordered for mirror-1 upgrade

**October 15, 2025**:
- Updated pool capacity information
- Added Backups pool documentation (1.81TB external USB storage)
- Documented interim storage solution: nullfs mount for overflow storage
- Identified upgrade path for 1TB drives

**April 12, 2025**:
- Initial comprehensive documentation created

*Last updated: February 5, 2026*
