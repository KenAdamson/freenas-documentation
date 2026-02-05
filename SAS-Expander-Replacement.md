# SAS Expander Replacement

This document covers the diagnosis of the failing HP SAS Expander, current error data, and the replacement plan.

## Summary

The HP SAS Expander (P/N 487738-001) with PMC Sierra SAS2x36 chipset is failing. All pool drives have been migrated off the expander onto the Intel motherboard SATA and Marvell 88SE9215 controllers. Only two non-pool test drives remain on the expander. A replacement expander is needed before any future drive expansion through the SAS path.

## Failure Timeline

| Date | Event |
|------|-------|
| 2026-01-31 | Drive stress test on da11 fails — device disappears after ~63 seconds of sequential read |
| 2026-01-31 | dmesg shows STP IOC terminated errors (loginfo 31130000, 31110630) on da10 and da11 simultaneously |
| 2026-01-31 | SMP diagnostics confirm all SATA PHYs negotiated at 3 Gbps (should be 6 Gbps) |
| 2026-01-31 | PHY error logs show tens of thousands of invalid dwords on every PHY, including unconnected ones |
| 2026-02-01 | All pool drives physically moved off SAS expander onto Intel and Marvell controllers |
| 2026-02-02 | Post-migration SMP scan shows phy 2 dropped to 1.5 Gbps; error counts continue climbing |

## Current Expander

| Field | Value |
|-------|-------|
| Model | HP SAS Expander Card |
| Part Number | 487738-001 |
| Chipset | PMC Sierra SAS2x36 |
| Firmware | 2.08 |
| Speed | SAS-2 (6 Gbps per link — nominal) |
| Ports | 36 |
| Power | Passive PCIe edge power via powered riser + jumper |
| Enclosure ID | 5001438018df2825 |
| Uplink Ports | 8C and 3C to HBA (dual path) |
| Fanout Cables | 2C, 4C, 6C (SFF-8087 to 4x SATA) |

## Diagnostic Evidence

### SMP PHY Discovery (2026-02-02)

Only two SATA drives remain connected (da0 test TOSHIBA, da1 test HGST). Both are negotiating well below their 6 Gbps capability:

| PHY | Role | Negotiated Speed | Expected |
|-----|------|-----------------|----------|
| 2 | da0 (TOSHIBA MQ01ACF0) | **1.5 Gbps** (SATA I) | 6 Gbps |
| 3 | da1 (HGST HTS725050A7) | **3 Gbps** (SATA II) | 6 Gbps |
| 4-7 | HBA uplinks | 6 Gbps | 6 Gbps |
| 28-31 | HBA uplinks | 6 Gbps | 6 Gbps |

The SAS uplinks hold 6 Gbps because the HBA-to-expander path uses SAS signaling, not SATA. The SATA tunneling (STP) layer is where the chip is failing.

### PHY Error Counts (2026-02-02)

Collected via `smp_rep_phy_err_log /dev/pass2`. Every PHY — connected or not — shows thousands of errors:

| PHY | Connected? | Invalid Dwords | Running Disparity | Sync Loss |
|-----|-----------|---------------|-------------------|-----------|
| 2 | da0 | 27,447 | 24,602 | 2 |
| 3 | da1 | 22,773 | 19,061 | 3 |
| 4 | HBA uplink | 19,402 | 18,404 | 28 |
| 5 | HBA uplink | 22,061 | 20,168 | 5 |
| 6 | HBA uplink | 15,562 | 15,521 | 1 |
| 7 | HBA uplink | 30,528 | 29,750 | 2 |
| 8 | Empty | 92 | 92 | 1 |
| 9 | Empty | 30,095 | 28,518 | 2 |
| 10 | Empty | 15,308 | 14,883 | 1 |
| 11 | Empty | 7,954 | 7,078 | 14 |
| 12 | Empty | 14,403 | 13,239 | 2 |
| 13 | Empty | 56 | 54 | 1 |
| 28 | HBA uplink | 32,337 | 32,245 | 3 |
| 29 | HBA uplink | 17,392 | 16,761 | 26 |
| 30 | HBA uplink | 27,313 | 25,261 | 2 |
| 31 | HBA uplink | 24,314 | 22,898 | 2 |

