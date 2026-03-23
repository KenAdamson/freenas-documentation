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
- **TrueNAS version**: TrueNAS-13.0-U6.8 (FreeBSD 13.1-RELEASE-p9)
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

- **March 23, 2026**:
  - Optane SLOG (Intel MEMPEK1J032GAH 32GB) confirmed active in Mir1 pool as ZIL log device
  - Active M.2 cooler installed on Optane module
  - Failed chassis fan replaced with be quiet! Silent Wings Pro 4 (FDB)
  - All chassis fans set to max speed (4 exhaust, 1 intake)
  - Backups pool USB drive device naming documented (USB devices shift names across reboots)
  - Mir1 pool checksum errors cleared after successful scrub
  - Documented cooling configuration and temperature baselines in Maintenance Procedures
  - nullfs mounts added for Sonolux/Drone Footage (Mir1 -> Backups)
  - Mir1 at 86% capacity (13.3TB/15.4TB) — improved from 98% critical
- **October 15, 2025**:
  - Implemented nullfs mount solution for overflow storage from Backups pool
  - Multiple artist directories (MCB, NCC, Overlake School, RWB) moved to Backups with nullfs mounts back to Mir1
- **April 12, 2025**: Created comprehensive documentation including ZPools, Physical Drive Layout, SAS Expander Configuration

---

## Alerts

⚠️ **STORAGE WARNING**: Mir1 pool at 86% capacity (2.1TB free). Dedup ratio 1.25x. Monitor and plan expansion.

ℹ️ **USB DRIVE NOTE**: Backups pool mirror uses USB drives (da0/da1/da2). Device names are NOT stable across reboots — if a drive is disconnected or ports change, use `zpool online` or `zpool replace` with the new device name.

ℹ️ **OPTANE COOLER**: NVMe cooler fan uses sleeve bearings. Monitor for bearing failure — replace with FDB fan if it fails.

---

Last updated: March 23, 2026
