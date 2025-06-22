#Requires -Version 5.0

[CmdletBinding()]
param (
    [Parameter()]
    [string]$InputFile = "ip_list.csv", # Default input file name
    
    [Parameter()]
    [string]$OutputFile = "ping_results.csv",   # Default output file name
    
    [Parameter()]
    [int]$Timeout = 1500, # Ping timeout in milliseconds (default: 500ms)
    
    [Parameter()]
    [int]$MaxFailures = 5, # Number of consecutive failures before action (skip or jump)
    
    [Parameter()]
    [int]$Jump = 3,  # Number of IPs to skip after MaxFailures (0 = disabled)
    
    [Parameter()]
    [int]$Skip = 5, # Number of jumps before skipping entire range (only applies if Jump > 0)
    
    [Parameter()]
    [string]$ScanMode = "ping", # Scanning mode: "ping", "port", "both", "smart"
    
    [Parameter()]
    [string]$Ports = "80,443,22,53,8080,8443", # Comma-separated list of ports to scan
    
    [Parameter()]
    [int]$PortTimeout = 3000 # Port connection timeout in milliseconds
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
$DefaultMaxFailures = 5                         # Number of consecutive failures before action (skip or jump)

# Jump/Skip Settings
$DefaultJump = 3                                # Number of IPs to skip after MaxFailures (0 = disabled, jump feature off)
$DefaultSkip = 5                                # Number of jumps before skipping entire range (only applies if Jump > 0)

# Port Scanning Settings (NEW!)
$DefaultScanMode = "ping"                       # Default scan mode: "ping", "port", "both", "smart"
$DefaultPorts = "80,443,22,53,8080,8443"        # Default ports to scan (HTTP, HTTPS, SSH, DNS, Alt-HTTP, Alt-HTTPS)
$DefaultPortTimeout = 3000                      # Port connection timeout in milliseconds (3 seconds)

# Usage Examples:
# .\powerPinger.ps1                             # Uses interactive mode to select files
# .\powerPinger.ps1 -InputFile "do.csv"        # Uses specific input file, interactive output
# .\powerPinger.ps1 -Timeout 5000               # Uses 5 second timeout, interactive file selection
# .\powerPinger.ps1 -Jump 0                     # Disables jumping, interactive file selection
# .\powerPinger.ps1 -ScanMode smart             # Smart filtering detection mode
# .\powerPinger.ps1 -ScanMode port -Ports "80,443,22"  # Port-only scanning
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

# =====================================

# Add PowerShell version check
$isPSCore = $PSVersionTable.PSVersion.Major -ge 6

# Detect if running via "Run with PowerShell"
$isRunWithPowerShell = $MyInvocation.MyCommand.CommandType -eq 'ExternalScript' -and $Host.Name -eq 'ConsoleHost'

# =====================================
# WELCOME SCREEN & PROGRAM INFO
# =====================================

function Show-WelcomeScreen {
    param (
        [bool]$IsInteractiveMode
    )
    
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                            🔍 PowerPinger v2.0                              ║" -ForegroundColor Cyan
    Write-Host "║                      Advanced Network Range Scanner                         ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
    Write-Host "Current Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
    
    # Provide guidance for "Run with PowerShell" users
    if ($isRunWithPowerShell) {
        Write-Host "💡 Tip: For best experience, run from PowerShell terminal" -ForegroundColor Yellow
        Write-Host "   Right-click in folder → Open PowerShell window here → .\powerPinger.ps1" -ForegroundColor Gray
    }
    Write-Host ""
    
    if ($IsInteractiveMode) {
        Write-Host "🎯 Running in INTERACTIVE MODE" -ForegroundColor Magenta
        Write-Host "   You will be guided through configuration options" -ForegroundColor Gray
    } else {
        Write-Host "⚡ Running in COMMAND-LINE MODE" -ForegroundColor Yellow
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
    Write-Host "   • Smart timeout detection" -ForegroundColor White
    Write-Host "   • Jump mode: Skip unresponsive IP blocks" -ForegroundColor White
    Write-Host "   • Range skipping: Avoid scanning dead ranges" -ForegroundColor White
    Write-Host "   • Port scanning: Test service accessibility" -ForegroundColor White
    Write-Host "   • Network filtering detection: Identify access patterns" -ForegroundColor White
    Write-Host "   • Multiple scan modes: ping/port/both/smart" -ForegroundColor White
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
    Write-Host "Consecutive failures before action (default: $DefaultMaxFailures)" -ForegroundColor White    Write-Host "-Jump <num>           " -NoNewline -ForegroundColor Green
    Write-Host "IPs to skip after failures (0=disabled, default: $DefaultJump)" -ForegroundColor White
    Write-Host "-Skip <num>           " -NoNewline -ForegroundColor Green
    Write-Host "Jumps before skipping range (default: $DefaultSkip)" -ForegroundColor White
    Write-Host "-ScanMode <mode>      " -NoNewline -ForegroundColor Green
    Write-Host "Scan type: ping/port/both/smart (default: $DefaultScanMode)" -ForegroundColor White
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
    Write-Host ""
    Write-Host ".\powerPinger.ps1 -ScanMode smart -Ports `"80,443,22`"" -ForegroundColor Cyan
    Write-Host "   → Smart filtering detection with web/SSH ports" -ForegroundColor Gray
    Write-Host ""
    Write-Host ".\powerPinger.ps1 -ScanMode port -Ports `"80,443`" -PortTimeout 5000" -ForegroundColor Cyan
    Write-Host "   → Port-only scanning for HTTP/HTTPS services" -ForegroundColor Gray
    Write-Host ""
}

# Determine if we're in interactive mode
$InteractiveMode = (-not $PSBoundParameters.ContainsKey('InputFile')) -or (-not $PSBoundParameters.ContainsKey('OutputFile'))

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
    Write-Host ""
    Write-Host "📊 Current Settings:" -ForegroundColor Cyan
    Write-Host "   • Scan Mode: $DefaultScanMode (ping/port/both/smart)" -ForegroundColor White
    Write-Host "   • Timeout: ${DefaultTimeout}ms per ping" -ForegroundColor White
    Write-Host "   • Port Timeout: ${DefaultPortTimeout}ms per port" -ForegroundColor White
    Write-Host "   • Ports to Scan: $DefaultPorts" -ForegroundColor White
    Write-Host "   • Max Failures: $DefaultMaxFailures consecutive timeouts before action" -ForegroundColor White
    Write-Host "   • Jump Mode: $(if ($DefaultJump -gt 0) { "$DefaultJump IPs (enabled)" } else { "Disabled" })" -ForegroundColor White
    Write-Host "   • Skip Limit: $DefaultSkip jumps before skipping entire range" -ForegroundColor White
    Write-Host ""
    
    $customize = Read-Host "👉 Customize settings? (y/N)"
    
    if ($customize -match '^[Yy]') {
        Write-Host ""
        Write-Host "🔧 Advanced Configuration" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan
        
        # Scan Mode configuration (NEW!)
        Write-Host ""
        Write-Host "🎯 Scan Mode (current: $DefaultScanMode)" -ForegroundColor Yellow        Write-Host "💡 Choose scanning strategy for network filtering detection:" -ForegroundColor Gray
        Write-Host "   🏓 ping  - ICMP ping only (traditional mode)" -ForegroundColor White
        Write-Host "   🚪 port  - Port scanning only (bypass ICMP blocks)" -ForegroundColor White
        Write-Host "   🔄 both  - Ping + Port scan (comprehensive analysis)" -ForegroundColor White
        Write-Host "   🧠 smart - Intelligent mode (detect filtering patterns)" -ForegroundColor White
        Write-Host "📋 Recommended: 'smart' for filtered networks, 'ping' for normal networks" -ForegroundColor Gray
        $modeInput = Read-Host "👉 Enter scan mode (ping/port/both/smart) or press Enter for default ($DefaultScanMode)"
        if (-not [string]::IsNullOrWhiteSpace($modeInput) -and $modeInput -match '^(ping|port|both|smart)$') {
            $script:ScanMode = $modeInput.ToLower()
        }
        
        # Port List configuration (if port scanning enabled)
        if ($script:ScanMode -eq "port" -or $script:ScanMode -eq "both" -or $script:ScanMode -eq "smart") {
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
        if ($script:ScanMode -eq "ping" -or $script:ScanMode -eq "both" -or $script:ScanMode -eq "smart") {
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
        
        Write-Host ""
        Write-Host "✅ Configuration Updated!" -ForegroundColor Green
    } else {
        Write-Host "✅ Using default settings" -ForegroundColor Green
    }
}

# =====================================
# MAIN EXECUTION
# =====================================

# Determine if we're in interactive mode (missing key parameters)
$InteractiveMode = (-not $PSBoundParameters.ContainsKey('InputFile')) -or (-not $PSBoundParameters.ContainsKey('OutputFile'))

if ($InteractiveMode) {
    # Interactive Mode - get all configuration from user
    Write-Host "`n🔍 PowerPinger - Interactive Configuration" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Get input file
    if (-not $PSBoundParameters.ContainsKey('InputFile')) {
        $inputPath = Get-InputFile
        $InputFile = Split-Path -Leaf $inputPath
    } else {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $inputPath = Join-Path -Path $scriptPath -ChildPath $InputFile
    }
    
    # Get output file
    if (-not $PSBoundParameters.ContainsKey('OutputFile')) {
        $outputPath = Get-OutputFile
        $OutputFile = Split-Path -Leaf $outputPath
    } else {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $outputPath = Join-Path -Path $scriptPath -ChildPath $OutputFile
    }
      # Get scan configuration (only if not provided via command line)
    if ((-not $PSBoundParameters.ContainsKey('ScanMode')) -or
        (-not $PSBoundParameters.ContainsKey('Ports')) -or
        (-not $PSBoundParameters.ContainsKey('PortTimeout')) -or
        (-not $PSBoundParameters.ContainsKey('Timeout')) -or 
        (-not $PSBoundParameters.ContainsKey('MaxFailures')) -or 
        (-not $PSBoundParameters.ContainsKey('Jump')) -or 
        (-not $PSBoundParameters.ContainsKey('Skip'))) {
        Get-ScanConfiguration
    }
      # Show final configuration summary
    Write-Host "`n🎯 Final Configuration Summary" -ForegroundColor Magenta
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "   Input File: $InputFile" -ForegroundColor White
    Write-Host "   Output File: $OutputFile" -ForegroundColor White
    Write-Host "   Scan Mode: $ScanMode" -ForegroundColor White
    if ($ScanMode -eq "ping" -or $ScanMode -eq "both" -or $ScanMode -eq "smart") {
        Write-Host "   Ping Timeout: ${Timeout}ms" -ForegroundColor White
    }
    if ($ScanMode -eq "port" -or $ScanMode -eq "both" -or $ScanMode -eq "smart") {
        Write-Host "   Port Timeout: ${PortTimeout}ms" -ForegroundColor White
        Write-Host "   Ports to Scan: $Ports" -ForegroundColor White
    }
    Write-Host "   Max Failures: $MaxFailures" -ForegroundColor White
    if ($Jump -gt 0) {
        Write-Host "   Jump Mode: $Jump IPs (skip range after $Skip jumps)" -ForegroundColor White
    } else {
        Write-Host "   Jump Mode: Disabled" -ForegroundColor White
    }
    Write-Host ""# Ask for final confirmation
    Write-Host "🚀 Ready to start scanning? (Y/n): " -ForegroundColor Yellow -NoNewline
    $confirm = Read-Host
    $confirm = $confirm.Trim() # Remove any whitespace
    if (-not [string]::IsNullOrWhiteSpace($confirm) -and $confirm -match '^[Nn]') {
        Write-Host "Scan cancelled by user." -ForegroundColor Yellow
        exit 0
    }
    
} else {
    # Command-line Mode - use provided parameters or defaults
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $inputPath = Join-Path -Path $scriptPath -ChildPath $InputFile
    $outputPath = Join-Path -Path $scriptPath -ChildPath $OutputFile
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

# Perform comprehensive scan based on mode
function Invoke-ComprehensiveScan {
    param(
        [string]$IP,
        [string]$ScanMode,
        [int]$PingTimeoutMs,
        [string]$PortList,
        [int]$PortTimeoutMs,
        [string]$LocationData
    )
    
    $result = [PSCustomObject]@{
        IP = $IP
        Location = $LocationData
        PingResult = "Not Tested"
        PingTime = "N/A"
        PortsOpen = "Not Tested"
        ServiceStatus = "Unknown"
        FilteringDetected = "No"
    }
    
    $pingSuccessful = $false
    $portsOpen = @()
    
    # Perform ping test if required
    if ($ScanMode -eq "ping" -or $ScanMode -eq "both" -or $ScanMode -eq "smart") {
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
            $result.PingTime = "Timeout"        }
    }
    
    # Perform port test if required
    if ($ScanMode -eq "port" -or $ScanMode -eq "both" -or $ScanMode -eq "smart") {
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
    
    # Detect network filtering patterns (improved logic for unassigned IPs)
    if ($ScanMode -eq "both" -or $ScanMode -eq "smart") {
        if ($pingSuccessful -and $portsOpen.Count -eq 0) {            # Ping works but no services
            if ($portsRefused.Count -gt 0) {
                # Services actively refused - normal firewall behavior
                $result.FilteringDetected = "Likely-Filtered"
                $result.ServiceStatus = "Ping-Only"
            } elseif ($portsTimeout.Count -gt 0) {
                # Services timed out - could be filtered or unassigned
                $result.FilteringDetected = "Likely-Filtered"
                $result.ServiceStatus = "Ping-Only"
            } else {
                # No ports tested or other condition
                $result.FilteringDetected = "Likely-Filtered"
                $result.ServiceStatus = "Ping-Only"
            }
        } elseif (-not $pingSuccessful -and $portsOpen.Count -gt 0) {
            # Services work but ping doesn't - clear indication of ICMP filtering
            $result.FilteringDetected = "ICMP-Blocked"
            $result.ServiceStatus = "Services-Only"
        } elseif (-not $pingSuccessful -and $portsOpen.Count -eq 0) {            # Neither ping nor services work
            if ($portsRefused.Count -gt 0) {
                # Services actively refused but ping blocked - ICMP filtering
                $result.FilteringDetected = "ICMP-Blocked"
                $result.ServiceStatus = "Services-Refused"
            } elseif ($portsTimeout.Count -gt 0) {
                # All services timed out and ping failed - likely unassigned IP range
                $result.FilteringDetected = "Unassigned-Range"
                $result.ServiceStatus = "No-Response"
            } else {
                # No ports tested
                $result.FilteringDetected = "Unassigned-Range"
                $result.ServiceStatus = "No-Response"
            }
        } else {
            # Both ping and services work - normal operation
            $result.FilteringDetected = "No"
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
Write-Host "Scan mode: $ScanMode" -ForegroundColor Yellow
if ($ScanMode -eq "ping" -or $ScanMode -eq "both" -or $ScanMode -eq "smart") {
    Write-Host "Ping timeout: ${Timeout}ms" -ForegroundColor Yellow
}
if ($ScanMode -eq "port" -or $ScanMode -eq "both" -or $ScanMode -eq "smart") {
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
if ($ScanMode -eq "ping") {
    "IP,Location,Ping Time (ms)" | Out-File -FilePath $outputPath -Encoding utf8
} elseif ($ScanMode -eq "port") {
    "IP,Location,Ports Open,Service Status" | Out-File -FilePath $outputPath -Encoding utf8
} else {
    # both or smart mode - include all columns
    "IP,Location,Ping Result,Ping Time (ms),Ports Open,Service Status,Filtering Detected" | Out-File -FilePath $outputPath -Encoding utf8
}

# Process the input file
Write-Host "Starting to read input file..."

$ipRanges = Import-Csv -Path $inputPath -Header IP,Location,Region,City,PostalCode

foreach ($entry in $ipRanges) {
    $ipRange = $entry.IP
    
    # Skip empty lines
    if ([string]::IsNullOrWhiteSpace($ipRange)) {
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
    }      # Initialize counters for this range
    $successful = @()
    $totalIPs = ($range.EndIP - $range.StartIP + 1)
    $jumpCount = 0
    $currentPosition = $range.StartIP
    
    Write-Host "  Range contains $totalIPs IPs (from $(ConvertTo-IPString -IPInt $range.StartIP) to $(ConvertTo-IPString -IPInt $range.EndIP))" -ForegroundColor Yellow
    if ($Jump -gt 0) {
        Write-Host "  Jump mode enabled: will skip $Jump IPs after $MaxFailures failures (skip range after $Skip jumps)" -ForegroundColor Yellow
    }
    Write-Host "  Testing first $MaxFailures IPs for connectivity..." -ForegroundColor Yellow
    
    # Main scanning loop with jump functionality
    while ($currentPosition -le $range.EndIP) {
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
            
            # Use comprehensive scan function for all modes
            Write-Host "  Scanning: $currentIP" -ForegroundColor Cyan
            
            $scanResult = Invoke-ComprehensiveScan -IP $currentIP -ScanMode $ScanMode -PingTimeoutMs $Timeout -PortList $Ports -PortTimeoutMs $PortTimeout -LocationData "$($entry.Location),$($entry.Region),$($entry.City),$($entry.PostalCode)"
            
            # Determine if this IP is considered "successful" based on scan mode
            $isSuccessful = $false
            if ($ScanMode -eq "ping") {
                $isSuccessful = ($scanResult.PingResult -eq "Success")
            } elseif ($ScanMode -eq "port") {
                $isSuccessful = ($scanResult.PortsOpen -ne "None")
            } else {
                # both or smart mode - successful if either ping works or ports are open
                $isSuccessful = ($scanResult.PingResult -eq "Success") -or ($scanResult.PortsOpen -ne "None")
            }
            
            if (-not $isSuccessful) {
                $timeoutCount++
                if ($ScanMode -eq "ping") {
                    Write-Host "  ✗ $currentIP - No ping response" -ForegroundColor Red
                } elseif ($ScanMode -eq "port") {
                    Write-Host "  ✗ $currentIP - No open ports" -ForegroundColor Red
                } else {
                    Write-Host "  ✗ $currentIP - No response (ping: $($scanResult.PingResult), ports: $($scanResult.PortsOpen))" -ForegroundColor Red
                }
            } else {
                # Display results based on scan mode
                if ($ScanMode -eq "ping") {
                    Write-Host "  ✓ $currentIP - $($scanResult.PingTime) ms" -ForegroundColor Green
                } elseif ($ScanMode -eq "port") {
                    Write-Host "  ✓ $currentIP - Ports: $($scanResult.PortsOpen)" -ForegroundColor Green
                } else {
                    $statusText = "ping: $($scanResult.PingResult)"
                    if ($scanResult.PingTime -ne "N/A") { $statusText += " ($($scanResult.PingTime)ms)" }
                    $statusText += ", ports: $($scanResult.PortsOpen)"
                    if ($scanResult.FilteringDetected -ne "No") {
                        $statusText += " [FILTERING: $($scanResult.FilteringDetected)]"
                    }
                    Write-Host "  ✓ $currentIP - $statusText" -ForegroundColor Green
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
                } else {
                    $outputResult = [PSCustomObject]@{
                        IP = $currentIP
                        Location = $scanResult.Location
                        'Ping Result' = $scanResult.PingResult
                        'Ping Time (ms)' = $scanResult.PingTime
                        'Ports Open' = $scanResult.PortsOpen
                        'Service Status' = $scanResult.ServiceStatus
                        'Filtering Detected' = $scanResult.FilteringDetected
                    }
                }
                
                $outputResult | Export-Csv -Path $outputPath -Append -NoTypeInformation
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
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host | Out-Null