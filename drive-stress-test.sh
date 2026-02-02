#!/bin/sh
# drive-stress-test.sh — Sustained I/O stress test for FreeBSD/TrueNAS
# Uses only built-in tools: dd, smartctl, diskinfo, iostat, sha256, dmesg
# Exit codes: 0=PASS, 1=FAIL, 2=ABORT (device disappeared)

set -u

VERSION="1.0"
BLOCK_SIZE="1m"
RANDOM_BLOCK_SIZE="65536"  # 64K for random reads
PROGRESS_INTERVAL=30       # seconds between progress updates
DMESG_BASELINE=""
LOG_FILE=""
DEVICE=""
DEVICE_SHORT=""
DURATION=30
WRITE_TEST=0
FAIL=0
ABORT=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [options] /dev/adaX [duration_minutes]

Sustained I/O stress test for drive health verification.
Read-only by default. Tests sequential reads, random reads, and mixed I/O.

Options:
  --write-test    Enable DESTRUCTIVE write+verify test (erases all data!)
  --help          Show this help message

Arguments:
  /dev/adaX       The raw device to test (e.g., /dev/ada2, /dev/da0)
  duration        Test duration in minutes (default: 30)

Examples:
  $(basename "$0") /dev/ada2              # 30-minute read-only test
  $(basename "$0") /dev/ada2 60           # 60-minute read-only test
  $(basename "$0") --write-test /dev/ada2 # 30-min read + write-verify test

Exit codes:
  0  PASS — no errors, SMART healthy
  1  FAIL — I/O errors or SMART degradation detected
  2  ABORT — device disappeared during test
EOF
    exit 0
}

log() {
    _msg="$(date '+%Y-%m-%d %H:%M:%S') $1"
    echo "$_msg"
    [ -n "$LOG_FILE" ] && echo "$_msg" >> "$LOG_FILE"
}

log_section() {
    log "========================================"
    log "$1"
    log "========================================"
}

# Check if device still exists
check_device_alive() {
    if [ ! -c "$DEVICE" ]; then
        log "ABORT: Device $DEVICE has disappeared!"
        ABORT=1
        return 1
    fi
    return 0
}

# Check dmesg for new errors related to our device since baseline
check_dmesg_errors() {
    _current_lines=$(dmesg | wc -l)
    _baseline_lines=$(echo "$DMESG_BASELINE" | wc -l)
    if [ "$_current_lines" -gt "$_baseline_lines" ]; then
        _new=$(dmesg | tail -n +"$((_baseline_lines + 1))")
        _dev_errors=$(echo "$_new" | grep -i "$DEVICE_SHORT" | grep -iE "error|fail|timeout|fault|detach|destroy" || true)
        if [ -n "$_dev_errors" ]; then
            log "WARNING: New dmesg errors for $DEVICE_SHORT:"
            echo "$_dev_errors" | while IFS= read -r _line; do
                log "  $_line"
            done
            return 1
        fi
    fi
    return 0
}

# Extract a numeric SMART attribute value by ID
smart_attr() {
    _data="$1"
    _id="$2"
    echo "$_data" | awk -v id="$_id" '$1 == id { print $10 }'
}

