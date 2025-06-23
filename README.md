# 🎯 PowerPinger - Network Accessibility Scanner

## 🌍 Languages
[کوردی](README_KU.md) | [فارسی](README_FA.md) | [**English**](README.md)

## 📚 Documentation Navigation
- 📖 [Quick Start Guide](QUICKSTART.md) - Get started in 5 minutes
- 🚀 [Enhanced Features](ENHANCED_FEATURES.md) - Advanced capabilities overview
- 📋 [Changelog](CHANGELOG.md) - Version history and updates
- 🤝 [Contributing](CONTRIBUTING.md) - Development guidelines

---

## 🎯 What, When, and Who

### 🤔 **What Does This Tool Do?**
PowerPinger helps you **find accessible servers and internet services** when your normal internet access is restricted or limited. It scans IP addresses to discover which ones you can still reach and what services are available.

**What You Get:**
- 📋 **List of accessible IPs**: Discover servers you can connect to
- 🔍 **Service detection**: Find which ports/services work on each IP
- 🛡️ **Network analysis**: Understand what servers are reachable
- 📊 **Detailed reports**: Get CSV files with all connectivity information

## 🌍 Languages
[کوردی](README_KU.md) | [فارسی](README_FA.md) | [**English**](README.md)

## 📚 Documentation Navigation
- 📖 [Quick Start Guide](QUICKSTART.md) - Get started in 5 minutes
- 🚀 [Enhanced Features](ENHANCED_FEATURES.md) - Advanced capabilities overview
- 📋 [Changelog](CHANGELOG.md) - Version history and updates
- 🤝 [Contributing](CONTRIBUTING.md) - Development guidelines

---

## 🎯 What, When, and Who

### 🤔 **What Does This Tool Do?**
PowerPinger helps you **find accessible servers and internet services** when your normal internet access is restricted or limited. It scans IP addresses to discover which ones you can still reach and what services are available.

**What You Get:**
- 📋 **List of accessible IPs**: Discover servers you can connect to
- � **Service detection**: Find which ports/services work on each IP
- 🛡️ **Network analysis**: Understand what network limitations exist
- 📊 **Detailed reports**: Get CSV files with all connectivity information

### ⏰ **When Should You Use This?**
Perfect for situations where your internet access is heavily restricted:

- 🚫 **No internet access**: Your network blocks most websites and services
- 🔒 **VPN/Proxy blocked**: Can't use normal bypass tools
- 🛡️ **Behind firewalls**: Need to find what connections still work
- 📡 **Emergency connectivity**: Need alternative routes to internet services
- � **Network troubleshooting**: Understanding connectivity problems

### 👥 **Who Is This For?**
- 🔬 **Researchers**: Studying internet restrictions and accessibility
- 🌍 **Network monitoring teams**: Documenting network limitations
- �️ **Network professionals**: Analyzing connectivity and restrictions
- 🔧 **System administrators**: Troubleshooting network access
- �‍💻 **Anyone in restricted networks**: Finding working internet connections

### � **Why This Tool?**
**PowerPinger is NOT the best network scanner available** - but it has unique advantages:

- � **Zero Installation**: Uses only what comes with Windows 10/11
- � **Ultra Portable**: Tool + IP lists = less than 18KB when zipped (can be emailed!)
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

3. **Run immediately** (no installation required):
```powershell
# Allow script execution (one-time setup)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run the scanner
.\powerPinger.ps1
```

### **🌐 Full Repository Installation**

1. **Clone the repository:**
```bash
git clone https://github.com/vafagh/PowerPinger.git
cd PowerPinger
```

