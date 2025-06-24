# 🎯 PowerPinger - Network Accessibility Scanner

## 🌍 Languages
[کوردی](README_KU.md) | [فارسی](README_FA.md) | [**English**](README.md)

## 📚 Documentation Navigation
- 📖 [Quick Start Guide](docs/QUICKSTART.md) - Get started in 5 minutes
- 🚀 [Enhanced Features](docs/ENHANCED_FEATURES.md) - Advanced capabilities overview
- 📋 [Changelog](docs/CHANGELOG.md) - Version history and updates
- 🤝 [Contributing](docs/CONTRIBUTING.md) - Development guidelines

---

## 🎯 What, When, and Who

### 🤔 **What Does This Tool Do?**
PowerPinger helps you **find accessible servers and internet services** when your normal internet access is restricted or limited. It scans IP addresses to discover which ones you can still reach and what services are available.

**What You Get:**
- 📋 **List of accessible IPs**: Discover servers you can connect to
- 🔍 **Service detection**: Find which ports/services work on each IP
- 🛡️ **Network analysis**: Understand what servers are reachable
- 📊 **Detailed reports**: Get CSV files with all connectivity information

### ⏰ **When Should You Use This?**
Perfect for situations where your internet access is heavily restricted:

- 🚫 **No internet access**: Your network blocks most websites and services
- 🔒 **VPN/Proxy blocked**: Can't use normal bypass tools
- 🛡️ **Behind firewalls**: Need to find what connections still work
- 📡 **Emergency connectivity**: Need alternative routes to internet services
- 🔧 **Network troubleshooting**: Understanding connectivity problems

### 👥 **Who Is This For?**
- 🔬 **Researchers**: Studying internet restrictions and accessibility
- 🌍 **Network monitoring teams**: Documenting network limitations
- 🖥️ **Network professionals**: Analyzing connectivity and restrictions
- 🔧 **System administrators**: Troubleshooting network access
- 👨‍💻 **Anyone in restricted networks**: Finding working internet connections

### 🤔 **Why This Tool?**
**PowerPinger is NOT the best network scanner available** - but it has unique advantages:

- 💾 **Zero Installation**: Uses only what comes with Windows 10/11
- 📦 **Ultra Portable**: Tool + IP lists = less than 18KB when zipped (can be emailed!)
- 🔓 **Works When Others Don't**: No need for admin rights or special software
- 🎯 **Purpose-Built**: Specifically designed for restricted network environments
- ⚡ **Instant Ready**: Extract and run immediately on any Windows computer

### ⚠️ **Important Warnings**

**🚨 SECURITY RISKS:**
- **You can be monitored**: Network admins can see your scanning activity
- **Legal compliance**: Only scan networks you have permission to test
- **Professional use**: Get proper authorization first

**🛡️ USE RESPONSIBLY:**
- Only scan your own networks or with explicit permission
- Respect local laws and network policies
- Don't overwhelm target systems

---

## 📦 Installation

### **🚀 Zero-Dependency Deployment (Recommended for Restricted Networks)**

**PowerPinger requires NO additional software installation!** It runs on any Windows 10+ system using the built-in PowerShell.

**For Restricted/Corporate Networks:**
1. **Download only 2 files** (~1500 lines total):
   - `powerPinger.ps1` (main script)
   - Your IP list file (e.g., `targets.csv`)

2. **Transfer method options**:
   - USB drive
   - Email attachment
   - File sharing systems
   - Code repository access
   - Any available file transfer method

3. **Run immediately** (no installation needed):
```powershell
# Allow script execution (one-time setup)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run the scanner - Method 1: Right-click
# Right-click on powerPinger.ps1 → Select "Run with PowerShell"

# Run the scanner - Method 2: Command line
.\powerPinger.ps1
```

### **🌐 Full Repository Installation**

1. **Clone repository:**
```bash
git clone https://github.com/vafagh/PowerPinger.git
cd PowerPinger
```

2. **Ensure PowerShell execution policy:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🎯 Usage Scenarios & Automation

### **📧 Email/USB Deployment (< 18KB)**
```powershell
# Essential files: powerPinger.ps1 + ip_list.csv
# Zipped: < 18KB - can be emailed!
# Extract and run immediately on any Windows machine
```

### **⏰ Task Scheduler Automation**
```powershell
# Create scheduled task for regular scanning
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-File "C:\path\to\powerPinger.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "NetworkScan"
```

### **🔄 Automated Scanning with Intervals**
```powershell
# Scan every hour with timestamped output
while ($true) {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    .\powerPinger.ps1 -OutputFile "scan_$timestamp.csv"
    Start-Sleep -Seconds 3600  # 1 hour delay
}
```

