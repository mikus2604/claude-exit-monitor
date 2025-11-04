# Contributing to Claude Exit Monitor

Thank you for considering contributing to Claude Exit Monitor! 🎉

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- System information (OS, kernel version)
- Relevant log excerpts

### Suggesting Features

Feature requests are welcome! Please include:
- Use case and motivation
- Proposed implementation (if you have ideas)
- Potential impact on performance/resources

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly on your system
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Guidelines

- **Shell scripts**: Follow existing style (Bash, 2-space indent)
- **Comments**: Explain why, not what
- **Error handling**: Always check exit codes and handle errors gracefully
- **Performance**: Keep it lightweight - this is a monitoring tool
- **Compatibility**: Test on different Linux distributions if possible

### Testing Checklist

Before submitting a PR, please verify:
- [ ] Scripts are executable (`chmod +x`)
- [ ] No syntax errors (`bash -n script.sh`)
- [ ] Service installs successfully
- [ ] Daemon starts and runs
- [ ] Log rotation works
- [ ] Alert detection triggers correctly
- [ ] Dashboard displays properly
- [ ] Command monitoring captures exit codes

### Areas for Contribution

**High Priority:**
- Cross-distribution testing (Ubuntu, Debian, RHEL, Arch, etc.)
- Support for non-systemd init systems
- Additional exit code mappings
- Performance optimizations

**Medium Priority:**
- Configuration file support (instead of editing scripts)
- Email alerts for critical events
- Web dashboard (optional)
- Container/Docker support

**Low Priority:**
- macOS support (using launchd instead of systemd)
- Windows support (WSL compatibility)
- Metrics export (Prometheus, etc.)

## Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/claude-exit-monitor.git
cd claude-exit-monitor

# Make changes
vim claude-monitor-daemon.sh

# Test locally (don't install as service yet)
./claude-monitor-daemon.sh start

# Check logs
tail -f logs/daemon.log

# Stop daemon
./claude-monitor-daemon.sh stop

# When ready, test service installation
sudo ./install-monitor-service.sh
```

## Questions?

Feel free to open an issue for questions or discussions!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