2. **Ensure PowerShell execution policy allows scripts:**
```powershell
## 🚀 How to Use

### **Requirements**
- Windows 10/11 (any edition)
- No additional software needed!

### **Quick Start**
1. **Download** - Extract the tool files to any folder
2. **Double-click** `powerPinger.ps1` or run from command line
3. **Follow prompts** - Interactive setup will guide you

### **Simple Usage Scenarios**

#### 📞 **Scenario 1: "Can I reach any servers?"**
```powershell
# Just run it - uses default IP list
.\powerPinger.ps1
```
**Result**: Shows which of the pre-loaded IPs you can reach

#### 🔍 **Scenario 2: "What services work on this IP?"**
```powershell
# Check specific IPs for web services
.\powerPinger.ps1 -InputFile "my_targets.csv" -ScanMode "comprehensive" -Ports "80,443"
```
**Result**: Shows ping + web port accessibility for each IP

#### 🚫 **Scenario 3: "Ping is blocked, try ports only"**
```powershell
# Skip ping, test services directly
.\powerPinger.ps1 -ScanMode "port" -Ports "80,443,22,53"
```
**Result**: Bypasses ping restrictions, checks TCP connections

#### ⚡ **Scenario 4: "Quick scan, don't test everything"**
```powershell
# Stop after finding 3 working IPs per range
.\powerPinger.ps1 -MaxResponses 3 -ScanMode "comprehensive"
```
**Result**: Faster scanning, good for network discovery

#### 🤖 **Scenario 5: "Run automatically every hour"**
```powershell
# Windows Task Scheduler or script automation
.\powerPinger.ps1 -InputFile "targets.csv" -OutputFile "hourly_scan.csv" -ScanMode "port"
```
**Result**: Automated monitoring, no user interaction needed

#### 📧 **Scenario 6: "Email-friendly deployment"**
1. **Zip the folder** (becomes <18KB)
2. **Email to target location**
3. **Extract and run** - no installation needed

### **Input Files Made Simple**

**Create a CSV file** with IPs you want to test:
```csv
IP,Description
8.8.8.8,Google DNS
1.1.1.1,Cloudflare DNS
192.168.1.0/24,Local network range
```

**Or just list IPs** in a text file:
```
8.8.8.8
1.1.1.1
192.168.1.0/24
```

## 🎛️ Scan Modes Explained

| Mode | What it does | When to use |
|------|-------------|-------------|
| **`ping`** | Only tests ping | When you just need basic connectivity |
| **`port`** | Only tests TCP ports | When ping is blocked by firewall |
| **`both`** | Tests ping + ports separately | When you want complete information |
| **`both`** | Analyzes accessibility patterns | When you want to understand what's reachable |

## 📊 Understanding Results

Your results CSV will show:
- **Ping Result**: Success/Failed/Timeout
- **Ping Time**: Response time in milliseconds  
- **Ports Open**: Which TCP ports responded
- **Service Status**: Overall accessibility assessment
- **Network Status**: Type of accessibility found

**Network Status Types:**
- **No**: Everything works normally
- **ICMP-Blocked**: Ping fails but services work
- **Service-Blocked**: Ping works but services fail
- **Unassigned-Range**: No response (likely no server assigned)

## 🔧 Advanced Configuration

**Timeouts** (if network is slow):
```powershell
.\powerPinger.ps1 -Timeout 5000 -PortTimeout 10000
```

**Custom ports** (test specific services):
```powershell
.\powerPinger.ps1 -Ports "80,443,22,53,8080,3389"
```

**Skip dead ranges** (for large scans):
```powershell
.\powerPinger.ps1 -Jump 10 -MaxFailures 5
```
## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch  
3. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Important Disclaimers

### **⚖️ Legal Warning**
- **Only scan networks you own** or have explicit permission to test
- **Check local laws** - network scanning may be restricted in your area
- **Get authorization** before scanning corporate or third-party networks
- **You are responsible** for compliance with all laws and policies

### **🛠️ Technical Limitations**
- **Not thoroughly tested** in all network environments
- **May contain bugs** that affect results accuracy
- **Results may vary** based on network conditions
- **No guarantees** about performance or accuracy

### **🚫 No Warranties**
- Provided **"as is"** without any warranties
- **No liability** for damages or consequences from use
- **Use at your own risk** and test in safe environments first

**By using PowerPinger, you acknowledge these terms and accept all responsibility.**

---

**⭐ If this tool helps you, please star the repository!**

## 📚 More Information
- 📖 [Quick Start Guide](QUICKSTART.md) - Get started in 5 minutes
- 🚀 [Enhanced Features](ENHANCED_FEATURES.md) - Advanced capabilities overview
- 📋 [Changelog](CHANGELOG.md) - Version history and updates
- 🤝 [Contributing](CONTRIBUTING.md) - Development guidelines
- 🎯 [MaxResponses Feature](MAXRESPONSES_FEATURE.md) - Response limiting documentation

[⬆️ Back to top](#-powerpinger---network-accessibility-scanner)
