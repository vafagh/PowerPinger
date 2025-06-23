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
    [int]$Skip = 3, # Number of jumps before skipping entire range (only applies if Jump > 0)    [Parameter()]
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
    Write-Host "   • Port scanning: Test service accessibility" -ForegroundColor White
    Write-Host "   • Network accessibility detection: Identify access patterns" -ForegroundColor White
    Write-Host "   • Multiple scan modes: ping/port/both" -ForegroundColor White
    Write-Host "   • PowerShell 5.1 & 6+ compatibility" -ForegroundColor White
    Write-Host "   • IPv6 range detection (auto-skip)" -ForegroundColor White
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
        Write-Host "❌ ERROR: No CSV or TXT files found in the script directory!" -ForegroundColor Red
        Write-Host "📁 Please place your IP range file in: $scriptDirectory" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "📋 Expected file format:" -ForegroundColor Cyan
        Write-Host "   Line 1: 192.168.1.0/24,US,CA,City,12345" -ForegroundColor White
        Write-Host "   Line 2: 8.8.8.8,US,CA,Google,12345" -ForegroundColor White
        Write-Host "   Line 3: 10.0.0.0/16,US,NY,Private,00000" -ForegroundColor White
        exit 1
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
        Show-FileMenu -Files $allFiles -Title "📂 Available IP Range Files"
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

# Helper function to convert CIDR notation to IP range
function Get-IPRange {
    param (
        [string]$BaseIP,
        [int]$CIDRSuffix
    )
    
    try {
        # Convert IP to its numeric representation
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
        
        # Return start and end IPs
        return @{
            StartIP = $startIP
            EndIP = $endIP
        }
    } catch {
        Write-Error "Error calculating IP range for $BaseIP/$CIDRSuffix : $_"
        return $null
    }
}

