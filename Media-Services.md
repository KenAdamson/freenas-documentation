# Media Services

This document describes the media server stack running on `workhorse` (192.168.7.58), which provides Plex streaming, media acquisition, and supporting services for the household. It covers the current as-built configuration and the planned migration to new hardware.

## Current Hardware: Beelink EQi12

| Spec | Detail |
|------|--------|
| **Hostname** | workhorse |
| **OS** | Ubuntu 24.04.3 LTS |
| **Kernel** | 6.17.0-14-generic |
| **CPU** | Intel Core i5-1235U (10C/12T) |
| **RAM** | 32 GB DDR4 SODIMM |
| **Boot Disk** | 1 TB NVMe (local) |
| **NIC** | Realtek RTL8168h (r8169 driver), 1 GbE |
| **IP Address** | 192.168.7.58/24 |
| **Form Factor** | Mini PC |

## Network Mounts

| Mount Point | Source | Type | Purpose |
|-------------|--------|------|---------|
| `/mnt/media` | `192.168.7.195:/mnt/Mir1/media` | NFS v3/TCP | Primary media library (movies, TV, downloads, temp) |
| `/mnt/backups` | `192.168.7.195:/mnt/Backups` | NFS v3/TCP | Backup pool, overflow TV storage |
| `/mnt/plex-azure` | Azure Blob (`adamsonplexstorage/plex-storage`) | blobfuse2 (FUSE) | Cloud overflow storage (being migrated off) |

### Blobfuse2 Configuration

- **Config file**: `/home/kenadamson/.blobfuse2.yaml`
- **File cache**: `/tmp/blobfuse2_cache` (20 GB max, 86400s TTL, LRU eviction)
- **Block size**: 16 MB, max concurrency 64
- **Systemd unit**: `blobfuse2-plex.service`

## Service Architecture

Services run as a mix of Docker containers on the `media-network` bridge (172.30.0.0/16) and native systemd services.

### Docker Containers (media-network)

| Service | Image | IP | Port | Purpose |
|---------|-------|----|------|---------|
| Radarr | `linuxserver/radarr:latest` | 172.30.0.6 | 7878 | Movie management and acquisition |
| Prowlarr | `linuxserver/prowlarr:latest` | 172.30.0.5 | 9696 | Unified indexer manager |
| qBittorrent | `linuxserver/qbittorrent:latest` | 172.30.0.7 | 8080 | Torrent client |
| Jackett | `linuxserver/jackett:latest` | 172.30.0.4 | 9117 | Indexer proxy (legacy, being replaced by Prowlarr) |
| FlareSolverr | `ghcr.io/flaresolverr/flaresolverr:latest` | 172.30.0.2 | 8191 | CloudFlare bypass for indexers |
| Requestrr | `darkalfx/requestrr:latest` | 172.30.0.3 | 4545 | Chat bot for media requests |
| Pi-hole | `pihole/pihole:latest` | — | 53 (DNS), 8888 (web) | Network-wide ad blocking / DNS |

### Native Systemd Services

| Service | Unit | Port | Notes |
|---------|------|------|-------|
| Plex Media Server | `plexmediaserver.service` | 32400 | Systemd override in `/etc/systemd/system/plexmediaserver.service.d/override.conf` |
| Sonarr | `sonarr.service` | 8989 | TV show management, v4.0.16.2944 (.NET) |
| qBittorrent Proxy | `qbt-proxy.service` | 8090 | Auth compatibility proxy for Sonarr→qBittorrent (`/home/kenadamson/qbt-auth-proxy-v3.py`) |
| Blobfuse2 | `blobfuse2-plex.service` | — | Azure blob mount |

### Service Versions

| Service | Version |
|---------|---------|
| Plex Media Server | 1.42.2.10156-f737b826c |
| Sonarr | 4.0.16.2944 |
| Radarr | 5.28.0.10274 |

## Radarr Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `/home/kenadamson/.config/Radarr` | `/config` | Configuration |
| `/mnt/media/movies` | `/movies` | Movie library |
| `/mnt/media/downloads` | `/media-downloads` | Download staging |
| `/mnt/backups` | `/downloads` | Backup pool access |
| `/mnt/plex-azure/movies` | `/azure-movies` | Azure movie migration source |

### Radarr Remote Path Mappings

| Host | Remote Path | Local Path |
|------|------------|------------|
| 192.168.7.58 | `/mnt/media/downloads/` | `/media-downloads/` |
| qbittorrent | `/mnt/media/movies/` | `/movies/` |
| 192.168.7.58 | `/mnt/media/movies/` | `/movies/` |

## qBittorrent Configuration

| Setting | Value |
|---------|-------|
| Default save path | `/mnt/media/movies` |
| Temp path | `/mnt/media/downloads` |
| Category `radarr` | Save path: `/mnt/media/downloads/radarr` |
| Category `tv-sonarr` | Save path: `/mnt/media/tv` |
| Auto TMM | Enabled |
| Category changed TMM | Enabled |

