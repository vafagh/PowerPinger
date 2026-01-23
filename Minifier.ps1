#Requires -Version 5.0

$sourceFile = Join-Path $PSScriptRoot "powerPinger.ps1"
$minifiedFile = Join-Path $PSScriptRoot "powerPinger_min.ps1"
$zipFile = Join-Path $PSScriptRoot "powerPinger.zip"

Write-Host ""
Write-Host "PowerPinger Script Minifier" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $sourceFile)) {
    Write-Error "Source file not found: $sourceFile"
    exit 1
}

Write-Host "[1/4] Reading source file..." -ForegroundColor Yellow
$originalSize = (Get-Item $sourceFile).Length
Write-Host "  Original size: $([math]::Round($originalSize/1KB, 2)) KB" -ForegroundColor Gray

$content = Get-Content $sourceFile -Raw

Write-Host ""
Write-Host "[2/4] Minifying script..." -ForegroundColor Yellow

$originalLines = ($content -split "`n").Count
Write-Host "  Original lines: $originalLines" -ForegroundColor Gray

# Remove multi-line comments
$content = $content -replace '(?s)<#.*?#>', ''

# Process lines
$lines = $content -split "`n"
$processedLines = @()

foreach ($line in $lines) {
    # Preserve #Requires directives
    if ($line -match '^\s*#Requires') {
        $processedLines += $line
        continue
    }
    
    # Skip lines that are only comments
    if ($line -match '^\s*#') {
        continue
    }
    
    # Handle inline comments more carefully
    $trimmedLine = $line
    if ($line -match '#') {
        # Check if # is actually inside a string
        $inString = $false
        $inSingleQuote = $false
        $escaped = $false
        $result = ""
        
        for ($i = 0; $i -lt $line.Length; $i++) {
            $char = $line[$i]
            
            if ($escaped) {
                $result += $char
                $escaped = $false
                continue
            }
            
            if ($char -eq '`') {
                $result += $char
                $escaped = $true
                continue
            }
            
            if ($char -eq '"' -and -not $inSingleQuote) {
                $inString = -not $inString
                $result += $char
                continue
            }
            
            if ($char -eq "'" -and -not $inString) {
                $inSingleQuote = -not $inSingleQuote
                $result += $char
                continue
            }
            
            # If we hit a # and we're not in a string, it's a comment
            if ($char -eq '#' -and -not $inString -and -not $inSingleQuote) {
                break
            }
            
            $result += $char
        }
        
        $trimmedLine = $result.TrimEnd()
    }
    
    if ($trimmedLine.Trim() -ne '') {
        $processedLines += $trimmedLine.TrimEnd()
    }
}

$content = $processedLines -join "`n"

# Remove excessive blank lines
while ($content -match "`n`n`n") {
    $content = $content -replace "`n`n`n", "`n`n"
}

# Aggressive variable name minification
Write-Host "  Extracting all variables..." -ForegroundColor Gray

# Extract ALL parameter names (script params and function params) to preserve them
$paramNames = @()

# Get script-level parameters
if ($content -match '(?s)param\s*\((.*?)\n\)') {
    $paramBlock = $matches[1]
    $paramMatches = [regex]::Matches($paramBlock, '\[\w+\]\s*\$(\w+)')
    $paramNames += $paramMatches | ForEach-Object { $_.Groups[1].Value }
}

# Get ALL function parameters throughout the script
$functionMatches = [regex]::Matches($content, '(?s)function\s+[\w-]+\s*\{\s*param\s*\((.*?)\n\s*\)')
foreach ($funcMatch in $functionMatches) {
    $funcParamBlock = $funcMatch.Groups[1].Value
    $funcParamMatches = [regex]::Matches($funcParamBlock, '\[\w+\]\s*\$(\w+)')
    $paramNames += $funcParamMatches | ForEach-Object { $_.Groups[1].Value }
}

$paramNames = $paramNames | Select-Object -Unique

Write-Host "  Found $($paramNames.Count) parameter names to preserve..." -ForegroundColor Gray

# Built-in PowerShell variables that should NOT be renamed
$builtInVars = @(
    '_', 'PSScriptRoot', 'PSBoundParameters', 'PSCmdlet', 'PSItem', 'args', 'input',
    'MyInvocation', 'PSCommandPath', 'Error', 'Host', 'HOME', 'true', 'false', 'null',
    'ConfirmPreference', 'DebugPreference', 'ErrorActionPreference', 'VerbosePreference',
    'WarningPreference', 'WhatIfPreference', 'ErrorView', 'FormatEnumerationLimit',
    'MaximumAliasCount', 'MaximumDriveCount', 'MaximumErrorCount', 'MaximumFunctionCount',
    'MaximumHistoryCount', 'MaximumVariableCount', 'OFS', 'OutputEncoding', 'PWD',
    'ShellId', 'StackTrace', 'LASTEXITCODE', 'PROFILE', 'PID', 'ExecutionContext',
    'foreach', 'switch', 'matches', 'this'
) + $paramNames

