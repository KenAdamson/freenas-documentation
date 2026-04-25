# SAS Expander Configuration

Current SAS fabric: **LSI SAS3008 HBA (mpr0) + Adaptec AEC-82885T expander**, dual SFF-8643 wide-port uplink.

*Last updated: 2026-04-25 — slot swap executed; HBA now CPU-direct PCIe 3.0 x8.*

> **History:** The previous HP SAS Expander (P/N 487738-001, PMC Sierra SAS2x36) was diagnosed as failing in January 2026 (invalid-dword errors across every PHY including unconnected ones, STP tunnels terminating mid-transfer). All pool drives were temporarily migrated off it onto Intel/Marvell SATA controllers. The **Adaptec AEC-82885T was installed on 2026-04-05**, replacing the HP expander permanently.

## SAS HBA

| Field | Value |
|---|---|
| Model | Supermicro AOC-S3008L-L8E |
| Chipset | LSI / Broadcom SAS3008 |
| Mode | IT (confirmed via `mprutil show adapter`) |
| BIOS | 8.17.00.00 |
| Firmware | 8.00.00.00 |
| Driver | `mpr` (native FreeBSD/TrueNAS) |
| SAS speed | 12 Gb/s (SAS-3) |
| SATA NCQ | Enabled |
| PCIe link (current) | **x8 PCIe 3.0 (~7.88 GB/s)** — slot 2, CPU-direct (post 2026-04-25 swap) |
| Operating temperature | ~84 °C under sustained load post-swap (was ~76 °C in slot 3); within SAS3008 envelope |

## SAS Expander

