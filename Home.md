# TrueNAS Server Documentation

Welcome to the comprehensive documentation for our TrueNAS server. This wiki contains detailed information about the server's configuration, including:

- [ZPools Overview](ZPools.md)
- [Physical Drive Layout](Physical-Drive-Layout.md)
- [SAS Expander Configuration](SAS-Expander-Configuration.md)
- [Maintenance Procedures](Maintenance-Procedures.md)
- [Troubleshooting Guide](Troubleshooting-Guide.md)
- [Drive Stress Test](Drive-Stress-Test.md)
- [SAS Expander Replacement](SAS-Expander-Replacement.md)
- [Storage Expansion Plan](Storage-Expansion-Plan.md)

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
| Storage Expansion Plan | Phased drive replacement and capacity upgrade strategy | [Storage Expansion Plan](Storage-Expansion-Plan.md) |

## Recent Changes

- **February 4-5, 2026**:
  - Pool is ONLINE after emergency drive failures and resilvers
  - 3x Seagate ST2000LM015 drives failed (from same 2021 Amazon batch); all removed
  - USB drives pressed into emergency service for mirror-1 and mirror-3
  - All pool drives migrated off failing HP SAS expander to Intel/Marvell SATA controllers
  - SMART monitoring configured: temperature thresholds (10/40/50°C), weekly short tests, monthly long tests
  - Ordered 1x WD Red Plus 8TB (WD80EFPX) for mirror-1 stabilization
  - Updated storage expansion plan: 4x 8TB WD Red Plus staged over time ($840 total)
- **February 2, 2026**: HP SAS expander diagnosed as failing (PMC Sierra SAS2x36 chip degradation). See [SAS Expander Replacement](SAS-Expander-Replacement.md)
- **October 15, 2025**: Documented critical storage capacity (98% full) and interim overflow solution
- **April 12, 2025**: Initial comprehensive documentation created

---

## Current Status

**Pool**: Mir1 is ONLINE at ~97% capacity. All 6 mirrors operational, no errors.

**Temporary measures in place**:
- mirror-1: USB Seagate drive + last surviving Seagate HDD (ada6, expected to fail)
- mirror-3: USB WD My Passport + WD Red Plus 2TB HDD
- 1.7TB overflow storage via Backups pool (nullfs mount at /mnt/media/movies_2)

**Pending hardware**:
- 1x WD Red Plus 8TB ordered for mirror-1 (Phase 1 of [Storage Expansion Plan](Storage-Expansion-Plan.md))
- Adaptec AEC-82885T SAS expander needed to replace failing HP expander
- SFP+ NIC for 20 Gb/s network upgrade

---

Last updated: February 5, 2026