## Media Library Paths

| Path | Content | Approx Size |
|------|---------|-------------|
| `/mnt/media/movies` | Primary movie library (~900 titles) | ~8 TB |
| `/mnt/media/tv` | TV shows | varies |
| `/mnt/media/downloads` | Download staging / qBittorrent temp | varies |
| `/mnt/media/temp` | Legacy temp path (unused) | — |
| `/mnt/backups/tv_02` | Overflow TV storage (5 shows, ~227 GB) | 227 GB |
| `/mnt/plex-azure/movies` | Azure cloud overflow (being emptied) | ~30 GB remaining |

## Pi-hole

Pi-hole runs as a Docker container on `workhorse`. DNS (port 53) is bound to 192.168.7.58 specifically (not 0.0.0.0). Web UI is on port 8888.

**Known issue**: Pi-hole goes down when the Plex server reboots, causing DNS outages for the entire network. Future plan: migrate Pi-hole to the MikroTik RB5009 router (RouterOS v7 container support) so DNS is independent of the media server lifecycle.

## API Keys (Reference)

| Service | API Key |
|---------|---------|
| Sonarr | `38a44f0807334a2db7ecb56a71daebc9` |
| Radarr | `96d985473ebb4cf5943729853b85ed96` |
| Prowlarr | `641f8437aba344689e73f1cc608c1673` |

## Known Issues

- **Plex service currently inactive**: `plexmediaserver.service` is not running as of February 14, 2026. May require manual start after reboot.
- **Jackett → Prowlarr migration**: Prowlarr has been deployed but Jackett is still running. Some indexers (1337x, KickassTorrents) need CloudFlare bypass configuration in Prowlarr via FlareSolverr.
- **Azure egress costs**: Remaining content on Azure blob storage incurs ~$0.087/GB egress when accessed. Migration to NAS in progress.
- **Sonarr TV shows on backup pool**: 5 shows (~227 GB) still served from `/mnt/backups/tv_02/` instead of primary storage.

---

## Future State: Lenovo ThinkStation P520

Hardware ordered February 14, 2026. This section describes the target configuration after migration.

### New Hardware

| Spec | Detail |
|------|--------|
| **Hostname** | workhorse (migrated) |
| **Chassis** | Lenovo ThinkStation P520 (tower, whisper quiet) |
| **CPU** | Intel Xeon W-2135 (6C/12T, 3.7 GHz base, 4.5 GHz boost, 140W TDP) |
| **RAM** | 16 GB DDR4 ECC RDIMM (expandable to 256 GB, 4 DIMM slots) |
| **Boot Disk** | 1 TB NVMe (swapped from Beelink, native M.2 slot) |
| **PSU** | 690W (standard PCIe GPU power connectors: 8-pin + 6-pin) |
| **GPU** | Intel Arc A770 16GB (hardware transcoding via QSV/VA-API, AV1/H.265/H.264) |
| **NIC (production)** | Mellanox ConnectX-3 Pro MCX312C-XCCT, dual-port 10GbE SFP+ (in-kernel `mlx4_en` driver) |
| **NIC (management)** | Intel I219-LM 1GbE onboard |
| **Drive Bays** | 2x 3.5"/2.5" + 1x 2.5" + 2x 5.25" Flex Bays + 2x M.2 NVMe |

### PCIe Layout

| Slot | Electrical | Assignment |
|------|-----------|------------|
| 1 | PCIe 3.0 x8 | Mellanox ConnectX-3 Pro (dual 10GbE SFP+) |
| 2 | PCIe 3.0 x16 (FL/FH, 75W) | Intel Arc A770 GPU |
| 3 | PCIe 3.0 x4 | Available |
| 4 | PCIe 3.0 x16 (FL/FH, 75W) | Available |

### Network Configuration (Target)

| Interface | Network | Purpose |
|-----------|---------|---------|
| Intel I219-LM (onboard 1GbE) | Management VLAN | SSH, out-of-band access |
| Mellanox SFP+ port 1 | LACP bond → CRS305 | Production traffic (10GbE) |
| Mellanox SFP+ port 2 | LACP bond → CRS305 | Production traffic (10GbE) |

**Aggregate production bandwidth**: 20 Gbps (802.3ad LACP bond)

### Power Budget

| Component | Draw |
|-----------|------|
| Xeon W-2135 | 140W TDP |
| Arc A770 | 225W peak |
| Mellanox NIC | ~8W |
| NVMe + fans + misc | ~15W |
| **Peak total** | **~388W** |
| **Estimated idle** | **~80-100W** |
| **690W PSU headroom** | **~44%** |

### Hardware Transcoding

