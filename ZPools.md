# ZPools Configuration

This page documents all ZPools configured on the TrueNAS server, including their mirrors and individual drives.

## ZPool Overview

| ZPool Name | Size | Allocated | Free | Capacity | Dedup | Status | Last Scrub | Purpose |
|------------|------|-----------|------|----------|-------|--------|------------|---------|
| Mir1       | 9.98TB | 9.79TB | 199GB | 98% | 1.25x | ONLINE | September 21, 2025 | Primary data storage |
| Backups    | 1.81TB | 67GB | 1.75TB | 3% | 1.00x | ONLINE | August 11, 2025 | External USB backup storage |
| freenas-boot | 55.5GB | 20.3GB | 35.2GB | 36% | 1.00x | ONLINE | April 9, 2025 | System boot pool |

## Detailed ZPool Configuration

### Mir1 (Primary Storage)

**Configuration**: 6 mirror vdevs with 2 drives each, plus a cache device
**Size**: 9.98TB total (9.79TB used, 199GB free, 98% capacity)
**Deduplication Ratio**: 1.25x
**Fragmentation**: 64%
**Status**: ONLINE - **CRITICAL: Pool is 98% full**
**Last Scrub**: Completed on Sun Sep 21 12:58:34 2025 (repaired 0B in 12:58:33 with 0 errors)

**Current Issues**:
- Pool is critically full at 98% capacity
- Only 199GB free at pool level, ~71GB available at dataset level
- Requires immediate attention: replace 1TB drives (da1, da11) with 2TB drives

#### mirror-0
| Drive | State | Read Errors | Write Errors | Checksum Errors |
|-------|-------|-------------|--------------|-----------------|
| gptid/4f7b78d1-d17d-11ef-8a75-b496913a6fde | ONLINE | 0 | 0 | 0 |
| gptid/4cffd486-d1af-11ef-8a75-b496913a6fde | ONLINE | 0 | 0 | 0 |

#### mirror-1
| Drive | State | Read Errors | Write Errors | Checksum Errors |
|-------|-------|-------------|--------------|-----------------|
| gptid/017ac5ca-9656-11eb-bb15-d45d643eabc1 | ONLINE | 0 | 0 | 0 |
| gptid/5a9d8d43-9778-11eb-bb15-d45d643eabc1 | ONLINE | 0 | 0 | 0 |

#### mirror-3
| Drive | State | Read Errors | Write Errors | Checksum Errors |
|-------|-------|-------------|--------------|-----------------|
| gptid/0f3f574a-9748-11eb-bb15-d45d643eabc1 | ONLINE | 0 | 0 | 0 |
| gptid/dea802f8-9655-11eb-bb15-d45d643eabc1 | ONLINE | 0 | 0 | 0 |

#### mirror-4
| Drive | State | Read Errors | Write Errors | Checksum Errors |
|-------|-------|-------------|--------------|-----------------|
| gptid/4b17ad79-13e6-11ef-af29-b496913a6fde | ONLINE | 0 | 0 | 0 |
| gptid/f613b9f9-1407-11ef-af29-b496913a6fde | ONLINE | 0 | 0 | 0 |

#### mirror-5
| Drive | State | Read Errors | Write Errors | Checksum Errors |
|-------|-------|-------------|--------------|-----------------|
| gptid/b9bb4736-6a05-11ee-8632-b496913a6fde | ONLINE | 0 | 0 | 0 |
| gptid/7e75d4d4-69eb-11ee-8632-b496913a6fde | ONLINE | 0 | 0 | 0 |

#### mirror-6
| Drive | State | Read Errors | Write Errors | Checksum Errors |
|-------|-------|-------------|--------------|-----------------|
| gptid/53cb5f22-14a9-11f0-ae6a-b496913a6fde | ONLINE | 0 | 0 | 0 |
| gptid/53c00b9b-14a9-11f0-ae6a-b496913a6fde | ONLINE | 0 | 0 | 0 |

#### Cache Device
| Drive | State | Read Errors | Write Errors | Checksum Errors |
|-------|-------|-------------|--------------|-----------------|
| gptid/21b92d71-98b9-11eb-8ea4-d45d643eabc1 | ONLINE | 0 | 0 | 0 |

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

## Recent Updates

**October 15, 2025**:
- Updated pool capacity information: Mir1 is now at 98% capacity (9.79TB used, 199GB free)
- Added Backups pool documentation (1.81TB external USB storage)
- Documented interim storage solution: nullfs mount from /mnt/Backups/movies_02 to /mnt/Mir1/media/movies_2
- Updated dataset usage information to reflect current state
- Added critical status warnings for nearly full datasets
- Identified upgrade path: replace da1 and da11 (1TB drives) with 2TB drives

**April 12, 2025**:
- Initial comprehensive documentation created
- Documented all ZPools, datasets, and physical drive layout

*Last updated: October 15, 2025*
