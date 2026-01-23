#Requires -Version 5.0

<#
.SYNOPSIS
    PowerPinger - Network Accessibility Scanner

.DESCRIPTION
    A PowerShell-based network scanner for discovering accessible servers and services
    through intelligent ping and port scanning analysis.

.NOTES
    ⚠️  IMPORTANT DISCLAIMERS:
    
    LEGAL COMPLIANCE:
    - Only use on networks you own or have explicit written permission to test
    - Using network scanning tools may violate local laws, regulations, or policies
    - You are solely responsible for ensuring compliance with all applicable laws
    
    TECHNICAL LIMITATIONS:
    - This tool has not been thoroughly tested under all network conditions
    - Software may contain bugs, errors, or unexpected behaviors
    - Results may not accurately reflect actual network conditions
    - No guarantee of accuracy, completeness, or reliability of results
    
    NO WARRANTIES:
    - Software provided "AS IS" without warranties of any kind
    - Author accepts no responsibility for damages, losses, or consequences
    - Use at your own risk and discretion
    
    By using this script, you acknowledge that you have read, understood, 
    and agree to these terms and disclaimers.

.EXAMPLE
    .\powerPinger.ps1 -InputFile "targets.csv" -ScanMode "both"
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$InputFile = "ip_list.csv", # Default input file name
    
    [Parameter()]
    [string]$OutputFile = "ping_results.csv",   # Default output file name
    
    [Parameter()]
    [int]$Timeout = 1500, # Ping timeout in milliseconds (default: 500ms)
    
    [Parameter()]
    [int]$MaxFailures = 4, # Number of consecutive failures before action (skip or jump)
    
    [Parameter()]
    [int]$Jump = 16,  # Number of IPs to skip after MaxFailures (0 = disabled)
    
    [Parameter()]
    [int]$Skip = 3, # Number of jumps before skipping entire range (only applies if Jump > 0)
    
    [Parameter()]
    [int]$DelayMs = 0, # Delay in milliseconds between batches (rate limiting, 0 = disabled)
    
    [Parameter()]
    [string]$ScanMode = "ping", # Scanning mode: "ping", "port", "both", "parallel"
    
    [Parameter()]
    [string]$Ports = "80,443,22,53,8080,8443", # Comma-separated list of ports to scan
    
    [Parameter()]
    [int]$PortTimeout = 3000, # Port connection timeout in milliseconds
    
    [Parameter()]
    [int]$MaxResponses = 10 # Maximum successful responses before skipping range (0 = disabled)
)

# =====================================
# CONFIGURATION SETTINGS
# =====================================
# Default values for all script parameters
# Modify these values to change the script's default behavior
# These settings will be used when no command-line parameters are provided

# File Settings
$DefaultInputFile = "ip_list.csv"               # Default input CSV file name
$DefaultOutputFile = "ping_results.csv"         # Default output CSV file name

# Ping Settings
$DefaultTimeout = 1500                          # Ping timeout in milliseconds (1000ms = 1 second)
$DefaultMaxFailures = 4                         # Number of consecutive failures before action (skip or jump)

# Jump/Skip Settings
$DefaultJump = 16                               # Number of IPs to skip after MaxFailures (0 = disabled, jump feature off)
$DefaultSkip = 3                                # Number of jumps before skipping entire range (only applies if Jump > 0)

# Port Scanning Settings (NEW!)
$DefaultScanMode = "ping"                       # Default scan mode: "ping", "port", "both", "parallel"
$DefaultPorts = "80,443,22,53,8080,8443"        # Default ports to scan (HTTP, HTTPS, SSH, DNS, Alt-HTTP, Alt-HTTPS)
$DefaultPortTimeout = 3000                      # Port connection timeout in milliseconds (3 seconds)
$DefaultMaxResponses = 10                       # Maximum successful responses before skipping range (0 = disabled)

# Usage Examples:
# .\powerPinger.ps1                             # Uses interactive mode to select files
# .\powerPinger.ps1 -InputFile "do.csv"        # Uses specific input file, interactive output
# .\powerPinger.ps1 -Timeout 5000               # Uses 5 second timeout, interactive file selection
# .\powerPinger.ps1 -Jump 0                     # Disables jumping, interactive file selection
# .\powerPinger.ps1 -ScanMode both             # Full accessibility detection mode
# .\powerPinger.ps1 -ScanMode port -Ports "80,443,22"  # Port-only scanning
# .\powerPinger.ps1 -ScanMode parallel         # Fast parallel ping scanning
# .\powerPinger.ps1 -MaxResponses 5             # Stop after 5 responses per range
# .\powerPinger.ps1 -InputFile "do.csv" -OutputFile "results.csv"  # Full command line mode

# Override with default values if not specified via parameters
if (-not $PSBoundParameters.ContainsKey('InputFile')) { $InputFile = $DefaultInputFile }
if (-not $PSBoundParameters.ContainsKey('OutputFile')) { $OutputFile = $DefaultOutputFile }
if (-not $PSBoundParameters.ContainsKey('Timeout')) { $Timeout = $DefaultTimeout }
if (-not $PSBoundParameters.ContainsKey('MaxFailures')) { $MaxFailures = $DefaultMaxFailures }
if (-not $PSBoundParameters.ContainsKey('Jump')) { $Jump = $DefaultJump }
if (-not $PSBoundParameters.ContainsKey('Skip')) { $Skip = $DefaultSkip }
if (-not $PSBoundParameters.ContainsKey('ScanMode')) { $ScanMode = $DefaultScanMode }
if (-not $PSBoundParameters.ContainsKey('Ports')) { $Ports = $DefaultPorts }
if (-not $PSBoundParameters.ContainsKey('PortTimeout')) { $PortTimeout = $DefaultPortTimeout }
if (-not $PSBoundParameters.ContainsKey('MaxResponses')) { $MaxResponses = $DefaultMaxResponses }

# =====================================

# Add PowerShell version check
$isPSCore = $PSVersionTable.PSVersion.Major -ge 6

# Detect if running via "Run with PowerShell"
$isRunWithPowerShell = $MyInvocation.MyCommand.CommandType -eq 'ExternalScript' -and $Host.Name -eq 'ConsoleHost'

# =====================================
# WELCOME SCREEN & PROGRAM INFO
# =====================================

# Function to detect if console supports Unicode/emojis properly
function Test-UnicodeSupport {
    # Check if we're in Windows Terminal, VS Code, or similar modern terminal
    $modernTerminal = $false
    
    # Check environment variables that indicate modern terminals
    if ($env:WT_SESSION -or $env:TERM_PROGRAM -eq "vscode" -or $env:ConEmuPID) {
        $modernTerminal = $true
    }
    
    # Check console font (modern terminals usually have better Unicode support)
    try {
        $host_ui = $Host.UI.RawUI
        if ($host_ui.WindowTitle -match "Windows Terminal|Visual Studio Code") {
            $modernTerminal = $true
        }
    }
    catch {
        # Ignore errors in font detection
    }
    
    return $modernTerminal
}

# Function to get appropriate icon/symbol for display
function Get-DisplayIcon {
    param([string]$IconType)
    
    $supportsUnicode = Test-UnicodeSupport
    
    if ($supportsUnicode) {
        # Modern terminal - use emojis and Unicode
        switch ($IconType) {
            "search" { return "🔍" }
            "target" { return "🎯" }
            "rocket" { return "🚀" }
            "gear" { return "⚙️" }
            "folder" { return "📂" }
            "disk" { return "💾" }
            "chart" { return "📊" }
            "bulb" { return "💡" }
            "check" { return "✅" }
            "cross" { return "❌" }
            "warning" { return "⚠️" }
            "shield" { return "🛡️" }
            "lightning" { return "⚡" }
            "package" { return "📦" }
            default { return "•" }
        }
    } else {
        # Legacy PowerShell console - use simple ASCII
        switch ($IconType) {
            "search" { return "[SCAN]" }
            "target" { return "[TARGET]" }
            "rocket" { return "[START]" }
            "gear" { return "[CONFIG]" }
            "folder" { return "[INPUT]" }
            "disk" { return "[OUTPUT]" }
            "chart" { return "[RESULTS]" }
            "bulb" { return "[TIP]" }
            "check" { return "[OK]" }
            "cross" { return "[ERROR]" }
            "warning" { return "[WARN]" }
            "shield" { return "[FILTER]" }
            "lightning" { return "[FAST]" }
            "package" { return "[PORTABLE]" }
            default { return "*" }
        }
    }
}

function Show-WelcomeScreen {
    param (
        [bool]$IsInteractiveMode
    )
      Clear-Host
    $searchIcon = Get-DisplayIcon "search"
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                            $searchIcon PowerPinger v2.0                              ║" -ForegroundColor Cyan
    Write-Host "║                      Advanced Network Range Scanner                         ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
    Write-Host "Current Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
      # Provide guidance for "Run with PowerShell" users
    if ($isRunWithPowerShell) {
        $bulbIcon = Get-DisplayIcon "bulb"
        Write-Host "$bulbIcon Tip: For best experience, run from PowerShell terminal" -ForegroundColor Yellow
        Write-Host "   Right-click in folder → Open PowerShell window here → .\powerPinger.ps1" -ForegroundColor Gray
    }
    Write-Host ""
    
    if ($IsInteractiveMode) {
        $targetIcon = Get-DisplayIcon "target"
        Write-Host "$targetIcon Running in INTERACTIVE MODE" -ForegroundColor Magenta
        Write-Host "   You will be guided through configuration options" -ForegroundColor Gray
    } else {
        $lightningIcon = Get-DisplayIcon "lightning"
        Write-Host "$lightningIcon Running in COMMAND-LINE MODE" -ForegroundColor Yellow
        Write-Host "   Using provided parameters, skipping interactive questions" -ForegroundColor Gray
    }
    Write-Host ""
}

function Show-ProgramCapabilities {
    Write-Host "🚀 PROGRAM CAPABILITIES:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📂 Input Support:" -ForegroundColor Cyan
    Write-Host "   • CSV and TXT files with IP ranges" -ForegroundColor White
    Write-Host "   • Individual IPs (e.g., 8.8.8.8)" -ForegroundColor White
    Write-Host "   • CIDR notation (e.g., 192.168.1.0/24)" -ForegroundColor White
    Write-Host "   • Mixed formats in same file" -ForegroundColor White
    Write-Host ""
      Write-Host "⚙️ Advanced Features:" -ForegroundColor Cyan
    Write-Host "   • Adaptive timeout detection" -ForegroundColor White
    Write-Host "   • Jump mode: Skip unresponsive IP blocks" -ForegroundColor White
    Write-Host "   • Range skipping: Avoid scanning dead ranges" -ForegroundColor White
    Write-Host "   • Live control: Press 'S' during scan to skip current range" -ForegroundColor White
    Write-Host "   • Port scanning: Test service accessibility" -ForegroundColor White
    Write-Host "   • Network accessibility detection: Identify access patterns" -ForegroundColor White
    Write-Host "   • Multiple scan modes: ping/port/both" -ForegroundColor White
    Write-Host "   • PowerShell 5.1 & 6+ compatibility" -ForegroundColor White
    Write-Host "   • Full IPv6 support with intelligent range limiting" -ForegroundColor White
    Write-Host "   • Rate limiting: Prevent DDoS detection with batch delays" -ForegroundColor White
    Write-Host ""
    
    Write-Host "⚠️  Safety Warning:" -ForegroundColor Yellow
    Write-Host "   • Scanning large production networks (Cloudflare, AWS, etc.) may trigger" -ForegroundColor Red
    Write-Host "     DDoS protection and block your IP or internet access" -ForegroundColor Red
    Write-Host "   • Use rate limiting (-DelayMs 100-500) for production infrastructure" -ForegroundColor Yellow
    Write-Host "   • Test with small ranges first before scanning large networks" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "📊 Output Features:" -ForegroundColor Cyan
    Write-Host "   • CSV format with location data" -ForegroundColor White
    Write-Host "   • Response time logging" -ForegroundColor White
    Write-Host "   • Detailed progress reporting" -ForegroundColor White
    Write-Host "   • Auto-timestamped filenames" -ForegroundColor White
    Write-Host ""
    
    Write-Host "💡 Usage Modes:" -ForegroundColor Cyan
    Write-Host "   • Interactive: Guided setup with menus" -ForegroundColor White
    Write-Host "   • Command-line: Full automation for scripts" -ForegroundColor White
    Write-Host "   • Mixed: Combine parameters with interactive options" -ForegroundColor White
    Write-Host ""
}

