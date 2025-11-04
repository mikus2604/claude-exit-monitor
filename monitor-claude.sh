#!/bin/bash

# Claude Code Monitoring Script
# Logs resource usage, exit codes, and crash reasons

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs/claude-monitor"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/claude-monitor-$TIMESTAMP.log"
RESOURCE_LOG="$LOG_DIR/resources-$TIMESTAMP.csv"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

# Initialize resource log with headers
echo "timestamp,pid,cpu_percent,mem_mb,mem_percent,vsz_mb,rss_mb" > "$RESOURCE_LOG"

# Function to monitor process resources
monitor_process() {
    local pid=$1
    while kill -0 "$pid" 2>/dev/null; do
        # Get process stats
        if ps -p "$pid" -o pid,pcpu,pmem,vsz,rss --no-headers >/dev/null 2>&1; then
            read -r p_pid p_cpu p_mem p_vsz p_rss <<< $(ps -p "$pid" -o pid=,pcpu=,pmem=,vsz=,rss= --no-headers)

            # Convert KB to MB
            vsz_mb=$(echo "scale=2; $p_vsz / 1024" | bc)
            rss_mb=$(echo "scale=2; $p_rss / 1024" | bc)
            mem_mb=$(echo "scale=2; $rss_mb" | bc)

            # Log to CSV
            echo "$(date '+%Y-%m-%d %H:%M:%S'),$p_pid,$p_cpu,$mem_mb,$p_mem,$vsz_mb,$rss_mb" >> "$RESOURCE_LOG"

            # Check for high memory usage (warning at 80%)
            mem_threshold=$(echo "$p_mem > 80" | bc)
            if [ "$mem_threshold" -eq 1 ]; then
                log_warning "High memory usage detected: ${p_mem}% (${mem_mb}MB)"
            fi

            # Check for high CPU usage (info at 90%)
            cpu_threshold=$(echo "$p_cpu > 90" | bc)
            if [ "$cpu_threshold" -eq 1 ]; then
                log_warning "High CPU usage detected: ${p_cpu}%"
            fi
        fi

        sleep 2
    done
}

# Function to check system resources
check_system_resources() {
    log "=== System Resources ==="

    # Memory
    local mem_info=$(free -h | grep "Mem:")
    log "Memory: $mem_info"

    # Disk space
    local disk_info=$(df -h / | tail -1)
    log "Disk: $disk_info"

    # Check if disk is >90% full
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        log_warning "Disk usage is high: ${disk_usage}%"
    fi

    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    log "Load average:$load_avg"

    log "========================"
}

# Function to analyze exit reason
analyze_exit() {
    local exit_code=$1
    local pid=$2

    log "=== Exit Analysis ==="
    log "Exit code: $exit_code"

    case $exit_code in
        0)
            log_success "Process exited normally (clean exit)"
            ;;
        1)
            log_error "Process exited with error code 1 (general error)"
            ;;
        2)
            log_error "Process exited with error code 2 (misuse of shell command)"
            ;;
        126)
            log_error "Process exited with error code 126 (command cannot execute)"
            ;;
        127)
            log_error "Process exited with error code 127 (command not found)"
            ;;
        130)
            log_warning "Process terminated by SIGINT (Ctrl+C)"
            ;;
        137)
            log_error "Process killed by SIGKILL (kill -9 or OOM killer)"
            ;;
        139)
            log_error "Process terminated by SIGSEGV (segmentation fault)"
            ;;
        143)
            log_warning "Process terminated by SIGTERM (graceful shutdown)"
            ;;
        *)
            log_warning "Process exited with unknown code: $exit_code"
            ;;
    esac

    # Check for OOM killer
    log "Checking for OOM killer activity..."
    if dmesg | tail -100 | grep -i "killed process" | grep -q "$pid"; then
        log_error "Process was killed by OOM (Out of Memory) killer!"
        dmesg | tail -20 | grep -i "out of memory" >> "$LOG_FILE"
    fi

    # Check kernel logs for signals
    log "Checking kernel logs for signals..."
    if dmesg | tail -50 | grep -q "signal"; then
        dmesg | tail -20 | grep "signal" >> "$LOG_FILE"
    fi

    # Check system logs
    log "Checking system logs..."
    if journalctl -n 50 --no-pager 2>/dev/null | grep -i -E "error|killed|terminated" | tail -10 >> "$LOG_FILE"; then
        log "Recent system errors logged"
    fi

    log "===================="
}

# Function to get max memory usage from resource log
get_max_memory() {
    if [ -f "$RESOURCE_LOG" ]; then
        local max_mem=$(tail -n +2 "$RESOURCE_LOG" | awk -F',' '{print $4}' | sort -n | tail -1)
        local max_mem_pct=$(tail -n +2 "$RESOURCE_LOG" | awk -F',' '{print $5}' | sort -n | tail -1)
        log "Peak memory usage: ${max_mem}MB (${max_mem_pct}%)"
    fi
}

# Main monitoring function
main() {
    log "=========================================="
    log "Claude Code Monitor Started"
    log "Log file: $LOG_FILE"
    log "Resource log: $RESOURCE_LOG"
    log "=========================================="

    # Check initial system state
    check_system_resources

    # Get the command to run
    if [ -z "$1" ]; then
        log_error "No command provided. Usage: $0 <command>"
        exit 1
    fi

    log "Starting command: $@"

    # Start the command in background
    "$@" &
    local pid=$!

    log "Process started with PID: $pid"

    # Start resource monitoring in background
    monitor_process "$pid" &
    local monitor_pid=$!

    # Wait for the process to complete
    wait "$pid"
    local exit_code=$?

    # Stop resource monitoring
    kill "$monitor_pid" 2>/dev/null
    wait "$monitor_pid" 2>/dev/null

    # Analyze the exit
    log ""
    analyze_exit "$exit_code" "$pid"

    # Get peak memory usage
    get_max_memory

    # Final system state
    log ""
    check_system_resources

    log "=========================================="
    log "Claude Code Monitor Finished"
    log "Exit code: $exit_code"
    log "=========================================="

    # Return the same exit code as the monitored process
    exit "$exit_code"
}

# Run main function with all arguments
main "$@"