**Key finding**: Empty/unconnected PHYs (9, 10, 11, 12) have 7,000-30,000 invalid dwords. This rules out cable or drive issues — the chip itself is generating noise across all its transceivers. The PMC Sierra SAS2x36 is dying.

### STP Error Codes from dmesg

When drives were still on the expander under load:

| Error | Loginfo | Meaning |
|-------|---------|---------|
| STP IOC terminated | 31130000 | SAS expander terminated the SATA tunnel — command timeout |
| STP IOC terminated | 31110630 | SAS expander terminated the SATA tunnel — hardware failure |

Both drives hit errors simultaneously during concurrent stress tests, confirming a centralized failure in the expander rather than individual drive or cable faults.

## Recommended Replacement: Adaptec AEC-82885T

| Field | Value |
|-------|-------|
| Model | Adaptec AEC-82885T |
| Chipset | PMC Sierra PM8074 (SAS-3) |
| Speed | 12 Gb/s SAS-3 / 6 Gb/s SATA |
| Ports | 36 (same as current) |
| Connectors | SFF-8644 (external) + SFF-8643 (internal Mini-SAS HD) |
| Power | PCIe slot powered directly — no riser or jumper required |
| Aux Power | Optional 4-pin molex for high drive counts |
| Typical Price | $80-250 (eBay/Amazon) |

### Why This Model

- **Direct PCIe power**: Plugs into a PCIe slot and draws power from the bus. No powered riser card or jumper hack like the HP 487738-001 requires.
- **SAS-3 (12 Gbps)**: Removes the 6 Gbps expander bottleneck. The Supermicro AOC-S3008L-L8E HBA is SAS-3 native, so the full uplink path runs at 12 Gbps.
- **Compatible with existing HBA**: The LSI SAS3008 in the Supermicro HBA is fully compatible with SAS-3 expanders. Backward-compatible with SAS-2 and SATA devices.
- **36 ports**: Same port count as the current expander — supports all 12 pool drives plus headroom.

### Cable Considerations

The AEC-82885T uses SFF-8643 (Mini-SAS HD) internal connectors. The existing fanout cables are SFF-8087 (Mini-SAS) to 4x SATA. Two options:

1. **Adapter cables**: SFF-8643 to SFF-8087 adapters (~$10-15 each, need 3 for the fanout cables + 0 for uplinks since the HBA already has SFF-8643)
2. **New fanout cables**: SFF-8643 to 4x SATA forward breakout cables (replaces the existing SFF-8087 fanouts entirely)

The HBA-to-expander uplink cables can be simplified: both ends would be SFF-8643, eliminating the current SFF-8643-to-SFF-8087 adapter cables (ports 8C and 3C).

## SMP Diagnostic Commands

For future reference, these commands talk to the expander via the HBA:

```sh
# General expander info (firmware, port count, change count)
smp_rep_general /dev/pass2

# Manufacturer info
smp_rep_manufacturer /dev/pass2

# PHY discovery (link speeds, attached devices)
smp_discover /dev/pass2

# PHY error log for a specific PHY
smp_rep_phy_err_log /dev/pass2 --phy=2

# Reset error counters (useful before a test)
smp_phy_control /dev/pass2 --phy=2 --op=ce
```

Note: The expander's pass device (`pass2`) may change across reboots. Find it with:
```sh
camcontrol devlist | grep -i "exp"
```

## Current Status

- **Pool drives**: All migrated off the SAS expander. Mirrors split across Intel motherboard SATA and Marvell 88SE9215 (3 direct ports + port multiplier).
- **Expander**: Still installed. Only 1 non-pool drive remains: TeamGroup T253X2001T 1TB SSD (da0) with a Windows partition table. The TOSHIBA and HGST test drives have been removed.
- **TeamGroup SSD**: Connected via SAS expander, negotiating at 3.0 Gb/s (half rate). Drive tested poorly and is considered unreliable. Will be removed when the expander is replaced or during SFP+ NIC installation (whichever comes first).
- **Action needed**: Order Adaptec AEC-82885T + SFF-8643 cables before expanding back onto the SAS path.

*Last updated: February 5, 2026*
