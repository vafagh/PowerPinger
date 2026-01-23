# 🎯 PowerPinger - Network Scanner for Restricted Environments

## 🌍 Languages
[کوردی](README_KU.md) | [فارسی](README_FA.md) | [**English**](README.md)

## 📚 Quick Links
- 📖 [Quick Start](docs/QUICKSTART.md) - 5 minute setup
- 🚀 [Advanced Features](docs/ENHANCED_FEATURES.md) - Full capabilities
- 📋 [Changelog](docs/CHANGELOG.md) - Version history

---

## 🎯 Overview

PowerPinger finds accessible servers and services in restricted network environments. Scans IP ranges to discover reachable hosts and open ports.

**Key Features:**
- ✅ **Zero installation** - Uses Windows built-in PowerShell
- 📦 **Ultra portable** - ~15KB zipped (email-friendly)
- 🌐 **Full IPv4/IPv6 support** - Intelligent range handling
- ⚡ **Multiple scan modes** - ping/port/both/parallel
- 🛡️ **Network pre-flight checks** - Validates connectivity before scanning
- 🎯 **Smart rate limiting** - Prevents DDoS detection
- 📊 **CSV output** - Structured results

## ⚠️ Important Warnings

**Legal & Security:**
- Only scan networks you own or have explicit permission to test
- Network admins can monitor your scanning activity
- Respect local laws and network policies
- Scanning production networks (Cloudflare, AWS) may block your IP

## 📦 Quick Start

### For Restricted Networks (Recommended)
1. Download 2 files: `powerPinger.ps1` + `ip_list.csv`
2. Transfer via USB/email (< 15KB zipped)
3. Extract and run:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\powerPinger.ps1
```

### From Git Repository
```bash
git clone https://github.com/vafagh/PowerPinger.git
cd PowerPinger
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\powerPinger.ps1
```

## 🎮 Usage Examples

```powershell
# Interactive mode
.\powerPinger.ps1

# Basic scan
.\powerPinger.ps1 -InputFile "targets.csv" -OutputFile "results.csv"

# Advanced scan with port detection
.\powerPinger.ps1 -ScanMode "both" -Ports "80,443,22" -MaxResponses 10

# Parallel mode for speed
.\powerPinger.ps1 -ScanMode "parallel" -Timeout 1000
```

## 🛠️ Development Tools

**Minifier** - Reduces script size for portability:
```powershell
.\Minifier.ps1
# Creates powerPinger_min.ps1 (~23% smaller)
# Creates powerPinger.zip (~85% compression)
```

## 📊 Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-InputFile` | Input CSV/TXT file | ip_list.csv |
| `-OutputFile` | Output CSV file | ping_results.csv |
| `-Timeout` | Ping timeout (ms) | 1500 |
| `-MaxFailures` | Failures before skip | 4 |
| `-Jump` | IPs to skip on failure | 16 |
| `-Skip` | Jumps before range skip | 3 |
| `-ScanMode` | ping/port/both/parallel | ping |
| `-Ports` | Ports to scan | 80,443,22,53 |
| `-MaxResponses` | Limit per range | 0 (unlimited) |

## 📝 Input File Format

**CSV:**
```csv
IP,Location,Region,City,PostalCode
192.168.10.0/24 
192.168.1.0/24,Office,US,NYC,10001
8.8.8.8,Google DNS,US,Mountain View,94043
2001:4860:4860::8888,Google DNS IPv6,US,,
```

**TXT:**
```
192.168.1.0/24
10.0.0.0/16
8.8.8.8
```

## ⚖️ License & Disclaimer

**MIT License** - See [LICENSE](docs/LICENSE)

**Use at your own risk.** Only scan networks you own or have permission to test. Author accepts no liability for misuse or damages.

---

Made for restricted network environments 🌐