function Show-ParameterInfo {
    Write-Host "📋 AVAILABLE PARAMETERS:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "-InputFile <file>     " -NoNewline -ForegroundColor Green
    Write-Host "Input CSV/TXT file name" -ForegroundColor White
    Write-Host "-OutputFile <file>    " -NoNewline -ForegroundColor Green
    Write-Host "Output CSV file name" -ForegroundColor White
    Write-Host "-Timeout <ms>         " -NoNewline -ForegroundColor Green
    Write-Host "Ping timeout in milliseconds (default: $DefaultTimeout)" -ForegroundColor White
    Write-Host "-MaxFailures <num>    " -NoNewline -ForegroundColor Green
    Write-Host "Consecutive failures before action (default: $DefaultMaxFailures)" -ForegroundColor White
    Write-Host "-Jump <num>           " -NoNewline -ForegroundColor Green
    Write-Host "IPs to skip after failures (0=disabled, default: $DefaultJump)" -ForegroundColor White
    Write-Host "-Skip <num>           " -NoNewline -ForegroundColor Green
    Write-Host "Jumps before skipping range (default: $DefaultSkip)" -ForegroundColor White    Write-Host "-ScanMode <mode>      " -NoNewline -ForegroundColor Green
    Write-Host "Scan type: ping/port/both/parallel (default: $DefaultScanMode)" -ForegroundColor White
    Write-Host "-Ports <list>         " -NoNewline -ForegroundColor Green
    Write-Host "Comma-separated ports to scan (default: $DefaultPorts)" -ForegroundColor White
    Write-Host "-PortTimeout <ms>     " -NoNewline -ForegroundColor Green
    Write-Host "Port connection timeout in ms (default: $DefaultPortTimeout)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📝 EXAMPLE COMMANDS:" -ForegroundColor Yellow
    Write-Host "====================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host ".\powerPinger.ps1" -ForegroundColor Cyan
    Write-Host "   → Interactive mode with all options" -ForegroundColor Gray
    Write-Host ""
    Write-Host ".\powerPinger.ps1 -Timeout 5000" -ForegroundColor Cyan
    Write-Host "   → Interactive files, 5-second timeout" -ForegroundColor Gray
    Write-Host ""
    Write-Host ".\powerPinger.ps1 -InputFile `"ranges.csv`" -Jump 10" -ForegroundColor Cyan
    Write-Host "   → Specific input, interactive output, jump 10 IPs" -ForegroundColor Gray
    Write-Host ""    Write-Host ".\powerPinger.ps1 -InputFile `"do.csv`" -OutputFile `"results.csv`" -Jump 0" -ForegroundColor Cyan
    Write-Host "   → Full command-line mode, no jumping" -ForegroundColor Gray
    Write-Host ""    Write-Host ".\powerPinger.ps1 -ScanMode both -Ports `"80,443,22`"" -ForegroundColor Cyan
    Write-Host "   → Full accessibility detection with web/SSH ports" -ForegroundColor Gray
    Write-Host ""
    Write-Host ".\powerPinger.ps1 -ScanMode parallel" -ForegroundColor Cyan
    Write-Host "   → Fast parallel ping scanning with batch processing" -ForegroundColor Gray
    Write-Host ""
    Write-Host ".\powerPinger.ps1 -ScanMode port -Ports `"80,443`" -PortTimeout 5000" -ForegroundColor Cyan
    Write-Host "   → Port-only scanning for HTTP/HTTPS services" -ForegroundColor Gray
    Write-Host ""
}

# Determine if we're in interactive mode - only when NO parameters provided
$InteractiveMode = $PSBoundParameters.Count -eq 0

# Show welcome screen
Show-WelcomeScreen -IsInteractiveMode $InteractiveMode

if ($InteractiveMode) {
    Show-ProgramCapabilities
    Write-Host "Press Enter to continue to configuration..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Clear-Host
    Write-Host "🔍 PowerPinger - Interactive Configuration" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
} else {
    Write-Host "ℹ️  To see full program capabilities, run without parameters: .\powerPinger.ps1" -ForegroundColor Cyan
    Write-Host ""
}

# =====================================
# INTERACTIVE FILE SELECTION
# =====================================

function Show-FileMenu {
    param (
        [array]$Files,
        [string]$Title
    )
    
    Write-Host "`n$Title" -ForegroundColor Yellow
    Write-Host ("=" * $Title.Length) -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $Files.Count; $i++) {
        Write-Host "[$($i + 1)] $($Files[$i].Name)" -ForegroundColor Cyan
    }
    Write-Host "[0] Exit" -ForegroundColor Red
    Write-Host ""
}