### **🎮 Interactive Usage**
```powershell
# Quick scan with defaults
.\powerPinger.ps1

# Advanced scan with custom options
.\powerPinger.ps1 -ScanMode "both" -Ports "80,443,22,53" -MaxResponses 10
```

---

## 🌟 Key Features

- 🛡️ **Network accessibility detection**: Advanced analysis to identify different types of access and available servers
- 🚀 **Zero dependencies**: No additional software needed - just PowerShell
- ⚡ **Fast and efficient**: ~1000 lines of code + IP list = complete network analysis suite
- 🎯 **Multiple scan modes**: ping/port/both/parallel
- 📊 **Detailed reporting**: Results in CSV format

## 🚀 Quick Start

### Prerequisites
- Windows 10 or later
- PowerShell 5.1+ (pre-installed by default)

### 1. Download
```bash
git clone https://github.com/vafagh/PowerPinger.git
cd PowerPinger
```

### 2. First Scan
```powershell
# Simple scan
.\powerPinger.ps1

# Comprehensive accessibility detection
.\powerPinger.ps1 -ScanMode "both" -Ports "80,443,22,53"
```

## 📋 Scan Modes

- **`ping`** - ICMP ping only
- **`port`** - Port scanning only  
- **`both`** - Ping first, then port scan non-responders (optimized)
- **`parallel`** - Fast parallel ping with batch processing

## 🛡️ Network Accessibility Detection

This tool can identify these types of access patterns:

### ICMP Blocking
- **Symptoms**: Services work but ping doesn't
- **Common in**: Corporate networks, restricted environments

### Service Blocking  
- **Symptoms**: Ping works but services don't
- **Common in**: Advanced configurations, security monitoring

### Normal Access
- **Symptoms**: Both ping and services work

## 📁 Input File Format

### CSV for Individual IPs
```csv
IP,Location,Region,City,PostalCode
8.8.8.8,Google DNS,US,Mountain View,94035
1.1.1.1,Cloudflare DNS,US,San Francisco,94107
```

### TXT for Ranges
```
192.168.1.0/24
10.0.0.0/16
172.16.0.0/12
```

## 🔧 Configuration

```powershell
# Timeouts
.\powerPinger.ps1 -Timeout 2000 -PortTimeout 5000

# Specific ports
.\powerPinger.ps1 -Ports "80,443,8080,8443"

# Jump mode after failures
.\powerPinger.ps1 -MaxFailures 3 -Jump 5

# Limit responses per range
.\powerPinger.ps1 -MaxResponses 5
```

## 📊 Sample Output

```csv
IP,Location,Ping Result,Ping Time (ms),Ports Open,Service Status,Network Status
8.8.8.8,Google DNS,Success,15,53;443,Accessible,Normal
1.1.1.1,Cloudflare DNS,Success,12,53;443,Accessible,Normal
```

## 🔍 Network Status Types

| Status | Description |
|--------|-------------|
| **Normal** | Both ping and ports work |
| **ICMP-Blocked** | Services work, ping doesn't |
| **Service-Blocked** | Ping works, services are refused |
| **Unassigned-Range** | No response, likely no assigned server |

## 💡 Tips

### For Restricted Networks
- Copy only the powerPinger.ps1 file
- No installation required
- Run from USB or network

### For Performance Analysis
- Use "both" mode
- Increase timeouts for slow networks
- Enable Jump mode for large ranges

## 🤝 Contributing

To contribute to this project development:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## ⚠️ Important Disclaimers and Risks

### **⚖️ Legal and Compliance**
- **Use only on authorized networks**: Only use this tool on networks you own or have explicit written permission to test
- **Local laws**: Using network scanning tools may violate local laws and regulations
- **Organizational policies**: Check your organization's IT policies before use
- **Your responsibility**: You are fully responsible for legal compliance

### **🛠️ Technical Limitations**
- **Incomplete testing**: This tool has not been thoroughly tested under all conditions
- **Potential errors**: Software may contain bugs that affect results
- **Result accuracy**: Ping and connection results may not be accurate
- **Environmental changes**: Results vary based on network changes

### **🚫 No Warranties**
- **"As is"**: This software is provided without any warranties
- **No liability**: Author accepts no responsibility for any damages
- **Result accuracy**: No guarantee of result correctness

### **⚠️ Use at Your Own Risk**
- **Personal responsibility**: You accept all risks
- **Expert consultation**: Consult with experts
- **Testing**: Test before official use

**By using PowerPinger, you acknowledge that you have read and understood these terms.**

## 🔗 Useful Links

- [Full Documentation](docs/QUICKSTART.md)
- [Enhanced Features](docs/ENHANCED_FEATURES.md)
- [Changelog](docs/CHANGELOG.md)

## 📄 License

This project is released under the MIT License. See [LICENSE](docs/LICENSE) for more information.