# ============================================================
# Parse arguments
# ============================================================
while [ $# -gt 0 ]; do
    case "$1" in
        --write-test) WRITE_TEST=1; shift ;;
        --help|-h) usage ;;
        /dev/*) DEVICE="$1"; shift ;;
        [0-9]*) DURATION="$1"; shift ;;
        *) echo "Unknown argument: $1"; usage ;;
    esac
done

if [ -z "$DEVICE" ]; then
    echo "Error: No device specified."
    usage
fi

DEVICE_SHORT=$(basename "$DEVICE")
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="drive-test-${DEVICE_SHORT}-${TIMESTAMP}.log"

log_section "Drive Stress Test v${VERSION}"
log "Device:    $DEVICE"
log "Duration:  ${DURATION} minutes"
log "Write test: $([ $WRITE_TEST -eq 1 ] && echo 'ENABLED (DESTRUCTIVE)' || echo 'disabled')"
log "Log file:  $LOG_FILE"

# ============================================================
# Pre-flight checks
# ============================================================
log_section "Phase 0: Pre-flight Checks"

# Device exists?
if [ ! -c "$DEVICE" ]; then
    log "FATAL: $DEVICE does not exist or is not a character device."
    exit 2
fi

# Check if device is part of an ONLINE ZFS pool
_zpool_match=$(zpool status 2>/dev/null | grep -E "ONLINE|DEGRADED|FAULTED" | grep "$DEVICE_SHORT" || true)
if [ -n "$_zpool_match" ]; then
    _pool_name=$(zpool status 2>/dev/null | grep -B100 "$DEVICE_SHORT" | grep "pool:" | tail -1 | awk '{print $2}')
    log "FATAL: $DEVICE_SHORT is part of pool '$_pool_name' and is ONLINE."
    log "Offline or detach the device first:"
    log "  zpool offline $_pool_name $DEVICE_SHORT"
    log "  zpool detach $_pool_name $DEVICE_SHORT"
    exit 1
fi

# Also check by gptid — ZFS often references drives by GPT label, not device name
_gptids=$(glabel status 2>/dev/null | grep "$DEVICE_SHORT" | awk '{print $1}' || true)
if [ -n "$_gptids" ]; then
    for _gid in $_gptids; do
        _gpt_match=$(zpool status 2>/dev/null | grep -E "ONLINE|DEGRADED" | grep "$_gid" || true)
        if [ -n "$_gpt_match" ]; then
            _pool_name=$(zpool status 2>/dev/null | grep -B100 "$_gid" | grep "pool:" | tail -1 | awk '{print $2}')
            log "FATAL: $DEVICE_SHORT (as $_gid) is part of pool '$_pool_name' and is ONLINE."
            log "Offline or detach the device first."
            exit 1
        fi
    done
fi

# Drive geometry
log ""
log "Drive info (diskinfo):"
_diskinfo=$(diskinfo -v "$DEVICE" 2>&1) || true
echo "$_diskinfo" | head -20 | while IFS= read -r _line; do log "  $_line"; done
_drive_bytes=$(diskinfo "$DEVICE" 2>/dev/null | awk '{print $3}')
_drive_gb=$((_drive_bytes / 1073741824))
log "  Drive size: ${_drive_gb} GB (${_drive_bytes} bytes)"

# SMART baseline
log ""
log "SMART baseline:"
SMART_BEFORE=$(smartctl -a "$DEVICE" 2>&1) || true
_smart_health=$(echo "$SMART_BEFORE" | grep "SMART overall-health" || echo "(could not read)")
log "  $_smart_health"

_realloc_before=$(smart_attr "$SMART_BEFORE" 5)
_pending_before=$(smart_attr "$SMART_BEFORE" 197)
_uncorr_before=$(smart_attr "$SMART_BEFORE" 198)
_crc_before=$(smart_attr "$SMART_BEFORE" 199)

log "  Reallocated sectors: ${_realloc_before:-(n/a)}"
log "  Pending sectors:     ${_pending_before:-(n/a)}"
log "  Uncorrectable:       ${_uncorr_before:-(n/a)}"
log "  CRC errors:          ${_crc_before:-(n/a)}"

# dmesg baseline
DMESG_BASELINE=$(dmesg)

log ""
log "Pre-flight complete. Starting tests."

# ============================================================
# Calculate phase durations
# ============================================================
TOTAL_SECONDS=$((DURATION * 60))

if [ $WRITE_TEST -eq 1 ]; then
    # With write test: 30% sequential, 30% random, 15% mixed, 25% write+verify
    SEQ_SECONDS=$((TOTAL_SECONDS * 30 / 100))
    RAND_SECONDS=$((TOTAL_SECONDS * 30 / 100))
    MIX_SECONDS=$((TOTAL_SECONDS * 15 / 100))
    WRITE_SECONDS=$((TOTAL_SECONDS * 25 / 100))
else
    # Read-only: 40% sequential, 40% random, 20% mixed
    SEQ_SECONDS=$((TOTAL_SECONDS * 40 / 100))
    RAND_SECONDS=$((TOTAL_SECONDS * 40 / 100))
    MIX_SECONDS=$((TOTAL_SECONDS * 20 / 100))
    WRITE_SECONDS=0
fi

# ============================================================
# Phase 1: Sequential Read
# ============================================================
log_section "Phase 1: Sequential Read (${SEQ_SECONDS}s)"

_seq_start=$(date +%s)
_seq_bytes=0
_seq_errors=0
_seq_passes=0
_last_progress=$(date +%s)

while true; do
    _now=$(date +%s)
    _elapsed=$((_now - _seq_start))
    [ "$_elapsed" -ge "$SEQ_SECONDS" ] && break

    check_device_alive || break

    # Read 100MB chunks, timed
    _chunk_out=$(dd if="$DEVICE" of=/dev/null bs="$BLOCK_SIZE" count=100 skip=$((_seq_passes * 100)) 2>&1) || {
        _seq_errors=$((_seq_errors + 1))
        log "ERROR: Sequential read failed at pass $_seq_passes"
    }
    _chunk_bytes=$(echo "$_chunk_out" | grep "bytes transferred" | awk '{print $1}')
    [ -n "$_chunk_bytes" ] && _seq_bytes=$((_seq_bytes + _chunk_bytes))
    _seq_passes=$((_seq_passes + 1))

    # Progress update
    if [ $((_now - _last_progress)) -ge "$PROGRESS_INTERVAL" ]; then
        _mb=$((_seq_bytes / 1048576))
        _rate=0
        [ "$_elapsed" -gt 0 ] && _rate=$((_seq_bytes / _elapsed / 1048576))
        log "  Progress: ${_mb} MB read, ${_rate} MB/s, ${_seq_errors} errors, ${_elapsed}/${SEQ_SECONDS}s"
        _last_progress=$_now

        if ! check_dmesg_errors; then
            _seq_errors=$((_seq_errors + 1))
        fi
    fi

    # If we've read past the end of the drive, wrap around
    _max_chunks=$((_drive_bytes / 104857600))  # 100MB chunks
    if [ $_seq_passes -ge "$_max_chunks" ]; then
        _seq_passes=0
        log "  Wrapped around — starting from beginning of drive"
    fi
done

_seq_elapsed=$(($(date +%s) - _seq_start))
_seq_mb=$((_seq_bytes / 1048576))
_seq_rate=0
[ "$_seq_elapsed" -gt 0 ] && _seq_rate=$((_seq_bytes / _seq_elapsed / 1048576))
log "Sequential read complete: ${_seq_mb} MB in ${_seq_elapsed}s (${_seq_rate} MB/s), ${_seq_errors} errors"

[ "$_seq_errors" -gt 0 ] && FAIL=1
[ "$ABORT" -eq 1 ] && { log "Device disappeared. Aborting."; exit 2; }

# ============================================================
# Phase 2: Random Read
# ============================================================
log_section "Phase 2: Random Read (${RAND_SECONDS}s)"

_rand_start=$(date +%s)
_rand_reads=0
_rand_errors=0
_rand_bytes=0
_last_progress=$(date +%s)

# Max offset in 64K blocks
_max_offset=$((_drive_bytes / RANDOM_BLOCK_SIZE - 1))
[ "$_max_offset" -le 0 ] && _max_offset=1

while true; do
    _now=$(date +%s)
    _elapsed=$((_now - _rand_start))
    [ "$_elapsed" -ge "$RAND_SECONDS" ] && break

    check_device_alive || break

    # Generate pseudo-random offset using /dev/urandom
    _rand_hex=$(dd if=/dev/urandom bs=4 count=1 2>/dev/null | od -An -tu4 | tr -d ' ')
    _offset=$((_rand_hex % _max_offset))

    # Read one 64K block at random offset
    dd if="$DEVICE" of=/dev/null bs="$RANDOM_BLOCK_SIZE" count=1 skip="$_offset" 2>/dev/null || {
        _rand_errors=$((_rand_errors + 1))
        log "ERROR: Random read failed at offset $_offset"
    }
    _rand_reads=$((_rand_reads + 1))
    _rand_bytes=$((_rand_bytes + RANDOM_BLOCK_SIZE))

    # Progress update
    if [ $((_now - _last_progress)) -ge "$PROGRESS_INTERVAL" ]; then
        _mb=$((_rand_bytes / 1048576))
        log "  Progress: ${_rand_reads} reads, ${_mb} MB, ${_rand_errors} errors, ${_elapsed}/${RAND_SECONDS}s"
        _last_progress=$_now

        if ! check_dmesg_errors; then
            _rand_errors=$((_rand_errors + 1))
        fi
    fi
done

_rand_elapsed=$(($(date +%s) - _rand_start))
_rand_mb=$((_rand_bytes / 1048576))
log "Random read complete: ${_rand_reads} reads, ${_rand_mb} MB in ${_rand_elapsed}s, ${_rand_errors} errors"

[ "$_rand_errors" -gt 0 ] && FAIL=1
[ "$ABORT" -eq 1 ] && { log "Device disappeared. Aborting."; exit 2; }

# ============================================================
# Phase 3: Mixed Read (alternating sequential + random)
# ============================================================
log_section "Phase 3: Mixed Read (${MIX_SECONDS}s)"

_mix_start=$(date +%s)
_mix_seq_bytes=0
_mix_rand_reads=0
_mix_errors=0
_mix_pass=0
_last_progress=$(date +%s)

while true; do
    _now=$(date +%s)
    _elapsed=$((_now - _mix_start))
    [ "$_elapsed" -ge "$MIX_SECONDS" ] && break

    check_device_alive || break

    # Alternate: even passes do sequential, odd do random
    if [ $((_mix_pass % 2)) -eq 0 ]; then
        # Sequential: 50MB burst
        _skip=$((_mix_pass / 2 * 50))
        _max_skip=$((_drive_bytes / 1048576 - 50))
        [ "$_skip" -gt "$_max_skip" ] && _skip=0
        dd if="$DEVICE" of=/dev/null bs="$BLOCK_SIZE" count=50 skip="$_skip" 2>/dev/null || {
            _mix_errors=$((_mix_errors + 1))
        }
        _mix_seq_bytes=$((_mix_seq_bytes + 52428800))
    else
        # Random: 10 random reads
        _i=0
        while [ $_i -lt 10 ]; do
            _rand_hex=$(dd if=/dev/urandom bs=4 count=1 2>/dev/null | od -An -tu4 | tr -d ' ')
            _offset=$((_rand_hex % _max_offset))
            dd if="$DEVICE" of=/dev/null bs="$RANDOM_BLOCK_SIZE" count=1 skip="$_offset" 2>/dev/null || {
                _mix_errors=$((_mix_errors + 1))
            }
            _mix_rand_reads=$((_mix_rand_reads + 1))
            _i=$((_i + 1))
        done
    fi
    _mix_pass=$((_mix_pass + 1))

    # Progress update
    if [ $((_now - _last_progress)) -ge "$PROGRESS_INTERVAL" ]; then
        _seq_mb=$((_mix_seq_bytes / 1048576))
        log "  Progress: ${_seq_mb} MB seq + ${_mix_rand_reads} random reads, ${_mix_errors} errors, ${_elapsed}/${MIX_SECONDS}s"
        _last_progress=$_now

        if ! check_dmesg_errors; then
            _mix_errors=$((_mix_errors + 1))
        fi
    fi
done

_mix_elapsed=$(($(date +%s) - _mix_start))
_mix_seq_mb=$((_mix_seq_bytes / 1048576))
log "Mixed read complete: ${_mix_seq_mb} MB seq + ${_mix_rand_reads} random in ${_mix_elapsed}s, ${_mix_errors} errors"

[ "$_mix_errors" -gt 0 ] && FAIL=1
[ "$ABORT" -eq 1 ] && { log "Device disappeared. Aborting."; exit 2; }

# ============================================================
# Phase 4: Write + Verify (only with --write-test)
# ============================================================
if [ $WRITE_TEST -eq 1 ]; then
    log_section "Phase 4: Write + Verify (${WRITE_SECONDS}s) — DESTRUCTIVE"
    log "WARNING: This will DESTROY all data on $DEVICE!"

    _write_start=$(date +%s)
    _write_errors=0
    _patterns="00 ff aa"
    _chunk_mb=100
    _chunks_per_pattern=$((WRITE_SECONDS / 3 / 2))  # time per pattern, halved (write+read)
    [ "$_chunks_per_pattern" -le 0 ] && _chunks_per_pattern=1

    for _pat in $_patterns; do
        _now=$(date +%s)
        [ $((_now - _write_start)) -ge "$WRITE_SECONDS" ] && break

        check_device_alive || break

        log "  Writing pattern 0x${_pat}..."

        # Write pattern
        _w=0
        while [ $_w -lt "$_chunks_per_pattern" ]; do
            _now=$(date +%s)
            [ $((_now - _write_start)) -ge "$WRITE_SECONDS" ] && break

            # Generate pattern block and write
            dd if=/dev/zero bs="${BLOCK_SIZE}" count="$_chunk_mb" 2>/dev/null | \
                tr '\000' "$(printf "\\$(printf '%03o' "0x$_pat")")" | \
                dd of="$DEVICE" bs="${BLOCK_SIZE}" seek=$((_w * _chunk_mb)) count="$_chunk_mb" 2>/dev/null || {
                    _write_errors=$((_write_errors + 1))
                    log "ERROR: Write failed at chunk $_w with pattern 0x${_pat}"
                }
            _w=$((_w + 1))
        done

        log "  Verifying pattern 0x${_pat}..."

        # Read back and verify
        _v=0
        while [ $_v -lt "$_w" ]; do
            _now=$(date +%s)
            [ $((_now - _write_start)) -ge "$WRITE_SECONDS" ] && break

            check_device_alive || break

            # Generate expected hash
            _expected=$(dd if=/dev/zero bs="${BLOCK_SIZE}" count="$_chunk_mb" 2>/dev/null | \
                tr '\000' "$(printf "\\$(printf '%03o' "0x$_pat")")" | sha256)
            # Read actual and hash
            _actual=$(dd if="$DEVICE" bs="${BLOCK_SIZE}" skip=$((_v * _chunk_mb)) count="$_chunk_mb" 2>/dev/null | sha256)

            if [ "$_expected" != "$_actual" ]; then
                _write_errors=$((_write_errors + 1))
                log "ERROR: Verify mismatch at chunk $_v with pattern 0x${_pat}"
                log "  Expected: $_expected"
                log "  Actual:   $_actual"
            fi
            _v=$((_v + 1))
        done

        log "  Pattern 0x${_pat}: wrote $_w chunks, verified $_v chunks"
    done

    _write_elapsed=$(($(date +%s) - _write_start))
    log "Write+verify complete in ${_write_elapsed}s, ${_write_errors} errors"

    [ "$_write_errors" -gt 0 ] && FAIL=1
    [ "$ABORT" -eq 1 ] && { log "Device disappeared. Aborting."; exit 2; }
fi

# ============================================================
# Post-flight
# ============================================================
log_section "Post-flight Analysis"

check_device_alive || { log "Device disappeared before post-flight."; exit 2; }

# SMART after
SMART_AFTER=$(smartctl -a "$DEVICE" 2>&1) || true
_smart_health_after=$(echo "$SMART_AFTER" | grep "SMART overall-health" || echo "(could not read)")
log "SMART health: $_smart_health_after"

_realloc_after=$(smart_attr "$SMART_AFTER" 5)
_pending_after=$(smart_attr "$SMART_AFTER" 197)
_uncorr_after=$(smart_attr "$SMART_AFTER" 198)
_crc_after=$(smart_attr "$SMART_AFTER" 199)

log ""
log "SMART attribute changes:"
log "                        Before  -> After"
log "  Reallocated sectors:  ${_realloc_before:-(n/a)}  -> ${_realloc_after:-(n/a)}"
log "  Pending sectors:      ${_pending_before:-(n/a)}  -> ${_pending_after:-(n/a)}"
log "  Uncorrectable:        ${_uncorr_before:-(n/a)}  -> ${_uncorr_after:-(n/a)}"
log "  CRC errors:           ${_crc_before:-(n/a)}  -> ${_crc_after:-(n/a)}"

# Flag any SMART degradation
_smart_fail=0
if [ -n "$_realloc_before" ] && [ -n "$_realloc_after" ]; then
    [ "$_realloc_after" -gt "$_realloc_before" ] && {
        log "FAIL: Reallocated sector count increased!"
        _smart_fail=1
    }
fi
if [ -n "$_pending_before" ] && [ -n "$_pending_after" ]; then
    [ "$_pending_after" -gt "$_pending_before" ] && {
        log "FAIL: Pending sector count increased!"
        _smart_fail=1
    }
fi
if [ -n "$_uncorr_before" ] && [ -n "$_uncorr_after" ]; then
    [ "$_uncorr_after" -gt "$_uncorr_before" ] && {
        log "FAIL: Uncorrectable error count increased!"
        _smart_fail=1
    }
fi
if [ -n "$_crc_before" ] && [ -n "$_crc_after" ]; then
    [ "$_crc_after" -gt "$_crc_before" ] && {
        log "FAIL: CRC error count increased (cable/connection issue)!"
        _smart_fail=1
    }
fi
[ "$_smart_fail" -eq 1 ] && FAIL=1

# New dmesg entries
log ""
log "New dmesg entries since test started:"
_current_lines=$(dmesg | wc -l)
_baseline_lines=$(echo "$DMESG_BASELINE" | wc -l)
if [ "$_current_lines" -gt "$_baseline_lines" ]; then
    _new_msgs=$(dmesg | tail -n +"$((_baseline_lines + 1))")
    _dev_msgs=$(echo "$_new_msgs" | grep -i "$DEVICE_SHORT" || true)
    if [ -n "$_dev_msgs" ]; then
        echo "$_dev_msgs" | while IFS= read -r _line; do log "  $_line"; done
    else
        log "  (none related to $DEVICE_SHORT)"
    fi
else
    log "  (none)"
fi

# ============================================================
# Summary
# ============================================================
log_section "RESULTS"

_total_elapsed=$(($(date +%s) - _seq_start))
_total_errors=$((_seq_errors + _rand_errors + _mix_errors))
[ $WRITE_TEST -eq 1 ] && _total_errors=$((_total_errors + _write_errors))

log "Device:          $DEVICE ($DEVICE_SHORT)"
log "Duration:        ${_total_elapsed}s (requested ${DURATION}m)"
log "I/O errors:      $_total_errors"
log "SMART degraded:  $([ $_smart_fail -eq 1 ] && echo 'YES' || echo 'no')"
log "dmesg errors:    $(check_dmesg_errors > /dev/null 2>&1 && echo 'no' || echo 'YES')"
log ""

if [ $FAIL -eq 1 ]; then
    log ">>> RESULT: FAIL <<<"
    log "Drive exhibited errors during testing. Review log: $LOG_FILE"
    exit 1
else
    log ">>> RESULT: PASS <<<"
    log "No errors detected. Full log: $LOG_FILE"
    exit 0
fi
