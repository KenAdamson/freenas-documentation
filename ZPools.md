# ZPools Configuration

This page documents all ZPools configured on the TrueNAS server, including their mirrors and individual drives.

## ZPool Overview

| ZPool Name | Size | Allocated | Free | Capacity | Dedup | Status | Last Scrub | Purpose |
|------------|------|-----------|------|----------|-------|--------|------------|---------|
| Mir1       | 9.98TB | 8.86TB | 1.12TB | 88% | 1.25x | ONLINE | March 27, 2025 | Primary data storage |
| freenas-boot | 55.5GB | 20.3GB | 35.2GB | 36% | 1.00x | ONLINE | April 9, 2025 | System boot pool |

## Detailed ZPool Configuration

### Mir1 (Primary Storage)

**Configuration**: 6 mirror vdevs with 2 drives each, plus a cache device
**Size**: 9.98TB total (8.86TB used, 1.12TB free, 88% capacity)
**Deduplication Ratio**: 1.25x
**Fragmentation**: 58%
**Status**: ONLINE
**Last Scrub**: Completed on Thu Mar 27 13:46:51 2025 (repaired 0B in 13:45:53 with 0 errors)

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

### freenas-boot (System Boot Pool)

**Configuration**: Single disk
**Size**: 55.5GB total (20.3GB used, 35.2GB free, 36% capacity)
**Deduplication Ratio**: 1.00x
**Fragmentation**: 2%
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
| Mir1 | 8.92TB | 1019GB | 396KB | /mnt/Mir1 | Root dataset |
| Mir1/Artists | 3.06TB | 1019GB | 3.01TB | /mnt/Mir1/Artists | Artist files |
| Mir1/Documents | 128KB | 1019GB | 128KB | /mnt/Mir1/Documents | Document storage |
| Mir1/Files | 888GB | 1019GB | 888GB | /mnt/Mir1/Files | General file storage |
| Mir1/Music | 18.7MB | 1019GB | 18.7MB | /mnt/Mir1/Music | Music files |
| Mir1/Photography | 245GB | 1019GB | 245GB | /mnt/Mir1/Photography | Photography files |
| Mir1/Pictures | 172KB | 1019GB | 172KB | /mnt/Mir1/Pictures | Picture storage |
| Mir1/Projects | 35.5GB | 1019GB | 35.5GB | /mnt/Mir1/Projects | Project files |
| Mir1/media | 4.71TB | 1019GB | 4.70TB | /mnt/Mir1/media | Media storage |
| Mir1/sonolux | 88KB | 1019GB | 88KB | /mnt/Mir1/sonolux | Sonolux data |
| Mir1/proxy-cache | 348KB | 1019GB | 348KB | /mnt/Mir1/proxy-cache | Proxy cache |

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

To view the complete dataset structure, run:

```bash
zfs list
```

## ZPool Performance Statistics

To view performance statistics for all ZPools, run:

```bash
zpool iostat -v
```

*Note: This documentation is based on the zpool status, list, and zfs list outputs from April 12, 2025.*