function Get-InputFile {
    $scriptDirectory = if ($MyInvocation.MyCommand.Path) { 
        Split-Path -Parent $MyInvocation.MyCommand.Path 
    } else { 
        Get-Location 
    }
    
    # Find all CSV and TXT files in the script directory
    $csvFiles = Get-ChildItem -Path $scriptDirectory -Filter "*.csv" -File
    $txtFiles = Get-ChildItem -Path $scriptDirectory -Filter "*.txt" -File
    $allFiles = @($csvFiles) + @($txtFiles) | Sort-Object Name
    
    if ($allFiles.Count -eq 0) {
        Write-Host "📋 No CSV or TXT files found in the script directory" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "❓ Would you like to:" -ForegroundColor Cyan
        Write-Host "[1] Enter IP addresses manually (recommended for quick tests)" -ForegroundColor Green
        Write-Host "[2] Create a new input file and exit" -ForegroundColor Yellow
        Write-Host "[0] Exit" -ForegroundColor Red
        Write-Host ""
        
        $choice = Read-Host "👉 Select option (0-2)"
        
        if ($choice -eq "1") {
            return "MANUAL_INPUT"
        } elseif ($choice -eq "2") {
            Write-Host ""
            Write-Host "📝 Creating sample template file: ip_list.csv" -ForegroundColor Cyan
            $sampleContent = @"
# Sample IP ranges - Edit this file with your own ranges
# Format: IP/CIDR,Country,Region,City,PostalCode
8.8.8.8,US,CA,Mountain View,94043
1.1.1.1,US,CA,San Francisco,94107
192.168.1.0/24,Local,Network,LAN,00000
"@
            $samplePath = Join-Path -Path $scriptDirectory -ChildPath "ip_list.csv"
            $sampleContent | Out-File -FilePath $samplePath -Encoding UTF8
            Write-Host "✅ Sample file created: $samplePath" -ForegroundColor Green
            Write-Host "📝 Edit this file and run the script again" -ForegroundColor Yellow
            exit 0
        } else {
            Write-Host "👋 Exiting..." -ForegroundColor Yellow
            exit 0
        }
    }
    
    # If only one file exists, use it automatically
    if ($allFiles.Count -eq 1) {
        Write-Host "📄 Found only one IP range file: $($allFiles[0].Name)" -ForegroundColor Green
        Write-Host "✅ Using this file automatically..." -ForegroundColor Green
        Start-Sleep -Seconds 1
        return $allFiles[0].FullName
    }
    
    # Multiple files found - show menu
    do {
        Write-Host ""
        Write-Host "📂 Available IP Range Files" -ForegroundColor Yellow
        Write-Host "============================" -ForegroundColor Yellow
        
        for ($i = 0; $i -lt $allFiles.Count; $i++) {
            Write-Host "[$($i + 1)] $($allFiles[$i].Name)" -ForegroundColor Cyan
        }
        Write-Host "[0] Exit" -ForegroundColor Red
        Write-Host ""
        
        Write-Host "❓ Which file contains your IP ranges to scan?" -ForegroundColor Yellow
        Write-Host "💡 Tip: Files should contain IP addresses or CIDR ranges" -ForegroundColor Gray
        $selection = Read-Host "👉 Select input file (1-$($allFiles.Count)) or press Enter for default ($DefaultInputFile)"
        
        if ([string]::IsNullOrWhiteSpace($selection)) {
            # User pressed Enter - use default from settings
            $defaultFile = $allFiles | Where-Object { $_.Name -eq $DefaultInputFile }
            if ($defaultFile) {
                Write-Host "✅ Using default file: $($defaultFile.Name)" -ForegroundColor Green
                return $defaultFile.FullName
            } else {
                Write-Host "⚠️  Default file '$DefaultInputFile' not found. Please select a file." -ForegroundColor Red
                continue
            }
        }
        
        if ($selection -eq "0") {
            Write-Host "👋 Exiting..." -ForegroundColor Yellow
            exit 0
        }
        
        try {
            $selectedIndex = [int]$selection - 1
            if ($selectedIndex -ge 0 -and $selectedIndex -lt $allFiles.Count) {
                Write-Host "✅ Selected: $($allFiles[$selectedIndex].Name)" -ForegroundColor Green
                return $allFiles[$selectedIndex].FullName
            } else {
                Write-Host "❌ Invalid selection. Please choose a number between 1 and $($allFiles.Count)." -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Please enter a valid number." -ForegroundColor Red
        }
    } while ($true)
}

function Get-OutputFile {
    $scriptDirectory = if ($MyInvocation.MyCommand.Path) { 
        Split-Path -Parent $MyInvocation.MyCommand.Path 
    } else { 
        Get-Location 
    }
    $currentDateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $defaultName = "Found_$currentDateTime"
    
    Write-Host ""
    Write-Host "💾 Output File Configuration" -ForegroundColor Yellow
    Write-Host "============================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "❓ What would you like to name your results file?" -ForegroundColor Yellow
    Write-Host "📝 The file will contain all responsive IPs with ping times" -ForegroundColor Gray
    Write-Host "💡 Extension (.csv) will be added automatically" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎯 Default option: $defaultName" -ForegroundColor Cyan
    Write-Host "📂 File will be saved in: $scriptDirectory" -ForegroundColor Gray
    Write-Host ""
    
    $fileName = Read-Host "👉 Enter filename (without extension) or press Enter for default"
    
    if ([string]::IsNullOrWhiteSpace($fileName)) {
        $fileName = $defaultName
        Write-Host "✅ Using default filename: $fileName" -ForegroundColor Green
    } else {
        # Sanitize filename
        $fileName = $fileName -replace '[<>:"/\\|?*]', '_'
        Write-Host "✅ Using custom filename: $fileName" -ForegroundColor Green
    }
    
    $outputFile = "$fileName.csv"
    $fullPath = Join-Path -Path $scriptDirectory -ChildPath $outputFile
    
    # Check if file exists and ask for confirmation
    if (Test-Path $fullPath) {
        Write-Host ""
        Write-Host "⚠️  File already exists: $outputFile" -ForegroundColor Yellow
        $overwrite = Read-Host "👉 Overwrite existing file? (y/N)"
        if ($overwrite -notmatch '^[Yy]') {
            Write-Host "📝 Please choose a different filename:" -ForegroundColor Cyan
            return Get-OutputFile  # Recursive call to get new name
        }
    }
      Write-Host "📁 Results will be saved to: $outputFile" -ForegroundColor Green
    return $fullPath
}

function Get-ScanConfiguration {
    Write-Host ""
    Write-Host "⚙️  Scan Configuration" -ForegroundColor Yellow
    Write-Host "======================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "❓ Would you like to customize scanning parameters?" -ForegroundColor Yellow
    Write-Host "💡 Current defaults work well for most scenarios" -ForegroundColor Gray
    Write-Host ""    Write-Host "📊 Current Settings:" -ForegroundColor Cyan
    Write-Host "   • Scan Mode: $DefaultScanMode (ping/port/both/parallel)" -ForegroundColor White
    Write-Host "   • Timeout: ${DefaultTimeout}ms per ping" -ForegroundColor White
    Write-Host "   • Port Timeout: ${DefaultPortTimeout}ms per port" -ForegroundColor White
    Write-Host "   • Ports to Scan: $DefaultPorts" -ForegroundColor White
    Write-Host "   • Max Failures: $DefaultMaxFailures consecutive timeouts before action" -ForegroundColor White
    Write-Host "   • Jump Mode: $(if ($DefaultJump -gt 0) { "$DefaultJump IPs (enabled)" } else { "Disabled" })" -ForegroundColor White
    Write-Host "   • Skip Limit: $DefaultSkip jumps before skipping entire range" -ForegroundColor White
    Write-Host "   • Max Responses: $(if ($DefaultMaxResponses -gt 0) { "$DefaultMaxResponses per range (enabled)" } else { "Disabled" })" -ForegroundColor White
    Write-Host ""
    
    $customize = Read-Host "👉 Customize settings? (y/N)"
      if ($customize -match '^[Yy]') {
        Write-Host ""        Write-Host "🔧 Advanced Configuration" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan
        
        # Scan Mode configuration
        Write-Host ""        Write-Host "🎯 Scan Mode (current: $DefaultScanMode)" -ForegroundColor Yellow
        Write-Host "💡 Choose scanning strategy for network accessibility detection:" -ForegroundColor Gray
        Write-Host "   🏓 ping     - ICMP ping only (traditional mode)" -ForegroundColor White
        Write-Host "   🚪 port     - Port scanning only (bypass ICMP blocks)" -ForegroundColor White
        Write-Host "   🔄 both     - Ping first, then port scan non-responders" -ForegroundColor White
        Write-Host "   ⚡ parallel - Fast parallel ping with batch processing" -ForegroundColor White
        Write-Host "📋 Recommended: 'parallel' for large ranges, 'both' for restricted networks" -ForegroundColor Gray
        $modeInput = Read-Host "👉 Enter scan mode (ping/port/both/parallel) or press Enter for default ($DefaultScanMode)"
        if (-not [string]::IsNullOrWhiteSpace($modeInput) -and $modeInput -match '^(ping|port|both|parallel)$') {
            $script:ScanMode = $modeInput.ToLower()
        }
        
        # Port List configuration (if port scanning enabled)
        if ($script:ScanMode -eq "port" -or $script:ScanMode -eq "both") {
            Write-Host ""
            Write-Host "🚪 Port Selection (current: $DefaultPorts)" -ForegroundColor Yellow
            Write-Host "💡 Common service ports to test for accessibility:" -ForegroundColor Gray
            Write-Host "   🌐 80,443    - Web services (HTTP, HTTPS)" -ForegroundColor White
            Write-Host "   🔐 22        - SSH secure shell" -ForegroundColor White
            Write-Host "   🌍 53        - DNS domain name system" -ForegroundColor White
            Write-Host "   📧 993,995   - Secure email (IMAPS, POP3S)" -ForegroundColor White
            Write-Host "   🔀 8080,8443 - Alternative web ports" -ForegroundColor White
            Write-Host "📋 Format: comma-separated list (e.g., 80,443,22)" -ForegroundColor Gray
            $portsInput = Read-Host "👉 Enter ports to scan or press Enter for default ($DefaultPorts)"
            if (-not [string]::IsNullOrWhiteSpace($portsInput)) {
                $script:Ports = $portsInput
            }
            
            # Port Timeout configuration
            Write-Host ""
            Write-Host "⏱️  Port Connection Timeout (current: ${DefaultPortTimeout}ms)" -ForegroundColor Yellow
            Write-Host "💡 Time to wait for port connection (higher = more reliable)" -ForegroundColor Gray
            Write-Host "📋 Common values: 1000ms (fast), 3000ms (balanced), 5000ms (thorough)" -ForegroundColor Gray
            $portTimeoutInput = Read-Host "👉 Enter port timeout in milliseconds or press Enter for default ($DefaultPortTimeout)"
            if (-not [string]::IsNullOrWhiteSpace($portTimeoutInput) -and $portTimeoutInput -match '^\d+$') {
                $script:PortTimeout = [int]$portTimeoutInput
            }
        }
        
        # Ping Timeout configuration (if ping enabled)
        if ($script:ScanMode -eq "ping" -or $script:ScanMode -eq "both") {
            Write-Host ""
            Write-Host "⏱️  Ping Timeout (current: ${DefaultTimeout}ms)" -ForegroundColor Yellow
            Write-Host "💡 Lower = faster scanning, higher = more accurate for slow networks" -ForegroundColor Gray
            Write-Host "📋 Common values: 1000ms (fast), 3000ms (balanced), 5000ms (thorough)" -ForegroundColor Gray
            $timeoutInput = Read-Host "👉 Enter timeout in milliseconds or press Enter for default ($DefaultTimeout)"
            if (-not [string]::IsNullOrWhiteSpace($timeoutInput) -and $timeoutInput -match '^\d+$') {
                $script:Timeout = [int]$timeoutInput
            }
        }
        
        # Max Failures configuration
        Write-Host ""
        Write-Host "❌ Max Consecutive Failures (current: $DefaultMaxFailures)" -ForegroundColor Yellow
        Write-Host "💡 How many failed tests before taking action (skip or jump)" -ForegroundColor Gray
        Write-Host "📋 Common values: 2 (aggressive), 5 (balanced), 10 (conservative)" -ForegroundColor Gray
        $failuresInput = Read-Host "👉 Enter max failures or press Enter for default ($DefaultMaxFailures)"
        if (-not [string]::IsNullOrWhiteSpace($failuresInput) -and $failuresInput -match '^\d+$') {
            $script:MaxFailures = [int]$failuresInput
        }
        
        # Jump Mode configuration
        Write-Host ""
        Write-Host "🦘 Jump Mode Configuration" -ForegroundColor Yellow
        Write-Host "💡 Skip a number of IPs when too many consecutive failures occur" -ForegroundColor Gray
        Write-Host "✅ Recommended for large ranges with sparse responsive IPs" -ForegroundColor Gray
        Write-Host "❌ Set to 0 to disable (will skip entire range instead)" -ForegroundColor Gray
        $jumpInput = Read-Host "👉 Enter IPs to jump (0=disabled) or press Enter for default ($DefaultJump)"
        if (-not [string]::IsNullOrWhiteSpace($jumpInput) -and $jumpInput -match '^\d+$') {
            $script:Jump = [int]$jumpInput
        }
          if ($script:Jump -gt 0) {
            # Skip Limit configuration
            Write-Host ""
            Write-Host "🛑 Skip Limit (current: $DefaultSkip)" -ForegroundColor Yellow
            Write-Host "💡 After how many jumps should we skip the entire range?" -ForegroundColor Gray
            Write-Host "📋 Common values: 3 (aggressive), 5 (balanced), 10 (patient)" -ForegroundColor Gray
            $skipInput = Read-Host "👉 Enter skip limit or press Enter for default ($DefaultSkip)"
            if (-not [string]::IsNullOrWhiteSpace($skipInput) -and $skipInput -match '^\d+$') {
                $script:Skip = [int]$skipInput
            }
        }
        
        # Max Responses configuration
        Write-Host ""
        Write-Host "🎯 Max Responses per Range (current: $DefaultMaxResponses)" -ForegroundColor Yellow
        Write-Host "💡 Stop scanning a range after finding this many responsive IPs" -ForegroundColor Gray
        Write-Host "💡 Useful for dense networks to avoid scanning unnecessary IPs" -ForegroundColor Gray
        Write-Host "📋 Common values: 5 (quick), 10 (balanced), 0 (disabled)" -ForegroundColor Gray
        $maxResponsesInput = Read-Host "👉 Enter max responses (0=disabled) or press Enter for default ($DefaultMaxResponses)"
        if (-not [string]::IsNullOrWhiteSpace($maxResponsesInput) -and $maxResponsesInput -match '^\d+$') {
            $script:MaxResponses = [int]$maxResponsesInput
        }
        
        # Rate Limiting configuration
        Write-Host ""
        Write-Host "⏱️  Rate Limiting (current: ${script:DelayMs}ms)" -ForegroundColor Yellow
        Write-Host "💡 Delay between batches to prevent DDoS detection (parallel mode)" -ForegroundColor Gray
        Write-Host "⚠️  IMPORTANT: Use 100-500ms for production networks (Cloudflare, AWS, etc.)" -ForegroundColor Red
        Write-Host "📋 Values: 0 (no delay, risky), 100 (safe), 250 (safer), 500 (safest)" -ForegroundColor Gray
        $delayInput = Read-Host "👉 Enter delay in ms (0=disabled) or press Enter for default (${script:DelayMs})"
        if (-not [string]::IsNullOrWhiteSpace($delayInput) -and $delayInput -match '^\d+$') {
            $script:DelayMs = [int]$delayInput
        }
        
        Write-Host ""
        Write-Host "✅ Configuration Updated!" -ForegroundColor Green
    } else {
        Write-Host "✅ Using default settings" -ForegroundColor Green
    }
}

# =====================================
# MAIN EXECUTION
# =====================================

if ($InteractiveMode) {
    # Interactive Mode - get all configuration from user
    Write-Host "`n🔍 PowerPinger - Interactive Configuration" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Get input file
    $inputPath = Get-InputFile
    $InputFile = Split-Path -Leaf $inputPath
    
    # Get output file
    $outputPath = Get-OutputFile
    $OutputFile = Split-Path -Leaf $outputPath
    
    # Get scan configuration
    Get-ScanConfiguration
    
    # Show final configuration summary
    Write-Host "`n🎯 Final Configuration Summary" -ForegroundColor Magenta
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "   Input File: $InputFile" -ForegroundColor White
    Write-Host "   Output File: $OutputFile" -ForegroundColor White
    Write-Host "   Scan Mode: $ScanMode" -ForegroundColor White
    if ($ScanMode -eq "ping" -or $ScanMode -eq "both") {
        Write-Host "   Ping Timeout: ${Timeout}ms" -ForegroundColor White
    }
    if ($ScanMode -eq "port" -or $ScanMode -eq "both") {
        Write-Host "   Port Timeout: ${PortTimeout}ms" -ForegroundColor White
        Write-Host "   Ports to Scan: $Ports" -ForegroundColor White
    }
    Write-Host "   Max Failures: $MaxFailures" -ForegroundColor White
    if ($Jump -gt 0) {
        Write-Host "   Jump Mode: $Jump IPs (skip range after $Skip jumps)" -ForegroundColor White
    } else {
        Write-Host "   Jump Mode: Disabled" -ForegroundColor White
    }
    if ($MaxResponses -gt 0) {
        Write-Host "   Max Responses: $MaxResponses per range" -ForegroundColor White
    } else {
        Write-Host "   Max Responses: Disabled" -ForegroundColor White
    }
    if ($ScanMode -eq "parallel") {
        if ($DelayMs -gt 0) {
            Write-Host "   Rate Limiting: ${DelayMs}ms delay between batches" -ForegroundColor Green
        } else {
            Write-Host "   Rate Limiting: Disabled (⚠️ Risk of DDoS detection)" -ForegroundColor Red
        }
    }
    Write-Host ""
    # Ask for final confirmation
    Write-Host "🚀 Ready to start scanning? (Y/n): " -ForegroundColor Yellow -NoNewline
    $confirm = Read-Host
    $confirm = $confirm.Trim() # Remove any whitespace
    if (-not [string]::IsNullOrWhiteSpace($confirm) -and $confirm -match '^[Nn]') {
        Write-Host "Scan cancelled by user." -ForegroundColor Yellow
        exit 0
    }
    
} else {
    # Command-line Mode - use provided parameters or defaults, fully non-interactive
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    
    # Validate required parameters
    if (-not $InputFile) {
        Write-Host "❌ ERROR: InputFile parameter is required when running in non-interactive mode." -ForegroundColor Red
        Write-Host "💡 Usage: .\powerPinger.ps1 -InputFile 'your_file.csv' -OutputFile 'results.csv'" -ForegroundColor Yellow
        exit 1
    }
    
    if (-not $OutputFile) {
        Write-Host "❌ ERROR: OutputFile parameter is required when running in non-interactive mode." -ForegroundColor Red
        Write-Host "💡 Usage: .\powerPinger.ps1 -InputFile 'your_file.csv' -OutputFile 'results.csv'" -ForegroundColor Yellow
        exit 1
    }
    
    # Set up file paths
    $inputPath = Join-Path -Path $scriptPath -ChildPath $InputFile
    $outputPath = Join-Path -Path $scriptPath -ChildPath $OutputFile
    
    # Validate input file exists
    if (-not (Test-Path $inputPath)) {
        Write-Host "❌ ERROR: Input file not found: $inputPath" -ForegroundColor Red
        exit 1
    }
    
    # Show configuration summary for command-line mode
    Write-Host "🚀 PowerPinger - Non-Interactive Mode" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "   Input File: $InputFile" -ForegroundColor White
    Write-Host "   Output File: $OutputFile" -ForegroundColor White
    Write-Host "   Scan Mode: $ScanMode" -ForegroundColor White
    if ($ScanMode -eq "ping" -or $ScanMode -eq "both" -or $ScanMode -eq "parallel") {
        Write-Host "   Ping Timeout: ${Timeout}ms" -ForegroundColor White
    }
    if ($ScanMode -eq "port" -or $ScanMode -eq "both") {
        Write-Host "   Port Timeout: ${PortTimeout}ms" -ForegroundColor White
        Write-Host "   Ports to Scan: $Ports" -ForegroundColor White
    }
    Write-Host "   Max Failures: $MaxFailures" -ForegroundColor White
    if ($Jump -gt 0) {
        Write-Host "   Jump Mode: $Jump IPs (skip range after $Skip jumps)" -ForegroundColor White
    } else {
        Write-Host "   Jump Mode: Disabled" -ForegroundColor White
    }
    if ($MaxResponses -gt 0) {
        Write-Host "   Max Responses: $MaxResponses per range" -ForegroundColor White
    } else {
        Write-Host "   Max Responses: Disabled" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "⚡ Starting scan automatically..." -ForegroundColor Green
}

# Helper function to check for keyboard input without blocking
function Test-SkipKeyPressed {
    try {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'S') {
                Write-Host ""
                Write-Host "  🛑 SKIP KEY DETECTED - Stopping current range..." -ForegroundColor Yellow
                Write-Host ""
                return $true
            }
        }
    } catch {
        # Silently handle any console access errors
    }
    return $false
}

