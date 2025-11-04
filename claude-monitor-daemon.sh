#!/bin/bash

# Claude Code Background Monitor Daemon
# Lightweight continuous monitoring with auto-restart

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs/claude-monitor"
DAEMON_LOG="$LOG_DIR/daemon.log"
RESOURCE_LOG="$LOG_DIR/daemon-resources.csv"
ALERT_LOG="$LOG_DIR/daemon-alerts.log"

mkdir -p "$LOG_DIR"

# Lightweight: only log every 30 seconds (not 2 seconds)
SAMPLE_INTERVAL=30

# PID file for daemon management
PID_FILE="/var/run/claude-monitor-daemon.pid"

# Log rotation settings
MAX_LOG_SIZE=10485760  # 10MB
MAX_RESOURCE_LINES=10000  # Keep last ~3 days at 30s intervals

log_daemon() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DAEMON_LOG"
}

log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" >> "$ALERT_LOG"
    log_daemon "ALERT: $1"
}

# Initialize resource log if needed
init_resource_log() {
    if [ ! -f "$RESOURCE_LOG" ]; then
        echo "timestamp,total_mem_mb,used_mem_mb,mem_percent,disk_percent,load_1m,claude_processes" > "$RESOURCE_LOG"
    fi
}

# Rotate logs if too large
rotate_logs() {
    # Rotate main daemon log
    if [ -f "$DAEMON_LOG" ] && [ $(stat -f%z "$DAEMON_LOG" 2>/dev/null || stat -c%s "$DAEMON_LOG" 2>/dev/null) -gt $MAX_LOG_SIZE ]; then
        mv "$DAEMON_LOG" "$DAEMON_LOG.old"
        log_daemon "Log rotated"
    fi

    # Trim resource log
    if [ -f "$RESOURCE_LOG" ]; then
        local line_count=$(wc -l < "$RESOURCE_LOG")
        if [ $line_count -gt $MAX_RESOURCE_LINES ]; then
            # Keep header + last MAX_RESOURCE_LINES
            (head -1 "$RESOURCE_LOG" && tail -n $MAX_RESOURCE_LINES "$RESOURCE_LOG") > "$RESOURCE_LOG.tmp"
            mv "$RESOURCE_LOG.tmp" "$RESOURCE_LOG"
            log_daemon "Resource log trimmed to $MAX_RESOURCE_LINES lines"
        fi
    fi
}

# Check for Claude Code or Node processes
check_claude_processes() {
    # Count node processes (likely Claude Code or Next.js)
    pgrep -f "node" 2>/dev/null | wc -l
}

# Collect system metrics
collect_metrics() {
    # Memory (in MB)
    local mem_total=$(free -m | grep "Mem:" | awk '{print $2}')
    local mem_used=$(free -m | grep "Mem:" | awk '{print $3}')
    local mem_percent=$(echo "scale=1; ($mem_used / $mem_total) * 100" | bc)

    # Disk usage (root partition)
    local disk_percent=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    # Load average (1 minute)
    local load_1m=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)

    # Claude/Node process count
    local claude_procs=$(check_claude_processes)

    # Log to CSV
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$mem_total,$mem_used,$mem_percent,$disk_percent,$load_1m,$claude_procs" >> "$RESOURCE_LOG"

    # Check thresholds and alert
    check_thresholds "$mem_percent" "$disk_percent" "$mem_used"
}

# Alert on threshold violations
check_thresholds() {
    local mem_percent=$1
    local disk_percent=$2
    local mem_used_mb=$3

    # Memory warning at 85%
    if [ $(echo "$mem_percent > 85" | bc) -eq 1 ]; then
        log_alert "High memory usage: ${mem_percent}% (${mem_used_mb}MB used)"
    fi

    # Disk warning at 90%
    if [ $disk_percent -gt 90 ]; then
        log_alert "High disk usage: ${disk_percent}%"
    fi

    # Check for OOM killer activity (last 1 minute)
    if dmesg -T 2>/dev/null | tail -50 | grep -i "out of memory" | grep -q "$(date '+%b %e')"; then
        log_alert "OOM killer detected in system logs!"
    fi
}

# Daemon startup
start_daemon() {
    log_daemon "=========================================="
    log_daemon "Claude Monitor Daemon Starting"
    log_daemon "PID: $$"
    log_daemon "Sample interval: ${SAMPLE_INTERVAL}s"
    log_daemon "=========================================="

    # Store PID
    echo $$ > "$PID_FILE"

    # Initialize
    init_resource_log

    # Main monitoring loop
    while true; do
        collect_metrics
        rotate_logs

        sleep $SAMPLE_INTERVAL
    done
}

# Daemon shutdown
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_daemon "Stopping daemon (PID: $pid)"
            kill "$pid"
            rm -f "$PID_FILE"
            log_daemon "Daemon stopped"
            return 0
        else
            log_daemon "Daemon not running (stale PID file)"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        log_daemon "Daemon not running (no PID file)"
        return 1
    fi
}

# Status check
status_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Claude Monitor Daemon is running (PID: $pid)"
            echo "Logs: $DAEMON_LOG"
            echo "Resources: $RESOURCE_LOG"
            echo "Alerts: $ALERT_LOG"

            # Show recent stats
            if [ -f "$RESOURCE_LOG" ]; then
                echo ""
                echo "Recent metrics (last 5 samples):"
                tail -5 "$RESOURCE_LOG" | column -t -s','
            fi

            return 0
        else
            echo "Daemon not running (stale PID file)"
            return 1
        fi
    else
        echo "Daemon not running"
        return 1
    fi
}

# Handle signals
trap 'log_daemon "Received SIGTERM, shutting down..."; exit 0' SIGTERM
trap 'log_daemon "Received SIGINT, shutting down..."; exit 0' SIGINT

# Command handling
case "${1:-start}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        sleep 2
        start_daemon
        ;;
    status)
        status_daemon
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
