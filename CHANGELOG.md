# Changelog

All notable changes to Claude Exit Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-04

### Added
- Initial release
- Background monitoring daemon with systemd service
- Auto-start on boot capability
- Auto-restart on crash (10-second delay)
- Lightweight continuous monitoring (30-second intervals)
- Real-time resource tracking (memory, disk, CPU, processes)
- Alert detection for high resource usage
- OOM killer detection
- On-demand command monitoring script
- Detailed exit code analysis
- Interactive log viewer
- Dashboard for quick status overview
- Log rotation to prevent disk fill
- Comprehensive documentation

### Features
- `claude-monitor-daemon.sh` - Background monitoring daemon
- `monitor-claude.sh` - On-demand command wrapper for detailed analysis
- `monitor-dashboard.sh` - Real-time status dashboard
- `view-claude-logs.sh` - Interactive log viewer
- `install-monitor-service.sh` - Automated systemd service installer
- `claude-monitor.service` - Systemd service configuration

### Resource Limits
- Memory limit: 50MB
- CPU quota: 5%
- Sample interval: 30 seconds (background), 2 seconds (on-demand)

### Alert Thresholds
- Memory warning: 85%
- Disk warning: 90%
- OOM killer detection: Active

[1.0.0]: https://github.com/yourusername/claude-exit-monitor/releases/tag/v1.0.0