# Helper function to detect IP version
function Get-IPVersion {
    param ([string]$IPAddress)
    
    try {
        $parsed = [System.Net.IPAddress]::Parse($IPAddress)
        if ($parsed.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
            return 4
        } elseif ($parsed.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
            return 6
        }
        return 0
    } catch {
        return 0
    }
}

# Helper function to convert CIDR notation to IP range (IPv4 and IPv6)
function Get-IPRange {
    param (
        [string]$BaseIP,
        [int]$CIDRSuffix
    )
    
    try {
        $ipVersion = Get-IPVersion -IPAddress $BaseIP
        
        if ($ipVersion -eq 4) {
            # IPv4 processing
            $ipAddress = [System.Net.IPAddress]::Parse($BaseIP)
            $ipBytes = $ipAddress.GetAddressBytes()
            if ([BitConverter]::IsLittleEndian) {
                [Array]::Reverse($ipBytes)
            }
            $ipInt = [BitConverter]::ToUInt32($ipBytes, 0)
            
            # Calculate subnet boundaries
            $mask = [UInt32]([Math]::Pow(2, 32 - $CIDRSuffix) - 1)
            $startIP = $ipInt -band (-bnot $mask)
            $endIP = $startIP + $mask
            
            return @{
                StartIP = $startIP
                EndIP = $endIP
                IPVersion = 4
                TotalIPs = ($endIP - $startIP + 1)
            }
        } elseif ($ipVersion -eq 6) {
            # IPv6 processing - return byte arrays instead of integers
            $ipAddress = [System.Net.IPAddress]::Parse($BaseIP)
            $ipBytes = $ipAddress.GetAddressBytes()
            
            # Calculate number of host bits
            $hostBits = 128 - $CIDRSuffix
            
            # For IPv6, we can't enumerate all IPs in large ranges
            # Calculate theoretical total (may be huge)
            if ($hostBits -le 32) {
                $totalIPs = [Math]::Pow(2, $hostBits)
            } else {
                $totalIPs = [double]::PositiveInfinity
            }
            
            # Calculate network address (zero out host bits)
            $networkBytes = [byte[]]::new(16)
            [Array]::Copy($ipBytes, $networkBytes, 16)
            
            # Zero out host bits to get network address
            $byteIndex = [Math]::Floor($CIDRSuffix / 8)
            $bitIndex = $CIDRSuffix % 8
            
            if ($bitIndex -ne 0) {
                $networkBytes[$byteIndex] = $networkBytes[$byteIndex] -band (0xFF -shl (8 - $bitIndex))
                $byteIndex++
            }
            
            for ($i = $byteIndex; $i -lt 16; $i++) {
                $networkBytes[$i] = 0
            }
            
            # Calculate broadcast/last address (set all host bits to 1)
            $broadcastBytes = [byte[]]::new(16)
            [Array]::Copy($networkBytes, $broadcastBytes, 16)
            
            $byteIndex = [Math]::Floor($CIDRSuffix / 8)
            $bitIndex = $CIDRSuffix % 8
            
            if ($bitIndex -ne 0) {
                $broadcastBytes[$byteIndex] = $broadcastBytes[$byteIndex] -bor (0xFF -shr $bitIndex)
                $byteIndex++
            }
            
            for ($i = $byteIndex; $i -lt 16; $i++) {
                $broadcastBytes[$i] = 0xFF
            }
            
            return @{
                StartIP = $networkBytes
                EndIP = $broadcastBytes
                IPVersion = 6
                TotalIPs = $totalIPs
                HostBits = $hostBits
            }
        } else {
            Write-Error "Invalid IP address format: $BaseIP"
            return $null
        }
    } catch {
        Write-Error "Error calculating IP range for $BaseIP/$CIDRSuffix : $_"
        return $null
    }
}

# Helper function to convert numeric IP to string format (IPv4 and IPv6)
function ConvertTo-IPString {
    param (
        [Parameter(ParameterSetName='IPv4')]
        [uint32]$IPInt,
        
        [Parameter(ParameterSetName='IPv6')]
        [byte[]]$IPBytes
    )
    
    try {
        if ($PSCmdlet.ParameterSetName -eq 'IPv4') {
            $bytes = [BitConverter]::GetBytes($IPInt)
            if ([BitConverter]::IsLittleEndian) {
                [Array]::Reverse($bytes)
            }
            return [System.Net.IPAddress]::new($bytes).ToString()
        } else {
            return [System.Net.IPAddress]::new($IPBytes).ToString()
        }
    } catch {
        Write-Error "Error converting IP to string: $_"
        return $null
    }
}

# Helper function to increment IPv6 address bytes
function Add-IPv6Address {
    param (
        [byte[]]$IPBytes,
        [int]$Increment = 1
    )
    
    $result = [byte[]]::new(16)
    [Array]::Copy($IPBytes, $result, 16)
    
    # Add increment starting from the least significant byte
    $carry = $Increment
    for ($i = 15; $i -ge 0 -and $carry -gt 0; $i--) {
        $sum = $result[$i] + $carry
        $result[$i] = $sum -band 0xFF
        $carry = $sum -shr 8
    }
    
    return $result
}

# Helper function to compare IPv6 addresses
function Compare-IPv6Address {
    param (
        [byte[]]$Address1,
        [byte[]]$Address2
    )
    
    for ($i = 0; $i -lt 16; $i++) {
        if ($Address1[$i] -lt $Address2[$i]) { return -1 }
        if ($Address1[$i] -gt $Address2[$i]) { return 1 }
    }
    return 0
}

# Helper function to convert CIDR to a list of IPs
function Convert-CIDRToIPList {
    param(
        [string]$CIDR
    )
    try {
        if ($CIDR -match "/") {
            $baseIP = $CIDR.Split("/")[0]
            $subnet = [int]$CIDR.Split("/")[1]
        } else {
            $baseIP = $CIDR
            $subnet = 32
        }
        
        $range = Get-IPRange -BaseIP $baseIP -CIDRSuffix $subnet
        if ($null -eq $range) {
            return @()
        }
        
        $ipList = @()
        for ($ipNum = $range.StartIP; $ipNum -le $range.EndIP; $ipNum++) {
            $currentIP = ConvertTo-IPString -IPInt $ipNum
            if ($null -ne $currentIP) {
                $ipList += $currentIP
            }
        }
        return $ipList
    }
    catch {
        Write-Host "Error parsing CIDR ${CIDR}: $_" -ForegroundColor Red
        return @()
    }
}

# =====================================
# PARALLEL PING FUNCTIONS (NEW!)
# =====================================

# Parallel ping function using runspaces for PowerShell 5.1 compatibility
function Invoke-ParallelPing {
    param(
        [string[]]$IPList,
        [int]$TimeoutMs = 1500,
        [int]$MaxConcurrent = 50
    )
    
    if ($IPList.Count -eq 0) {
        return @()
    }
    
    $results = @()
    
    if ($isPSCore) {
        # PowerShell Core - use ForEach-Object -Parallel
        $results = $IPList | ForEach-Object -Parallel {
            try {
                # Detect if IPv6 address
                $isIPv6 = $_ -match ':'
                
                if ($isIPv6) {
                    # Use .NET Ping for IPv6 (Test-Connection has issues with IPv6)
                    $ping = New-Object System.Net.NetworkInformation.Ping
                    $pingReply = $ping.Send($_, $using:TimeoutMs)
                    if ($pingReply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                        [PSCustomObject]@{
                            IP = $_
                            Success = $true
                            ResponseTime = $pingReply.RoundtripTime
                            Status = "Success"
                        }
                    } else {
                        [PSCustomObject]@{
                            IP = $_
                            Success = $false
                            ResponseTime = 0
                            Status = $pingReply.Status.ToString()
                        }
                    }
                } else {
                    # IPv4 - use Test-Connection
                    $ping = Test-Connection -ComputerName $_ -Count 1 -TimeoutSeconds ($using:TimeoutMs / 1000) -ErrorAction SilentlyContinue
                    if ($ping) {
                        [PSCustomObject]@{
                            IP = $_
                            Success = $true
                            ResponseTime = $ping.ResponseTime
                            Status = "Success"
                        }
                    } else {
                        [PSCustomObject]@{
                            IP = $_
                            Success = $false
                            ResponseTime = 0
                            Status = "Timeout"
                        }
                    }
                }
            } catch {
                [PSCustomObject]@{
                    IP = $_
                    Success = $false
                    ResponseTime = 0
                    Status = "Error: $($_.Exception.Message)"
                }
            }
        } -ThrottleLimit $MaxConcurrent
    } else {
        # PowerShell 5.1 - use runspaces
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxConcurrent)
        $runspacePool.Open()
        
        $jobs = @()
        
        foreach ($ip in $IPList) {
            $scriptBlock = {
                param($IPAddress, $Timeout)
                try {
                    $ping = New-Object System.Net.NetworkInformation.Ping
                    $pingReply = $ping.Send($IPAddress, $Timeout)
                    if ($pingReply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                        [PSCustomObject]@{
                            IP = $IPAddress
                            Success = $true
                            ResponseTime = $pingReply.RoundtripTime
                            Status = "Success"
                        }
                    } else {
                        [PSCustomObject]@{
                            IP = $IPAddress
                            Success = $false
                            ResponseTime = 0
                            Status = "Timeout"
                        }
                    }
                } catch {
                    [PSCustomObject]@{
                        IP = $IPAddress
                        Success = $false
                        ResponseTime = 0
                        Status = "Error"
                    }
                }
            }
            
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool
            $powershell.AddScript($scriptBlock).AddArgument($ip).AddArgument($TimeoutMs) | Out-Null
            
            $jobs += [PSCustomObject]@{
                PowerShell = $powershell
                AsyncResult = $powershell.BeginInvoke()
                IP = $ip
            }
        }
        
        # Collect results
        foreach ($job in $jobs) {
            try {
                $result = $job.PowerShell.EndInvoke($job.AsyncResult)
                if ($result) {
                    $results += $result
                }
            } catch {
                $results += [PSCustomObject]@{
                    IP = $job.IP
                    Success = $false
                    ResponseTime = 0
                    Status = "Error"
                }
            } finally {
                $job.PowerShell.Dispose()
            }
        }
        
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
    
    return $results
}

# Batch parallel ping with intelligent jumping
function Invoke-BatchParallelPing {
    param(
        [uint32]$StartIP,
        [uint32]$EndIP,
        [int]$TimeoutMs = 1500,
        [int]$BatchSize = 256,
        [int]$JumpSize = 1024,
        [int]$DelayMs = 0,
        [string]$LocationData,
        [string]$OutputPath
    )
    
    $totalIPs = $EndIP - $StartIP + 1
    $currentPos = $StartIP
    $successfulIPs = @()
    $batchNumber = 0
    
    if ($DelayMs -gt 0) {
        Write-Host "  Starting parallel ping scan with $BatchSize IPs per batch (${DelayMs}ms delay between batches)" -ForegroundColor Yellow
    } else {
        Write-Host "  Starting parallel ping scan with $BatchSize IPs per batch" -ForegroundColor Yellow
    }
    
    while ($currentPos -le $EndIP) {
        # Check for skip key press
        if (Test-SkipKeyPressed) {
            Write-Host "    ⏭️  Skip key pressed - stopping parallel scan" -ForegroundColor Yellow
            break
        }
        
        $batchNumber++
        $batchEnd = [Math]::Min($currentPos + $BatchSize - 1, $EndIP)
        $batchIPs = @()
        
        # Build IP list for this batch
        for ($ipNum = $currentPos; $ipNum -le $batchEnd; $ipNum++) {
            $ipString = ConvertTo-IPString -IPInt $ipNum
            if ($ipString) {
                $batchIPs += $ipString
            }
        }
        
        if ($batchIPs.Count -eq 0) {
            $currentPos = $batchEnd + 1
            continue
        }
        
        Write-Host "  Batch $batchNumber`: Testing $($batchIPs.Count) IPs ($(ConvertTo-IPString -IPInt $currentPos) - $(ConvertTo-IPString -IPInt $batchEnd))" -ForegroundColor Cyan
        
        # Perform parallel ping on batch
        $results = Invoke-ParallelPing -IPList $batchIPs -TimeoutMs $TimeoutMs -MaxConcurrent 50
        
        # Check for skip key after batch completes
        if (Test-SkipKeyPressed) {
            Write-Host "    ⏭️  Skip key pressed - stopping parallel scan" -ForegroundColor Yellow
            break
        }
        
        # Process results
        $batchSuccessful = $results | Where-Object { $_.Success }
        
        if ($batchSuccessful.Count -gt 0) {
            Write-Host "    ✓ Found $($batchSuccessful.Count) responsive IPs in batch" -ForegroundColor Green
            
            # Save results to file and add to successful list
            foreach ($result in $batchSuccessful) {
                $successfulIPs += $result.IP
                
                # Output to CSV
                $outputResult = [PSCustomObject]@{
                    IP = $result.IP
                    Location = $LocationData
                    'Ping Time (ms)' = $result.ResponseTime
                }
                $outputResult | Export-Csv -Path $OutputPath -Append -NoTypeInformation
                
                Write-Host "    ✓ $($result.IP) - $($result.ResponseTime) ms" -ForegroundColor Green
            }
        } else {
            Write-Host "    ✗ No responsive IPs found in batch" -ForegroundColor Red
            
            # Check if we should jump ahead for large ranges
            $remainingIPs = $EndIP - $batchEnd
            if ($remainingIPs -gt ($JumpSize + $BatchSize) -and $totalIPs -gt ($JumpSize + $BatchSize)) {
                Write-Host "    🦘 Jumping $JumpSize IPs ahead due to no responses" -ForegroundColor Yellow
                $currentPos = $batchEnd + 1 + $JumpSize
                continue
            }
        }
        
        # Rate limiting: delay before next batch
        if ($DelayMs -gt 0 -and $currentPos -le $EndIP) {
            Start-Sleep -Milliseconds $DelayMs
        }
        
        # Move to next batch
        $currentPos = $batchEnd + 1
    }
    
    return $successfulIPs
}

