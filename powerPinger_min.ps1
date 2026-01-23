#Requires -Version 5.0
[CmdletBinding()]
param (
    [Parameter()]
    [string]$InputFile = "ip_list.csv",
    [Parameter()]
    [string]$OutputFile = "ping_results.csv",
    [Parameter()]
    [int]$Timeout = 1500,
    [Parameter()]
    [int]$MaxFailures = 4,
    [Parameter()]
    [int]$Jump = 16,
    [Parameter()]
    [int]$Skip = 3,
    [Parameter()]
    [int]$DelayMs = 0,
    [Parameter()]
    [string]$ScanMode = "ping",
    [Parameter()]
    [string]$Ports = "80,443,22,53,8080,8443",
    [Parameter()]
    [int]$PortTimeout = 3000,
    [Parameter()]
    [int]$MaxResponses = 10
)
$k = "ip_list.csv"
$h = "ping_results.csv"
$y = 1500
$g = 4
$bh = 16
$be = 3
$p = "ping"
$aq = "80,443,22,53,8080,8443"
$e = 3000
$a = 10
if (-not $PSBoundParameters.ContainsKey('InputFile')) { $InputFile = $k }
if (-not $PSBoundParameters.ContainsKey('OutputFile')) { $OutputFile = $h }
if (-not $PSBoundParameters.ContainsKey('Timeout')) { $Timeout = $y }
if (-not $PSBoundParameters.ContainsKey('MaxFailures')) { $MaxFailures = $g }
if (-not $PSBoundParameters.ContainsKey('Jump')) { $Jump = $bh }
if (-not $PSBoundParameters.ContainsKey('Skip')) { $Skip = $be }
if (-not $PSBoundParameters.ContainsKey('ScanMode')) { $ScanMode = $p }
if (-not $PSBoundParameters.ContainsKey('Ports')) { $Ports = $aq }
if (-not $PSBoundParameters.ContainsKey('PortTimeout')) { $PortTimeout = $e }
if (-not $PSBoundParameters.ContainsKey('MaxResponses')) { $MaxResponses = $a }
$cx = $aa.PSVersion.Major -ge 6
$d = $MyInvocation.MyCommand.CommandType -eq 'ExternalScript' -and $Host.Name -eq 'ConsoleHost'
function Test-UnicodeSupport {
    $w = $false
    if ($eq:WT_SESSION -or $eq:TERM_PROGRAM -eq "vscode" -or $eq:ConEmuPID) {
        $w = $true
    }
    try {
        $dn = $Host.UI.RawUI
        if ($dn.WindowTitle -match "Windows Terminal|Visual Studio Code") {
            $w = $true
        }
    }
    catch {
    }
    return $w
}
function Get-DisplayIcon {
    param([string]$IconType)
    $o = Test-UnicodeSupport
    if ($o) {
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
    $bq = Get-DisplayIcon "search"
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                            $bq PowerPinger v2.0                              ║" -ForegroundColor Cyan
    Write-Host "║                      Advanced Network Range Scanner                         ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""    Write-Host "PowerShell Version: $($aa.PSVersion)" -ForegroundColor Green
    Write-Host "Current Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
    if ($d) {
        $dh = Get-DisplayIcon "bulb"
        Write-Host "$dh Tip: For best experience, run from PowerShell terminal" -ForegroundColor Yellow
        Write-Host "   Right-click in folder → Open PowerShell window here → .\powerPinger.ps1" -ForegroundColor Gray
    }
    Write-Host ""
    if ($IsInteractiveMode) {
        $bp = Get-DisplayIcon "target"
        Write-Host "$bp Running in INTERACTIVE MODE" -ForegroundColor Magenta
        Write-Host "   You will be guided through configuration options" -ForegroundColor Gray
    } else {
        $ab = Get-DisplayIcon "lightning"
        Write-Host "$ab Running in COMMAND-LINE MODE" -ForegroundColor Yellow
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
    Write-Host "Ping timeout in milliseconds (default: $y)" -ForegroundColor White
    Write-Host "-MaxFailures <num>    " -NoNewline -ForegroundColor Green
    Write-Host "Consecutive failures before action (default: $g)" -ForegroundColor White
    Write-Host "-Jump <num>           " -NoNewline -ForegroundColor Green
    Write-Host "IPs to skip after failures (0=disabled, default: $bh)" -ForegroundColor White
    Write-Host "-Skip <num>           " -NoNewline -ForegroundColor Green
    Write-Host "Jumps before skipping range (default: $be)" -ForegroundColor White    Write-Host "-ScanMode <mode>      " -NoNewline -ForegroundColor Green
    Write-Host "Scan type: ping/port/both/parallel (default: $p)" -ForegroundColor White
    Write-Host "-Ports <list>         " -NoNewline -ForegroundColor Green
    Write-Host "Comma-separated ports to scan (default: $aq)" -ForegroundColor White
    Write-Host "-PortTimeout <ms>     " -NoNewline -ForegroundColor Green
    Write-Host "Port connection timeout in ms (default: $e)" -ForegroundColor White
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
$n = $PSBoundParameters.Count -eq 0
Show-WelcomeScreen -IsInteractiveMode $n
if ($n) {
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
function Show-FileMenu {
    param (
        [array]$Files,
        [string]$Title
    )
    Write-Host "`n$Title" -ForegroundColor Yellow
    Write-Host ("=" * $Title.Length) -ForegroundColor Yellow
    for ($er = 0; $er -lt $Files.Count; $er++) {
        Write-Host "[$($er + 1)] $($Files[$er].Name)" -ForegroundColor Cyan
    }
    Write-Host "[0] Exit" -ForegroundColor Red
    Write-Host ""
}
function Get-InputFile {
    $m = if ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        Get-Location
    }
    $df = Get-ChildItem -Path $m -Filter "*.csv" -File
    $dd = Get-ChildItem -Path $m -Filter "*.txt" -File
    $dg = @($df) + @($dd) | Sort-Object Name
    if ($dg.Count -eq 0) {
        Write-Host "📋 No CSV or TXT files found in the script directory" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "❓ Would you like to:" -ForegroundColor Cyan
        Write-Host "[1] Enter IP addresses manually (recommended for quick tests)" -ForegroundColor Green
        Write-Host "[2] Create a new input file and exit" -ForegroundColor Yellow
        Write-Host "[0] Exit" -ForegroundColor Red
        Write-Host ""
        $du = Read-Host "👉 Select option (0-2)"
        if ($du -eq "1") {
            return "MANUAL_INPUT"
        } elseif ($du -eq "2") {
            Write-Host ""
            Write-Host "📝 Creating sample template file: ip_list.csv" -ForegroundColor Cyan
            $af = @"
8.8.8.8,US,CA,Mountain View,94043
1.1.1.1,US,CA,San Francisco,94107
192.168.1.0/24,Local,Network,LAN,00000
"@
            $br = Join-Path -Path $m -ChildPath "ip_list.csv"
            $af | Out-File -FilePath $br -Encoding UTF8
            Write-Host "✅ Sample file created: $br" -ForegroundColor Green
            Write-Host "📝 Edit this file and run the script again" -ForegroundColor Yellow
            exit 0
        } else {
            Write-Host "👋 Exiting..." -ForegroundColor Yellow
            exit 0
        }
    }
    if ($dg.Count -eq 1) {
        Write-Host "📄 Found only one IP range file: $($dg[0].Name)" -ForegroundColor Green
        Write-Host "✅ Using this file automatically..." -ForegroundColor Green
        Start-Sleep -Seconds 1
        return $dg[0].FullName
    }
    do {
        Write-Host ""
        Write-Host "📂 Available IP Range Files" -ForegroundColor Yellow
        Write-Host "============================" -ForegroundColor Yellow
        for ($er = 0; $er -lt $dg.Count; $er++) {
            Write-Host "[$($er + 1)] $($dg[$er].Name)" -ForegroundColor Cyan
        }
        Write-Host "[0] Exit" -ForegroundColor Red
        Write-Host ""
        Write-Host "❓ Which file contains your IP ranges to scan?" -ForegroundColor Yellow
        Write-Host "💡 Tip: Files should contain IP addresses or CIDR ranges" -ForegroundColor Gray
        $ck = Read-Host "👉 Select input file (1-$($dg.Count)) or press Enter for default ($k)"
        if ([string]::IsNullOrWhiteSpace($ck)) {
            $bb = $dg | Where-Object { $_.Name -eq $k }
            if ($bb) {
                Write-Host "✅ Using default file: $($bb.Name)" -ForegroundColor Green
                return $bb.FullName
            } else {
                Write-Host "⚠️  Default file '$k' not found. Please select a file." -ForegroundColor Red
                continue
            }
        }
        if ($ck -eq "0") {
            Write-Host "👋 Exiting..." -ForegroundColor Yellow
            exit 0
        }
        try {
            $ad = [int]$ck - 1
            if ($ad -ge 0 -and $ad -lt $dg.Count) {
                Write-Host "✅ Selected: $($dg[$ad].Name)" -ForegroundColor Green
                return $dg[$ad].FullName
            } else {
                Write-Host "❌ Invalid selection. Please choose a number between 1 and $($dg.Count)." -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Please enter a valid number." -ForegroundColor Red
        }
    } while ($true)
}
function Get-OutputFile {
    $m = if ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        Get-Location
    }
    $s = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $bg = "Found_$s"
    Write-Host ""
    Write-Host "💾 Output File Configuration" -ForegroundColor Yellow
    Write-Host "============================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "❓ What would you like to name your results file?" -ForegroundColor Yellow
    Write-Host "📝 The file will contain all responsive IPs with ping times" -ForegroundColor Gray
    Write-Host "💡 Extension (.csv) will be added automatically" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎯 Default option: $bg" -ForegroundColor Cyan
    Write-Host "📂 File will be saved in: $m" -ForegroundColor Gray
    Write-Host ""
    $cv = Read-Host "👉 Enter filename (without extension) or press Enter for default"
    if ([string]::IsNullOrWhiteSpace($cv)) {
        $cv = $bg
        Write-Host "✅ Using default filename: $cv" -ForegroundColor Green
    } else {
        $cv = $cv -replace '[<>:"/\\|?*]', '_'
        Write-Host "✅ Using custom filename: $cv" -ForegroundColor Green
    }
    $outputFile = "$cv.csv"
    $cw = Join-Path -Path $m -ChildPath $outputFile
    if (Test-Path $cw) {
        Write-Host ""
        Write-Host "⚠️  File already exists: $outputFile" -ForegroundColor Yellow
        $ch = Read-Host "👉 Overwrite existing file? (y/N)"
        if ($ch -notmatch '^[Yy]') {
            Write-Host "📝 Please choose a different filename:" -ForegroundColor Cyan
            return Get-OutputFile
        }
    }
      Write-Host "📁 Results will be saved to: $outputFile" -ForegroundColor Green
    return $cw
}
function Get-ScanConfiguration {
    Write-Host ""
    Write-Host "⚙️  Scan Configuration" -ForegroundColor Yellow
    Write-Host "======================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "❓ Would you like to customize scanning parameters?" -ForegroundColor Yellow
    Write-Host "💡 Current defaults work well for most scenarios" -ForegroundColor Gray
    Write-Host ""    Write-Host "📊 Current Settings:" -ForegroundColor Cyan
    Write-Host "   • Scan Mode: $p (ping/port/both/parallel)" -ForegroundColor White
    Write-Host "   • Timeout: ${DefaultTimeout}ms per ping" -ForegroundColor White
    Write-Host "   • Port Timeout: ${DefaultPortTimeout}ms per port" -ForegroundColor White
    Write-Host "   • Ports to Scan: $aq" -ForegroundColor White
    Write-Host "   • Max Failures: $g consecutive timeouts before action" -ForegroundColor White
    Write-Host "   • Jump Mode: $(if ($bh -gt 0) { "$bh IPs (enabled)" } else { "Disabled" })" -ForegroundColor White
    Write-Host "   • Skip Limit: $be jumps before skipping entire range" -ForegroundColor White
    Write-Host "   • Max Responses: $(if ($a -gt 0) { "$a per range (enabled)" } else { "Disabled" })" -ForegroundColor White
    Write-Host ""
    $cm = Read-Host "👉 Customize settings? (y/N)"
      if ($cm -match '^[Yy]') {
        Write-Host ""        Write-Host "🔧 Advanced Configuration" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan
        Write-Host ""        Write-Host "🎯 Scan Mode (current: $p)" -ForegroundColor Yellow
        Write-Host "💡 Choose scanning strategy for network accessibility detection:" -ForegroundColor Gray
        Write-Host "   🏓 ping     - ICMP ping only (traditional mode)" -ForegroundColor White
        Write-Host "   🚪 port     - Port scanning only (bypass ICMP blocks)" -ForegroundColor White
        Write-Host "   🔄 both     - Ping first, then port scan non-responders" -ForegroundColor White
        Write-Host "   ⚡ parallel - Fast parallel ping with batch processing" -ForegroundColor White
        Write-Host "📋 Recommended: 'parallel' for large ranges, 'both' for restricted networks" -ForegroundColor Gray
        $cn = Read-Host "👉 Enter scan mode (ping/port/both/parallel) or press Enter for default ($p)"
        if (-not [string]::IsNullOrWhiteSpace($cn) -and $cn -match '^(ping|port|both|parallel)$') {
            $dt:ScanMode = $cn.ToLower()
        }
        if ($dt:ScanMode -eq "port" -or $dt:ScanMode -eq "both") {
            Write-Host ""
            Write-Host "🚪 Port Selection (current: $aq)" -ForegroundColor Yellow
            Write-Host "💡 Common service ports to test for accessibility:" -ForegroundColor Gray
            Write-Host "   🌐 80,443    - Web services (HTTP, HTTPS)" -ForegroundColor White
            Write-Host "   🔐 22        - SSH secure shell" -ForegroundColor White
            Write-Host "   🌍 53        - DNS domain name system" -ForegroundColor White
            Write-Host "   📧 993,995   - Secure email (IMAPS, POP3S)" -ForegroundColor White
            Write-Host "   🔀 8080,8443 - Alternative web ports" -ForegroundColor White
            Write-Host "📋 Format: comma-separated list (e.g., 80,443,22)" -ForegroundColor Gray
            $bv = Read-Host "👉 Enter ports to scan or press Enter for default ($aq)"
            if (-not [string]::IsNullOrWhiteSpace($bv)) {
                $dt:Ports = $bv
            }
            Write-Host ""
            Write-Host "⏱️  Port Connection Timeout (current: ${DefaultPortTimeout}ms)" -ForegroundColor Yellow
            Write-Host "💡 Time to wait for port connection (higher = more reliable)" -ForegroundColor Gray
            Write-Host "📋 Common values: 1000ms (fast), 3000ms (balanced), 5000ms (thorough)" -ForegroundColor Gray
            $l = Read-Host "👉 Enter port timeout in milliseconds or press Enter for default ($e)"
            if (-not [string]::IsNullOrWhiteSpace($l) -and $l -match '^\d+$') {
                $dt:PortTimeout = [int]$l
            }
        }
        if ($dt:ScanMode -eq "ping" -or $dt:ScanMode -eq "both") {
            Write-Host ""
            Write-Host "⏱️  Ping Timeout (current: ${DefaultTimeout}ms)" -ForegroundColor Yellow
            Write-Host "💡 Lower = faster scanning, higher = more accurate for slow networks" -ForegroundColor Gray
            Write-Host "📋 Common values: 1000ms (fast), 3000ms (balanced), 5000ms (thorough)" -ForegroundColor Gray
            $ao = Read-Host "👉 Enter timeout in milliseconds or press Enter for default ($y)"
            if (-not [string]::IsNullOrWhiteSpace($ao) -and $ao -match '^\d+$') {
                $dt:Timeout = [int]$ao
            }
        }
        Write-Host ""
        Write-Host "❌ Max Consecutive Failures (current: $g)" -ForegroundColor Yellow
        Write-Host "💡 How many failed tests before taking action (skip or jump)" -ForegroundColor Gray
        Write-Host "📋 Common values: 2 (aggressive), 5 (balanced), 10 (conservative)" -ForegroundColor Gray
        $ag = Read-Host "👉 Enter max failures or press Enter for default ($g)"
        if (-not [string]::IsNullOrWhiteSpace($ag) -and $ag -match '^\d+$') {
            $dt:MaxFailures = [int]$ag
        }
        Write-Host ""
        Write-Host "🦘 Jump Mode Configuration" -ForegroundColor Yellow
        Write-Host "💡 Skip a number of IPs when too many consecutive failures occur" -ForegroundColor Gray
        Write-Host "✅ Recommended for large ranges with sparse responsive IPs" -ForegroundColor Gray
        Write-Host "❌ Set to 0 to disable (will skip entire range instead)" -ForegroundColor Gray
        $cl = Read-Host "👉 Enter IPs to jump (0=disabled) or press Enter for default ($bh)"
        if (-not [string]::IsNullOrWhiteSpace($cl) -and $cl -match '^\d+$') {
            $dt:Jump = [int]$cl
        }
          if ($dt:Jump -gt 0) {
            Write-Host ""
            Write-Host "🛑 Skip Limit (current: $be)" -ForegroundColor Yellow
            Write-Host "💡 After how many jumps should we skip the entire range?" -ForegroundColor Gray
            Write-Host "📋 Common values: 3 (aggressive), 5 (balanced), 10 (patient)" -ForegroundColor Gray
            $co = Read-Host "👉 Enter skip limit or press Enter for default ($be)"
            if (-not [string]::IsNullOrWhiteSpace($co) -and $co -match '^\d+$') {
                $dt:Skip = [int]$co
            }
        }
        Write-Host ""
        Write-Host "🎯 Max Responses per Range (current: $a)" -ForegroundColor Yellow
        Write-Host "💡 Stop scanning a range after finding this many responsive IPs" -ForegroundColor Gray
        Write-Host "💡 Useful for dense networks to avoid scanning unnecessary IPs" -ForegroundColor Gray
        Write-Host "📋 Common values: 5 (quick), 10 (balanced), 0 (disabled)" -ForegroundColor Gray
        $j = Read-Host "👉 Enter max responses (0=disabled) or press Enter for default ($a)"
        if (-not [string]::IsNullOrWhiteSpace($j) -and $j -match '^\d+$') {
            $dt:MaxResponses = [int]$j
        }
        Write-Host ""
        Write-Host "⏱️  Rate Limiting (current: ${script:DelayMs}ms)" -ForegroundColor Yellow
        Write-Host "💡 Delay between batches to prevent DDoS detection (parallel mode)" -ForegroundColor Gray
        Write-Host "⚠️  IMPORTANT: Use 100-500ms for production networks (Cloudflare, AWS, etc.)" -ForegroundColor Red
        Write-Host "📋 Values: 0 (no delay, risky), 100 (safe), 250 (safer), 500 (safest)" -ForegroundColor Gray
        $bs = Read-Host "👉 Enter delay in ms (0=disabled) or press Enter for default (${script:DelayMs})"
        if (-not [string]::IsNullOrWhiteSpace($bs) -and $bs -match '^\d+$') {
            $dt:DelayMs = [int]$bs
        }
        Write-Host ""
        Write-Host "✅ Configuration Updated!" -ForegroundColor Green
    } else {
        Write-Host "✅ Using default settings" -ForegroundColor Green
    }
}
if ($n) {
    Write-Host "`n🔍 PowerPinger - Interactive Configuration" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host ""
    $ci = Get-InputFile
    $InputFile = Split-Path -Leaf $ci
    $outputPath = Get-OutputFile
    $OutputFile = Split-Path -Leaf $outputPath
    Get-ScanConfiguration
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
    Write-Host "🚀 Ready to start scanning? (Y/n): " -ForegroundColor Yellow -NoNewline
    $dk = Read-Host
    $dk = $dk.Trim()
    if (-not [string]::IsNullOrWhiteSpace($dk) -and $dk -match '^[Nn]') {
        Write-Host "Scan cancelled by user." -ForegroundColor Yellow
        exit 0
    }
} else {
    $bt = Split-Path -Parent $MyInvocation.MyCommand.Path
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
    $ci = Join-Path -Path $bt -ChildPath $InputFile
    $outputPath = Join-Path -Path $bt -ChildPath $OutputFile
    if (-not (Test-Path $ci)) {
        Write-Host "❌ ERROR: Input file not found: $ci" -ForegroundColor Red
        exit 1
    }
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
function Test-SkipKeyPressed {
    try {
        if ([Console]::KeyAvailable) {
            $en = [Console]::ReadKey($true)
            if ($en.Key -eq 'S') {
                Write-Host ""
                Write-Host "  🛑 SKIP KEY DETECTED - Stopping current range..." -ForegroundColor Yellow
                Write-Host ""
                return $true
            }
        }
    } catch {
    }
    return $false
}
function Get-IPVersion {
    param ([string]$IPAddress)
    try {
        $ea = [System.Net.IPAddress]::Parse($IPAddress)
        if ($ea.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
            return 4
        } elseif ($ea.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
            return 6
        }
        return 0
    } catch {
        return 0
    }
}
function Get-IPRange {
    param (
        [string]$BaseIP,
        [int]$CIDRSuffix
    )
    try {
        $cj = Get-IPVersion -IPAddress $BaseIP
        if ($cj -eq 4) {
            $ipAddress = [System.Net.IPAddress]::Parse($BaseIP)
            $dp = $ipAddress.GetAddressBytes()
            if ([BitConverter]::IsLittleEndian) {
                [Array]::Reverse($dp)
            }
            $ipInt = [BitConverter]::ToUInt32($dp, 0)
            $el = [UInt32]([Math]::Pow(2, 32 - $CIDRSuffix) - 1)
            $startIP = $ipInt -band (-bnot $el)
            $endIP = $startIP + $el
            return @{
                StartIP = $startIP
                EndIP = $endIP
                IPVersion = 4
                TotalIPs = ($endIP - $startIP + 1)
            }
        } elseif ($cj -eq 6) {
            $ipAddress = [System.Net.IPAddress]::Parse($BaseIP)
            $dp = $ipAddress.GetAddressBytes()
            $cq = 128 - $CIDRSuffix
            if ($cq -le 32) {
                $cu = [Math]::Pow(2, $cq)
            } else {
                $cu = [double]::PositiveInfinity
            }
            $an = [byte[]]::new(16)
            [Array]::Copy($dp, $an, 16)
            $cg = [Math]::Floor($CIDRSuffix / 8)
            $cr = $CIDRSuffix % 8
            if ($cr -ne 0) {
                $an[$cg] = $an[$cg] -band (0xFF -shl (8 - $cr))
                $cg++
            }
            for ($er = $cg; $er -lt 16; $er++) {
                $an[$er] = 0
            }
            $x = [byte[]]::new(16)
            [Array]::Copy($an, $x, 16)
            $cg = [Math]::Floor($CIDRSuffix / 8)
            $cr = $CIDRSuffix % 8
            if ($cr -ne 0) {
                $x[$cg] = $x[$cg] -bor (0xFF -shr $cr)
                $cg++
            }
            for ($er = $cg; $er -lt 16; $er++) {
                $x[$er] = 0xFF
            }
            return @{
                StartIP = $an
                EndIP = $x
                IPVersion = 6
                TotalIPs = $cu
                HostBits = $cq
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
function ConvertTo-IPString {
    param (
        [Parameter(ParameterSetName='IPv4')]
        [uint32]$IPInt,
        [Parameter(ParameterSetName='IPv6')]
        [byte[]]$dp
    )
    try {
        if ($PSCmdlet.ParameterSetName -eq 'IPv4') {
            $ei = [BitConverter]::GetBytes($IPInt)
            if ([BitConverter]::IsLittleEndian) {
                [Array]::Reverse($ei)
            }
            return [System.Net.IPAddress]::new($ei).ToString()
        } else {
            return [System.Net.IPAddress]::new($dp).ToString()
        }
    } catch {
        Write-Error "Error converting IP to string: $_"
        return $null
    }
}
function Add-IPv6Address {
    param (
        [byte[]]$dp,
        [int]$Increment = 1
    )
    $dx = [byte[]]::new(16)
    [Array]::Copy($dp, $dx, 16)
    $ee = $Increment
    for ($er = 15; $er -ge 0 -and $ee -gt 0; $er--) {
        $eo = $dx[$er] + $ee
        $dx[$er] = $eo -band 0xFF
        $ee = $eo -shr 8
    }
    return $dx
}
function Compare-IPv6Address {
    param (
        [byte[]]$cz,
        [byte[]]$da
    )
    for ($er = 0; $er -lt 16; $er++) {
        if ($cz[$er] -lt $da[$er]) { return -1 }
        if ($cz[$er] -gt $da[$er]) { return 1 }
    }
    return 0
}
function Convert-CIDRToIPList {
    param(
        [string]$CIDR
    )
    try {
        if ($CIDR -match "/") {
            $baseIP = $CIDR.Split("/")[0]
            $dy = [int]$CIDR.Split("/")[1]
        } else {
            $baseIP = $CIDR
            $dy = 32
        }
        $range = Get-IPRange -BaseIP $baseIP -CIDRSuffix $dy
        if ($null -eq $range) {
            return @()
        }
        $eb = @()
        for ($ec = $range.StartIP; $ec -le $range.EndIP; $ec++) {
            $by = ConvertTo-IPString -IPInt $ec
            if ($null -ne $by) {
                $eb += $by
            }
        }
        return $eb
    }
    catch {
        Write-Host "Error parsing CIDR ${CIDR}: $_" -ForegroundColor Red
        return @()
    }
}
function Invoke-ParallelPing {
    param(
        [string[]]$eb,
        [int]$TimeoutMs = 1500,
        [int]$MaxConcurrent = 50
    )
    if ($eb.Count -eq 0) {
        return @()
    }
    $do = @()
    if ($cx) {
        $do = $eb | ForEach-Object -Parallel {
            try {
                $dw = $_ -match ':'
                if ($dw) {
                    $ek = New-Object System.Net.NetworkInformation.Ping
                    $bz = $ek.Send($_, $ef:TimeoutMs)
                    if ($bz.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                        [PSCustomObject]@{
                            IP = $_
                            Success = $true
                            ResponseTime = $bz.RoundtripTime
                            Status = "Success"
                        }
                    } else {
                        [PSCustomObject]@{
                            IP = $_
                            Success = $false
                            ResponseTime = 0
                            Status = $bz.Status.ToString()
                        }
                    }
                } else {
                    $ek = Test-Connection -ComputerName $_ -Count 1 -TimeoutSeconds ($ef:TimeoutMs / 1000) -ErrorAction SilentlyContinue
                    if ($ek) {
                        [PSCustomObject]@{
                            IP = $_
                            Success = $true
                            ResponseTime = $ek.ResponseTime
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
        $al = [runspacefactory]::CreateRunspacePool(1, $MaxConcurrent)
        $al.Open()
        $em = @()
        foreach ($ip in $eb) {
            $bd = {
                param($IPAddress, $Timeout)
                try {
                    $ek = New-Object System.Net.NetworkInformation.Ping
                    $bz = $ek.Send($IPAddress, $Timeout)
                    if ($bz.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                        [PSCustomObject]@{
                            IP = $IPAddress
                            Success = $true
                            ResponseTime = $bz.RoundtripTime
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
            $bi = [powershell]::Create()
            $bi.RunspacePool = $al
            $bi.AddScript($bd).AddArgument($ip).AddArgument($TimeoutMs) | Out-Null
            $em += [PSCustomObject]@{
                PowerShell = $bi
                AsyncResult = $bi.BeginInvoke()
                IP = $ip
            }
        }
        foreach ($ep in $em) {
            try {
                $dx = $ep.PowerShell.EndInvoke($ep.AsyncResult)
                if ($dx) {
                    $do += $dx
                }
            } catch {
                $do += [PSCustomObject]@{
                    IP = $ep.IP
                    Success = $false
                    ResponseTime = 0
                    Status = "Error"
                }
            } finally {
                $ep.PowerShell.Dispose()
            }
        }
        $al.Close()
        $al.Dispose()
    }
    return $do
}
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
    $cu = $EndIP - $StartIP + 1
    $bk = $StartIP
    $ae = @()
    $ba = 0
    if ($DelayMs -gt 0) {
        Write-Host "  Starting parallel ping scan with $BatchSize IPs per batch (${DelayMs}ms delay between batches)" -ForegroundColor Yellow
    } else {
        Write-Host "  Starting parallel ping scan with $BatchSize IPs per batch" -ForegroundColor Yellow
    }
    while ($bk -le $EndIP) {
        if (Test-SkipKeyPressed) {
            Write-Host "    ⏭️  Skip key pressed - stopping parallel scan" -ForegroundColor Yellow
            break
        }
        $ba++
        $de = [Math]::Min($bk + $BatchSize - 1, $EndIP)
        $cs = @()
        for ($ec = $bk; $ec -le $de; $ec++) {
            $ct = ConvertTo-IPString -IPInt $ec
            if ($ct) {
                $cs += $ct
            }
        }
        if ($cs.Count -eq 0) {
            $bk = $de + 1
            continue
        }
        Write-Host "  Batch $ba`: Testing $($cs.Count) IPs ($(ConvertTo-IPString -IPInt $bk) - $(ConvertTo-IPString -IPInt $de))" -ForegroundColor Cyan
        $do = Invoke-ParallelPing -IPList $cs -TimeoutMs $TimeoutMs -MaxConcurrent 50
        if (Test-SkipKeyPressed) {
            Write-Host "    ⏭️  Skip key pressed - stopping parallel scan" -ForegroundColor Yellow
            break
        }
        $r = $do | Where-Object { $_.Success }
        if ($r.Count -gt 0) {
            Write-Host "    ✓ Found $($r.Count) responsive IPs in batch" -ForegroundColor Green
            foreach ($dx in $r) {
                $ae += $dx.IP
                $ap = [PSCustomObject]@{
                    IP = $dx.IP
                    Location = $LocationData
                    'Ping Time (ms)' = $dx.ResponseTime
                }
                $ap | Export-Csv -Path $OutputPath -Append -NoTypeInformation
                Write-Host "    ✓ $($dx.IP) - $($dx.ResponseTime) ms" -ForegroundColor Green
            }
        } else {
            Write-Host "    ✗ No responsive IPs found in batch" -ForegroundColor Red
            $am = $EndIP - $de
            if ($am -gt ($JumpSize + $BatchSize) -and $cu -gt ($JumpSize + $BatchSize)) {
                Write-Host "    🦘 Jumping $JumpSize IPs ahead due to no responses" -ForegroundColor Yellow
                $bk = $de + 1 + $JumpSize
                continue
            }
        }
        if ($DelayMs -gt 0 -and $bk -le $EndIP) {
            Start-Sleep -Milliseconds $DelayMs
        }
        $bk = $de + 1
    }
    return $ae
}
function Test-Port {
    param(
        [string]$IP,
        [int]$Port,
        [int]$TimeoutMs = 3000
    )
    try {
        $cb = New-Object System.Net.Sockets.TcpClient
        $az = $cb.ConnectAsync($IP, $Port)
        $dx = $az.Wait($TimeoutMs)
        if ($dx -and $cb.Connected) {
            $cb.Close()
            return @{ Status = "Open"; Type = "Connected" }
        } else {
            $cb.Close()
            if ($az.Exception -and $az.Exception.InnerException -match "refused|reset") {
                return @{ Status = "Closed"; Type = "Refused" }
            } else {
                return @{ Status = "Closed"; Type = "Timeout" }
            }
        }
    } catch [System.Net.Sockets.SocketException] {
        if ($_.Exception.Message -match "refused|reset") {
            return @{ Status = "Closed"; Type = "Refused" }
        } else {
            return @{ Status = "Closed"; Type = "Timeout" }
        }
    } catch {
        return @{ Status = "Closed"; Type = "Timeout" }
    }
}
function Test-PortScan {
    param(
        [string]$IP,
        [string]$PortList,
        [int]$TimeoutMs = 3000
    )
    $cc = @()
    $aj = @()
    $ac = @()
    $ports = $PortList -split ','
    foreach ($port in $ports) {
        $dj = [int]$port.Trim()
        $bj = Test-Port -IP $IP -Port $dj -TimeoutMs $TimeoutMs
        if ($bj.Status -eq "Open") {
            $cc += $dj
        } elseif ($bj.Type -eq "Refused") {
            $aj += $dj
        } else {
            $ac += $dj
        }
    }
    return @{
        Open = $cc
        Refused = $aj
        Timeout = $ac
    }
}
function Test-NetworkConnectivity {
    param(
        [bool]$Interactive = $true
    )
    $f = [PSCustomObject]@{
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
    Write-Host "[1/6] Checking IPv4 Configuration..." -ForegroundColor Yellow
    $as = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.IPAddress -notmatch "^127\." -and $_.PrefixOrigin -ne "WellKnown"
    }
    if ($as) {
        $bf = $as | Select-Object -First 1
        $f.IPv4Address = $bf.IPAddress
        Write-Host "  ✓ IPv4 Address Found: $($bf.IPAddress)" -ForegroundColor Green
        $ce = Get-NetRoute -AddressFamily IPv4 -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($ce) {
            $f.IPv4Gateway = $ce.NextHop
            Write-Host "  ✓ IPv4 Gateway: $($ce.NextHop)" -ForegroundColor Green
            Write-Host "  → Testing IPv4 gateway connectivity..." -ForegroundColor Gray
            $dz = Invoke-QuickPing -IP $ce.NextHop -TimeoutMs 2000
            if ($dz.Success) {
                Write-Host "  ✓ IPv4 Gateway Ping: Success ($($dz.ResponseTime)ms)" -ForegroundColor Green
                $f.IPv4Ready = $true
            } else {
                Write-Host "  ✗ IPv4 Gateway Ping: Failed ($($dz.Status))" -ForegroundColor Red
                $f.Issues += "IPv4 gateway not responding"
            }
        } else {
            Write-Host "  ✗ No IPv4 Gateway Found" -ForegroundColor Red
            $f.Issues += "No IPv4 default gateway configured"
        }
    } else {
        Write-Host "  ✗ No IPv4 Address Assigned" -ForegroundColor Red
        $f.Issues += "No IPv4 address assigned to network adapter"
    }
    Write-Host "`n[2/6] Checking IPv6 Configuration..." -ForegroundColor Yellow
    $au = Get-NetIPAddress -AddressFamily IPv6 | Where-Object {
        $_.IPAddress -notmatch "^fe80:" -and $_.PrefixOrigin -ne "WellKnown"
    }
    if ($au) {
        $ax = $au | Select-Object -First 1
        $f.IPv6Address = $ax.IPAddress
        Write-Host "  ✓ IPv6 Address Found: $($ax.IPAddress)" -ForegroundColor Green
        $cd = Get-NetRoute -AddressFamily IPv6 -DestinationPrefix "::/0" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cd) {
            $f.IPv6Gateway = $cd.NextHop
            Write-Host "  ✓ IPv6 Gateway: $($cd.NextHop)" -ForegroundColor Green
            Write-Host "  → Testing IPv6 gateway connectivity..." -ForegroundColor Gray
            $dz = Invoke-QuickPing -IP $cd.NextHop -TimeoutMs 2000
            if ($dz.Success) {
                Write-Host "  ✓ IPv6 Gateway Ping: Success ($($dz.ResponseTime)ms)" -ForegroundColor Green
                $f.IPv6Ready = $true
            } else {
                Write-Host "  ✗ IPv6 Gateway Ping: Failed ($($dz.Status))" -ForegroundColor Red
                $f.Issues += "IPv6 gateway not responding"
            }
        } else {
            Write-Host "  ✗ No IPv6 Gateway Found" -ForegroundColor Red
            $f.Issues += "No IPv6 default gateway configured"
        }
    } else {
        Write-Host "  ✗ No IPv6 Address Assigned (Link-local only)" -ForegroundColor Red
        $f.Issues += "No global IPv6 address assigned to network adapter"
    }
    Write-Host "`n[3/6] Testing DNS Resolution..." -ForegroundColor Yellow
    $bu = Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object -First 1
    if ($bu) {
        Write-Host "  ✓ DNS Servers Configured: $($bu.ServerAddresses -join ', ')" -ForegroundColor Green
        try {
            $dl = Resolve-DnsName -Name "one.one.one.one" -Type A -ErrorAction Stop
            Write-Host "  ✓ DNS Resolution: Working" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ DNS Resolution: Failed" -ForegroundColor Red
            $f.Issues += "DNS resolution not working"
        }
    } else {
        Write-Host "  ✗ No DNS Servers Configured" -ForegroundColor Red
        $f.Issues += "No DNS servers configured"
    }
    Write-Host "`n[4/6] Testing External Connectivity (1.1.1.1)..." -ForegroundColor Yellow
    $bw = $false
    $ak = $false
    if ($f.IPv4Ready) {
        Write-Host "  → Pinging 1.1.1.1 (Cloudflare DNS)..." -ForegroundColor Gray
        $ds = Invoke-QuickPing -IP "1.1.1.1" -TimeoutMs 3000
        if ($ds.Success) {
            Write-Host "  ✓ IPv4 Internet Connectivity: Success ($($ds.ResponseTime)ms)" -ForegroundColor Green
            $f.CanScanIPv4 = $true
        } else {
            Write-Host "  ✗ IPv4 Internet Connectivity: Failed ($($ds.Status))" -ForegroundColor Red
            $f.Issues += "Cannot reach external IPv4 hosts (1.1.1.1 unreachable)"
            $f.CanScanIPv4 = $false
            $ak = $true
        }
        if ($Interactive) {
            Write-Host "`n  Would you like to run traceroute to 1.1.1.1? (Y/n) [Default: Y]" -ForegroundColor Cyan
            Write-Host "  Command: tracert -d -w 1500 1.1.1.1" -ForegroundColor Gray
            $cp = Read-Host "  Your choice"
            if ([string]::IsNullOrWhiteSpace($cp)) { $cp = 'Y' }
            if ($cp -eq 'Y' -or $cp -eq 'y') {
                Write-Host "`n  Running traceroute... (Press Ctrl+C to cancel)`n" -ForegroundColor Cyan
                & tracert -d -w 1500 1.1.1.1 | Out-Host
                Write-Host ""
                $bw = $true
            }
        }
    } else {
        Write-Host "  ⊗ Skipped (No IPv4 connectivity)" -ForegroundColor Gray
    }
    if ($f.IPv6Ready) {
        Write-Host "  → Pinging 2606:4700:4700::1111 (Cloudflare DNS IPv6)..." -ForegroundColor Gray
        $di = Invoke-QuickPing -IP "2606:4700:4700::1111" -TimeoutMs 3000
        if ($di.Success) {
            Write-Host "  ✓ IPv6 Internet Connectivity: Success ($($di.ResponseTime)ms)" -ForegroundColor Green
            $f.CanScanIPv6 = $true
        } else {
            Write-Host "  ✗ IPv6 Internet Connectivity: Failed ($($di.Status))" -ForegroundColor Red
            $f.Issues += "Cannot reach external IPv6 hosts"
        }
    } else {
        Write-Host "  ⊗ IPv6 External Test Skipped (No IPv6 connectivity)" -ForegroundColor Gray
    }
    Write-Host "`n[5/6] Testing DCI DNS Connectivity (217.218.155.155)..." -ForegroundColor Yellow
    if ($f.IPv4Ready) {
        $dr = Invoke-QuickPing -IP "217.218.155.155" -TimeoutMs 3000
        if ($dr.Success) {
            Write-Host "  ✓ DCI DNS: Reachable ($($dr.ResponseTime)ms)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ DCI DNS: Unreachable ($($dr.Status))" -ForegroundColor Red
        }
        if ($Interactive -and $ak) {
            Write-Host "`n  Would you like to run traceroute to DCI DNS? (Y/n) [Default: Y]" -ForegroundColor Cyan
            Write-Host "  Command: tracert -d -w 1500 217.218.155.155" -ForegroundColor Gray
            $cp = Read-Host "  Your choice"
            if ([string]::IsNullOrWhiteSpace($cp)) { $cp = 'Y' }
            if ($cp -eq 'Y' -or $cp -eq 'y') {
                Write-Host "`n  Running traceroute... (Press Ctrl+C to cancel)`n" -ForegroundColor Cyan
                & tracert -d -w 1500 217.218.155.155 | Out-Host
                Write-Host ""
            }
        }
    } else {
        Write-Host "  ⊗ Skipped (No IPv4 connectivity)" -ForegroundColor Gray
    }
    Write-Host "`n[6/6] Connectivity Summary..." -ForegroundColor Yellow
    Write-Host "  ════════════════════════════════════════════════" -ForegroundColor Cyan
    if ($f.CanScanIPv4) {
        Write-Host "  ✓ IPv4 Scanning: READY" -ForegroundColor Green
    } else {
        Write-Host "  ✗ IPv4 Scanning: NOT AVAILABLE" -ForegroundColor Red
    }
    if ($f.CanScanIPv6) {
        Write-Host "  ✓ IPv6 Scanning: READY" -ForegroundColor Green
    } else {
        Write-Host "  ✗ IPv6 Scanning: NOT AVAILABLE" -ForegroundColor Red
    }
    if ($f.Issues.Count -gt 0) {
        Write-Host "`n  ⚠️  Issues Detected:" -ForegroundColor Yellow
        foreach ($eh in $f.Issues) {
            Write-Host "     • $eh" -ForegroundColor Yellow
        }
    }
    Write-Host "  ════════════════════════════════════════════════" -ForegroundColor Cyan
    if (-not $f.CanScanIPv4 -and -not $f.CanScanIPv6) {
        Write-Host "`n  ✗ CRITICAL: No network connectivity available for scanning!" -ForegroundColor Red
        if ($Interactive) {
            Write-Host "`n  Options:" -ForegroundColor Yellow
            Write-Host "    1. Fix network issues and restart script" -ForegroundColor Gray
            Write-Host "    2. Continue anyway (scanning will fail)" -ForegroundColor Gray
            Write-Host "    3. Exit script [Default]" -ForegroundColor Gray
            $du = Read-Host "`n  Your choice (1/2/3)"
            if ([string]::IsNullOrWhiteSpace($du)) { $du = '3' }
            if ($du -eq '3') {
                Write-Host "`n  Exiting script..." -ForegroundColor Yellow
                exit 0
            } elseif ($du -eq '1') {
                Write-Host "`n  Please fix network connectivity and restart the script." -ForegroundColor Yellow
                exit 0
            } else {
                Write-Host "`n  ⚠️  Continuing with limited connectivity..." -ForegroundColor Yellow
            }
        }
    } elseif (-not $f.CanScanIPv4 -or -not $f.CanScanIPv6) {
        Write-Host "`n  ⚠️  WARNING: Partial connectivity detected!" -ForegroundColor Yellow
        if (-not $f.CanScanIPv4) {
            Write-Host "    → IPv4 scanning will be skipped or may fail" -ForegroundColor Yellow
        }
        if (-not $f.CanScanIPv6) {
            Write-Host "    → IPv6 scanning will be skipped or may fail" -ForegroundColor Yellow
        }
        if ($Interactive) {
            Write-Host "`n  Continue with limited connectivity? (Y/n) [Default: Y]" -ForegroundColor Yellow
            $cp = Read-Host "  Your choice"
            if ([string]::IsNullOrWhiteSpace($cp)) { $cp = 'Y' }
            if ($cp -ne 'Y' -and $cp -ne 'y') {
                Write-Host "`n  Exiting script..." -ForegroundColor Yellow
                exit 0
            }
        }
    } else {
        Write-Host "`n  ✓ Network connectivity check passed! Ready to scan." -ForegroundColor Green
    }
    Write-Host ""
    return $f
}
function Invoke-QuickPing {
    param(
        [string]$IP,
        [int]$TimeoutMs
    )
    try {
        $dq = New-Object System.Net.NetworkInformation.Ping
        $bz = $dq.Send($IP, $TimeoutMs)
        if ($bz.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
            return [PSCustomObject]@{
                Success = $true
                ResponseTime = $bz.RoundtripTime
                Status = "Success"
            }
        } else {
            return [PSCustomObject]@{
                Success = $false
                ResponseTime = 0
                Status = $bz.Status.ToString()
            }
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            ResponseTime = 0
            Status = "Error: $($_.Exception.Message)"
        }
    }
}
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
function Save-ScanResult {
    param(
        [string]$IP,
        [string]$ScanMode,
        [object]$ScanResult,
        [string]$OutputPath
    )
    $ap = $null
    if ($ScanMode -eq "ping") {
        $ap = [PSCustomObject]@{
            IP = $IP
            Location = $ScanResult.Location
            'Ping Time (ms)' = $ScanResult.PingTime
        }
    } elseif ($ScanMode -eq "port") {
        $ap = [PSCustomObject]@{
            IP = $IP
            Location = $ScanResult.Location
            'Ports Open' = $ScanResult.PortsOpen
            'Service Status' = $ScanResult.ServiceStatus
        }
    } elseif ($ScanMode -eq "both") {
        $ap = [PSCustomObject]@{
            IP = $IP
            Location = $ScanResult.Location
            'Ping Result' = $ScanResult.PingResult
            'Ping Time (ms)' = $ScanResult.PingTime
            'Ports Open' = $ScanResult.PortsOpen
            'Service Status' = $ScanResult.ServiceStatus
            'Network Status' = $ScanResult.NetworkStatus
        }
    }
    if ($ap) {
        $ap | Export-Csv -Path $OutputPath -Append -NoTypeInformation
    }
}
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
    $bn = @()
    $cf = 0
    $c = $false
    if ($Range.IPVersion -eq 4) {
        $q = $Range.StartIP
        while ($q -le $Range.EndIP -and -not $c) {
            if (Test-SkipKeyPressed) {
                Write-Host "  ⏭️  Skip key pressed - skipping remaining IPs in range $IPRange" -ForegroundColor Yellow
                break
            }
            $bo = [Math]::Min($q + $MaxFailures - 1, $Range.EndIP)
            $av = 0
            for ($ec = $q; $ec -le $bo; $ec++) {
                $by = ConvertTo-IPString -IPInt $ec
                if ($null -eq $by) { continue }
                Write-Host "  Scanning: $by" -ForegroundColor Cyan
                $scanResult = Invoke-NetworkScan -IP $by -ScanMode $ScanMode -PingTimeoutMs $Timeout -PortList $Ports -PortTimeoutMs $PortTimeout -LocationData $LocationData
                $isSuccessful = Test-ScanSuccess -ScanMode $ScanMode -ScanResult $scanResult
                if (-not $isSuccessful) {
                    $av++
                    Write-ScanResult -IP $by -IsSuccessful $false -ScanMode $ScanMode -ScanResult $scanResult
                } else {
                    Write-ScanResult -IP $by -IsSuccessful $true -ScanMode $ScanMode -ScanResult $scanResult
                    $bn += $by
                    Save-ScanResult -IP $by -ScanMode $ScanMode -ScanResult $scanResult -OutputPath $OutputPath
                    if ($MaxResponses -gt 0 -and $bn.Count -ge $MaxResponses) {
                        Write-Host "  Reached maximum responses ($MaxResponses) for range $IPRange - skipping remaining IPs" -ForegroundColor Yellow
                        $c = $true
                        break
                    }
                }
            }
            if ($av -ge $MaxFailures) {
                if ($Jump -gt 0) {
                    $cf++
                    if ($cf -ge $Skip) {
                        Write-Host "  Reached jump limit ($Skip jumps) - skipping remaining IPs in range $IPRange" -ForegroundColor Red
                        break
                    }
                    Write-Host "  Jumping $Jump IPs due to $av/$MaxFailures consecutive timeouts (jump #$cf)" -ForegroundColor Yellow
                    $q = $bo + 1 + $Jump
                } else {
                    Write-Host "  Skipping remaining IPs in range $IPRange due to $av/$MaxFailures consecutive timeouts" -ForegroundColor Red
                    break
                }
            } else {
                $q = $bo + 1
            }
        }
    } else {
        $q = $Range.StartIP
        $bc = 65536
        $ed = 0
        $b = 0
        while ((Compare-IPv6Address -Address1 $q -Address2 $Range.EndIP) -le 0 -and $ed -lt $bc -and -not $c) {
            if (Test-SkipKeyPressed) {
                Write-Host "  ⏭️  Skip key pressed - skipping remaining IPs in IPv6 range $IPRange" -ForegroundColor Yellow
                break
            }
            $ar = ConvertTo-IPString -IPBytes $q
            if ($null -eq $ar) {
                $q = Add-IPv6Address -IPBytes $q -Increment 1
                $ed++
                continue
            }
            Write-Host "  Scanning: $ar" -ForegroundColor Cyan
            $scanResult = Invoke-NetworkScan -IP $ar -ScanMode $ScanMode -PingTimeoutMs $Timeout -PortList $Ports -PortTimeoutMs $PortTimeout -LocationData $LocationData
            $isSuccessful = Test-ScanSuccess -ScanMode $ScanMode -ScanResult $scanResult
            if ($isSuccessful) {
                $b = 0
                Write-ScanResult -IP $ar -IsSuccessful $true -ScanMode $ScanMode -ScanResult $scanResult
                $bn += $ar
                Save-ScanResult -IP $ar -ScanMode $ScanMode -ScanResult $scanResult -OutputPath $OutputPath
                if ($MaxResponses -gt 0 -and $bn.Count -ge $MaxResponses) {
                    Write-Host "  Reached maximum responses ($MaxResponses) for range $IPRange - skipping remaining IPs" -ForegroundColor Yellow
                    $c = $true
                    break
                }
            } else {
                $b++
                Write-ScanResult -IP $ar -IsSuccessful $false -ScanMode $ScanMode -ScanResult $scanResult
                if ($b -ge $MaxFailures) {
                    if ($Jump -gt 0) {
                        $cf++
                        if ($cf -ge $Skip) {
                            Write-Host "  Reached jump limit ($Skip jumps) - skipping remaining IPs in range $IPRange" -ForegroundColor Red
                            break
                        }
                        Write-Host "  Jumping $Jump IPs due to $b/$MaxFailures consecutive failures (jump #$cf)" -ForegroundColor Yellow
                        $q = Add-IPv6Address -IPBytes $q -Increment $Jump
                        $ed += $Jump
                        $b = 0
                        continue
                    } else {
                        Write-Host "  Skipping remaining IPs in range $IPRange due to $b/$MaxFailures consecutive failures" -ForegroundColor Red
                        break
                    }
                }
            }
            $q = Add-IPv6Address -IPBytes $q -Increment 1
            $ed++
        }
    }
    return $bn
}
function Invoke-NetworkScan {
    param(
        [string]$IP,
        [string]$ScanMode,
        [int]$PingTimeoutMs,
        [string]$PortList,
        [int]$PortTimeoutMs,
        [string]$LocationData,
        [bool]$SkipPing = $false
    )
    $dx = [PSCustomObject]@{
        IP = $IP
        Location = $LocationData
        PingResult = "Not Tested"
        PingTime = "N/A"
        PortsOpen = "Not Tested"
        ServiceStatus = "Unknown"
        NetworkStatus = "Normal"
    }
    $t = $false
    $ca = @()
    if (($ScanMode -eq "ping" -or $ScanMode -eq "both") -and -not $SkipPing) {
        $dw = $IP -match ':'
        if ($cx -and -not $dw) {
            $ek = Test-Connection -ComputerName $IP -Count 1 -TimeoutSeconds ($PingTimeoutMs / 1000) -ErrorAction SilentlyContinue
        } else {
            try {
                $dq = New-Object System.Net.NetworkInformation.Ping
                $bz = $dq.Send($IP, $PingTimeoutMs)
                if ($bz.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                    $ek = [PSCustomObject]@{
                        ResponseTime = $bz.RoundtripTime
                        Status = "Success"
                    }
                } else {
                    $ek = $null
                }
            } catch {
                $ek = $null
            }
        }
        if ($ek) {
            $t = $true
            $dx.PingResult = "Success"
            $dx.PingTime = $ek.ResponseTime
        } else {
            $dx.PingResult = "Failed"
            $dx.PingTime = "Timeout"
        }
    } elseif ($SkipPing) {
        $dx.PingResult = "Failed"
        $dx.PingTime = "Timeout"
    }
    $z = $false
    if ($ScanMode -eq "port") {
        $z = $true
    } elseif ($ScanMode -eq "both") {
        $z = -not $t
    }
    if ($z) {
        $v = Test-PortScan -IP $IP -PortList $PortList -TimeoutMs $PortTimeoutMs
        $ca = $v.Open
        $at = $v.Refused
        $aw = $v.Timeout
        if ($ca.Count -gt 0) {
            $dx.PortsOpen = ($ca -join ',')
            $dx.ServiceStatus = "Accessible"
        } else {
            $dx.PortsOpen = "None"
            if ($at.Count -gt 0) {
                $dx.ServiceStatus = "Refused"
            } else {
                $dx.ServiceStatus = "Unavailable"
            }
        }
    }
    if ($ScanMode -eq "both") {
        if ($t -and $ca.Count -eq 0) {
            $dx.NetworkStatus = "Normal"
            $dx.ServiceStatus = "Ping-Responsive"
        } elseif (-not $t -and $ca.Count -gt 0) {
            $dx.NetworkStatus = "ICMP-Blocked"
            $dx.ServiceStatus = "Services-Only"
        } elseif (-not $t -and $ca.Count -eq 0) {
            if ($at.Count -gt 0) {
                $dx.NetworkStatus = "ICMP-Blocked"
                $dx.ServiceStatus = "Services-Refused"
            } elseif ($aw.Count -gt 0) {
                $dx.NetworkStatus = "Unassigned-Range"
                $dx.ServiceStatus = "No-Response"
            } else {
                $dx.NetworkStatus = "Unassigned-Range"
                $dx.ServiceStatus = "No-Response"
            }
        } else {
            $dx.NetworkStatus = "Normal"
        }
    }
    return $dx
}
function Get-ServiceName {
    param([int]$Port)
    $cy = @{
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
    if ($cy.ContainsKey($Port)) {
        return $cy[$Port]
    } else {
        return "Port-$Port"
    }
}
Write-Host "`nLooking for input file at: $ci" -ForegroundColor Cyan
if (-not (Test-Path -Path $ci)) {
    Write-Error "Input file not found at: $ci"
    exit 1
}
$ai = Test-NetworkConnectivity -Interactive $true
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
Write-Host "Network Status: IPv4=$($ai.CanScanIPv4) | IPv6=$($ai.CanScanIPv6)" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "💡 Tip: Press 'S' at any time during scanning to skip the current range" -ForegroundColor Cyan
Write-Host ""
if ($ScanMode -eq "ping" -or $ScanMode -eq "parallel") {
    "IP,Location,Ping Time (ms)" | Out-File -FilePath $outputPath -Encoding utf8
} elseif ($ScanMode -eq "port") {
    "IP,Location,Ports Open,Service Status" | Out-File -FilePath $outputPath -Encoding utf8
} else {
    "IP,Location,Ping Result,Ping Time (ms),Ports Open,Service Status,Network Status" | Out-File -FilePath $outputPath -Encoding utf8
}
Write-Host "Starting to read input file..."
$dc = Import-Csv -Path $ci -Header IP,Location,Region,City,PostalCode
foreach ($eg in $dc) {
    $ipRange = $eg.IP
    if ([string]::IsNullOrWhiteSpace($ipRange) -or $ipRange.StartsWith('#')) {
        continue
    }
    Write-Host "Processing IP Range: $ipRange" -ForegroundColor Cyan
    Write-Host "  💡 Press 'S' key anytime to skip this range" -ForegroundColor Gray
    if ($ipRange -match "/") {
        $baseIP = $ipRange.Split("/")[0]
        $dy = [int]$ipRange.Split("/")[1]
        $bx = $ipRange
    } else {
        $baseIP = $ipRange
        $cj = Get-IPVersion -IPAddress $baseIP
        if ($cj -eq 4) {
            $dy = 32
            $bx = "$ipRange/32"
            Write-Host "Note: Single IPv4 address detected - using /32 subnet"
        } elseif ($cj -eq 6) {
            $dy = 128
            $bx = "$ipRange/128"
            Write-Host "Note: Single IPv6 address detected - using /128 subnet"
        } else {
            Write-Host "[ERROR] Invalid IP address format: $baseIP"
            continue
        }
    }
    try {
        $null = [System.Net.IPAddress]::Parse($baseIP)
    } catch {
        Write-Host "[ERROR] Invalid IP address format: $baseIP"
        continue
    }
    $range = Get-IPRange -BaseIP $baseIP -CIDRSuffix $dy
    if ($null -eq $range) {
        Write-Host "[ERROR] Failed to calculate range for: $ipRange"
        continue
    }
    if ($range.IPVersion -eq 4 -and -not $ai.CanScanIPv4) {
        Write-Host "[SKIPPED] IPv4 range detected but IPv4 connectivity is not available" -ForegroundColor Yellow
        Write-Host "          Range: $ipRange" -ForegroundColor Yellow
        Write-Host "          Reason: $($ai.Issues | Where-Object { $_ -like '*IPv4*' } | Select-Object -First 1)" -ForegroundColor Yellow
        Write-Host ""
        continue
    }
    if ($range.IPVersion -eq 6 -and -not $ai.CanScanIPv6) {
        Write-Host "[SKIPPED] IPv6 range detected but IPv6 connectivity is not available" -ForegroundColor Yellow
        Write-Host "          Range: $ipRange" -ForegroundColor Yellow
        Write-Host "          Reason: $($ai.Issues | Where-Object { $_ -like '*IPv6*' } | Select-Object -First 1)" -ForegroundColor Yellow
        Write-Host ""
        continue
    }
    $bn = @()
    $cf = 0
    $c = $false
    if ($range.IPVersion -eq 6) {
        $cu = $range.TotalIPs
        $bc = 65536
        if ($range.HostBits -gt 16) {
            Write-Host "[WARNING] IPv6 range /$dy is very large (2^$($range.HostBits) addresses)" -ForegroundColor Yellow
            Write-Host "          Limiting scan to first $bc addresses for safety" -ForegroundColor Yellow
            $ay = $true
        } else {
            $ay = $false
        }
        $q = $range.StartIP
        $bl = ConvertTo-IPString -IPBytes $range.StartIP
        $db = ConvertTo-IPString -IPBytes $range.EndIP
        if ($ay) {
            Write-Host "  IPv6 Range: $bl to $db (scanning first $bc)" -ForegroundColor Yellow
        } else {
            Write-Host "  IPv6 Range: $bl to $db ($cu addresses)" -ForegroundColor Yellow
        }
    } else {
        $cu = $range.TotalIPs
        $q = $range.StartIP
        Write-Host "  Range contains $cu IPs (from $(ConvertTo-IPString -IPInt $range.StartIP) to $(ConvertTo-IPString -IPInt $range.EndIP))" -ForegroundColor Yellow
    }
    if ($Jump -gt 0) {
        Write-Host "  Jump mode enabled: will skip $Jump IPs after $MaxFailures failures (skip range after $Skip jumps)" -ForegroundColor Yellow
    }
    if ($MaxResponses -gt 0) {
        Write-Host "  Response limit enabled: will skip range after $MaxResponses successful responses" -ForegroundColor Yellow
    }    Write-Host "  Testing first $MaxFailures IPs for connectivity..." -ForegroundColor Yellow
    if ($ScanMode -eq "parallel") {
        Write-Host "  Using parallel ping mode with batch processing" -ForegroundColor Yellow
        if ($range.IPVersion -eq 4) {
            $bn = Invoke-BatchParallelPing -StartIP $range.StartIP -EndIP $range.EndIP -TimeoutMs $Timeout -BatchSize 256 -JumpSize 1024 -DelayMs $DelayMs -LocationData "$($eg.Location),$($eg.Region),$($eg.City),$($eg.PostalCode)" -OutputPath $outputPath
        } else {
            Write-Host "  Building IPv6 address list for parallel scanning..." -ForegroundColor Yellow
            $eb = @()
            $by = $range.StartIP
            $bc = 65536
            $ed = 0
            while ((Compare-IPv6Address -Address1 $by -Address2 $range.EndIP) -le 0 -and $ed -lt $bc) {
                if (Test-SkipKeyPressed) {
                    Write-Host "  ⏭️  Skip key pressed - stopping IPv6 address list build" -ForegroundColor Yellow
                    break
                }
                $ej = ConvertTo-IPString -IPBytes $by
                $eb += $ej
                $by = Add-IPv6Address -IPBytes $by -Increment 1
                $ed++
            }
            Write-Host "  Testing $($eb.Count) IPv6 addresses in parallel..." -ForegroundColor Yellow
            $do = Invoke-ParallelPing -IPList $eb -TimeoutMs $Timeout -MaxConcurrent 50
            $er = $do | Where-Object { $_.Success }
            foreach ($dx in $er) {
                $bn += $dx.IP
                $ap = [PSCustomObject]@{
                    IP = $dx.IP
                    Location = "$($eg.Location),$($eg.Region),$($eg.City),$($eg.PostalCode)"
                    'Ping Time (ms)' = $dx.ResponseTime
                }
                $ap | Export-Csv -Path $outputPath -Append -NoTypeInformation
                Write-Host "  ✓ $($dx.IP) - $($dx.ResponseTime) ms" -ForegroundColor Green
            }
        }
    } else {
        $u = @()
        $ah = @()
        if ($ScanMode -eq "both") {
            Write-Host "  Phase 1: Quick ping sweep to identify responsive hosts" -ForegroundColor Yellow
            if ($range.IPVersion -eq 4) {
                for ($ec = $range.StartIP; $ec -le $range.EndIP; $ec++) {
                    if (Test-SkipKeyPressed) {
                        Write-Host "  ⏭️  Skip key pressed - stopping ping sweep for current range" -ForegroundColor Yellow
                        break
                    }
                    if ($MaxResponses -gt 0 -and $bn.Count -ge $MaxResponses) {
                        Write-Host "  Reached maximum responses ($MaxResponses) - stopping ping sweep" -ForegroundColor Yellow
                        break
                    }
                    $by = ConvertTo-IPString -IPInt $ec
                    if ($null -eq $by) { continue }
                    $bm = $null
                    try {
                        $dq = New-Object System.Net.NetworkInformation.Ping
                        $bz = $dq.Send($by, $Timeout)
                        if ($bz.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                            $bm = [PSCustomObject]@{
                                ResponseTime = $bz.RoundtripTime
                                Status = "Success"
                            }
                        }
                    } catch {
                        $bm = $null
                    }
                    if ($bm) {
                        $u += $by
                        $bn += $by
                        $ap = [PSCustomObject]@{
                            IP = $by
                            Location = "$($eg.Location),$($eg.Region),$($eg.City),$($eg.PostalCode)"
                            'Ping Result' = "Success"
                            'Ping Time (ms)' = $bm.ResponseTime
                            'Ports Open' = "N/A"
                            'Service Status' = "Ping-Responsive"
                            'Network Status' = "Normal"
                        }
                        $ap | Export-Csv -Path $outputPath -Append -NoTypeInformation
                        Write-Host "  ✓ $by - $($bm.ResponseTime) ms (ping responsive)" -ForegroundColor Green
                    } else {
                        $ah += $by
                    }
                }
            } else {
                $by = $range.StartIP
                $bc = 65536
                $ed = 0
                while ((Compare-IPv6Address -Address1 $by -Address2 $range.EndIP) -le 0 -and $ed -lt $bc) {
                    if (Test-SkipKeyPressed) {
                        Write-Host "  ⏭️  Skip key pressed - stopping IPv6 ping sweep for current range" -ForegroundColor Yellow
                        break
                    }
                    if ($MaxResponses -gt 0 -and $bn.Count -ge $MaxResponses) {
                        Write-Host "  Reached maximum responses ($MaxResponses) - stopping ping sweep" -ForegroundColor Yellow
                        break
                    }
                    $ar = ConvertTo-IPString -IPBytes $by
                    if ($null -eq $ar) {
                        $by = Add-IPv6Address -IPBytes $by -Increment 1
                        $ed++
                        continue
                    }
                    $bm = $null
                    try {
                        $dq = New-Object System.Net.NetworkInformation.Ping
                        $bz = $dq.Send($ar, $Timeout)
                        if ($bz.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                            $bm = [PSCustomObject]@{
                                ResponseTime = $bz.RoundtripTime
                                Status = "Success"
                            }
                        }
                    } catch {
                        $bm = $null
                    }
                    if ($bm) {
                        $u += $ar
                        $bn += $ar
                        $ap = [PSCustomObject]@{
                            IP = $ar
                            Location = "$($eg.Location),$($eg.Region),$($eg.City),$($eg.PostalCode)"
                            'Ping Result' = "Success"
                            'Ping Time (ms)' = $bm.ResponseTime
                            'Ports Open' = "N/A"
                            'Service Status' = "Ping-Responsive"
                            'Network Status' = "Normal"
                        }
                        $ap | Export-Csv -Path $outputPath -Append -NoTypeInformation
                        Write-Host "  ✓ $ar - $($bm.ResponseTime) ms (ping responsive)" -ForegroundColor Green
                    } else {
                        $ah += $ar
                    }
                    $by = Add-IPv6Address -IPBytes $by -Increment 1
                    $ed++
                }
            }
            Write-Host "  Phase 1 complete: $($u.Count) ping responders, $($ah.Count) non-responders" -ForegroundColor Cyan
            if ($ah.Count -gt 0) {
                Write-Host "  Phase 2: Port scanning non-responders for service detection" -ForegroundColor Yellow
                foreach ($ip in $ah) {
                    if (Test-SkipKeyPressed) {
                        Write-Host "  ⏭️  Skip key pressed - stopping port scan for current range" -ForegroundColor Yellow
                        break
                    }
                    if ($MaxResponses -gt 0 -and $bn.Count -ge $MaxResponses) {
                        Write-Host "  Reached maximum responses ($MaxResponses) - stopping port scan" -ForegroundColor Yellow
                        break
                    }
                    $scanResult = Invoke-NetworkScan -IP $ip -ScanMode $ScanMode -PingTimeoutMs $Timeout -PortList $Ports -PortTimeoutMs $PortTimeout -LocationData "$($eg.Location),$($eg.Region),$($eg.City),$($eg.PostalCode)" -SkipPing $true
                    if ($scanResult.PortsOpen -ne "None" -and $scanResult.PortsOpen -ne "Not Tested") {
                        $bn += $ip
                        $ap = [PSCustomObject]@{
                            IP = $ip
                            Location = $scanResult.Location
                            'Ping Result' = $scanResult.PingResult
                            'Ping Time (ms)' = $scanResult.PingTime
                            'Ports Open' = $scanResult.PortsOpen
                            'Service Status' = $scanResult.ServiceStatus
                            'Network Status' = $scanResult.NetworkStatus
                        }
                        $ap | Export-Csv -Path $outputPath -Append -NoTypeInformation
                        Write-Host "  ✓ $ip - Ports: $($scanResult.PortsOpen) [STATUS: $($scanResult.NetworkStatus)]" -ForegroundColor Green
                    }
                }
            }
        } else {
            $bn = Invoke-UnifiedScan `
                -Range $range `
                -ScanMode $ScanMode `
                -Timeout $Timeout `
                -Ports $Ports `
                -PortTimeout $PortTimeout `
                -MaxFailures $MaxFailures `
                -Jump $Jump `
                -Skip $Skip `
                -MaxResponses $MaxResponses `
                -LocationData "$($eg.Location),$($eg.Region),$($eg.City),$($eg.PostalCode)" `
                -OutputPath $outputPath `
                -IPRange $ipRange
        }
    }
    if ($bn.Count -gt 0) {
        if ($range.IPVersion -eq 6 -and $range.HostBits -gt 16) {
            Write-Host "✓ Range ${cidrRange}: $($bn.Count) IPs reachable (limited scan)" -ForegroundColor Green
        } else {
            Write-Host "✓ Range ${cidrRange}: $($bn.Count)/$cu IPs reachable" -ForegroundColor Green
        }
        if ($cf -gt 0) {
            Write-Host "  └─ Used $cf jump(s) during scan" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "✗ Range ${cidrRange}: No reachable IPs found" -ForegroundColor Red
        if ($cf -gt 0) {
            Write-Host "  └─ Used $cf jump(s) during scan" -ForegroundColor Cyan
        }
    }
}
Write-Host "Script completed. Results saved to '$outputPath'." -ForegroundColor Green
Write-Host ""
if ($n) {
    Write-Host "Press Enter to exit..." -ForegroundColor Yellow
    Read-Host | Out-Null
}