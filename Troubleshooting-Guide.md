# Troubleshooting Guide

This page provides solutions for common issues that may occur with the TrueNAS server.

## ZPool Issues

### Degraded Pool

**Symptoms:**
- ZPool shows as DEGRADED in `zpool status`
- One or more drives show as UNAVAIL or FAULTED

**Troubleshooting Steps:**
1. Identify the failed drive:
   ```
   zpool status
   ```

2. Check if the drive is physically accessible:
   ```
   smartctl -a /dev/[drive_id]
   ```

3. Verify the physical location using the [Physical Drive Layout](Physical-Drive-Layout.md) document

4. Replace the drive following the [Drive Replacement Procedure](Maintenance-Procedures.md#drive-replacement-procedure)

### Checksum Errors

**Symptoms:**
- `zpool status` shows checksum errors
- Files may be corrupted

**Troubleshooting Steps:**
1. Run a scrub to attempt automatic repairs:
   ```
   zpool scrub [pool_name]
   ```

2. Check which files are affected:
   ```
   zpool status -v [pool_name]
   ```

3. If errors persist after scrub, check drive health:
   ```
   smartctl -a /dev/[drive_id]
   ```

4. Consider replacing the drive if SMART tests indicate issues

### ZPool Import Failures

**Symptoms:**
- Unable to import ZPool after system restart
- "Pool cannot be imported" error

**Troubleshooting Steps:**
1. Try forcing the import:
   ```
   zpool import -f [pool_name]
   ```

2. If that fails, try recovery mode:
   ```
   zpool import -F [pool_name]
   ```

3. Check SAS connections and expander status (see [SAS Expander Configuration](SAS-Expander-Configuration.md))

4. Verify all drives are detected:
   ```
   camcontrol devlist
   ```

## Hardware Issues

### Drive Not Detected

**Symptoms:**
- Drive missing from `camcontrol devlist`
- Drive missing from TrueNAS web interface

**Troubleshooting Steps:**
1. Check physical connection:
   - Verify drive is properly seated in slot
   - Check SAS cable connections
   - Inspect SAS expander LEDs

2. Verify SAS expander can see the drive:
   ```
   sas2ircu [adapter_id] DISPLAY
   ```

3. Try reseating the drive or moving to a different slot

4. Replace SAS cables if necessary

### SAS Expander Issues

**Symptoms:**
- Multiple drives suddenly unavailable
- SAS expander error LEDs lit

**Troubleshooting Steps:**
1. Check SAS expander status:
   ```
   sas2ircu LIST
   ```

2. Verify all SAS cables are properly connected

3. Try restarting the system:
   ```
   shutdown -r now
   ```

4. If issues persist, try replacing SAS cables or the expander

### System Overheating

**Symptoms:**
- High temperature warnings in system logs
- Fans running at high speed
- System throttling or shutting down

**Troubleshooting Steps:**
1. Check system temperatures:
   ```
   ipmitool sdr type "Temperature"
   ```

2. Verify all fans are operational:
   ```
   ipmitool sdr type "Fan"
   ```

3. Check for dust buildup in the system
   - Clean air intakes and exhaust vents
   - Ensure proper airflow in the server room

4. Verify ambient temperature is within acceptable range (18-27°C)

## Performance Issues

### Slow Read/Write Speeds

**Symptoms:**
- File transfers are slower than expected
- Applications experience lag when accessing data

**Troubleshooting Steps:**
1. Check ZPool I/O statistics:
   ```
   zpool iostat -v 5
   ```

2. Verify ZFS ARC (cache) usage:
   ```
   arc_summary
   ```

3. Check for fragmentation:
   ```
   zpool list -v
   ```

4. Consider adding or expanding L2ARC (cache) or SLOG (ZIL) devices

### High CPU Usage

**Symptoms:**
- System feels sluggish
- High CPU usage shown in top or in TrueNAS dashboard

**Troubleshooting Steps:**
1. Identify processes using high CPU:
   ```
   top -o cpu
   ```

2. Check if deduplication is enabled (can be CPU intensive):
   ```
   zfs get dedup [pool_name]
   ```

3. Verify compression settings:
   ```
   zfs get compression [pool_name]
   ```

4. Consider adjusting ZFS dataset properties or upgrading CPU if necessary

## Network Issues

### Slow Network Performance

**Symptoms:**
- Slow file transfers over network
- Timeouts when accessing shares

**Troubleshooting Steps:**
1. Check network interface status:
   ```
   ifconfig
   ```

2. Test network speed:
   ```
   iperf3 -c [client_ip]
   ```

3. Verify jumbo frames if enabled:
   ```
   ping -s 8972 [gateway_ip]
   ```

4. Check for network errors:
   ```
   netstat -i
   ```

### SMB/CIFS Share Issues

**Symptoms:**
- Unable to access SMB shares
- Permission denied errors

**Troubleshooting Steps:**
1. Check SMB service status:
   ```
   service samba_server status
   ```

2. Verify permissions on the dataset:
   ```
   ls -la /mnt/[pool_name]/[dataset_name]
   ```

3. Check SMB configuration:
   ```
   midclt call smb.config
   ```

4. Restart SMB service:
   ```
   service samba_server restart
   ```

## System Recovery

### Boot Environment Issues

**Symptoms:**
- System fails to boot
- Boot loop

**Troubleshooting Steps:**
1. Access the boot menu by pressing F8 during startup
2. Select a previous boot environment
3. If successful, investigate what caused the current boot environment to fail
4. Create a new boot environment before making system changes

### Configuration Backup and Restore

**Recovery Steps:**
1. Access the TrueNAS web interface
2. Navigate to System > General > Upload Config
3. Select the previously saved configuration file
4. Restore the configuration
5. Reboot the system when prompted

## Emergency Procedures

### Emergency Power Loss Recovery

**Recovery Steps:**
1. Check all hardware for damage
2. Power on the system
3. Verify all ZPools import correctly:
   ```
   zpool import -f [pool_name]
   ```
4. Run a scrub on all pools:
   ```
   zpool scrub [pool_name]
   ```
5. Check system logs for errors:
   ```
   cat /var/log/messages
   ```

### Data Recovery from Failed Pool

**Recovery Steps:**
1. Do not make any changes to the failed pool
2. Try importing the pool in read-only mode:
   ```
   zpool import -o readonly=on [pool_name]
   ```
3. If successful, copy critical data to another storage
4. If unsuccessful, try recovery mode:
   ```
   zpool import -F [pool_name]
   ```
5. Consider professional data recovery services if critical data cannot be recovered

*Note: This is a template. Please replace with your actual troubleshooting procedures.*