# =====================================
# PORT SCANNING FUNCTIONS (NEW!)
# =====================================

# Test if a specific port is open on an IP address
function Test-Port {
    param(
        [string]$IP,
        [int]$Port,
        [int]$TimeoutMs = 3000
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectTask = $tcpClient.ConnectAsync($IP, $Port)
        
        # Wait for connection with timeout
        $result = $connectTask.Wait($TimeoutMs)
        
        if ($result -and $tcpClient.Connected) {
            $tcpClient.Close()
            return @{ Status = "Open"; Type = "Connected" }
        } else {
            $tcpClient.Close()
            # Check if it was a timeout or connection refused
            if ($connectTask.Exception -and $connectTask.Exception.InnerException -match "refused|reset") {
                return @{ Status = "Closed"; Type = "Refused" }
            } else {
                return @{ Status = "Closed"; Type = "Timeout" }
            }
        }
    } catch [System.Net.Sockets.SocketException] {
        # Handle specific socket exceptions
        if ($_.Exception.Message -match "refused|reset") {
            return @{ Status = "Closed"; Type = "Refused" }
        } else {
            return @{ Status = "Closed"; Type = "Timeout" }
        }
    } catch {
        return @{ Status = "Closed"; Type = "Timeout" }
    }
}

# Test multiple ports on an IP and return accessible ones
function Test-PortScan {
    param(
        [string]$IP,
        [string]$PortList,
        [int]$TimeoutMs = 3000
    )
    
    $openPorts = @()
    $refusedPorts = @()
    $timedOutPorts = @()
    $ports = $PortList -split ','
    
    foreach ($port in $ports) {
        $portNum = [int]$port.Trim()
        $portResult = Test-Port -IP $IP -Port $portNum -TimeoutMs $TimeoutMs
        
        if ($portResult.Status -eq "Open") {
            $openPorts += $portNum
        } elseif ($portResult.Type -eq "Refused") {
            $refusedPorts += $portNum
        } else {
            $timedOutPorts += $portNum
        }
    }
    
    return @{
        Open = $openPorts
        Refused = $refusedPorts
        Timeout = $timedOutPorts
    }
}

# Function to check network connectivity before scanning
function Test-NetworkConnectivity {
    param(
        [bool]$Interactive = $true
    )
    
    $connectivityReport = [PSCustomObject]@{
        IPv4Ready = $false
        IPv6Ready = $false
        IPv4Address = $null
        IPv6Address = $null
        IPv4Gateway = $null
        IPv6Gateway = $null
        CanScanIPv4 = $false
        CanScanIPv6 = $false
        Issues = @()
    }
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       NETWORK CONNECTIVITY PRE-FLIGHT CHECK                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Check IPv4 Configuration
    Write-Host "[1/6] Checking IPv4 Configuration..." -ForegroundColor Yellow
    $ipv4Adapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.IPAddress -notmatch "^127\." -and $_.PrefixOrigin -ne "WellKnown" 
    }
    
    if ($ipv4Adapters) {
        $ipv4Primary = $ipv4Adapters | Select-Object -First 1
        $connectivityReport.IPv4Address = $ipv4Primary.IPAddress
        Write-Host "  ✓ IPv4 Address Found: $($ipv4Primary.IPAddress)" -ForegroundColor Green
        
        # Get IPv4 Gateway
        $ipv4Route = Get-NetRoute -AddressFamily IPv4 -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($ipv4Route) {
            $connectivityReport.IPv4Gateway = $ipv4Route.NextHop
            Write-Host "  ✓ IPv4 Gateway: $($ipv4Route.NextHop)" -ForegroundColor Green
            
            # Test gateway ping
            Write-Host "  → Testing IPv4 gateway connectivity..." -ForegroundColor Gray
            $gwPing = Invoke-QuickPing -IP $ipv4Route.NextHop -TimeoutMs 2000
            if ($gwPing.Success) {
                Write-Host "  ✓ IPv4 Gateway Ping: Success ($($gwPing.ResponseTime)ms)" -ForegroundColor Green
                $connectivityReport.IPv4Ready = $true
            } else {
                Write-Host "  ✗ IPv4 Gateway Ping: Failed ($($gwPing.Status))" -ForegroundColor Red
                $connectivityReport.Issues += "IPv4 gateway not responding"
            }
        } else {
            Write-Host "  ✗ No IPv4 Gateway Found" -ForegroundColor Red
            $connectivityReport.Issues += "No IPv4 default gateway configured"
        }
    } else {
        Write-Host "  ✗ No IPv4 Address Assigned" -ForegroundColor Red
        $connectivityReport.Issues += "No IPv4 address assigned to network adapter"
    }
    
    # Check IPv6 Configuration
    Write-Host "`n[2/6] Checking IPv6 Configuration..." -ForegroundColor Yellow
    $ipv6Adapters = Get-NetIPAddress -AddressFamily IPv6 | Where-Object { 
        $_.IPAddress -notmatch "^fe80:" -and $_.PrefixOrigin -ne "WellKnown" 
    }
    
    if ($ipv6Adapters) {
        $ipv6Primary = $ipv6Adapters | Select-Object -First 1
        $connectivityReport.IPv6Address = $ipv6Primary.IPAddress
        Write-Host "  ✓ IPv6 Address Found: $($ipv6Primary.IPAddress)" -ForegroundColor Green
        
        # Get IPv6 Gateway
        $ipv6Route = Get-NetRoute -AddressFamily IPv6 -DestinationPrefix "::/0" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($ipv6Route) {
            $connectivityReport.IPv6Gateway = $ipv6Route.NextHop
            Write-Host "  ✓ IPv6 Gateway: $($ipv6Route.NextHop)" -ForegroundColor Green
            
            # Test gateway ping
            Write-Host "  → Testing IPv6 gateway connectivity..." -ForegroundColor Gray
            $gwPing = Invoke-QuickPing -IP $ipv6Route.NextHop -TimeoutMs 2000
            if ($gwPing.Success) {
                Write-Host "  ✓ IPv6 Gateway Ping: Success ($($gwPing.ResponseTime)ms)" -ForegroundColor Green
                $connectivityReport.IPv6Ready = $true
            } else {
                Write-Host "  ✗ IPv6 Gateway Ping: Failed ($($gwPing.Status))" -ForegroundColor Red
                $connectivityReport.Issues += "IPv6 gateway not responding"
            }
        } else {
            Write-Host "  ✗ No IPv6 Gateway Found" -ForegroundColor Red
            $connectivityReport.Issues += "No IPv6 default gateway configured"
        }
    } else {
        Write-Host "  ✗ No IPv6 Address Assigned (Link-local only)" -ForegroundColor Red
        $connectivityReport.Issues += "No global IPv6 address assigned to network adapter"
    }
    
    # Test DNS Resolution
    Write-Host "`n[3/6] Testing DNS Resolution..." -ForegroundColor Yellow
    $dnsServers = Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object -First 1
    
    if ($dnsServers) {
        Write-Host "  ✓ DNS Servers Configured: $($dnsServers.ServerAddresses -join ', ')" -ForegroundColor Green
        
        # Test DNS resolution
        try {
            $dnsTest = Resolve-DnsName -Name "one.one.one.one" -Type A -ErrorAction Stop
            Write-Host "  ✓ DNS Resolution: Working" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ DNS Resolution: Failed" -ForegroundColor Red
            $connectivityReport.Issues += "DNS resolution not working"
        }
    } else {
        Write-Host "  ✗ No DNS Servers Configured" -ForegroundColor Red
        $connectivityReport.Issues += "No DNS servers configured"
    }
    
    # Test External Connectivity (Cloudflare DNS)
    Write-Host "`n[4/6] Testing External Connectivity (1.1.1.1)..." -ForegroundColor Yellow
    
    $tracertRan = $false
    $cfPingFailed = $false
    if ($connectivityReport.IPv4Ready) {
        Write-Host "  → Pinging 1.1.1.1 (Cloudflare DNS)..." -ForegroundColor Gray
        $cfPing = Invoke-QuickPing -IP "1.1.1.1" -TimeoutMs 3000
        
        if ($cfPing.Success) {
            Write-Host "  ✓ IPv4 Internet Connectivity: Success ($($cfPing.ResponseTime)ms)" -ForegroundColor Green
            $connectivityReport.CanScanIPv4 = $true
        } else {
            Write-Host "  ✗ IPv4 Internet Connectivity: Failed ($($cfPing.Status))" -ForegroundColor Red
            $connectivityReport.Issues += "Cannot reach external IPv4 hosts (1.1.1.1 unreachable)"
            $connectivityReport.CanScanIPv4 = $false
            $cfPingFailed = $true
        }
        
        # Always offer traceroute (skippable)
        if ($Interactive) {
            Write-Host "`n  Would you like to run traceroute to 1.1.1.1? (Y/n) [Default: Y]" -ForegroundColor Cyan
            Write-Host "  Command: tracert -d -w 1500 1.1.1.1" -ForegroundColor Gray
            $response = Read-Host "  Your choice"
            if ([string]::IsNullOrWhiteSpace($response)) { $response = 'Y' }
            
            if ($response -eq 'Y' -or $response -eq 'y') {
                Write-Host "`n  Running traceroute... (Press Ctrl+C to cancel)`n" -ForegroundColor Cyan
                & tracert -d -w 1500 1.1.1.1 | Out-Host
                Write-Host ""
                $tracertRan = $true
            }
        }
    } else {
        Write-Host "  ⊗ Skipped (No IPv4 connectivity)" -ForegroundColor Gray
    }
    
    # Test IPv6 External Connectivity
    if ($connectivityReport.IPv6Ready) {
        Write-Host "  → Pinging 2606:4700:4700::1111 (Cloudflare DNS IPv6)..." -ForegroundColor Gray
        $cfPing6 = Invoke-QuickPing -IP "2606:4700:4700::1111" -TimeoutMs 3000
        
        if ($cfPing6.Success) {
            Write-Host "  ✓ IPv6 Internet Connectivity: Success ($($cfPing6.ResponseTime)ms)" -ForegroundColor Green
            $connectivityReport.CanScanIPv6 = $true
        } else {
            Write-Host "  ✗ IPv6 Internet Connectivity: Failed ($($cfPing6.Status))" -ForegroundColor Red
            $connectivityReport.Issues += "Cannot reach external IPv6 hosts"
        }
    } else {
        Write-Host "  ⊗ IPv6 External Test Skipped (No IPv6 connectivity)" -ForegroundColor Gray
    }
    
    # Test DCI DNS (217.218.155.155) - only if 1.1.1.1 failed
    Write-Host "`n[5/6] Testing DCI DNS Connectivity (217.218.155.155)..." -ForegroundColor Yellow
    
    if ($connectivityReport.IPv4Ready) {
        $dciPing = Invoke-QuickPing -IP "217.218.155.155" -TimeoutMs 3000
        
        if ($dciPing.Success) {
            Write-Host "  ✓ DCI DNS: Reachable ($($dciPing.ResponseTime)ms)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ DCI DNS: Unreachable ($($dciPing.Status))" -ForegroundColor Red
        }
        
        # Only offer DCI traceroute if 1.1.1.1 ping failed
        if ($Interactive -and $cfPingFailed) {
            Write-Host "`n  Would you like to run traceroute to DCI DNS? (Y/n) [Default: Y]" -ForegroundColor Cyan
            Write-Host "  Command: tracert -d -w 1500 217.218.155.155" -ForegroundColor Gray
            $response = Read-Host "  Your choice"
            if ([string]::IsNullOrWhiteSpace($response)) { $response = 'Y' }
            
            if ($response -eq 'Y' -or $response -eq 'y') {
                Write-Host "`n  Running traceroute... (Press Ctrl+C to cancel)`n" -ForegroundColor Cyan
                & tracert -d -w 1500 217.218.155.155 | Out-Host
                Write-Host ""
            }
        }
    } else {
        Write-Host "  ⊗ Skipped (No IPv4 connectivity)" -ForegroundColor Gray
    }
    
    # Summary
    Write-Host "`n[6/6] Connectivity Summary..." -ForegroundColor Yellow
    Write-Host "  ════════════════════════════════════════════════" -ForegroundColor Cyan
    
    if ($connectivityReport.CanScanIPv4) {
        Write-Host "  ✓ IPv4 Scanning: READY" -ForegroundColor Green
    } else {
        Write-Host "  ✗ IPv4 Scanning: NOT AVAILABLE" -ForegroundColor Red
    }
    
    if ($connectivityReport.CanScanIPv6) {
        Write-Host "  ✓ IPv6 Scanning: READY" -ForegroundColor Green
    } else {
        Write-Host "  ✗ IPv6 Scanning: NOT AVAILABLE" -ForegroundColor Red
    }
    
    if ($connectivityReport.Issues.Count -gt 0) {
        Write-Host "`n  ⚠️  Issues Detected:" -ForegroundColor Yellow
        foreach ($issue in $connectivityReport.Issues) {
            Write-Host "     • $issue" -ForegroundColor Yellow
        }
    }
    
    Write-Host "  ════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # Decision point
    if (-not $connectivityReport.CanScanIPv4 -and -not $connectivityReport.CanScanIPv6) {
        Write-Host "`n  ✗ CRITICAL: No network connectivity available for scanning!" -ForegroundColor Red
        
        if ($Interactive) {
            Write-Host "`n  Options:" -ForegroundColor Yellow
            Write-Host "    1. Fix network issues and restart script" -ForegroundColor Gray
            Write-Host "    2. Continue anyway (scanning will fail)" -ForegroundColor Gray
            Write-Host "    3. Exit script [Default]" -ForegroundColor Gray
            $choice = Read-Host "`n  Your choice (1/2/3)"
            if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '3' }
            
            if ($choice -eq '3') {
                Write-Host "`n  Exiting script..." -ForegroundColor Yellow
                exit 0
            } elseif ($choice -eq '1') {
                Write-Host "`n  Please fix network connectivity and restart the script." -ForegroundColor Yellow
                exit 0
            } else {
                Write-Host "`n  ⚠️  Continuing with limited connectivity..." -ForegroundColor Yellow
            }
        }
    } elseif (-not $connectivityReport.CanScanIPv4 -or -not $connectivityReport.CanScanIPv6) {
        Write-Host "`n  ⚠️  WARNING: Partial connectivity detected!" -ForegroundColor Yellow
        
        if (-not $connectivityReport.CanScanIPv4) {
            Write-Host "    → IPv4 scanning will be skipped or may fail" -ForegroundColor Yellow
        }
        if (-not $connectivityReport.CanScanIPv6) {
            Write-Host "    → IPv6 scanning will be skipped or may fail" -ForegroundColor Yellow
        }
        
        if ($Interactive) {
            Write-Host "`n  Continue with limited connectivity? (Y/n) [Default: Y]" -ForegroundColor Yellow
            $response = Read-Host "  Your choice"
            if ([string]::IsNullOrWhiteSpace($response)) { $response = 'Y' }
            
            if ($response -ne 'Y' -and $response -ne 'y') {
                Write-Host "`n  Exiting script..." -ForegroundColor Yellow
                exit 0
            }
        }
    } else {
        Write-Host "`n  ✓ Network connectivity check passed! Ready to scan." -ForegroundColor Green
    }
    
    Write-Host ""
    return $connectivityReport
}