| Field | Value |
|---|---|
| Model | Adaptec AEC-82885T |
| Type | 36-port 12 Gb/s SAS-3 expander |
| Power | PCIe slot (12V/3.3V, **power-only** — no data lanes) |
| Current PCIe slot | **slot 3** (Gen3 x4 physical) — for power only; demoted from slot 2 in the 2026-04-25 swap to free the CPU-direct x8 for the HBA |
| External ports | 2x SFF-8644 (unused) |
| Internal ports | 7x SFF-8643 |
| Enclosure ID | `50000d17:017175be` (enclosure #2 in `sas3ircu`) |
| Slots reported | 25 |
| SES device | `ses1` at scbus13 target 32 |

The AEC-82885T is a pure SAS expander. It does not appear in `pciconf` because the PCIe slot is used only for 3.3V/12V rails — there is no PCIe data connection between the expander and the CPU. All drive I/O routes through the LSI HBA over the SFF-8643 uplink cables.

## HBA ↔ Expander uplink (wide port)

Two SFF-8643 to SFF-8643 cables connect the LSI HBA to the AEC-82885T. The SAS3008 treats all 8 PHYs as a single wide port pointing at the expander:

```
PhyNum  CtlrHandle  DevHandle  Disabled  Speed   Min    Max    Device
0       0001        0009       N         12      3.0    12     SAS Initiator
1       0001        0009       N         12      3.0    12     SAS Initiator
2       0001        0009       N         12      3.0    12     SAS Initiator
3       0001        0009       N         12      3.0    12     SAS Initiator
4       0001        0009       N         12      3.0    12     SAS Initiator
5       0001        0009       N         12      3.0    12     SAS Initiator
6       0001        0009       N         12      3.0    12     SAS Initiator
7       0001        0009       N         12      3.0    12     SAS Initiator
```

All 8 PHYs share the same `DevHandle 0009` — that is the signature of a wide port. Aggregate theoretical uplink bandwidth: **8 × 12 Gbps = 96 Gbps (~12 GB/s)**. Post-2026-04-25 slot swap, the HBA's PCIe 3.0 x8 upstream (~7.88 GB/s) is the new effective ceiling; previously the chipset-attached x4 in slot 3 was the bottleneck.

| Cable | Connector A (HBA side) | Connector B (expander side) | Length | Rated |
|---|---|---|---|---|
| Uplink #1 | SFF-8643 | SFF-8643 | 0.5 m | 12 Gb/s (H!Fiber) |
| Uplink #2 | SFF-8643 | SFF-8643 | 0.5 m | 12 Gb/s (H!Fiber) |

Loss of one uplink cable would transparently degrade the wide port to a 4-lane x 12 Gb/s link (48 Gbps), still far in excess of attached drive throughput. No reconfiguration is required for failover.

## Breakout cables (expander → drives)

3× SFF-8643 → 4× SATA forward breakout cables on the expander's internal ports feed the SATA drives:

| Breakout | Drives (as of 2026-04-24) |
|---|---|
| Breakout A | da0 (8T WD Red Plus, mirror-1), da1 (8T IronWolf VN004, mirror-1) |
| Breakout B | da2 (8T IronWolf VN004, mirror-5 — was da10), da6 (8T IronWolf VN0022, mirror-5), da3 (2T SA500, mirror-0) |
| Breakout C | da4 (2T SA500, mirror-4), da5 (2T WDS200T1R0A, mirror-3), da11 (2T WDS200T1R0A, mirror-3) |

*Physical port assignments may have drifted; re-verify with `sas3ircu 0 display` if exact slot numbers are needed. Drive-to-breakout assignments above reflect current pool membership, not necessarily the physical SAS routing.*

Exact physical cage assignments and expander slot numbers can be re-read at any time with:

```
sas3ircu 0 display
sesutil map        # resolves scbus13 targets to drives and slot positions
```

## Topology diagram

```
         ┌──────────────────────────────┐
         │ LSI SAS3008 HBA (mpr0)       │
         │ AOC-S3008L-L8E, IT mode      │
         │ PCIe 3.0 x8 (slot 2, CPU)    │
         └──┬─────────────────────────┬─┘
            │                         │
     SFF-8643│ (wide port: 8 PHYs @ 12 Gbps)
            │                         │
         ┌──┴─────────────────────────┴──┐
         │ Adaptec AEC-82885T expander   │
         │ 36-port SAS-3 / slot-powered  │
         └──┬────────────┬────────────┬──┘
            │            │            │
       SFF-8643       SFF-8643      SFF-8643
       → 4× SATA     → 4× SATA     → 4× SATA
            │            │            │
         drives       drives       drives
```

## Performance considerations

- **Expander is not the bottleneck.** The 96 Gbps uplink is well in excess of the HBA's PCIe 3.0 x8 upstream (~7.88 GB/s) and vastly more than the attached drives can collectively push.
- **HBA upstream is comfortably ahead of any realistic drive load.** At ~7.88 GB/s the link can soak a full all-SSD pool or a wide-mirror sequential scrub without saturating.
- **HBA temperature** climbed from ~76 °C (slot 3) to ~84 °C (slot 2) under sustained load — the new slot has different airflow geometry. Within SAS3008 junction limits (~100 °C) but worth watching; a card-mounted fan upgrade is the next step if it climbs further.

## Replacement procedures

### Failed uplink cable
1. Power the system down.
2. Label both cables before disconnecting.
3. Replace the failed cable.
4. Boot and verify all 8 PHYs come up at 12 Gbps with `mprutil show adapter`.

### Failed expander
The AEC-82885T is a passive device — if it fails, all drives behind it drop simultaneously. The pool will show both halves of any Adaptec-only mirror vdev offline. Recovery:

1. Replace the expander.
2. Re-seat all SFF-8643 cables.
3. Boot; drives re-import by GPTID, no `zpool replace` needed.

### Failed HBA
Similar to expander failure but worse — everything downstream of the HBA is gone. Replace with another IT-mode SAS3008 (or flash a new one) and boot. Drives re-import by GPTID.

## Diagnostics

```bash
# HBA status and PHY link state
mprutil -u 0 show adapter

# Full configuration dump
sas3ircu 0 display

# Enclosure status (drive slot mapping)
sas3ircu 0 display | grep -A 5 Enclosure

# Kernel bus messages
dmesg | grep mpr0
```
