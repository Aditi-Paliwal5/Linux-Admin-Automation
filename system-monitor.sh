
#!/bin/bash

set -u

REPORT_DIR="/report"

# Create the report directory if it does not exist.
if ! mkdir -p "$REPORT_DIR"; then
    echo "ERROR: Cannot create report directory."
    exit 1
fi

# This script requires root privileges for reliable system reporting.
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run with sudo or as root."
    exit 1
fi

# Capture total CPU time and idle CPU time from /proc/stat.
cpu_stats() {
    awk '/^cpu / {
        idle = $5 + $6
        total = 0
        for (i = 2; i <= NF; i++) {
            total += $i
        }
        printf "%.0f %.0f\n", total, idle
        exit
    }' /proc/stat
}

# Take two readings one second apart.
read -r total1 idle1 < <(cpu_stats)
sleep 1
read -r total2 idle2 < <(cpu_stats)

total_diff=$((total2 - total1))
idle_diff=$((idle2 - idle1))

if (( total_diff > 0 )); then
    cpu_usage=$(awk -v t="$total_diff" -v i="$idle_diff" \
        'BEGIN { printf "%.1f", 100 * (t - i) / t }')
else
    cpu_usage="N/A"
fi

# Calculate memory usage from /proc/meminfo.
memory_usage=$(awk '
    /^MemTotal:/ { total = $2 }
    /^MemAvailable:/ { available = $2 }
    END {
        if (total > 0) {
            printf "%.1f", 100 * (total - available) / total
        } else {
            print "N/A"
        }
    }
' /proc/meminfo)

# Get usage percentage for the filesystem containing /home.
disk_usage=$(df -P /home | awk 'NR == 2 {print $5}')

if [[ -z "$disk_usage" ]]; then
    disk_usage="N/A"
fi

# Generate a unique timestamp-based report filename.
timestamp=$(date '+%Y%m%d_%H%M%S')
report_file="$REPORT_DIR/system-performance-$timestamp.txt"

# Write the report.
{
    echo "System Performance Report - $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "-----------------------------------------------"
    echo "CPU Usage: ${cpu_usage}%"
    echo "Memory Usage: ${memory_usage}%"
    echo "Disk Usage: /home (${disk_usage})"
    echo "-----------------------------------------------"
} > "$report_file"

if [[ $? -eq 0 ]]; then
    chmod 640 "$report_file"
    echo "Report generated: $report_file"
else
    echo "ERROR: Failed to write report."
    exit 1
fi