# Helper function to perform quick ping test (works for both IPv4 and IPv6)
function Invoke-QuickPing {
    param(
        [string]$IP,
        [int]$TimeoutMs
    )
    
    try {
        $pingObj = New-Object System.Net.NetworkInformation.Ping
        $pingReply = $pingObj.Send($IP, $TimeoutMs)
        
        # Use proper enum comparison instead of string
        if ($pingReply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
            return [PSCustomObject]@{
                Success = $true
                ResponseTime = $pingReply.RoundtripTime
                Status = "Success"
            }
        } else {
            # Return actual status for troubleshooting
            return [PSCustomObject]@{
                Success = $false
                ResponseTime = 0
                Status = $pingReply.Status.ToString()
            }
        }
    } catch {
        # Return error message for debugging
        return [PSCustomObject]@{
            Success = $false
            ResponseTime = 0
            Status = "Error: $($_.Exception.Message)"
        }
    }
}

# Helper function to display scan result
function Write-ScanResult {
    param(
        [string]$IP,
        [bool]$IsSuccessful,
        [string]$ScanMode,
        [object]$ScanResult
    )
    
    if ($IsSuccessful) {
        if ($ScanMode -eq "ping") {
            Write-Host "  ✓ $IP - $($ScanResult.PingTime) ms" -ForegroundColor Green
        } elseif ($ScanMode -eq "port") {
            Write-Host "  ✓ $IP - Ports: $($ScanResult.PortsOpen)" -ForegroundColor Green
        } elseif ($ScanMode -eq "both") {
            Write-Host "  ✓ $IP - $($ScanResult.PingTime) ms, Ports: $($ScanResult.PortsOpen)" -ForegroundColor Green
        }
    } else {
        if ($ScanMode -eq "ping") {
            Write-Host "  ✗ $IP - No ping response" -ForegroundColor Red
        } elseif ($ScanMode -eq "port") {
            Write-Host "  ✗ $IP - No open ports" -ForegroundColor Red
        } elseif ($ScanMode -eq "both") {
            Write-Host "  ✗ $IP - No response" -ForegroundColor Red
        }
    }
}

# Helper function to save scan result to CSV
function Save-ScanResult {
    param(
        [string]$IP,
        [string]$ScanMode,
        [object]$ScanResult,
        [string]$OutputPath
    )
    
    $outputResult = $null
    
    if ($ScanMode -eq "ping") {
        $outputResult = [PSCustomObject]@{
            IP = $IP
            Location = $ScanResult.Location
            'Ping Time (ms)' = $ScanResult.PingTime
        }
    } elseif ($ScanMode -eq "port") {
        $outputResult = [PSCustomObject]@{
            IP = $IP
            Location = $ScanResult.Location
            'Ports Open' = $ScanResult.PortsOpen
            'Service Status' = $ScanResult.ServiceStatus
        }
    } elseif ($ScanMode -eq "both") {
        $outputResult = [PSCustomObject]@{
            IP = $IP
            Location = $ScanResult.Location
            'Ping Result' = $ScanResult.PingResult
            'Ping Time (ms)' = $ScanResult.PingTime
            'Ports Open' = $ScanResult.PortsOpen
            'Service Status' = $ScanResult.ServiceStatus
            'Network Status' = $ScanResult.NetworkStatus
        }
    }
    
    if ($outputResult) {
        $outputResult | Export-Csv -Path $OutputPath -Append -NoTypeInformation
    }
}

# Helper function to check if scan was successful
function Test-ScanSuccess {
    param(
        [string]$ScanMode,
        [object]$ScanResult
    )
    
    if ($ScanMode -eq "ping") {
        return ($ScanResult.PingResult -eq "Success")
    } elseif ($ScanMode -eq "port") {
        return ($ScanResult.PortsOpen -ne "None")
    } elseif ($ScanMode -eq "both") {
        return ($ScanResult.PingResult -eq "Success" -or $ScanResult.PortsOpen -ne "None")
    }
    
    return $false
}

# Unified scanning function for both IPv4 and IPv6 with jump logic
function Invoke-UnifiedScan {
    param(
        [object]$Range,
        [string]$ScanMode,
        [int]$Timeout,
        [string]$Ports,
        [int]$PortTimeout,
        [int]$MaxFailures,
        [int]$Jump,
        [int]$Skip,
        [int]$MaxResponses,
        [string]$LocationData,
        [string]$OutputPath,
        [string]$IPRange
    )
    
    $successful = @()
    $jumpCount = 0
    $maxResponsesReached = $false
    
    if ($Range.IPVersion -eq 4) {
        # IPv4 scanning
        $currentPosition = $Range.StartIP
        
        while ($currentPosition -le $Range.EndIP -and -not $maxResponsesReached) {
            if (Test-SkipKeyPressed) {
                Write-Host "  ⏭️  Skip key pressed - skipping remaining IPs in range $IPRange" -ForegroundColor Yellow
                break
            }
            
            $checkLimit = [Math]::Min($currentPosition + $MaxFailures - 1, $Range.EndIP)
            $timeoutCount = 0
            
            for ($ipNum = $currentPosition; $ipNum -le $checkLimit; $ipNum++) {
                $currentIP = ConvertTo-IPString -IPInt $ipNum
                if ($null -eq $currentIP) { continue }
                
                Write-Host "  Scanning: $currentIP" -ForegroundColor Cyan
                
                $scanResult = Invoke-NetworkScan -IP $currentIP -ScanMode $ScanMode -PingTimeoutMs $Timeout -PortList $Ports -PortTimeoutMs $PortTimeout -LocationData $LocationData
                $isSuccessful = Test-ScanSuccess -ScanMode $ScanMode -ScanResult $scanResult
                
                if (-not $isSuccessful) {
                    $timeoutCount++
                    Write-ScanResult -IP $currentIP -IsSuccessful $false -ScanMode $ScanMode -ScanResult $scanResult
                } else {
                    Write-ScanResult -IP $currentIP -IsSuccessful $true -ScanMode $ScanMode -ScanResult $scanResult
                    $successful += $currentIP
                    Save-ScanResult -IP $currentIP -ScanMode $ScanMode -ScanResult $scanResult -OutputPath $OutputPath
                    
                    if ($MaxResponses -gt 0 -and $successful.Count -ge $MaxResponses) {
                        Write-Host "  Reached maximum responses ($MaxResponses) for range $IPRange - skipping remaining IPs" -ForegroundColor Yellow
                        $maxResponsesReached = $true
                        break
                    }
                }
            }
            
            if ($timeoutCount -ge $MaxFailures) {
                if ($Jump -gt 0) {
                    $jumpCount++
                    if ($jumpCount -ge $Skip) {
                        Write-Host "  Reached jump limit ($Skip jumps) - skipping remaining IPs in range $IPRange" -ForegroundColor Red
                        break
                    }
                    Write-Host "  Jumping $Jump IPs due to $timeoutCount/$MaxFailures consecutive timeouts (jump #$jumpCount)" -ForegroundColor Yellow
                    $currentPosition = $checkLimit + 1 + $Jump
                } else {
                    Write-Host "  Skipping remaining IPs in range $IPRange due to $timeoutCount/$MaxFailures consecutive timeouts" -ForegroundColor Red
                    break
                }
            } else {
                $currentPosition = $checkLimit + 1
            }
        }
    } else {
        # IPv6 scanning
        $currentPosition = $Range.StartIP
        $maxIPv6Scan = 65536
        $count = 0
        $consecutiveFailures = 0
        
        while ((Compare-IPv6Address -Address1 $currentPosition -Address2 $Range.EndIP) -le 0 -and $count -lt $maxIPv6Scan -and -not $maxResponsesReached) {
            if (Test-SkipKeyPressed) {
                Write-Host "  ⏭️  Skip key pressed - skipping remaining IPs in IPv6 range $IPRange" -ForegroundColor Yellow
                break
            }
            
            $currentIPStr = ConvertTo-IPString -IPBytes $currentPosition
            if ($null -eq $currentIPStr) {
                $currentPosition = Add-IPv6Address -IPBytes $currentPosition -Increment 1
                $count++
                continue
            }
            
            Write-Host "  Scanning: $currentIPStr" -ForegroundColor Cyan
            
            $scanResult = Invoke-NetworkScan -IP $currentIPStr -ScanMode $ScanMode -PingTimeoutMs $Timeout -PortList $Ports -PortTimeoutMs $PortTimeout -LocationData $LocationData
            $isSuccessful = Test-ScanSuccess -ScanMode $ScanMode -ScanResult $scanResult
            
            if ($isSuccessful) {
                $consecutiveFailures = 0
                Write-ScanResult -IP $currentIPStr -IsSuccessful $true -ScanMode $ScanMode -ScanResult $scanResult
                $successful += $currentIPStr
                Save-ScanResult -IP $currentIPStr -ScanMode $ScanMode -ScanResult $scanResult -OutputPath $OutputPath
                
                if ($MaxResponses -gt 0 -and $successful.Count -ge $MaxResponses) {
                    Write-Host "  Reached maximum responses ($MaxResponses) for range $IPRange - skipping remaining IPs" -ForegroundColor Yellow
                    $maxResponsesReached = $true
                    break
                }
            } else {
                $consecutiveFailures++
                Write-ScanResult -IP $currentIPStr -IsSuccessful $false -ScanMode $ScanMode -ScanResult $scanResult
                
                if ($consecutiveFailures -ge $MaxFailures) {
                    if ($Jump -gt 0) {
                        $jumpCount++
                        if ($jumpCount -ge $Skip) {
                            Write-Host "  Reached jump limit ($Skip jumps) - skipping remaining IPs in range $IPRange" -ForegroundColor Red
                            break
                        }
                        Write-Host "  Jumping $Jump IPs due to $consecutiveFailures/$MaxFailures consecutive failures (jump #$jumpCount)" -ForegroundColor Yellow
                        $currentPosition = Add-IPv6Address -IPBytes $currentPosition -Increment $Jump
                        $count += $Jump
                        $consecutiveFailures = 0
                        continue
                    } else {
                        Write-Host "  Skipping remaining IPs in range $IPRange due to $consecutiveFailures/$MaxFailures consecutive failures" -ForegroundColor Red
                        break
                    }
                }
            }
            
            $currentPosition = Add-IPv6Address -IPBytes $currentPosition -Increment 1
            $count++
        }
    }
    
    return $successful
}

