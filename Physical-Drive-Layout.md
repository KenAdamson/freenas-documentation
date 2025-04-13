# Physical Drive Layout

This page documents the physical location of all drives in the TrueNAS server, organized by drive cage and slot.

## Drive Cage Overview

| Cage | Description | Total Slots | Occupied Slots |
|------|-------------|-------------|----------------|
| Cage 0 | IcyDock 6x SATA | 6 | 6 |
| Cage 1 | IcyDock 6x SATA | 6 | 6 |

## Hardware Configuration

- **Drive Cages**: 2x IcyDock 6x SATA drive cages
- **SAS HBA**: SuperMicro SAS HBA
- **SAS Expander**: HP SAS Expander
- **Fanout Cables**: 3 fanout cables (2C, 4C, 6C)

## Detailed Drive Mapping

### Cage 0 (IcyDock 6x SATA)

| Slot | Drive ID | Fanout Cable | Expander Port | ZPool | Vdev | Mirror |
|------|----------|--------------|---------------|-------|------|--------|
| 0 | da3 | 2C | P1 | Mir1 | mirror-0 | gptid/4f7b78d1-d17d-11ef-8a75-b496913a6fde, gptid/4cffd486-d1af-11ef-8a75-b496913a6fde |
| 1 | da2 | 2C | P2 | Mir1 | mirror-1 | gptid/017ac5ca-9656-11eb-bb15-d45d643eabc1, gptid/5a9d8d43-9778-11eb-bb15-d45d643eabc1 |
| 2 | da1 | 2C | P3 | Mir1 | mirror-3 | gptid/0f3f574a-9748-11eb-bb15-d45d643eabc1, gptid/dea802f8-9655-11eb-bb15-d45d643eabc1 |
| 3 | da5 | 4C | P3 | Mir1 | mirror-0 | gptid/4f7b78d1-d17d-11ef-8a75-b496913a6fde, gptid/4cffd486-d1af-11ef-8a75-b496913a6fde |
| 4 | da4 | 4C | P4 | Mir1 | mirror-1 | gptid/017ac5ca-9656-11eb-bb15-d45d643eabc1, gptid/5a9d8d43-9778-11eb-bb15-d45d643eabc1 |
| 5 | da11 | 6C | P1 | Mir1 | mirror-3 | gptid/0f3f574a-9748-11eb-bb15-d45d643eabc1, gptid/dea802f8-9655-11eb-bb15-d45d643eabc1 |

### Cage 1 (IcyDock 6x SATA)

| Slot | Drive ID | Fanout Cable | Expander Port | ZPool | Vdev | Mirror |
|------|----------|--------------|---------------|-------|------|--------|
| 0 | da0 | 2C | P4 | Mir1 | mirror-4 | gptid/4b17ad79-13e6-11ef-af29-b496913a6fde, gptid/f613b9f9-1407-11ef-af29-b496913a6fde |
| 1 | da7 | 4C | P1 | Mir1 | mirror-5 | gptid/b9bb4736-6a05-11ee-8632-b496913a6fde, gptid/7e75d4d4-69eb-11ee-8632-b496913a6fde |
| 2 | da6 | 4C | P2 | Mir1 | mirror-6 | gptid/53cb5f22-14a9-11f0-ae6a-b496913a6fde, gptid/53c00b9b-14a9-11f0-ae6a-b496913a6fde |
| 3 | da10 | 6C | P2 | Mir1 | mirror-4 | gptid/4b17ad79-13e6-11ef-af29-b496913a6fde, gptid/f613b9f9-1407-11ef-af29-b496913a6fde |
| 4 | da9 | 6C | P3 | Mir1 | mirror-5 | gptid/b9bb4736-6a05-11ee-8632-b496913a6fde, gptid/7e75d4d4-69eb-11ee-8632-b496913a6fde |
| 5 | da8 | 6C | P4 | Mir1 | mirror-6 | gptid/53cb5f22-14a9-11f0-ae6a-b496913a6fde, gptid/53c00b9b-14a9-11f0-ae6a-b496913a6fde |

## Connection Diagram

