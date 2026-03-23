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

### Checking Power Supply Status

1. **View Power Supply Information**
   ```
   ipmitool sdr type "Power Supply"
   ```

2. **Check System Temperatures**
   ```
   ipmitool sdr type "Temperature"
   ```

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

| Component | Idle | Load | Notes |
|-----------|------|------|-------|
| Optane SLOG (nvd0) | ~31°C | ~47°C | Active cooler, max fan |
| WD Red SA500 SSDs | 28-35°C | 39-43°C | Hottest components under sustained I/O |
| Spinners (WD Red, Seagate) | 25-30°C | 26-37°C | Adequate airflow from negative pressure |

### Fan Replacement Notes

- All chassis fan slots use 120mm fans
- Require fluid-dynamic bearing (FDB) fans for 24/7 NAS operation — sleeve bearings will fail prematurely
- be quiet! Silent Wings Pro 4 confirmed compatible as replacement
- BIOS does not expose PWM control via sysctl/IPMI — fan curves must be set in BIOS or via standalone PWM controller