# Helper function to convert numeric IP to string format
function ConvertTo-IPString {
    param (
        [uint32]$IPInt
    )
    
    try {
        $bytes = [BitConverter]::GetBytes($IPInt)
        if ([BitConverter]::IsLittleEndian) {
            [Array]::Reverse($bytes)
        }
        return [System.Net.IPAddress]::new($bytes).ToString()
    } catch {
        Write-Error "Error converting numeric IP $IPInt to string: $_"
        return $null
    }
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
            } catch {
                [PSCustomObject]@{
                    IP = $_
                    Success = $false
                    ResponseTime = 0
                    Status = "Error"
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
                    if ($pingReply.Status -eq "Success") {
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
        [string]$LocationData,
        [string]$OutputPath
    )
    
    $totalIPs = $EndIP - $StartIP + 1
    $currentPos = $StartIP
    $successfulIPs = @()
    $batchNumber = 0
    
    Write-Host "  Starting parallel ping scan with $BatchSize IPs per batch" -ForegroundColor Yellow
    
    while ($currentPos -le $EndIP) {
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
        if ($isPSCore) {
            $ping = Test-Connection -ComputerName $IP -Count 1 -TimeoutSeconds ($PingTimeoutMs / 1000) -ErrorAction SilentlyContinue
        } else {
            try {
                $pingObj = New-Object System.Net.NetworkInformation.Ping
                $pingReply = $pingObj.Send($IP, $PingTimeoutMs)
                if ($pingReply.Status -eq "Success") {
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

Write-Host "`n🚀 Starting operations..." -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Input file: $InputFile" -ForegroundColor Yellow
Write-Host "Output file: $OutputFile" -ForegroundColor Yellow
Write-Host "Scan mode: $ScanMode" -ForegroundColor Yellow    if ($ScanMode -eq "ping" -or $ScanMode -eq "both") {
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
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
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
    
    # Check for IPv6 (basic check)
    if ($ipRange -match ":" -or $ipRange -match "^2[0-9a-f]{3}:") {
        Write-Host "Skipping IPv6 range: $ipRange"
        continue
    }
    
    Write-Host "Processing IP Range: $ipRange"
    
    # Parse CIDR notation
    if ($ipRange -match "/") {
        $baseIP = $ipRange.Split("/")[0]
        $subnet = [int]$ipRange.Split("/")[1]
        $cidrRange = $ipRange
    } else {
        # No subnet mask found, assume it's a single IP (subnet /32)
        $baseIP = $ipRange
        $subnet = 32
        $cidrRange = "$ipRange/32"
        Write-Host "Note: Single IP detected - using /32 subnet"
    }
    
    # Validate IP address format
    try {
        $null = [System.Net.IPAddress]::Parse($baseIP)
    } catch {
        Write-Host "[ERROR] Invalid IPv4 format: $baseIP - Must be in format xxx.xxx.xxx.xxx"
        continue
    }
    
    # Calculate the IP range
    $range = Get-IPRange -BaseIP $baseIP -CIDRSuffix $subnet
    if ($null -eq $range) {
        Write-Host "[ERROR] Failed to calculate range for: $ipRange"
        continue
    }    # Initialize counters for this range
    $successful = @()
    $totalIPs = ($range.EndIP - $range.StartIP + 1)
    $jumpCount = 0
    $currentPosition = $range.StartIP
    $maxResponsesReached = $false
      Write-Host "  Range contains $totalIPs IPs (from $(ConvertTo-IPString -IPInt $range.StartIP) to $(ConvertTo-IPString -IPInt $range.EndIP))" -ForegroundColor Yellow
    if ($Jump -gt 0) {
        Write-Host "  Jump mode enabled: will skip $Jump IPs after $MaxFailures failures (skip range after $Skip jumps)" -ForegroundColor Yellow
    }
    if ($MaxResponses -gt 0) {
        Write-Host "  Response limit enabled: will skip range after $MaxResponses successful responses" -ForegroundColor Yellow
    }    Write-Host "  Testing first $MaxFailures IPs for connectivity..." -ForegroundColor Yellow
      # Handle parallel ping mode separately
    if ($ScanMode -eq "parallel") {
        Write-Host "  Using parallel ping mode with batch processing" -ForegroundColor Yellow
        $successful = Invoke-BatchParallelPing -StartIP $range.StartIP -EndIP $range.EndIP -TimeoutMs $Timeout -BatchSize 256 -JumpSize 1024 -LocationData "$($entry.Location),$($entry.Region),$($entry.City),$($entry.PostalCode)" -OutputPath $outputPath
    } else {
        # Traditional scanning modes: ping, port, both
        # For "both" mode: First do a quick ping sweep, then port scan non-responders
        $pingResponders = @()
        $nonResponders = @()
        
        if ($ScanMode -eq "both") {
            Write-Host "  Phase 1: Quick ping sweep to identify responsive hosts" -ForegroundColor Yellow
            
            # Quick ping sweep for "both" mode
            for ($ipNum = $range.StartIP; $ipNum -le $range.EndIP; $ipNum++) {
                if ($MaxResponses -gt 0 -and $successful.Count -ge $MaxResponses) {
                    Write-Host "  Reached maximum responses ($MaxResponses) - stopping ping sweep" -ForegroundColor Yellow
                    break
                }
                
                $currentIP = ConvertTo-IPString -IPInt $ipNum
                if ($null -eq $currentIP) { continue }
                
                # Quick ping test
                $pingResult = $null
                if ($isPSCore) {
                    $pingResult = Test-Connection -ComputerName $currentIP -Count 1 -TimeoutSeconds ($Timeout / 1000) -ErrorAction SilentlyContinue
                } else {
                    try {
                        $pingObj = New-Object System.Net.NetworkInformation.Ping
                        $pingReply = $pingObj.Send($currentIP, $Timeout)
                        if ($pingReply.Status -eq "Success") {
                            $pingResult = [PSCustomObject]@{
                                ResponseTime = $pingReply.RoundtripTime
                                Status = "Success"
                            }
                        }
                    } catch {
                        $pingResult = $null
                    }
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
            
            Write-Host "  Phase 1 complete: $($pingResponders.Count) ping responders, $($nonResponders.Count) non-responders" -ForegroundColor Cyan
            
            if ($nonResponders.Count -gt 0) {
                Write-Host "  Phase 2: Port scanning non-responders for service detection" -ForegroundColor Yellow
                
                # Port scan non-responders
                foreach ($ip in $nonResponders) {
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
        } else {            # Traditional scanning loop for ping and port modes
        # Main scanning loop with jump functionality
        while ($currentPosition -le $range.EndIP -and -not $maxResponsesReached) {
            # Check if we've exceeded the skip limit
            if ($jumpCount -ge $Skip -and $Jump -gt 0) {
                Write-Host "  Skipping remaining IPs in range $ipRange due to $jumpCount/$Skip jumps reached." -ForegroundColor Red
                break
            }
            
            # Pre-calculate limit for the current set of IPs to check
            $checkLimit = [Math]::Min($currentPosition + $MaxFailures - 1, $range.EndIP)
            
            # Check the current set of IPs for timeouts
            $timeoutCount = 0
            
            for ($ipNum = $currentPosition; $ipNum -le $checkLimit; $ipNum++) {
                $currentIP = ConvertTo-IPString -IPInt $ipNum
                
                # Skip invalid IPs
                if ($null -eq $currentIP) { continue }
                
                # Use scan function for ping and port modes
                Write-Host "  Scanning: $currentIP" -ForegroundColor Cyan
                
                $scanResult = Invoke-NetworkScan -IP $currentIP -ScanMode $ScanMode -PingTimeoutMs $Timeout -PortList $Ports -PortTimeoutMs $PortTimeout -LocationData "$($entry.Location),$($entry.Region),$($entry.City),$($entry.PostalCode)"
                
                # Determine if this IP is considered "successful" based on scan mode
                $isSuccessful = $false
                if ($ScanMode -eq "ping") {
                    $isSuccessful = ($scanResult.PingResult -eq "Success")
                } elseif ($ScanMode -eq "port") {
                    $isSuccessful = ($scanResult.PortsOpen -ne "None")
                }
                
                if (-not $isSuccessful) {
                    $timeoutCount++
                    if ($ScanMode -eq "ping") {
                        Write-Host "  ✗ $currentIP - No ping response" -ForegroundColor Red
                    } elseif ($ScanMode -eq "port") {
                        Write-Host "  ✗ $currentIP - No open ports" -ForegroundColor Red
                    }
                } else {
                    # Display results based on scan mode
                    if ($ScanMode -eq "ping") {
                        Write-Host "  ✓ $currentIP - $($scanResult.PingTime) ms" -ForegroundColor Green
                    } elseif ($ScanMode -eq "port") {
                        Write-Host "  ✓ $currentIP - Ports: $($scanResult.PortsOpen)" -ForegroundColor Green
                    }
                    
                    # Add to successful list
                    $successful += $currentIP
                    
                    # Save to the output file based on scan mode
                    if ($ScanMode -eq "ping") {
                        $outputResult = [PSCustomObject]@{
                            IP = $currentIP
                            Location = $scanResult.Location
                            'Ping Time (ms)' = $scanResult.PingTime
                        }
                    } elseif ($ScanMode -eq "port") {
                        $outputResult = [PSCustomObject]@{
                            IP = $currentIP
                            Location = $scanResult.Location
                            'Ports Open' = $scanResult.PortsOpen
                            'Service Status' = $scanResult.ServiceStatus
                        }
                    }
                    
                    $outputResult | Export-Csv -Path $outputPath -Append -NoTypeInformation
                    
                    # Check if we've reached the maximum number of responses for this range
                    if ($MaxResponses -gt 0 -and $successful.Count -ge $MaxResponses) {
                        Write-Host "  Reached maximum responses ($MaxResponses) for range $ipRange - skipping remaining IPs" -ForegroundColor Yellow
                        $maxResponsesReached = $true
                        break  # Exit the inner IP scanning loop for this batch
                    }
                }
            }
            
            # Handle failures and jumping logic
            if ($timeoutCount -ge $MaxFailures) {
                if ($Jump -gt 0) {
                    $jumpCount++
                    Write-Host "  Jumping $Jump IPs due to $timeoutCount/$MaxFailures consecutive timeouts (jump #$jumpCount)" -ForegroundColor Yellow
                    $currentPosition = $checkLimit + 1 + $Jump
                } else {
                    Write-Host "  Skipping remaining IPs in range $ipRange due to $timeoutCount/$MaxFailures consecutive timeouts." -ForegroundColor Red
                    break
                }
            } else {
                # Continue with next batch
                $currentPosition = $checkLimit + 1
            }
        }        }
    }
    
    # Display summary of reachable IPs
    if ($successful.Count -gt 0) {
        Write-Host "✓ Range ${cidrRange}: $($successful.Count)/$totalIPs IPs reachable" -ForegroundColor Green
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