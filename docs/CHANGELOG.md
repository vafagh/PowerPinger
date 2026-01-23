# Changelog

## 📚 Navigation

[🏠 Main README](README.md) | [🚀 Quick Start](QUICKSTART.md) | 
[🔧 Enhanced Features](ENHANCED_FEATURES.md) | [🤝 Contributing](CONTRIBUTING.md)

**Languages**: [کوردی](README_KU.md) | [فارسی](README_FA.md) | 
[English](README.md)

---

All notable changes to PowerPinger will be documented in this file.

## [2.2.0] - 2026-01-22

### Added

- **Minifier Tool**: New `Minifier.ps1` script for reducing file size
  - Removes comments and blank lines (~23% size reduction)
  - Renames variables while preserving parameters and built-ins
  - Creates minified script and ZIP archive (~85% compression)
  - Preserves all script functionality
  - Intelligent function parameter preservation

- **Full IPv6 Support**: Complete IPv6 scanning capabilities
  - IPv6 address parsing and validation
  - Intelligent range limiting (max 65,536 addresses per range)
  - IPv6 CIDR notation support (e.g., 2001:db8::/32)
  - Automatic /128 subnet for single IPv6 addresses
  - IPv6-aware ping functionality

- **Network Pre-flight Checks**: Comprehensive connectivity validation
  - IPv4 gateway ping testing
  - IPv6 gateway ping testing
  - DNS resolution verification
  - External connectivity tests (Cloudflare, DCI DNS)
  - Detailed connectivity reporting
  - Interactive troubleshooting options

- **Live Range Skip**: Real-time scan control
  - Press 'S' key during scanning to skip current range
  - Visual feedback and confirmation
  - Available in all scan modes

### Enhanced

- **README Documentation**: Simplified and consolidated
  - Removed repetitive content
  - Clearer quick start instructions
  - Concise parameter tables
  - Better organized sections
  - Consistent formatting across English, Persian, and Kurdish versions

- **Network Status Detection**: 
  - Identifies IPv4/IPv6 availability before scanning
  - Skips incompatible ranges with clear messages
  - Shows network status in scan summary

- **Error Handling**: Improved validation and user feedback
  - Better IP format detection
  - Clear error messages for invalid ranges
  - Graceful handling of connectivity issues

### Fixed

- **Minifier String Handling**: Fixed comment removal breaking strings
  - Properly handles single quotes in strings (e.g., `'S'`)
  - Preserves escaped characters
  - Respects string context for hash symbols

## [2.1.0] - 2025-06-22

### Added

- **MaxResponses Parameter**: New `-MaxResponses` parameter to limit 
  successful responses per range
  - Default value: 10 responses per range
  - Set to 0 to disable (scan all IPs in range)
  - Helps optimize scanning time for dense networks
  - Available in both interactive and command-line modes
  - Integrated with all scan modes (ping/port/both/smart)

### Fixed

- **Range Exit Logic**: Fixed issue where MaxResponses feature wasn't 
  properly stopping range scans
  - Added proper flag-based exit mechanism for outer scanning loop
  - Now correctly stops after reaching the specified number of successful 
    responses
  - Maintains accurate result counts and proper CSV output

### Enhanced

- **Interactive Configuration**: Added MaxResponses option to interactive 
  setup menu
- **Progress Display**: Shows "Response limit enabled" message during 
  scanning
- **Usage Examples**: Updated documentation with MaxResponses examples
- **Parameter Documentation**: Added comprehensive parameter descriptions

## [2.0.0] - 2025-06-22

### Added

- **Port Scanning Capabilities**: Complete TCP port scanning functionality
- **Smart Censorship Detection**: Intelligent analysis of filtering 
  patterns  
- **Four Scan Modes**: ping, port, both, smart scanning options
- **Censorship Pattern Recognition**: Detects ICMP-blocked, ping-only, 
  and service-filtering
- **Enhanced Configuration**: Interactive setup with guided options
- **Real-time Feedback**: Live scanning progress with color-coded results
- **Comprehensive Documentation**: README, quick start, contributing guides
- **Sample Data Files**: Example IP lists for testing and demonstration
- **Cross-Platform Support**: PowerShell 5.1+ and PowerShell Core 
  compatibility
- **GitHub Integration**: CI/CD workflows and proper repository structure

### Enhanced

- **Interactive Mode**: Improved user experience with better menus
- **Command-Line Interface**: More parameter options and flexibility
- **Output Formats**: Dynamic CSV headers based on scan mode
- **Error Handling**: Better error reporting and validation
- **Performance**: Optimized scanning algorithms and timeout handling

### Security

- **Sample Data Only**: Real IP ranges excluded from public repository
- **Responsible Use**: Clear licensing and usage guidelines
- **Privacy Protection**: No sensitive data in version control

## [1.0.0] - Previous Version

### Features

- Basic ICMP ping functionality
- CSV input/output support
- Jump mode for sparse ranges
- Simple progress reporting

---

## Release Notes

### v2.0.0 - Major Enhancement Release

This release transforms PowerPinger from a simple ping tool into a 
comprehensive network censorship detection platform. The addition of port 
scanning and smart detection makes it particularly valuable for understanding 
internet restrictions in censored environments.

**Key Highlights:**

- 🎯 **Censorship Detection**: Identifies government filtering patterns
- 🚪 **Port Scanning**: Bypass ICMP blocks with TCP connectivity tests  
- 🧠 **Smart Analysis**: Automatic pattern recognition and classification
- 🌍 **Global Research**: Tools for studying internet freedom worldwide

**Breaking Changes:**
- New default CSV headers in smart/both modes
- Additional configuration parameters
- Enhanced interactive setup process

**Migration Guide:**
- Existing CSV files remain compatible
- New features are opt-in via scan mode selection
- Default behavior maintains backward compatibility