# Extract all variable names from content
$allMatches = [regex]::Matches($content, '\$(\w+)')
$uniqueVars = $allMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique | Sort-Object -Property Length -Descending

# Filter out built-in variables and parameter names
$varsToRename = $uniqueVars | Where-Object {
    $var = $_
    $builtInVars -notcontains $var
}

Write-Host "  Found $($varsToRename.Count) variables to rename..." -ForegroundColor Gray

# Generate short variable names: a, b, c, ... z, aa, ab, ac, ... zz, aaa, etc.
function Get-ShortVarName {
    param([int]$Index)
    
    $letters = 'abcdefghijklmnopqrstuvwxyz'
    $result = ''
    $num = $Index
    
    do {
        $result = $letters[$num % 26] + $result
        $num = [Math]::Floor($num / 26) - 1
    } while ($num -ge 0)
    
    return $result
}

# Create mapping of old names to new short names
$varMap = @{}
for ($i = 0; $i -lt $varsToRename.Count; $i++) {
    $oldName = $varsToRename[$i]
    $newName = Get-ShortVarName $i
    $varMap[$oldName] = $newName
}

Write-Host "  Renaming variables..." -ForegroundColor Gray

# Replace variables (process longest names first to avoid partial matches)
foreach ($oldVar in $varsToRename) {
    $newVar = $varMap[$oldVar]
    # Use word boundary to ensure we only match complete variable names
    $content = $content -replace "\`$$oldVar\b", "`$$newVar"
}

$minifiedLines = ($content -split "`n").Count
Write-Host "  Minified lines: $minifiedLines" -ForegroundColor Gray
Write-Host "  Renamed $($varsToRename.Count) variables" -ForegroundColor Gray
Write-Host "  Removed lines: $($originalLines - $minifiedLines)" -ForegroundColor Green

Write-Host ""
Write-Host "[3/4] Saving minified file..." -ForegroundColor Yellow

$content | Out-File -FilePath $minifiedFile -Encoding utf8 -NoNewline

$minifiedSize = (Get-Item $minifiedFile).Length
$savedBytes = $originalSize - $minifiedSize
$savedPercent = [math]::Round(($savedBytes / $originalSize) * 100, 2)

Write-Host "  Minified file: $minifiedFile" -ForegroundColor Gray
Write-Host "  Minified size: $([math]::Round($minifiedSize/1KB, 2)) KB" -ForegroundColor Gray
Write-Host "  Space saved: $([math]::Round($savedBytes/1KB, 2)) KB ($savedPercent%)" -ForegroundColor Green

Write-Host ""
Write-Host "[4/4] Creating ZIP archive..." -ForegroundColor Yellow

if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

Compress-Archive -Path $minifiedFile -DestinationPath $zipFile -CompressionLevel Optimal -Force

$zipSize = (Get-Item $zipFile).Length
$zipSavedBytes = $originalSize - $zipSize
$zipSavedPercent = [math]::Round(($zipSavedBytes / $originalSize) * 100, 2)

Write-Host "  ZIP file: $zipFile" -ForegroundColor Gray
Write-Host "  ZIP size: $([math]::Round($zipSize/1KB, 2)) KB" -ForegroundColor Gray
Write-Host "  Space saved: $([math]::Round($zipSavedBytes/1KB, 2)) KB ($zipSavedPercent%)" -ForegroundColor Green

Write-Host ""
Write-Host "Minification Complete!" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Original:  $([math]::Round($originalSize/1KB, 2)) KB ($originalLines lines)" -ForegroundColor White
Write-Host "  Minified:  $([math]::Round($minifiedSize/1KB, 2)) KB ($minifiedLines lines) - Saved $savedPercent%" -ForegroundColor White
Write-Host "  Zipped:    $([math]::Round($zipSize/1KB, 2)) KB - Saved $zipSavedPercent%" -ForegroundColor White
Write-Host ""
Write-Host "Files created:" -ForegroundColor Green
Write-Host "  $minifiedFile" -ForegroundColor Gray
Write-Host "  $zipFile" -ForegroundColor Gray
Write-Host ""