```ascii
+-------------------+
| SuperMicro SAS HBA|
+--------+---+------+
         |   |
+--------+---+------+
|  HP SAS Expander  |---------------------------------------------------\
+--------+----------+                                                   |
         |         |                                                    |
         |         |                                                    |
         |         |                                               +----+---+
         |         |                                               | Fanout |
         |         |                                               |   6C   |
         |         |                                               +--+--+--+
         |         |                                               |  |  |  |
         |         |                                               |  |  |  |
         |      +--+-----+                                         |  |  |  |
         |      | Fanout |                                         |  |  |  |
         |      |   2C   |                                         |  |  |  |
         |      +--+--+--+                                         |  |  |  |
         |      |  |  |  |                                         |  |  |  |
         |      |  |  |  |                                         |  |  |  |
         |      |  |  |  |                                         |  |  |  |
         |      |  |  |  |          +-------------------+          |  |  |  |
         |      |  |  |  |          |      Cage 0       |          |  |  |  |
         |      |  |  |  |          |                   |          |  |  |  |
         |      |  |  |   --------> | P1 | +-----+  +-----+  |P3        |  |  |  | --------
         |      |  |  |             |    | | da3 |  | da5 |  |          |  |  |  |         |
         |      |  |  |             |    | +-----+  +-----+  |          |  |  |  |         |
         |      |  |  |          P2 |    | +-----+  +-----+  |P4        |  |  |  |         |
         |      |  |   -----------> |    | | da2 |  | da4 |  |<-------- |  |  |  | ---     |
         |      |  |                |    | +-----+  +-----+  |          |  |  |  |    |    |
         |      |  |                |    |                   |          |  |  |  |    |    |
         |      |  |             P3 |    | +-----+  +-----+  |P1        |  |  |  |    |    |
         |      |   --------------> |    | | da1 |  | da11|  |<---------   |  |  |    |    |
         |      |                   |    | +-----+  +-----+  |             |  |  |    |    |
         |      |                   |    |                   |             |  |  |    |    |
         |      |                   +-------------------+             |  |  |    |    |
         |      |                                                     |  |  |    |    |
         |      |                   +-------------------+             |  |  |    |    |
         |      |                   |      Cage 1       |             |  |  |    |    |
         |      |                   |                   |             |  |  |    |    |
         |      |                P4 |    | +-----+  +-----+  |P2           |  |  |    |    |
         |       -----------------> |    | | da0 |  | da10|  |<------------   |  |    |    |
         |                          |    | +-----+  +-----+  |                |  |    |    |
         |                          |    |                   |                |  |    |    |
         |                       P1 |    | +-----+  +-----+  |P3              |  |    |    |
    +----+---+ -------------------> |    | | da7 |  | da9 |  |<---------------   |    |    |
    | Fanout |                      |    | +-----+  +-----+  |                   |    |    |
    |   4C   |                      |    |                   |                   |    |    |
    +--+--+--+                   P2 |    | +-----+  +-----+  |P4                 |    |    |
    |     |  \--------------------> |    | | da6 |  | da8 |  |<------------------     |    |
    |     |                         |    | +-----+  +-----+  |                        |    |
    |     |                         |    |                   |                        |    |
    |     |                         +-------------------+                        |    |
    |     |                                                                      |    |
    |      ----------------------------------------------------------------------
     ----------------------------------------------------------------------------------
```

## Fanout Cable Connections

### Fanout Cable 2C

- **Port P1**: Connects to da3 (Cage 0, Slot 0)
- **Port P2**: Connects to da2 (Cage 0, Slot 1)
- **Port P3**: Connects to da1 (Cage 0, Slot 2)
- **Port P4**: Connects to da0 (Cage 1, Slot 0)

### Fanout Cable 4C

- **Port P1**: Connects to da7 (Cage 1, Slot 1)
- **Port P2**: Connects to da6 (Cage 1, Slot 2)
- **Port P3**: Connects to da5 (Cage 0, Slot 3)
- **Port P4**: Connects to da4 (Cage 0, Slot 4)

### Fanout Cable 6C

- **Port P1**: Connects to da11 (Cage 0, Slot 5)
- **Port P2**: Connects to da10 (Cage 1, Slot 3)
- **Port P3**: Connects to da9 (Cage 1, Slot 4)
- **Port P4**: Connects to da8 (Cage 1, Slot 5)

## Drive Replacement Guide

When replacing a drive, ensure you identify the correct physical location:

1. Identify the failed drive using `zpool status` (e.g., `da3`)
2. Refer to this document to find the physical location (e.g., Cage 0, Slot 0)
3. Verify the SAS expander port and fanout cable (e.g., Expander Port P1, Fanout Cable 2C)

### Identifying Drive by Blinking the LED

To visually identify a drive by making its activity LED blink:

1. SSH into the TrueNAS server
2. Use the dd command to generate disk activity on the target drive:
```bash
dd if=/dev/daX of=/dev/null bs=1M count=10240
```
Replace `daX` with the drive identifier (e.g., `da3`)

3. The activity LED for that specific drive should now blink rapidly
4. Observe which physical drive is blinking to confirm its location
5. Press Ctrl+C to stop the dd command when identification is complete

### Replacing the Drive

1. Power down the system if required
2. Replace the drive in the identified slot
3. Power up the system and use `zpool replace` to add the new drive to the pool:
```bash
zpool replace Mir1 da3 /dev/da3
```

## Mapping between Drive IDs and GPTIDs

For reference, here is the mapping between drive IDs and their corresponding GPTIDs as shown in `zpool status`:

| Drive ID | GPTID |
|----------|-------|
| da0 | gptid/4b17ad79-13e6-11ef-af29-b496913a6fde |
| da1 | gptid/0f3f574a-9748-11eb-bb15-d45d643eabc1 |
| da2 | gptid/017ac5ca-9656-11eb-bb15-d45d643eabc1 |
| da3 | gptid/4f7b78d1-d17d-11ef-8a75-b496913a6fde |
| da4 | gptid/5a9d8d43-9778-11eb-bb15-d45d643eabc1 |
| da5 | gptid/4cffd486-d1af-11ef-8a75-b496913a6fde |
| da6 | gptid/53cb5f22-14a9-11f0-ae6a-b496913a6fde |
| da7 | gptid/b9bb4736-6a05-11ee-8632-b496913a6fde |
| da8 | gptid/53c00b9b-14a9-11f0-ae6a-b496913a6fde |
| da9 | gptid/7e75d4d4-69eb-11ee-8632-b496913a6fde |
| da10 | gptid/f613b9f9-1407-11ef-af29-b496913a6fde |
| da11 | gptid/dea802f8-9655-11eb-bb15-d45d643eabc1 |

*Note: This documentation is based on the physical drive layout information from April 12, 2025.*
