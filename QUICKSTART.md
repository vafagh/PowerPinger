# PowerPinger Quick Start Guide

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

#### Smart Censorship Detection
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

### Smart Mode (Censorship Detection)
```csv
IP,Location,Ping Result,Ping Time (ms),Ports Open,Service Status,Censorship Detected
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

## 📊 Understanding Results

| Status | Meaning |
|--------|---------|
| **No Censorship** | Both ping and ports work |
| **ICMP-Blocked** | Ping fails, services work |
| **Ping-Only** | Ping works, no services |
| **Full Block** | Nothing responds |

## 🎯 Use Cases

- **Network Testing**: Verify connectivity
- **Censorship Research**: Detect filtering patterns  
- **Security Assessment**: Check service availability
- **Troubleshooting**: Diagnose network issues

Need more help? Check the full [README.md](README.md) or [open an issue](https://github.com/yourusername/PowerPinger/issues)!
