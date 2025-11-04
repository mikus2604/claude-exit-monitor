#!/bin/bash

# Helper script to view Claude Code monitoring logs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs/claude-monitor"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ ! -d "$LOG_DIR" ]; then
    echo -e "${YELLOW}No logs found. Monitor logs will be created in:${NC}"
    echo "$LOG_DIR"
    exit 0
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Claude Code Monitor Logs${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# List available log files
echo -e "${YELLOW}Available log sessions:${NC}"
ls -lht "$LOG_DIR"/*.log 2>/dev/null | head -10

echo ""
echo -e "${YELLOW}Choose an action:${NC}"
echo "1) View latest log"
echo "2) View latest resource usage (CSV)"
echo "3) Analyze resource usage (summary)"
echo "4) View all logs"
echo "5) Search logs for errors"
echo "6) Clean old logs (keep last 10)"
echo ""

read -p "Enter choice (1-6): " choice

case $choice in
    1)
        latest_log=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
        if [ -n "$latest_log" ]; then
            echo -e "${GREEN}Viewing: $latest_log${NC}"
            echo ""
            cat "$latest_log"
        else
            echo "No logs found"
        fi
        ;;
    2)
        latest_csv=$(ls -t "$LOG_DIR"/resources-*.csv 2>/dev/null | head -1)
        if [ -n "$latest_csv" ]; then
            echo -e "${GREEN}Viewing: $latest_csv${NC}"
            echo ""
            column -t -s',' "$latest_csv" | less -S
        else
            echo "No resource logs found"
        fi
        ;;
    3)
        latest_csv=$(ls -t "$LOG_DIR"/resources-*.csv 2>/dev/null | head -1)
        if [ -n "$latest_csv" ]; then
            echo -e "${GREEN}Resource Usage Summary: $latest_csv${NC}"
            echo ""

            # Skip header and calculate stats
            echo -e "${YELLOW}CPU Usage:${NC}"
            awk -F',' 'NR>1 {sum+=$3; if($3>max) max=$3; if(min=="" || $3<min) min=$3} END {print "  Min: "min"%\n  Max: "max"%\n  Avg: "(sum/(NR-1))"%"}' "$latest_csv"

            echo ""
            echo -e "${YELLOW}Memory Usage (MB):${NC}"
            awk -F',' 'NR>1 {sum+=$4; if($4>max) max=$4; if(min=="" || $4<min) min=$4} END {print "  Min: "min"MB\n  Max: "max"MB\n  Avg: "(sum/(NR-1))"MB"}' "$latest_csv"

            echo ""
            echo -e "${YELLOW}Memory Usage (%):${NC}"
            awk -F',' 'NR>1 {sum+=$5; if($5>max) max=$5; if(min=="" || $5<min) min=$5} END {print "  Min: "min"%\n  Max: "max"%\n  Avg: "(sum/(NR-1))"%"}' "$latest_csv"

            echo ""
            echo -e "${YELLOW}Sample count:${NC} $(tail -n +2 "$latest_csv" | wc -l) measurements"
        else
            echo "No resource logs found"
        fi
        ;;
    4)
        echo -e "${GREEN}All logs:${NC}"
        for log in $(ls -t "$LOG_DIR"/*.log 2>/dev/null); do
            echo ""
            echo -e "${CYAN}=== $log ===${NC}"
            cat "$log"
            echo ""
        done | less
        ;;
    5)
        echo -e "${GREEN}Searching for errors in all logs...${NC}"
        echo ""
        grep -i -E "error|killed|failed|terminated|warning" "$LOG_DIR"/*.log 2>/dev/null | less
        ;;
    6)
        echo -e "${YELLOW}Cleaning old logs (keeping last 10)...${NC}"
        cd "$LOG_DIR"
        ls -t *.log 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null
        ls -t resources-*.csv 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null
        echo -e "${GREEN}Done! Remaining logs:${NC}"
        ls -lh "$LOG_DIR"
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