The Intel Arc A770 provides hardware-accelerated video transcoding via VA-API / Intel Quick Sync Video:

- **Decode**: H.264, H.265/HEVC, AV1, VP9, MPEG-2
- **Encode**: H.264, H.265/HEVC, AV1
- **Use cases**: Plex real-time transcoding for remote clients, batch re-encoding of media library
- **Driver**: Intel i915/xe (in-kernel)

Local 3.5" drive bays available for scratch/batch storage during encoding workflows.

### Migration Checklist

- [ ] Receive P520, RAM, Mellanox NIC
- [ ] Install RAM, NVMe (from Beelink), Arc A770, Mellanox NIC
- [ ] Verify PSU has 8-pin + 6-pin PCIe power cables for A770
- [ ] Install Ubuntu, configure NFS mounts to NAS (192.168.7.195)
- [ ] Configure Mellanox LACP bond (`mlx4_en` driver, `mode=4`)
- [ ] Configure management VLAN on Intel I219-LM
- [ ] Migrate Docker containers: Radarr, Prowlarr, qBittorrent, Jackett, FlareSolverr, Requestrr
- [ ] Migrate native services: Plex, Sonarr, qBittorrent proxy, Blobfuse2
- [ ] Migrate Pi-hole to MikroTik RB5009 (or keep on Beelink)
- [ ] Verify Plex hardware transcoding with Arc A770
- [ ] Verify 10GbE throughput to NAS (`iperf3`)
- [ ] Repurpose Beelink for lab use
- [ ] Return Sabrent NT-C5GA (Realtek RTL8157 — not as advertised)

### Parts Ordered

| # | Component | Model | Price | Source |
|---|-----------|-------|------:|--------|
| 1 | Workstation | Lenovo ThinkStation P520 (W-2135, 690W PSU) | $250.00 | eBay |
| 2 | RAM | Samsung 16GB DDR4-2666 ECC RDIMM | $90.00 | eBay |
| 3 | NIC | Mellanox ConnectX-3 Pro MCX312C-XCCT (dual 10GbE SFP+) | $17.45 | eBay |
| | **Total** | | **$357.45** | |

### Already Owned

| Item | Notes |
|------|-------|
| Intel Arc A770 16GB | Hardware transcoding GPU |
| 1 TB NVMe SSD | Swap from Beelink |
| MikroTik CRS305-1G-4S+IN | 10GbE aggregation switch |
| SFP+ DAC cables / transceivers | Verify stock, may need 1-2 more |

---

## Topology Diagram

### Current State
```
                    ┌─────────────────┐
                    │   TrueNAS NAS   │
                    │  192.168.7.195  │
                    │  Intel 10GbE    │
                    │  FreeBSD / ZFS  │
                    └───────┬─────────┘
                            │ 10GbE SFP+
                    ┌───────┴─────────┐
                    │  CRS305-1G-4S+  │
                    │  10GbE Switch   │
                    └───────┬─────────┘
                            │ 1GbE (limited by NIC)
                    ┌───────┴─────────┐
                    │    workhorse    │
                    │  192.168.7.58   │
                    │  Beelink EQi12  │
                    │  Realtek 1GbE   │
                    │  Plex + *arr    │
                    │  + Pi-hole      │
                    └─────────────────┘
```

### Future State
```
                    ┌─────────────────┐
                    │   TrueNAS NAS   │
                    │  192.168.7.195  │
                    │  Intel 10GbE    │
                    │  FreeBSD / ZFS  │
                    └───────┬─────────┘
                            │ 10GbE SFP+
                    ┌───────┴─────────┐
                    │  CRS305-1G-4S+  │
                    │  10GbE Switch   │
                    └──┬──────────┬───┘
           LACP Bond   │          │
         ┌─────────────┘          │
         │  20 Gbps               │ 10GbE SFP+
         │  (2x 10GbE)           │
  ┌──────┴──────────┐    ┌───────┴─────────┐
  │    workhorse    │    │  RB5009UG+S+IN  │
  │  ThinkStation   │    │  MikroTik Router │
  │  P520           │    │  Pi-hole (ctr)   │
  │  Xeon W-2135    │    └─────────────────┘
  │  Arc A770 (GPU) │
  │  Mellanox 2x10G │
  │  Intel 1G (mgmt)│
  │  Plex + *arr    │
  └─────────────────┘
         │
  ┌──────┴──────────┐
  │  Beelink EQi12  │
  │  (repurposed)   │
  │  Lab server     │
  └─────────────────┘
```

---

## Related Documentation

- [ZPools Overview](ZPools) - NAS pool configuration
- [Physical Drive Layout](Physical-Drive-Layout) - NAS drive locations
- [Storage Expansion Plan](Storage-Expansion-Plan) - NAS capacity upgrade plan

---

*Created: February 14, 2026*
*Last Updated: February 14, 2026*
