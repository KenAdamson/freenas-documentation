# SAS Expander Configuration

This page documents the SAS expander configuration, including expander details, breakout cable positions, and port mappings.

## SAS HBA Overview

| Component | Details |
|-----------|---------|
| Model | Supermicro AOC-S3008L-L8E |
| Board Name | LSI3008-IT |
| Chipset | LSI SAS3008 |
| Chip Revision | ALL |
| BIOS Revision | 8.17.00.00 |
| Firmware Revision | 8.00.00.00 |
| Mode | IT Mode (confirmed with mprutil show adapter) |
| Speed | 12Gbps SAS3 / SATA3 |
| Interface | PCIe Gen3 x8 (8.0 GB/sec) |
| Driver | Native FreeBSD / TrueNAS support (mpr driver) |
| Firmware | Flashed and confirmed in IT mode |
| Temperature | 80°C (normal operating temperature) |
| SATA NCQ | Enabled |
| Integrated RAID | No |
| Physical Ports | 8 SAS lanes (PhyNum 0-7), all operating at 6.0 Gbps |

## SAS Expander Overview

| Component | Details |
|-----------|---------|
| Model | HP SAS Expander Card (Part Number: 487738-001) |
| Chipset | LSI SAS2x36 (36-port 6Gbps SAS-2 Expander) |
| Speed | SAS-2 (6Gbps per link) - works well with SATA SSDs at 6Gbps |
| Power | Passive PCIe edge power (via powered riser) |
| Connectivity | Connected via SFF-8087 Mini-SAS internal ports |
| Breakout Cables | 2C, 4C, 6C (mapped in Physical-Drive-Layout.md) |
| Uplink Ports | Connected to HBA via ports 8C and 3C for fault-tolerance and multipath |

## Breakout Cable Configuration

| Breakout Cable | Connected To | Drives |
|----------------|--------------|--------|
| Fanout Cable 2C | Expander Ports P1-P4 | da0, da1, da2, da3 |
| Fanout Cable 4C | Expander Ports P1-P4 | da4, da5, da6, da7 |
| Fanout Cable 6C | Expander Ports P1-P4 | da8, da9, da10, da11 |

## Cable Specifications

### Cable Connection Summary

| Connection | Cable Type | Connector A | Connector B | Notes |
|------------|------------|------------|------------|-------|
| HBA → Expander | SFF-8643 to SFF-8087 | SFF-8643 (HBA) | SFF-8087 (Expander) | Uplink, multi-lane SAS |
| Expander → Drive Cages | SFF-8087 to 4x SATA Forward Breakout | SFF-8087 (Expander) | 4x SATA (Cage) | 3 fanout cables, direct to IcyDock SATA |

### HBA to Expander Interconnect Cables

| Connection | Cable Type | Connector Type | Length | Speed Rating |
|------------|------------|----------------|--------|--------------|
| HBA to Expander (8C) | SFF-8643 to SFF-8087 | Mini-SAS HD to Mini-SAS | 0.5m | 12Gbps |
| HBA to Expander (3C) | SFF-8643 to SFF-8087 | Mini-SAS HD to Mini-SAS | 0.5m | 12Gbps |

#### HBA to SAS Expander Cable Details

- **Cable Type**: SFF-8643 (Mini-SAS HD) to SFF-8087 (Mini-SAS)
- **Connector Details**:
  - SFF-8643 (High-Density) plugs into the Supermicro HBA
  - SFF-8087 connects to the HP SAS Expander
- **Specifications**:
  - Carries multi-lane SAS (up to 4 lanes of 6-12 Gbps each)
  - Supports SAS 3.0 speeds from HBA, but expander runs at SAS-2 (6Gbps)
  - Example: H!Fiber.com 12G Internal Mini SAS HD SFF-8643 to SFF-8087 (36-pin) cable
- **Purpose**: High-speed uplink from HBA to SAS Expander (control and data plane)

### Expander to Drive Fanout Cables

