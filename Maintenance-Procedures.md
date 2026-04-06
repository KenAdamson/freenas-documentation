# Maintenance Procedures

This page documents common maintenance procedures for the TrueNAS server.

## Scheduled Maintenance Tasks

| Task | Frequency | Description |
|------|-----------|-------------|
| SMART Tests | Weekly | Run short SMART tests weekly and long tests monthly |
| ZPool Scrub | Monthly | Verify data integrity and repair any corrupted data |
| Snapshots | Daily | Create and manage automated snapshots |
| Backup Verification | Monthly | Verify backup integrity |
| System Updates | Quarterly | Apply TrueNAS updates after testing |

## Drive Replacement Procedure

### Replacing a Failed Drive

1. **Identify the Failed Drive**
   ```
   zpool status
   ```
   Look for drives marked as UNAVAIL or FAULTED.

2. **Locate the Physical Drive**
   - Refer to the [Physical Drive Layout](Physical-Drive-Layout.md) document
   - Note the cage number, slot number, and SAS expander port

3. **Prepare for Replacement**
   - Ensure you have the correct replacement drive
   - Verify the model and capacity match the failed drive

4. **Replace the Drive**
   - Power down the system if hot-swap is not supported
   - Remove the failed drive from its slot
   - Insert the new drive in the same slot
   - Power up the system if it was powered down

5. **Rebuild the ZPool**
   ```
   zpool replace <pool_name> <old_device> <new_device>
   ```
   Example:
   ```
   zpool replace tank da3 /dev/da3
   ```

6. **Monitor Rebuild Progress**
   ```
   zpool status
   ```
   The resilver process will begin automatically.

## ZPool Scrub Procedure

1. **Start a Scrub**
   ```
   zpool scrub <pool_name>
   ```
   Example:
   ```
   zpool scrub tank
   ```

2. **Check Scrub Progress**
   ```
   zpool status
   ```

3. **Cancel a Scrub (if necessary)**
   ```
   zpool scrub -s <pool_name>
   ```

## Snapshot Management

### Creating Snapshots

1. **Create a Manual Snapshot**
   ```
   zfs snapshot <pool_name>/<dataset_name>@<snapshot_name>
   ```
   Example:
   ```
   zfs snapshot tank/documents@backup-2025-04-12
   ```

2. **List Snapshots**
   ```
   zfs list -t snapshot
   ```

3. **Delete a Snapshot**
   ```
   zfs destroy <pool_name>/<dataset_name>@<snapshot_name>
   ```

### Configuring Automated Snapshots

1. Navigate to **Storage > Snapshots** in the TrueNAS web interface
2. Click **Add** to create a new snapshot task
3. Configure the following:
   - Dataset: Select the dataset to snapshot
   - Recursive: Enable to include child datasets
   - Naming Schema: e.g., `auto-%Y-%m-%d-%H-%M`
   - Schedule: Set frequency (hourly, daily, weekly, etc.)
   - Retention Policy: Number of snapshots to keep

## System Updates

### Updating TrueNAS

1. **Backup Configuration**
   - Navigate to **System > General > Save Config**
   - Download the configuration file to a safe location

2. **Check for Updates**
   - Navigate to **System > Update**
   - Click **Check for Updates**

3. **Apply Updates**
   - Review available updates
   - Create a new boot environment if prompted
   - Apply updates and reboot when complete

4. **Verify System Status**
   - Check all ZPools are online
   - Verify services are running correctly
   - Test critical functionality

## Hardware Maintenance

### Checking Drive Health

1. **View SMART Status**
   ```
   smartctl -a /dev/da0
   ```
   Replace `da0` with the drive you want to check.

2. **Run SMART Tests**
   ```
   smartctl -t short /dev/da0   # Short test
   smartctl -t long /dev/da0    # Long test
   ```

3. **View Test Results**
   ```
   smartctl -l selftest /dev/da0
   ```

4. **Run Sustained I/O Stress Test**
   For drive verification after reseating, connection troubleshooting, or vetting replacement drives, see [Drive Stress Test](Drive-Stress-Test).
   ```
   ./drive-stress-test.sh /dev/ada2        # 30-minute read-only test
   ./drive-stress-test.sh --write-test /dev/ada2  # destructive write+verify
   ```

### Checking System Temperatures

The ASUS WS C246 PRO does not expose `ipmitool` (no BMC). Temperature data is collected through a few different interfaces depending on the component:

| Component | Tool | Notes |
|---|---|---|
| LSI SAS3008 HBA | `mprutil -u 0 show adapter` | Reports chip temperature in the "Temperature:" field. Typical: 75-80 °C under load. |
| Adaptec AEC-82885T expander | `getencstat -v /dev/ses1` | The "Temperature Sensor" element reports the PMC PM8074 ASIC temperature. Decode: actual °C = (byte 2 of the status tuple) − 20. |
| NVMe (Optane SLOG) | `nvmecontrol logpage -p 2 nvme0` | Parses the "Temperature: N K, N C, N F" line. |
| SATA drives | `smartctl -A /dev/adaX` | Look at attribute 194 `Temperature_Celsius` — the **RAW_VALUE** column (right after the "-" marker), not the normalized field. |

**One-shot: all hot chips at once.** Use the `hot-chips.sh` script in this repository:

```sh
./hot-chips.sh
```

Output looks like:

```
SAS fabric
  LSI SAS3008 HBA (mpr0)         76 °C  warn 85°C / crit 95°C
  Adaptec AEC-82885T expander    79 °C  warn 85°C / crit 95°C

NVMe
  nvme0 (INTEL MEMPEK1J032GAH)   31 °C

SATA / SAS drives
  ada0                           37 °C
  ada1                           27 °C
  ...
```

The script color-codes values by warning and critical thresholds (default 85 °C warn, 95 °C crit). Override with `WARN_C=80 CRIT_C=90 ./hot-chips.sh` if you want tighter bounds.

**Continuous logging:** for baseline collection during resilvers, scrubs, or cooling changes, use `hot-chips-log.sh`:

```sh
# Sample every 60 seconds to a log file; run in tmux so it survives disconnects
tmux new -s templog './hot-chips-log.sh 60 /var/log/sas-temps.log'
```

Output is tab-separated, one sample per line, with a header row identifying each column. Columns: `epoch`, `iso`, `hba_c`, `exp_c`, `slog_c`, then one column per attached drive. Missing values are logged as `-`. Feed it into `awk`, `sqlite`, or `gnuplot` for analysis.

**Manual decode of the expander temperature** (if you want to reproduce the script math by hand):

```sh
getencstat -v /dev/ses1 | grep "Temperature Sensor.*OK"
# Element 0x16: Temperature Sensor, status: OK (0x01 0x00 0x63 0x00), descriptor: 'Temperature 00  '
#                                               ^^^^ ^^^^ ^^^^ ^^^^
#                                               status    +20 offset
#                                                         ^^^^
#                                                         0x63 = 99
#                                                         99 - 20 = 79 °C
```

### Checking Power Supply Status

The NAS runs on a Seasonic Prime GX-1300 (single 12V rail, no BMC telemetry). Monitor the PSU indirectly:

- **UPS telemetry** (if the UPS is on USB/network) — reports load in watts and line voltage
- **Drive flapping as a canary** — the mirror-4 SA500 "failure" in March 2026 turned out to be a power/cable issue, not a drive issue. If drives start dropping intermittently and SMART looks clean, suspect power delivery before the drive.
- **Visual inspection** — PSU fan should be spinning under load (above ~30% — the GX-1300 runs fanless below that).

## Backup Procedures

### Creating a Full Backup

1. **Create a ZFS Snapshot**
   ```
   zfs snapshot -r tank@backup-full
   ```

2. **Send the Snapshot to Backup Pool**
   ```
   zfs send -R tank@backup-full | zfs receive -F backup/tank
   ```

### Creating an Incremental Backup

1. **Create a New Snapshot**
   ```
   zfs snapshot -r tank@backup-incremental
   ```

2. **Send Incremental Changes**
   ```
   zfs send -R -i tank@backup-full tank@backup-incremental | zfs receive -F backup/tank
   ```

*Note: This is a template. Please replace with your actual maintenance procedures.*

## Cooling Configuration (Updated 2026-03-23)

### Chassis: Thermaltake W100

- **Top exhaust**: 4x 120mm fans, set to max speed
- **Rear intake**: 1x 120mm be quiet! Silent Wings Pro 4 (FDB bearing, replaced failed original chassis fan)
- **Front**: Passive intake through drive bays (negative pressure pulls air in)
- **Airflow**: Negative pressure configuration — cool air enters through drive bays and rear, exhausts through top

### Optane SLOG Cooler

- **Device**: Intel MEMPEK1J032GAH (32GB M.2 Optane) — used as ZFS SLOG for Mir1 pool
- **Cooler**: Active M.2 heatsink with fan, set to max speed
- **Note**: The NVMe cooler fan uses sleeve bearings — monitor for bearing failure over time. Optane runs 31-47°C depending on write load.

### Temperature Baselines (idle / under load)

*Observed 2026-04-06 after PSU swap + Adaptec expander install.*

| Component | Idle | Load | Notes |
|---|---|---|---|
| LSI SAS3008 HBA (mpr0) | ~70°C | ~76-80°C | Has added fan; SAS3008 junction spec is ~100°C |
| Adaptec AEC-82885T expander | ~75°C | ~79-85°C | No dedicated fan; PMC PM8074 rated to 110°C junction |
| Intel Optane 32GB SLOG (nvd0) | ~31°C | ~47°C | Thermalright HR10 2280 PRO heatsink |
| WD Red SA500 SSDs | 28-35°C | 39-43°C | Hottest drives under sustained I/O |
| 8TB spinners (WD Red Plus, IronWolf) | 35-40°C | 40-45°C | On the Adaptec expander |
| 1TB-2TB 2.5"/3.5" spinners | 25-33°C | 30-38°C | Mix of AHCI and Adaptec |

**Thermal thresholds (SMART):**
- Informational: 40 °C
- Critical: 55 °C

The SAS fabric chips (HBA and expander) run substantially hotter than anything else in the case — they are SAS-3 ASICs designed to run in datacenter enclosures with forced air, and temperatures in the 75-85 °C range are normal and within spec. If either climbs above ~90 °C consistently, add a 40 mm fan pointed at the chip (the HBA already has one; the expander would be the next candidate).

### Fan Replacement Notes

- All chassis fan slots use 120mm fans
- Require fluid-dynamic bearing (FDB) fans for 24/7 NAS operation — sleeve bearings will fail prematurely
- be quiet! Silent Wings Pro 4 confirmed compatible as replacement
- BIOS does not expose PWM control via sysctl/IPMI — fan curves must be set in BIOS or via standalone PWM controller
