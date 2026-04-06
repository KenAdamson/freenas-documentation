#!/bin/sh
# hot-chips-log.sh — Periodically sample hot-chips.sh and write a
# single-line-per-sample log suitable for eyeballing or feeding to
# awk/gnuplot/sqlite later.
#
# Usage:
#   ./hot-chips-log.sh [interval_seconds] [output_file]
#
# Defaults:
#   interval_seconds = 60
#   output_file      = stdout (pipe to tee if you want both)
#
# Example — run in a tmux session during a resilver:
#   tmux new -s templog './hot-chips-log.sh 60 /tmp/sas-temps.log'
#
# Output format (tab-separated, epoch + ISO timestamp for easy sort/grep):
#   epoch  iso  hba_c  expander_c  slog_c  ada0_c ... daN_c
#
# The header is printed once at the top of the output so column positions
# are self-describing. Missing values are logged as "-".

set -u

INTERVAL="${1:-60}"
OUTPUT="${2:-}"

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HOT_CHIPS="${HOT_CHIPS:-$SCRIPT_DIR/hot-chips.sh}"

if [ ! -x "$HOT_CHIPS" ]; then
    echo "ERROR: $HOT_CHIPS not found or not executable" >&2
    exit 1
fi

# Emit output to file if one was given, else stdout.
if [ -n "$OUTPUT" ]; then
    exec >> "$OUTPUT"
fi

# Strip ANSI color codes from hot-chips.sh output before parsing.
strip_ansi() {
    sed -e 's/\x1b\[[0-9;]*m//g'
}

# Pull an integer temp out of a hot-chips.sh line. The line format is
# "  <label>   NN °C  [notes]". We grab the field immediately before "°C".
extract_temp() {
    line="$1"
    echo "$line" | awk '
        {
            for (i=1; i<=NF; i++) {
                if ($i == "°C") { print $(i-1); exit }
            }
            print "-"
        }'
}

# Sample once and print a single tab-separated line.
sample_once() {
    snap=$("$HOT_CHIPS" 2>/dev/null | strip_ansi)

    hba=$(extract_temp "$(echo "$snap" | awk '/LSI SAS3008 HBA/')")
    exp=$(extract_temp "$(echo "$snap" | awk '/Adaptec AEC-82885T/')")
    slog=$(extract_temp "$(echo "$snap" | awk '/nvme0/')")

    # Drives — emit in the order hot-chips.sh reports them.
    drive_line=$(echo "$snap" | awk '
        /SATA \/ SAS drives/ { in_drives=1; next }
        in_drives && /^$/    { in_drives=0 }
        in_drives && /°C/ {
            label=$1
            for (i=1; i<=NF; i++) {
                if ($i == "°C") { printf "%s\t", $(i-1); break }
            }
        }
        END { printf "\n" }')

    # Drive labels (only used for the header row).
    if [ -z "${DRIVE_HEADER_PRINTED:-}" ]; then
        drive_labels=$(echo "$snap" | awk '
            /SATA \/ SAS drives/ { in_drives=1; next }
            in_drives && /^$/    { in_drives=0 }
            in_drives && /°C/    { printf "%s\t", $1 }
            END { printf "\n" }')
        printf 'epoch\tiso\thba_c\texp_c\tslog_c\t%s\n' "$drive_labels"
        DRIVE_HEADER_PRINTED=1
        export DRIVE_HEADER_PRINTED
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s' \
        "$(date +%s)" \
        "$(date +%Y-%m-%dT%H:%M:%S%z)" \
        "$hba" \
        "$exp" \
        "$slog" \
        "$drive_line"
}

# Graceful exit on Ctrl-C / TERM
trap 'echo "# stopped $(date +%Y-%m-%dT%H:%M:%S%z)" >&2; exit 0' INT TERM

echo "# hot-chips-log started $(date +%Y-%m-%dT%H:%M:%S%z), interval=${INTERVAL}s" >&2

while true; do
    sample_once
    sleep "$INTERVAL"
done