| Cable | Type | Connectors | Length | Speed Rating |
|-------|------|------------|--------|--------------|
| Fanout Cable 2C | SFF-8087 to SATA Fanout | Mini-SAS to 4x SATA | 1m | 6Gbps |
| Fanout Cable 4C | SFF-8087 to SATA Fanout | Mini-SAS to 4x SATA | 1m | 6Gbps |
| Fanout Cable 6C | SFF-8087 to SATA Fanout | Mini-SAS to 4x SATA | 1m | 6Gbps |

#### SAS Expander to Drive Cages Cable Details

- **Cable Type**: SFF-8087 (Mini-SAS) to 4 x SATA Forward Breakout
- **Connector Details**:
  - Expander side: SFF-8087 (Mini-SAS)
  - Drive cage side: 4 discrete SATA connectors (direct to IcyDock cage backplane)
- **Specifications**:
  - "Forward breakout" means host-side SAS to target-side SATA
  - Supports SATA 3.0 6Gbps per port
- **Purpose**: Distribute individual SAS lanes from the expander to the 12 SATA drives across the two IcyDock cages

### Cable Pinout Information

The SFF-8087 Mini-SAS to SATA fanout cables follow standard pinout configurations:

- Each SFF-8087 connector provides four SAS/SATA channels (4 ports)
- The fanout splits these into individual SATA connections
- Standard color coding is used on the SATA connectors (typically numbered or color-coded)
- Forward and reverse breakout cables are not interchangeable - these are forward breakout cables

## Port to Drive Mapping

For detailed port-to-drive mapping, including physical locations in drive cages and connections to specific expander ports, please refer to the [Physical Drive Layout](Physical-Drive-Layout.md) documentation.

## SAS Topology Diagram

```
+-------------------+
| Supermicro SAS HBA|
| AOC-S3008L-L8E    |
+--------+---+------+
         |   |
         |   |  <-- Dual uplink paths (8C and 3C) for fault-tolerance
         v   v
+--------+---+------+
|  HP SAS Expander  |
|  487738-001       |
+--------+----------+
         |
    +----+----+----+
    |         |    |
    v         v    v
+-------+ +-------+ +-------+
|Fanout | |Fanout | |Fanout |
|  2C   | |  4C   | |  6C   |
+-------+ +-------+ +-------+
    |         |        |
    v         v        v
+----------------------------+
|      Drive Cages           |
|  (See Physical-Drive-Layout|
|   for detailed connections)|
+----------------------------+
```

## Performance Considerations

- The SAS Expander operates at 6Gbps (SAS-2), while the HBA supports 12Gbps (SAS-3)
- This configuration creates a potential bottleneck at the expander level
- For SATA SSDs limited to 6Gbps, this is not an issue
- For maximum performance, migrating to SAS drives would be recommended for future upgrades
- Current configuration prioritizes drive density over maximum throughput
- Dual uplink paths (8C and 3C) provide fault-tolerance and multipath capabilities
- Multipath configuration helps distribute load across both uplink connections

### Future Upgrade Considerations

- **SAS Drives**: Migrating to SAS drives would provide better performance, reliability, and dual-port capabilities
- **Expander Upgrade**: A SAS-3 (12Gbps) expander would remove the current 6Gbps bottleneck
- **Direct Attachment**: Note that SATA drives cannot be direct-connected to the HBA for performance improvements; SAS drives are required for this approach

## Maintenance Notes

- The HP SAS Expander does not require any special configuration in TrueNAS
- It functions as a transparent device between the HBA and the drives
- When replacing drives, refer to the [Physical Drive Layout](Physical-Drive-Layout.md) documentation to identify the correct physical location
- The expander firmware is factory-default and does not need updates

## Troubleshooting SAS Connections

If a drive becomes unavailable, check the following:

1. Verify the SAS cable connections at both the expander and drive ends
2. Check for any loose breakout cable connections
3. Inspect the SAS expander for error LEDs
4. Use the following command to check the status of SAS connections:
   ```
   sas2ircu LIST
   ```
5. For detailed information about a specific SAS adapter:
   ```
   sas2ircu <adapter_id> DISPLAY
   ```

## Cable Replacement Procedure

When replacing SAS cables:

1. Power down the system
2. Label all cables before disconnecting
3. Replace the faulty cable
4. Ensure proper seating of all connectors
5. Power up the system and verify all drives are detected

*Note: This is a template. Please replace with your actual SAS expander configuration details.*