# Perform network scan based on mode
function Invoke-NetworkScan {
    param(
        [string]$IP,
        [string]$ScanMode,
        [int]$PingTimeoutMs,
        [string]$PortList,
        [int]$PortTimeoutMs,
        [string]$LocationData,
        [bool]$SkipPing = $false  # New parameter to skip ping if already done
    )
    
    $result = [PSCustomObject]@{
        IP = $IP
        Location = $LocationData
        PingResult = "Not Tested"
        PingTime = "N/A"
        PortsOpen = "Not Tested"
        ServiceStatus = "Unknown"
        NetworkStatus = "Normal"
    }
    
    $pingSuccessful = $false
    $portsOpen = @()
    
    # Perform ping test if required and not skipped
    if (($ScanMode -eq "ping" -or $ScanMode -eq "both") -and -not $SkipPing) {
        $isIPv6 = $IP -match ':'
        
        if ($isPSCore -and -not $isIPv6) {
            # PowerShell Core with IPv4
            $ping = Test-Connection -ComputerName $IP -Count 1 -TimeoutSeconds ($PingTimeoutMs / 1000) -ErrorAction SilentlyContinue
        } else {
            # PowerShell 5.1 or IPv6 - use .NET Ping
            try {
                $pingObj = New-Object System.Net.NetworkInformation.Ping
                $pingReply = $pingObj.Send($IP, $PingTimeoutMs)
                if ($pingReply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                    $ping = [PSCustomObject]@{
                        ResponseTime = $pingReply.RoundtripTime
                        Status = "Success"
                    }
                } else {
                    $ping = $null
                }
            } catch {
                $ping = $null
            }
        }
        
        if ($ping) {
            $pingSuccessful = $true
            $result.PingResult = "Success"
            $result.PingTime = $ping.ResponseTime
        } else {
            $result.PingResult = "Failed"
            $result.PingTime = "Timeout"
        }
    } elseif ($SkipPing) {
        # If ping was skipped, assume it failed (for both mode optimization)
        $result.PingResult = "Failed"
        $result.PingTime = "Timeout"
    }
    
    # For "both" mode: only port scan if ping failed (optimization)
    $shouldPortScan = $false
    if ($ScanMode -eq "port") {
        $shouldPortScan = $true
    } elseif ($ScanMode -eq "both") {
        # Only port scan if ping failed or was skipped
        $shouldPortScan = -not $pingSuccessful
    }
    
    # Perform port test if required
    if ($shouldPortScan) {
        $portScanResult = Test-PortScan -IP $IP -PortList $PortList -TimeoutMs $PortTimeoutMs
        $portsOpen = $portScanResult.Open
        $portsRefused = $portScanResult.Refused
        $portsTimeout = $portScanResult.Timeout
        
        if ($portsOpen.Count -gt 0) {
            $result.PortsOpen = ($portsOpen -join ',')
            $result.ServiceStatus = "Accessible"
        } else {
            $result.PortsOpen = "None"
            # Distinguish between refused (active host) and timeout (likely unassigned)
            if ($portsRefused.Count -gt 0) {
                $result.ServiceStatus = "Refused"
            } else {
                $result.ServiceStatus = "Unavailable"
            }
        }
    }
    
    # Detect network accessibility patterns (improved logic for unassigned IPs)
    if ($ScanMode -eq "both") {
        if ($pingSuccessful -and $portsOpen.Count -eq 0) {
            # Ping works - host is discovered, no need to port scan
            $result.NetworkStatus = "Normal"
            $result.ServiceStatus = "Ping-Responsive"
        } elseif (-not $pingSuccessful -and $portsOpen.Count -gt 0) {
            # Services work but ping doesn't - ICMP may be blocked
            $result.NetworkStatus = "ICMP-Blocked"
            $result.ServiceStatus = "Services-Only"
        } elseif (-not $pingSuccessful -and $portsOpen.Count -eq 0) {
            # Neither ping nor services work
            if ($portsRefused.Count -gt 0) {
                # Services actively refused but ping blocked - ICMP may be blocked
                $result.NetworkStatus = "ICMP-Blocked"
                $result.ServiceStatus = "Services-Refused"
            } elseif ($portsTimeout.Count -gt 0) {
                # All services timed out and ping failed - likely unassigned IP range
                $result.NetworkStatus = "Unassigned-Range"
                $result.ServiceStatus = "No-Response"
            } else {
                # No ports tested
                $result.NetworkStatus = "Unassigned-Range"
                $result.ServiceStatus = "No-Response"
            }
        } else {
            # Both ping and services work - normal operation
            $result.NetworkStatus = "Normal"
        }
    }
    
    return $result
}

# Get service name for common ports
function Get-ServiceName {
    param([int]$Port)
    
    $services = @{
        22 = "SSH"
        53 = "DNS"
        80 = "HTTP"
        443 = "HTTPS"
        993 = "IMAPS"
        995 = "POP3S"
        8080 = "HTTP-Alt"
        8443 = "HTTPS-Alt"
        9443 = "HTTPS-Alt2"
    }
    
    if ($services.ContainsKey($Port)) {
        return $services[$Port]
    } else {
        return "Port-$Port"
    }
}

# Check if input file exists
Write-Host "`nLooking for input file at: $inputPath" -ForegroundColor Cyan

if (-not (Test-Path -Path $inputPath)) {
    Write-Error "Input file not found at: $inputPath"
    exit 1
}

# Run network connectivity pre-flight check
$networkStatus = Test-NetworkConnectivity -Interactive $true

Write-Host "`n🚀 Starting operations..." -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Input file: $InputFile" -ForegroundColor Yellow
Write-Host "Output file: $OutputFile" -ForegroundColor Yellow
Write-Host "Scan mode: $ScanMode" -ForegroundColor Yellow   
if ($ScanMode -eq "ping" -or $ScanMode -eq "both") {
        Write-Host "Ping timeout: ${Timeout}ms" -ForegroundColor Yellow
}
if ($ScanMode -eq "port" -or $ScanMode -eq "both") {
    Write-Host "Port timeout: ${PortTimeout}ms" -ForegroundColor Yellow
    Write-Host "Ports to scan: $Ports" -ForegroundColor Yellow
}
Write-Host "Max consecutive failures: $MaxFailures" -ForegroundColor Yellow
if ($Jump -gt 0) {
    Write-Host "Jump mode: Skip $Jump IPs after failures (skip range after $Skip jumps)" -ForegroundColor Yellow
} else {
    Write-Host "Jump mode: Disabled" -ForegroundColor Yellow
}
Write-Host "Network Status: IPv4=$($networkStatus.CanScanIPv4) | IPv6=$($networkStatus.CanScanIPv6)" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "💡 Tip: Press 'S' at any time during scanning to skip the current range" -ForegroundColor Cyan
Write-Host ""

# Initialize output CSV with appropriate headers based on scan mode
if ($ScanMode -eq "ping" -or $ScanMode -eq "parallel") {
    "IP,Location,Ping Time (ms)" | Out-File -FilePath $outputPath -Encoding utf8
} elseif ($ScanMode -eq "port") {
    "IP,Location,Ports Open,Service Status" | Out-File -FilePath $outputPath -Encoding utf8
} else {
    # both mode - include all columns
    "IP,Location,Ping Result,Ping Time (ms),Ports Open,Service Status,Network Status" | Out-File -FilePath $outputPath -Encoding utf8
}

# Process the input file
Write-Host "Starting to read input file..."

$ipRanges = Import-Csv -Path $inputPath -Header IP,Location,Region,City,PostalCode

