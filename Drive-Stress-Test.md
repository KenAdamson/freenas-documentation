# Drive Stress Test

A sustained I/O stress test script for verifying drive health on FreeBSD/TrueNAS. Uses only built-in system tools — no additional packages or dependencies required.

## When to Use This

- **Before trusting a drive after reseating** — confirms the connection is solid and the drive can sustain I/O without dropping off the bus
- **Isolating cage/cable vs. drive problems** — run the test with the drive on a direct SATA connection bypassing the backplane
- **Vetting replacement or used drives** — run with `--write-test` on blank drives before adding them to a pool
- **After SMART warnings** — stress the drive and see if SMART counters increase during sustained load

## Quick Start

```
# Copy to the TrueNAS server
scp drive-stress-test.sh root@192.168.7.195:~/

# SSH in and run (30-minute read-only test)
ssh root@192.168.7.195
chmod +x ~/drive-stress-test.sh
./drive-stress-test.sh /dev/ada2

# Longer test
./drive-stress-test.sh /dev/ada2 60

# Destructive write+verify on a blank drive
./drive-stress-test.sh --write-test /dev/ada2
```

**Important:** The script refuses to run on a device that is part of an ONLINE ZFS pool. You must offline or detach the drive first:

```
zpool offline Mir1 ada2
./drive-stress-test.sh /dev/ada2
zpool online Mir1 ada2
```

## What It Tests

### Phase 1: Sequential Read
Reads the entire drive surface sequentially in 100MB chunks. Measures sustained throughput and catches bad sectors that would cause read errors. A healthy HDD should sustain 80-150 MB/s; a healthy SSD should sustain 300-500+ MB/s.

### Phase 2: Random Read
Reads 64KB blocks at random offsets across the drive. Stresses the seek mechanism on HDDs and catches issues with specific platters or heads. Also reveals thermal throttling under sustained random workload.

### Phase 3: Mixed Read
Alternates between 50MB sequential bursts and batches of 10 random reads. Simulates a realistic workload pattern where the drive has to switch between sequential and random access.

### Phase 4: Write + Verify (--write-test only)
**Destructive — erases all data.** Writes known patterns (0x00, 0xFF, 0xAA) across the drive and reads them back, verifying checksums. Catches silent corruption and weak sectors that read-only tests can't find.

## Interpreting Results

### Exit Codes
| Code | Meaning |
|------|---------|
| 0 | **PASS** — no I/O errors, no SMART degradation |
| 1 | **FAIL** — I/O errors detected or SMART counters increased |
| 2 | **ABORT** — device disappeared during the test |

### SMART Attributes Checked
The script captures SMART data before and after the test and flags any increase in these critical counters:

| Attribute | ID | What It Means |
|-----------|----|---------------|
| Reallocated Sector Count | 5 | Drive has remapped bad sectors to spares. Increasing = drive is actively failing. |
| Current Pending Sector | 197 | Sectors the drive suspects are bad but hasn't confirmed yet. |
| Offline Uncorrectable | 198 | Sectors that couldn't be read even during offline testing. |
| UDMA CRC Error Count | 199 | SATA link errors — indicates a bad cable, loose connector, or flaky backplane. |

### What to Look For

**Healthy drive:**
- Consistent throughput throughout (no sudden drops)
- Zero I/O errors
- SMART counters unchanged before/after
- No new dmesg entries
- Exit code 0

**Dying drive:**
- I/O errors during sequential or random reads
- SMART reallocated or pending sectors increasing
- Throughput drops significantly over time (thermal issues or head instability)
- Drive disappears mid-test (exit code 2)

**Connection problem (not the drive):**
- CRC errors increase (UDMA CRC Error Count, ID 199)
- Drive detaches and reattaches in dmesg
- Same drive passes when connected to a different port/cable
- Multiple "unrelated" drives fail in the same cage slot

### CRC Errors Specifically

A CRC error increase during testing is **not a drive failure** — it's a connection problem. The SATA link between the drive and the controller is corrupting data in transit. Check:
- Cable seating (push firmly)
- Cable quality (try a different cable)
- Backplane/cage connector (bypass the cage and test direct SATA)
- Port multiplier or SAS expander port (try a different port)

## Log Files

Each run creates a log file in the current directory:
```
drive-test-ada2-20260201-143022.log
```

The log contains all progress updates, error messages, SMART snapshots, and dmesg entries. Keep these for comparison when testing the same drive on different connections.
