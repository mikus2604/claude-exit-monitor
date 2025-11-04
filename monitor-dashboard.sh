#!/bin/bash

# Claude Monitor Dashboard - Real-time status display

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs/claude-monitor"
RESOURCE_LOG="$LOG_DIR/daemon-resources.csv"
ALERT_LOG="$LOG_DIR/daemon-alerts.log"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}   Claude Code Monitor Dashboard${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Service Status
echo -e "${BLUE}● Service Status${NC}"
if systemctl is-active --quiet claude-monitor; then
    echo -e "  ${GREEN}✓ Running${NC}"
    uptime_info=$(systemctl show claude-monitor -p ActiveEnterTimestamp --value)
    echo -e "  Started: $uptime_info"
else
    echo -e "  ${RED}✗ Not Running${NC}"
fi
echo ""

# Current System Metrics
echo -e "${BLUE}● Current System Metrics${NC}"
if [ -f "$RESOURCE_LOG" ]; then
    latest=$(tail -1 "$RESOURCE_LOG")
    timestamp=$(echo "$latest" | cut -d',' -f1)
    total_mem=$(echo "$latest" | cut -d',' -f2)
    used_mem=$(echo "$latest" | cut -d',' -f3)
    mem_percent=$(echo "$latest" | cut -d',' -f4)
    disk_percent=$(echo "$latest" | cut -d',' -f5)
    load_1m=$(echo "$latest" | cut -d',' -f6)
    claude_procs=$(echo "$latest" | cut -d',' -f7)

    echo -e "  Last update: $timestamp"

    # Memory bar
    mem_int=${mem_percent%.*}
    if [ $mem_int -gt 85 ]; then
        mem_color=$RED
    elif [ $mem_int -gt 70 ]; then
        mem_color=$YELLOW
    else
        mem_color=$GREEN
    fi
    echo -e "  Memory:      ${mem_color}${mem_percent}%${NC} (${used_mem}MB / ${total_mem}MB)"

    # Disk bar
    disk_int=${disk_percent%.*}
    if [ $disk_int -gt 90 ]; then
        disk_color=$RED
    elif [ $disk_int -gt 75 ]; then
        disk_color=$YELLOW
    else
        disk_color=$GREEN
    fi
    echo -e "  Disk:        ${disk_color}${disk_percent}%${NC}"

    echo -e "  Load (1m):   $load_1m"
    echo -e "  Node procs:  $claude_procs"
else
    echo -e "  ${YELLOW}No data yet${NC}"
fi
echo ""

# Statistics (last hour)
echo -e "${BLUE}● Statistics (Recent)${NC}"
if [ -f "$RESOURCE_LOG" ]; then
    # Last 120 samples = 1 hour at 30s intervals
    stats=$(tail -n 121 "$RESOURCE_LOG" | tail -n +2)

    if [ -n "$stats" ]; then
        mem_max=$(echo "$stats" | cut -d',' -f4 | sort -n | tail -1)
        mem_min=$(echo "$stats" | cut -d',' -f4 | sort -n | head -1)
        mem_avg=$(echo "$stats" | cut -d',' -f4 | awk '{sum+=$1} END {printf "%.1f", sum/NR}')

        disk_max=$(echo "$stats" | cut -d',' -f5 | sort -n | tail -1)

        echo -e "  Memory:  Min ${mem_min}% | Avg ${mem_avg}% | Max ${mem_max}%"
        echo -e "  Disk:    Max ${disk_max}%"

        sample_count=$(echo "$stats" | wc -l)
        duration_min=$(echo "scale=1; $sample_count * 0.5" | bc)
        echo -e "  Samples: $sample_count (${duration_min}min)"
    fi
fi
echo ""

# Recent Alerts
echo -e "${BLUE}● Recent Alerts (Last 10)${NC}"
if [ -f "$ALERT_LOG" ] && [ -s "$ALERT_LOG" ]; then
    tail -10 "$ALERT_LOG" | while read line; do
        echo -e "  ${YELLOW}⚠${NC} $line"
    done
else
    echo -e "  ${GREEN}✓ No alerts${NC}"
fi
echo ""

# Quick Actions
echo -e "${CYAN}========================================${NC}"
echo -e "${BLUE}Quick Commands:${NC}"
echo -e "  ${CYAN}sudo systemctl status claude-monitor${NC}  - Full service status"
echo -e "  ${CYAN}sudo systemctl restart claude-monitor${NC} - Restart service"
echo -e "  ${CYAN}tail -f $ALERT_LOG${NC}"
echo -e "                                         - Watch alerts live"
echo -e "  ${CYAN}./scripts/view-claude-logs.sh${NC}         - View all logs"
echo -e "${CYAN}========================================${NC}"