foreach ($entry in $ipRanges) {
    $ipRange = $entry.IP
    
    # Skip empty lines and comment lines (starting with #)
    if ([string]::IsNullOrWhiteSpace($ipRange) -or $ipRange.StartsWith('#')) {
        continue
    }
    
    Write-Host "Processing IP Range: $ipRange" -ForegroundColor Cyan
    Write-Host "  💡 Press 'S' key anytime to skip this range" -ForegroundColor Gray
    
    # Parse CIDR notation and detect IP version
    if ($ipRange -match "/") {
        $baseIP = $ipRange.Split("/")[0]
        $subnet = [int]$ipRange.Split("/")[1]
        $cidrRange = $ipRange
    } else {
        # No subnet mask found, assume single IP
        $baseIP = $ipRange
        $ipVersion = Get-IPVersion -IPAddress $baseIP
        if ($ipVersion -eq 4) {
            $subnet = 32
            $cidrRange = "$ipRange/32"
            Write-Host "Note: Single IPv4 address detected - using /32 subnet"
        } elseif ($ipVersion -eq 6) {
            $subnet = 128
            $cidrRange = "$ipRange/128"
            Write-Host "Note: Single IPv6 address detected - using /128 subnet"
        } else {
            Write-Host "[ERROR] Invalid IP address format: $baseIP"
            continue
        }
    }
    
    # Validate IP address format
    try {
        $null = [System.Net.IPAddress]::Parse($baseIP)
    } catch {
        Write-Host "[ERROR] Invalid IP address format: $baseIP"
        continue
    }
    
    # Calculate the IP range
    $range = Get-IPRange -BaseIP $baseIP -CIDRSuffix $subnet
    if ($null -eq $range) {
        Write-Host "[ERROR] Failed to calculate range for: $ipRange"
        continue
    }
    
    # Check if we can scan this IP protocol
    if ($range.IPVersion -eq 4 -and -not $networkStatus.CanScanIPv4) {
        Write-Host "[SKIPPED] IPv4 range detected but IPv4 connectivity is not available" -ForegroundColor Yellow
        Write-Host "          Range: $ipRange" -ForegroundColor Yellow
        Write-Host "          Reason: $($networkStatus.Issues | Where-Object { $_ -like '*IPv4*' } | Select-Object -First 1)" -ForegroundColor Yellow
        Write-Host ""
        continue
    }
    
    if ($range.IPVersion -eq 6 -and -not $networkStatus.CanScanIPv6) {
        Write-Host "[SKIPPED] IPv6 range detected but IPv6 connectivity is not available" -ForegroundColor Yellow
        Write-Host "          Range: $ipRange" -ForegroundColor Yellow
        Write-Host "          Reason: $($networkStatus.Issues | Where-Object { $_ -like '*IPv6*' } | Select-Object -First 1)" -ForegroundColor Yellow
        Write-Host ""
        continue
    }
    
    # Initialize counters for this range
    $successful = @()
    $jumpCount = 0
    $maxResponsesReached = $false
    
    # Handle IPv6 range limiting
    if ($range.IPVersion -eq 6) {
        $totalIPs = $range.TotalIPs
        
        # IPv6 ranges can be HUGE - implement intelligent limiting
        $maxIPv6Scan = 65536  # Maximum IPs to scan in IPv6 range (configurable)
        
        if ($range.HostBits -gt 16) {
            Write-Host "[WARNING] IPv6 range /$subnet is very large (2^$($range.HostBits) addresses)" -ForegroundColor Yellow
            Write-Host "          Limiting scan to first $maxIPv6Scan addresses for safety" -ForegroundColor Yellow
            $scanLimited = $true
        } else {
            $scanLimited = $false
        }
        
        $currentPosition = $range.StartIP
        $startIPStr = ConvertTo-IPString -IPBytes $range.StartIP
        $endIPStr = ConvertTo-IPString -IPBytes $range.EndIP
        
        if ($scanLimited) {
            Write-Host "  IPv6 Range: $startIPStr to $endIPStr (scanning first $maxIPv6Scan)" -ForegroundColor Yellow
        } else {
            Write-Host "  IPv6 Range: $startIPStr to $endIPStr ($totalIPs addresses)" -ForegroundColor Yellow
        }
    } else {
        # IPv4
        $totalIPs = $range.TotalIPs
        $currentPosition = $range.StartIP
        Write-Host "  Range contains $totalIPs IPs (from $(ConvertTo-IPString -IPInt $range.StartIP) to $(ConvertTo-IPString -IPInt $range.EndIP))" -ForegroundColor Yellow
    }
    if ($Jump -gt 0) {
        Write-Host "  Jump mode enabled: will skip $Jump IPs after $MaxFailures failures (skip range after $Skip jumps)" -ForegroundColor Yellow
    }
    if ($MaxResponses -gt 0) {
        Write-Host "  Response limit enabled: will skip range after $MaxResponses successful responses" -ForegroundColor Yellow
    }    Write-Host "  Testing first $MaxFailures IPs for connectivity..." -ForegroundColor Yellow
      # Handle parallel ping mode separately
    if ($ScanMode -eq "parallel") {
        Write-Host "  Using parallel ping mode with batch processing" -ForegroundColor Yellow
        
        if ($range.IPVersion -eq 4) {
            $successful = Invoke-BatchParallelPing -StartIP $range.StartIP -EndIP $range.EndIP -TimeoutMs $Timeout -BatchSize 256 -JumpSize 1024 -DelayMs $DelayMs -LocationData "$($entry.Location),$($entry.Region),$($entry.City),$($entry.PostalCode)" -OutputPath $outputPath
        } else {
            # IPv6 parallel mode - create IP list from range
            Write-Host "  Building IPv6 address list for parallel scanning..." -ForegroundColor Yellow
            $ipList = @()
            $currentIP = $range.StartIP
            $maxIPv6Scan = 65536
            $count = 0
            
            while ((Compare-IPv6Address -Address1 $currentIP -Address2 $range.EndIP) -le 0 -and $count -lt $maxIPv6Scan) {
                # Check for skip key press
                if (Test-SkipKeyPressed) {
                    Write-Host "  ⏭️  Skip key pressed - stopping IPv6 address list build" -ForegroundColor Yellow
                    break
                }
                
                $ipStr = ConvertTo-IPString -IPBytes $currentIP
                $ipList += $ipStr
                $currentIP = Add-IPv6Address -IPBytes $currentIP -Increment 1
                $count++
            }
            
            Write-Host "  Testing $($ipList.Count) IPv6 addresses in parallel..." -ForegroundColor Yellow
            $results = Invoke-ParallelPing -IPList $ipList -TimeoutMs $Timeout -MaxConcurrent 50
            
            $successfulResults = $results | Where-Object { $_.Success }
            foreach ($result in $successfulResults) {
                $successful += $result.IP
                $outputResult = [PSCustomObject]@{
                    IP = $result.IP
                    Location = "$($entry.Location),$($entry.Region),$($entry.City),$($entry.PostalCode)"
                    'Ping Time (ms)' = $result.ResponseTime
                }
                $outputResult | Export-Csv -Path $outputPath -Append -NoTypeInformation
                Write-Host "  ✓ $($result.IP) - $($result.ResponseTime) ms" -ForegroundColor Green
            }
        }
    } else {
        # Traditional scanning modes: ping, port, both
        # For "both" mode: First do a quick ping sweep, then port scan non-responders
        $pingResponders = @()
        $nonResponders = @()
        
        if ($ScanMode -eq "both") {
            Write-Host "  Phase 1: Quick ping sweep to identify responsive hosts" -ForegroundColor Yellow
            
            if ($range.IPVersion -eq 4) {
                # IPv4 quick ping sweep
                for ($ipNum = $range.StartIP; $ipNum -le $range.EndIP; $ipNum++) {
                    # Check for skip key press
                    if (Test-SkipKeyPressed) {
                        Write-Host "  ⏭️  Skip key pressed - stopping ping sweep for current range" -ForegroundColor Yellow
                        break
                    }
                    
                    if ($MaxResponses -gt 0 -and $successful.Count -ge $MaxResponses) {
                        Write-Host "  Reached maximum responses ($MaxResponses) - stopping ping sweep" -ForegroundColor Yellow
                        break
                    }
                    
                    $currentIP = ConvertTo-IPString -IPInt $ipNum
                    if ($null -eq $currentIP) { continue }
                    
                    # Quick ping test (IPv4)
                    $pingResult = $null
                    try {
                        $pingObj = New-Object System.Net.NetworkInformation.Ping
                        $pingReply = $pingObj.Send($currentIP, $Timeout)
                        if ($pingReply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                            $pingResult = [PSCustomObject]@{
                                ResponseTime = $pingReply.RoundtripTime
                                Status = "Success"
                            }
                        }
                    } catch {
                        $pingResult = $null
                    }
                    
                    if ($pingResult) {
                        $pingResponders += $currentIP
                        $successful += $currentIP
                        
                        # Save ping responder to output
                        $outputResult = [PSCustomObject]@{
                            IP = $currentIP
                            Location = "$($entry.Location),$($entry.Region),$($entry.City),$($entry.PostalCode)"
                            'Ping Result' = "Success"
                            'Ping Time (ms)' = $pingResult.ResponseTime
                            'Ports Open' = "N/A"
                            'Service Status' = "Ping-Responsive"
                            'Network Status' = "Normal"
                        }
                        $outputResult | Export-Csv -Path $outputPath -Append -NoTypeInformation
                        Write-Host "  ✓ $currentIP - $($pingResult.ResponseTime) ms (ping responsive)" -ForegroundColor Green
                    } else {
                        $nonResponders += $currentIP
                    }
                }
            } else {
                # IPv6 quick ping sweep
                $currentIP = $range.StartIP
                $maxIPv6Scan = 65536
                $count = 0
                
                while ((Compare-IPv6Address -Address1 $currentIP -Address2 $range.EndIP) -le 0 -and $count -lt $maxIPv6Scan) {
                    # Check for skip key press
                    if (Test-SkipKeyPressed) {
                        Write-Host "  ⏭️  Skip key pressed - stopping IPv6 ping sweep for current range" -ForegroundColor Yellow
                        break
                    }
                    
                    if ($MaxResponses -gt 0 -and $successful.Count -ge $MaxResponses) {
                        Write-Host "  Reached maximum responses ($MaxResponses) - stopping ping sweep" -ForegroundColor Yellow
                        break
                    }
                    
                    $currentIPStr = ConvertTo-IPString -IPBytes $currentIP
                    if ($null -eq $currentIPStr) { 
                        $currentIP = Add-IPv6Address -IPBytes $currentIP -Increment 1
                        $count++
                        continue 
                    }
                    
                    # Quick ping test for IPv6
                    $pingResult = $null
                    try {
                        $pingObj = New-Object System.Net.NetworkInformation.Ping
                        $pingReply = $pingObj.Send($currentIPStr, $Timeout)
                        if ($pingReply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                            $pingResult = [PSCustomObject]@{
                                ResponseTime = $pingReply.RoundtripTime
                                Status = "Success"
                            }
                        }
                    } catch {
                        $pingResult = $null
                    }
                    
                    if ($pingResult) {
                        $pingResponders += $currentIPStr
                        $successful += $currentIPStr
                        
                        # Save ping responder to output
                        $outputResult = [PSCustomObject]@{
                            IP = $currentIPStr
                            Location = "$($entry.Location),$($entry.Region),$($entry.City),$($entry.PostalCode)"
                            'Ping Result' = "Success"
                            'Ping Time (ms)' = $pingResult.ResponseTime
                            'Ports Open' = "N/A"
                            'Service Status' = "Ping-Responsive"
                            'Network Status' = "Normal"
                        }
                        $outputResult | Export-Csv -Path $outputPath -Append -NoTypeInformation
                        Write-Host "  ✓ $currentIPStr - $($pingResult.ResponseTime) ms (ping responsive)" -ForegroundColor Green
                    } else {
                        $nonResponders += $currentIPStr
                    }
                    
                    $currentIP = Add-IPv6Address -IPBytes $currentIP -Increment 1
                    $count++
                }
            }
            
            Write-Host "  Phase 1 complete: $($pingResponders.Count) ping responders, $($nonResponders.Count) non-responders" -ForegroundColor Cyan
            
            if ($nonResponders.Count -gt 0) {
                Write-Host "  Phase 2: Port scanning non-responders for service detection" -ForegroundColor Yellow
                
                # Port scan non-responders
                foreach ($ip in $nonResponders) {
                    # Check for skip key press
                    if (Test-SkipKeyPressed) {
                        Write-Host "  ⏭️  Skip key pressed - stopping port scan for current range" -ForegroundColor Yellow
                        break
                    }
                    
                    if ($MaxResponses -gt 0 -and $successful.Count -ge $MaxResponses) {
                        Write-Host "  Reached maximum responses ($MaxResponses) - stopping port scan" -ForegroundColor Yellow
                        break
                    }
                    
                    $scanResult = Invoke-NetworkScan -IP $ip -ScanMode $ScanMode -PingTimeoutMs $Timeout -PortList $Ports -PortTimeoutMs $PortTimeout -LocationData "$($entry.Location),$($entry.Region),$($entry.City),$($entry.PostalCode)" -SkipPing $true
                    
                    # Check if port scan found anything
                    if ($scanResult.PortsOpen -ne "None" -and $scanResult.PortsOpen -ne "Not Tested") {
                        $successful += $ip
                        
                        $outputResult = [PSCustomObject]@{
                            IP = $ip
                            Location = $scanResult.Location
                            'Ping Result' = $scanResult.PingResult
                            'Ping Time (ms)' = $scanResult.PingTime
                            'Ports Open' = $scanResult.PortsOpen
                            'Service Status' = $scanResult.ServiceStatus
                            'Network Status' = $scanResult.NetworkStatus
                        }
                        $outputResult | Export-Csv -Path $outputPath -Append -NoTypeInformation
                        Write-Host "  ✓ $ip - Ports: $($scanResult.PortsOpen) [STATUS: $($scanResult.NetworkStatus)]" -ForegroundColor Green
                    }
                }
            }
        } else {
            # Traditional scanning loop for ping and port modes
            # Use unified scanning function for both IPv4 and IPv6
            $successful = Invoke-UnifiedScan `
                -Range $range `
                -ScanMode $ScanMode `
                -Timeout $Timeout `
                -Ports $Ports `
                -PortTimeout $PortTimeout `
                -MaxFailures $MaxFailures `
                -Jump $Jump `
                -Skip $Skip `
                -MaxResponses $MaxResponses `
                -LocationData "$($entry.Location),$($entry.Region),$($entry.City),$($entry.PostalCode)" `
                -OutputPath $outputPath `
                -IPRange $ipRange
        }
    }
    
    # Display summary of reachable IPs
    if ($successful.Count -gt 0) {
        if ($range.IPVersion -eq 6 -and $range.HostBits -gt 16) {
            Write-Host "✓ Range ${cidrRange}: $($successful.Count) IPs reachable (limited scan)" -ForegroundColor Green
        } else {
            Write-Host "✓ Range ${cidrRange}: $($successful.Count)/$totalIPs IPs reachable" -ForegroundColor Green
        }
        if ($jumpCount -gt 0) {
            Write-Host "  └─ Used $jumpCount jump(s) during scan" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "✗ Range ${cidrRange}: No reachable IPs found" -ForegroundColor Red
        if ($jumpCount -gt 0) {
            Write-Host "  └─ Used $jumpCount jump(s) during scan" -ForegroundColor Cyan
        }
    }
}

Write-Host "Script completed. Results saved to '$outputPath'." -ForegroundColor Green
Write-Host ""

# Only wait for input in interactive mode
if ($InteractiveMode) {
    Write-Host "Press Enter to exit..." -ForegroundColor Yellow
    Read-Host | Out-Null
}