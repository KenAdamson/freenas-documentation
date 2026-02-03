# TrueNAS Server Documentation

Welcome to the comprehensive documentation for our TrueNAS server. This wiki contains detailed information about the server's configuration, including:

- [ZPools Overview](ZPools.md)
- [Physical Drive Layout](Physical-Drive-Layout.md)
- [SAS Expander Configuration](SAS-Expander-Configuration.md)
- [Maintenance Procedures](Maintenance-Procedures.md)
- [Troubleshooting Guide](Troubleshooting-Guide.md)
- [Drive Stress Test](Drive-Stress-Test.md)
- [SAS Expander Replacement](SAS-Expander-Replacement.md)

## Server Specifications

- **System Manufacturer**: ASUSTeK COMPUTER INC.
- **Product Name**: System Product Name
- **System Family**: Server
- **TrueNAS version**: TrueNAS-12.0-U8 (based on FreeBSD)
- **CPU**: Intel(R) Core(TM) i3-8100 CPU @ 3.60GHz
- **RAM**: 32 GB (2x 16GB modules)
- **Physical Memory**: 31.74 GB (34,086,277,120 bytes)
- **Storage Controllers**:
  - Supermicro AOC-S3008L-L8E (LSI SAS3008 PCI-Express Fusion-MPT SAS-3)
  - Intel Cannon Lake PCH SATA AHCI Controller
  - Marvell 88SE9215 PCIe 2.0 x1 4-port SATA 6 Gb/s Controller
- **SAS Expander**: HP SAS Expander Card (Part Number: 487738-001)
- **Drive Configuration**: 12 SATA drives across 2 IcyDock cages
- **Network Configuration**:
  - **Primary Interface**: ix0 (Intel 10GbE) - 192.168.7.195/24
  - **Additional Interfaces**: igb0, em0 (not in use)
  - **Default Gateway**: 192.168.7.1
  - **DNS Configuration**:
    - Domain: sonolux.industries
    - Nameservers: 1.1.1.1, 8.8.8.8, 8.8.4.4
- **System Temperatures**:
  - CPU Cores: 32.0°C - 34.0°C
  - ACPI Thermal Zone: 27.9°C
  - HBA Controller: 80°C
- **ZFS Information**:
  - ZFS Version: zfs-2.1.14-1
  - ZFS Kernel Module: zfs-kmod-v2023120100-zfs_f4871096b
  - ARC Memory: 24GB Total (13GB MFU, 10GB MRU)
- **System Performance**:
  - Uptime: 1 hour 54 minutes (as of documentation)
  - Load Averages: 0.34, 0.29, 0.25
  - CPU Usage: 0.5% user, 1.7% system, 97.7% idle
  - Memory: 27GB Wired, 36MB Active, 182MB Inactive, 2.9GB Free

## Quick Reference

| Resource | Description | Link |
|----------|-------------|------|
| ZPools | Overview of all ZPools and their configuration | [ZPools](ZPools.md) |
| Physical Drives | Mapping of drives to physical locations | [Physical Drive Layout](Physical-Drive-Layout.md) |
| SAS Configuration | SAS expander and cable configuration | [SAS Expander Configuration](SAS-Expander-Configuration.md) |
| Maintenance | Common maintenance procedures | [Maintenance Procedures](Maintenance-Procedures.md) |
| Troubleshooting | Common issues and solutions | [Troubleshooting Guide](Troubleshooting-Guide.md) |
| Drive Stress Test | Sustained I/O test for verifying drive health | [Drive Stress Test](Drive-Stress-Test.md) |
| SAS Expander Replacement | Diagnosis of failing expander and replacement plan | [SAS Expander Replacement](SAS-Expander-Replacement.md) |

## Recent Changes

- **October 15, 2025**:
  - Updated storage capacity information - Mir1 pool is now at **98% capacity (CRITICAL)**
  - Documented Backups pool (1.81TB external USB storage)
  - Implemented interim storage solution using nullfs mount from /mnt/Backups/movies_02 to /mnt/Mir1/media/movies_2
  - Provides additional 1.7TB storage accessible as /mnt/media/movies_2 via NFS
  - Identified urgent upgrade path: replace da1 and da11 (1TB drives) with 2TB NAS drives
- **April 12, 2025**: Created comprehensive documentation including ZPools, Physical Drive Layout, SAS Expander Configuration
- **April 12, 2025**: Added detailed drive mapping with fanout cable connections
- **April 12, 2025**: Documented drive replacement procedures including LED blinking technique
- **April 12, 2025**: Added cable specifications and performance considerations

---

## Critical Alerts

⚠️ **STORAGE CRITICAL (October 15, 2025)**: Mir1 pool is at 98% capacity with only 199GB free at pool level, ~71GB at dataset level. Immediate action required:
1. **Temporary Solution Implemented**: 1.7TB overflow storage via Backups pool mounted at /mnt/media/movies_2
2. **Permanent Solution Needed**: Replace da1 and da11 (1TB WD Blue drives) with 2TB NAS-rated drives to add ~1TB usable capacity

---

Last updated: October 15, 2025
