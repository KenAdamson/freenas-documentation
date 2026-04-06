#!/bin/sh
# hot-chips.sh — Report temperatures for the hot chips in the SAS fabric
# and all attached pool drives on the TrueNAS server.
#
# Covers:
#   - LSI SAS3008 HBA (mpr0)            — via mprutil
#   - Adaptec AEC-82885T SAS expander   — via SES temperature element on ses1
#   - Intel Optane SLOG (nvd0)          — via smartctl
#   - Pool drives (ada/da)              — via smartctl
#
# Usage: ./hot-chips.sh
#
# Requires: mprutil, getencstat, smartctl, nvmecontrol. All ship with TrueNAS
# CORE. POSIX sh + standard awk only — no bash, no gawk dependencies.

set -u

HBA_DEV="${HBA_DEV:-0}"
EXPANDER_DEV="${EXPANDER_DEV:-/dev/ses1}"
WARN_C="${WARN_C:-85}"
CRIT_C="${CRIT_C:-95}"

# --- formatting helpers ---------------------------------------------------

color_for_temp() {
    # $1 = temp in C. Echo an ANSI color code based on WARN_C / CRIT_C.
    # Coerce to int to avoid shell interpreting "069" as (invalid) octal.
    t=$(( ${1:-0} + 0 )) 2>/dev/null || t=0
    [ -t 1 ] || { echo ""; return; }
    if [ "$t" -ge "$CRIT_C" ]; then
        printf '\033[1;31m'   # bright red
    elif [ "$t" -ge "$WARN_C" ]; then
        printf '\033[1;33m'   # bright yellow
    else
        printf '\033[0;32m'   # green
    fi
}
reset_color() {
    [ -t 1 ] || { echo ""; return; }
    printf '\033[0m'
}

report() {
    # $1 = label, $2 = temp in C (integer), $3 = notes
    label="$1"
    temp="$2"
    notes="${3:-}"
    if [ -z "$temp" ]; then
        printf '  %-28s  %s\n' "$label" "(unavailable)"
        return
    fi
    color=$(color_for_temp "$temp")
    reset=$(reset_color)
    printf '  %-28s  %s%3d °C%s  %s\n' "$label" "$color" "$temp" "$reset" "$notes"
}

# --- HBA (LSI SAS3008) ----------------------------------------------------

hba_temp() {
    mprutil -u "$HBA_DEV" show adapter 2>/dev/null \
        | awk '/Temperature:/ {print $2; exit}'
}

# --- SAS Expander (Adaptec AEC-82885T) ------------------------------------
#
# SES-3 Temperature Sensor element status bytes:
#   byte 0: overall status code (0x01 = OK)
#   byte 1: reserved
#   byte 2: temperature, +20 °C offset (so actual = byte2 - 20)
#   byte 3: warning/critical flags
#
# We look for the first Temperature Sensor element with status "OK" on the
# given /dev/ses* device and decode byte 2.

expander_temp() {
    hex=$(getencstat -v "$EXPANDER_DEV" 2>/dev/null \
        | awk '/Temperature Sensor.*status: OK/ {
                split($0, a, /[()]/);
                split(a[2], b, " ");
                print b[3];
                exit;
              }')
    [ -n "$hex" ] || return
    raw=$(printf '%d' "$hex" 2>/dev/null) || return
    echo $(( raw - 20 ))
}

# --- NVMe (Optane SLOG) ---------------------------------------------------

nvme_temp() {
    # $1 = nvme device (e.g. nvme0)
    # nvmecontrol logpage -p 2 prints lines like:
    #   Temperature:                    303 K, 29.85 C, 85.73 F
    # We want the Celsius value (integer).
    nvmecontrol logpage -p 2 "$1" 2>/dev/null | awk '
        /Temperature:[[:space:]]+[0-9]+[[:space:]]*K/ {
            # split on "," and look for the " C" field
            for (i=1; i<=NF; i++) {
                if ($i == "C," || $i == "C") {
                    print int($(i-1) + 0.5);
                    exit;
                }
            }
        }'
}

# --- SATA/SAS drive temperature ------------------------------------------

drive_temp() {
    # $1 = device (e.g. ada0, da3).
    #
    # SMART attribute lines look like:
    #   194 Temperature_Celsius  0x0032  100 100 000  Old_age  Always  -  41 (Min/Max 16/106)
    # The RAW_VALUE (the actual reading in °C) is the field immediately after
    # the "-" marker. The preceding fields are normalized/worst/threshold
    # values that sometimes have leading zeros and must not be confused with
    # the temperature.

    smartctl -A "/dev/$1" 2>/dev/null | awk '
        /Temperature_Celsius|Airflow_Temperature_Cel|Temperature_Internal/ {
            for (i=1; i<=NF; i++) {
                if ($i == "-" && i < NF) {
                    t = int($(i+1) + 0)
                    if (t > 0 && t < 120) { print t; exit }
                }
            }
        }
        /Current Drive Temperature/ {
            # SCSI-style: "Current Drive Temperature:     35 C"
            for (i=1; i<=NF; i++) {
                if (($i == "C" || $i == "C,") && i > 1) {
                    t = int($(i-1) + 0)
                    if (t > 0 && t < 120) { print t; exit }
                }
            }
        }'
}

# --- main -----------------------------------------------------------------

echo "SAS fabric"
report "LSI SAS3008 HBA (mpr0)"       "$(hba_temp)"        "warn ${WARN_C}°C / crit ${CRIT_C}°C"
report "Adaptec AEC-82885T expander"  "$(expander_temp)"   "warn ${WARN_C}°C / crit ${CRIT_C}°C"

echo
echo "NVMe"
# Find the first nvme device (Optane SLOG).
for n in nvme0 nvme1; do
    if nvmecontrol devlist 2>/dev/null | grep -q "^ $n:"; then
        model=$(nvmecontrol devlist 2>/dev/null | awk -v d="$n:" '$0 ~ d {$1=""; print; exit}' | sed 's/^[[:space:]]*//')
        report "$n ($model)" "$(nvme_temp $n)"
    fi
done

echo
echo "SATA / SAS drives"
# Enumerate pool drives from camcontrol so we pick up everything currently attached.
drives=$(camcontrol devlist 2>/dev/null \
    | awk -F'[()]' '{
        split($2, parts, ",");
        for (i in parts) {
            d = parts[i];
            sub(/^ +/, "", d); sub(/ +$/, "", d);
            if (d ~ /^(ada|da)[0-9]+$/) print d;
        }
    }' | sort -u)

for d in $drives; do
    t=$(drive_temp "$d")
    [ -n "$t" ] && report "$d" "$t"
done
