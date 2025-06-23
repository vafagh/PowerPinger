# PowerPinger Quick Start Guide

## 📚 Navigation
[🏠 Main README](README.md) | [🔧 Enhanced Features](ENHANCED_FEATURES.md) | [📋 Changelog](CHANGELOG.md) | [🤝 Contributing](CONTRIBUTING.md)

## 🌍 Languages
[کوردی](QUICKSTART_KU.md) | [فارسی](QUICKSTART_FA.md) | [**English**](QUICKSTART.md)

---

## 🚀 5-Minute Setup

### 1. Download and Setup
```powershell
# Clone the repository
git clone https://github.com/yourusername/PowerPinger.git
cd PowerPinger

# Allow script execution (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. First Run (Interactive)
```powershell
# Run with interactive setup
.\powerPinger.ps1
```
This will guide you through:
- File selection
- Scan configuration
- Output options

### 3. Quick Examples

#### Basic Ping Test
```powershell
.\powerPinger.ps1 -InputFile "sample_ips.csv" -OutputFile "my_results.csv"
```

#### Smart Network Filtering Detection
```powershell
.\powerPinger.ps1 -InputFile "sample_ips.csv" -ScanMode "smart" -Ports "80,443,22"
```

#### Fast Port Scanning (Bypass Ping Blocks)
```powershell
.\powerPinger.ps1 -InputFile "sample_ips.csv" -ScanMode "port" -Ports "80,443"
```

## 📋 Sample Output

### Ping Mode
```csv
IP,Location,Ping Time (ms)
8.8.8.8,"US,CA,Mountain View,94043",15
1.1.1.1,"US,CA,San Francisco,94107",12
```

### Smart Mode (Network Filtering Detection)
```csv
IP,Location,Ping Result,Ping Time (ms),Ports Open,Service Status,Filtering Detected
8.8.8.8,"US,CA,Mountain View,94043",Success,15,"80,443",Accessible,No
203.0.113.5,"Example,Test,Documentation,00000",Failed,Timeout,"80,443",Services-Only,ICMP-Blocked
```

## 🔧 Common Issues

### Script Won't Run
```powershell
# Check execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### No Results
- Check input file format (CSV with headers)
- Verify network connectivity
- Try increasing timeout values

### Slow Scanning
- Reduce timeout values
- Enable jump mode: `-Jump 5 -MaxFailures 3`
- Use port-only mode for faster results
- Limit responses per range: `-MaxResponses 5`

## 📊 Understanding Results

| Status | Meaning |
|--------|---------|
| **No Filtering** | Both ping and ports work |
| **ICMP-Blocked** | Ping fails, services work |
| **Ping-Only** | Ping works, no services |
| **Full Block** | Nothing responds |

## 🎯 Use Cases

- **Network Testing**: Verify connectivity
- **Network Analysis**: Detect filtering patterns  
- **Security Assessment**: Check service availability
- **Troubleshooting**: Diagnose network issues

## 🎯 What Is This Tool For?

### 📖 **Quick Overview**
PowerPinger helps you **find accessible servers and services** in restricted network environments where normal internet access is limited or filtered. It's designed for network researchers who need to map connectivity patterns and discover available infrastructure.

### ⚡ **When To Use PowerPinger**
- 🚫 **Limited Internet Access**: Your network blocks most outbound connections
- 🔒 **No VPN/Proxy Access**: Standard bypass methods aren't available
- 🛡️ **Network Analysis**: Need to understand what paths are open
- 📡 **Alternative Routes**: Finding working connections through restrictions

### 👥 **Who Should Use This**
- 🔬 **Network Researchers**: Analyzing connectivity patterns
- 🛡️ **Security Professionals**: Understanding network topology
- 🌍 **Digital Rights Advocates**: Documenting network restrictions
- 🔧 **System Administrators**: Troubleshooting connectivity issues

### ⚠️ **Important Warning**
**Your network activity can be monitored!** Network administrators, ISPs, and other parties may observe and log this tool's scanning activity. Only use on networks you have permission to test, and ensure compliance with local laws and policies.

---

## ⚠️ Important Warning

**Before using PowerPinger:**
- ✅ **Only scan networks you own or have written permission to test**
- ❌ **Do not scan third-party networks without explicit authorization**
- 📋 **Check your organization's IT policies before use**
- ⚖️ **Ensure compliance with local laws and regulations**
- 🛡️ **This tool may contain bugs - use at your own risk**
- 📊 **Results may not always be accurate - verify with other tools**

**By using this tool, you accept full responsibility for compliance and results.**

Need more help? Check the full [README.md](README.md) or [open an issue](https://github.com/yourusername/PowerPinger/issues)!
