# Claude Exit Monitor

**A lightweight system monitoring daemon to diagnose why Claude Code (or any process) exits abruptly.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🎯 Purpose

Ever had Claude Code exit unexpectedly and wondered why? This monitoring system provides:
- **Real-time resource tracking** (memory, disk, CPU)
- **Exit code analysis** with detailed explanations
- **OOM killer detection**
- **Auto-restart capabilities**
- **Continuous background monitoring**

Perfect for debugging crashes, OOM kills, and mysterious process exits.

## ✨ Features

### Background Daemon (Always Running)
✅ **Auto-start on boot** - Systemd service starts automatically
✅ **Auto-restart on crash** - Restarts within 10 seconds if killed
✅ **Lightweight** - 30-second sampling interval (<1% CPU, <50MB RAM)
✅ **Continuous monitoring** - Memory, disk, CPU, process counts
✅ **Alert detection** - Warns on high resource usage and OOM kills
✅ **Log rotation** - Automatic cleanup prevents disk fill

### On-Demand Command Monitoring
✅ **Detailed exit analysis** - Explains exit codes (OOM, signals, errors)
✅ **Resource profiling** - 2-second sampling during execution
✅ **Peak usage tracking** - Shows maximum memory/CPU consumption
✅ **OOM detection** - Checks kernel logs for Out of Memory kills

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/mikus2604/claude-exit-monitor.git
cd claude-exit-monitor

# Install as a systemd service (requires root)
sudo ./install-monitor-service.sh
```

The daemon will start automatically and begin monitoring your system.

### Usage

#### View Dashboard
```bash
./monitor-dashboard.sh
```

Output:
```
========================================
   Claude Code Monitor Dashboard
========================================

● Service Status
  ✓ Running
  Started: Tue 2025-11-04 14:48:49 UTC

● Current System Metrics
  Last update: 2025-11-04 14:49:27
  Memory:      10.0% (1218MB / 7751MB)
  Disk:        78%
  Load (1m):   0.31
  Node procs:  0

● Statistics (Recent)
  Memory:  Min 10.0% | Avg 10.0% | Max 10.0%
  Disk:    Max 78%
  Samples: 14 (7.0min)

● Recent Alerts (Last 10)
  ✓ No alerts
```

#### Monitor a Specific Command
```bash
# Monitor any command and get detailed exit analysis
./monitor-claude.sh npm run build
./monitor-claude.sh node script.js
./monitor-claude.sh python train.py
```

#### View Logs Interactively
```bash
./view-claude-logs.sh
```

Interactive menu provides:
1. View latest log
2. View resource usage (CSV)
3. Analyze resource usage (min/max/avg)
4. View all logs
5. Search for errors
6. Clean old logs

## 📊 What Gets Monitored

### Background Daemon (Every 30 seconds)
- **Memory**: Total, used, percentage
- **Disk**: Usage percentage (root partition)
- **CPU**: 1-minute load average
- **Processes**: Count of Node.js processes

### Alerts Triggered On
- Memory usage > 85%
- Disk usage > 90%
- OOM (Out of Memory) killer activity

### Manual Command Monitoring (Every 2 seconds)
- Process CPU and memory usage
- Virtual memory size (VSZ)
- Resident set size (RSS)
- Exit code with detailed explanation
- OOM killer detection
- Signal detection (SIGTERM, SIGKILL, SIGINT, etc.)

## 📁 Log Files

All logs are stored in `logs/` directory:

### Background Daemon Logs
- `daemon.log` - Main daemon activity log
- `daemon-alerts.log` - Alerts for high usage, OOM kills
- `daemon-resources.csv` - Continuous metrics (30s intervals)

### On-Demand Monitoring Logs
- `claude-monitor-TIMESTAMP.log` - Full session log with exit analysis
- `resources-TIMESTAMP.csv` - Resource samples (2s intervals)

## 🔧 Service Management

```bash
# Check status
sudo systemctl status claude-monitor

# View live logs
sudo journalctl -u claude-monitor -f

# Restart service
sudo systemctl restart claude-monitor

# Stop service
sudo systemctl stop claude-monitor

# Disable auto-start on boot
sudo systemctl disable claude-monitor
```

## 📖 Exit Code Reference

The monitor automatically identifies common exit codes:

| Code | Meaning |
|------|---------|
| 0 | Normal exit (success) |
| 1 | General error |
| 2 | Misuse of shell command |
| 126 | Command cannot execute |
| 127 | Command not found |
| 130 | Terminated by SIGINT (Ctrl+C) |
| 137 | Killed by SIGKILL (kill -9 or OOM killer) |
| 139 | Segmentation fault (SIGSEGV) |
| 143 | Terminated by SIGTERM (graceful shutdown) |

## 🐛 Debugging Process Exits

When a process exits unexpectedly:

1. **Check recent alerts**
   ```bash
   tail -f logs/daemon-alerts.log
   ```

2. **View resource trends**
   ```bash
   ./monitor-dashboard.sh
   # or
   tail -20 logs/daemon-resources.csv | column -t -s','
   ```

3. **Check system logs for OOM kills**
   ```bash
   dmesg -T | grep -i "out of memory"
   ```

4. **Run manual monitoring on the command**
   ```bash
   ./monitor-claude.sh <your-command>
   ```

## ⚙️ Configuration

### Resource Limits
The daemon is configured with conservative limits (edit `claude-monitor.service`):
- **Memory limit**: 50MB
- **CPU quota**: 5%
- **Sample interval**: 30 seconds (edit in `claude-monitor-daemon.sh`)

### Alert Thresholds
Edit `claude-monitor-daemon.sh` to adjust thresholds:
- Memory warning: 85% (line ~83)
- Disk warning: 90% (line ~88)

### Log Rotation
- **Max log size**: 10MB
- **Max resource samples**: 10,000 (~3.5 days at 30s intervals)

## 🔍 How It Works

### Background Daemon
1. **Systemd** starts the daemon on boot
2. Daemon collects system metrics every 30 seconds
3. Writes to CSV log (`daemon-resources.csv`)
4. Checks thresholds and writes alerts
5. Rotates logs when they get too large
6. Systemd restarts daemon if it crashes

### Command Monitoring
1. Wrap any command with `monitor-claude.sh`
2. Script samples process stats every 2 seconds
3. Records CPU, memory, VSZ, RSS to CSV
4. Captures exit code and analyzes meaning
5. Checks kernel logs for OOM kills
6. Reports peak resource usage

## 🛡️ Security

- Runs as root (required for system monitoring)
- Uses `PrivateTmp=true` for isolation
- Uses `NoNewPrivileges=true` to prevent privilege escalation
- Logs are readable only by root

## 📋 Requirements

- Linux with systemd
- Bash 4.0+
- Standard utilities: `ps`, `free`, `df`, `dmesg`, `bc`
- Root access (for systemd service installation)

## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Credits

Designed to debug Claude Code exits, but works with any command-line process.

Built with ❤️ for developers tired of mysterious process exits.

## 🔗 Related Projects

- [Claude Code](https://claude.com/claude-code) - Anthropic's official CLI for Claude
- [htop](https://htop.dev/) - Interactive process viewer
- [glances](https://nicolargo.github.io/glances/) - Cross-platform monitoring tool

## 📞 Support

Found a bug or have a feature request? Please open an issue on GitHub.

---

**Remember**: The background daemon is running right now, silently tracking your system. When something goes wrong, the logs will be waiting for you. 🔍
