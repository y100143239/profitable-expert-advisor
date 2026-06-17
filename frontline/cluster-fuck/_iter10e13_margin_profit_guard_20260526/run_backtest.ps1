param (
    [string]$ConfigPath = "C:\Users\82204\AppData\Roaming\MetaQuotes\Terminal\D3027A7456F1BED80051EF2A0D0DD331\MQL5\Experts\Advisors\y100143239\profitable-expert-advisor\frontline\cluster-fuck\_united-V2\auto_tester_config.ini",
    [string]$TerminalPath = "C:\Users\82204\AppData\Roaming\MetaTrader 5\terminal64.exe"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Helper: write config without BOM (MT5 cannot parse .ini with a UTF-8 BOM)
function Write-ConfigNoBOM($Lines, $Path) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($Path, $Lines, $utf8NoBom)
}

# 1. 强制关闭现有的 terminal64 进程
Write-Host "Stopping any running instance of terminal64.exe..."
Stop-Process -Name "terminal64" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 2. 生成统一的时间戳
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportDirRel = "MQL5\Experts\Advisors\y100143239\profitable-expert-advisor\frontline\cluster-fuck\_united-V2\report_history\$timestamp"
$reportBaseName = "report"

$absoluteReportDir = "C:\Users\82204\AppData\Roaming\MetaQuotes\Terminal\D3027A7456F1BED80051EF2A0D0DD331\$reportDirRel"
New-Item -ItemType Directory -Force -Path $absoluteReportDir | Out-Null

# 3. Copy the original config into the report folder as a snapshot, modify only the copy
$runConfigPath = Join-Path $absoluteReportDir "backtest_config.ini"
$configContent = Get-Content $ConfigPath
$reportHtmlPath = "$reportDirRel\$reportBaseName.html"

$newConfig = $configContent -replace '^Report=.*', "Report=$reportHtmlPath"
$newConfig = $newConfig -replace '^ShutdownTerminal=.*', 'ShutdownTerminal=1'
Write-ConfigNoBOM $newConfig $runConfigPath
Write-Host "Config snapshot saved to: $runConfigPath"

# 4. Single MT5 run -> HTML report (the only format MT5 /config: supports)
Write-Host "Running MT5 strategy tester (single run)..."
Start-Process -FilePath $TerminalPath -ArgumentList "/config:`"$runConfigPath`"" -WindowStyle Minimized -Wait
Start-Sleep -Seconds 2

# 5. Verify HTML report
$absoluteHtmlPath = "$absoluteReportDir\$reportBaseName.html"
if (-not (Test-Path $absoluteHtmlPath)) {
    Write-Host "ERROR: HTML report not found at $absoluteHtmlPath" -ForegroundColor Red
    exit 1
}
$htmlSize = (Get-Item $absoluteHtmlPath).Length
Write-Host "HTML report generated: $absoluteHtmlPath ($([math]::Round($htmlSize/1024, 1)) KB)"

# 6. Extract deals.csv from the HTML report (for analyze_mt5_report.py)
$mt5Python = "C:\Users\82204\.conda\envs\mt5\python.exe"
$extractScript = Join-Path $ScriptDir "html_to_xlsx.py"
Write-Host "Extracting deals.csv from HTML report..."
$env:PYTHONIOENCODING = "utf-8"
& $mt5Python $extractScript $absoluteHtmlPath $absoluteReportDir
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: deals.csv extraction failed (exit code $LASTEXITCODE)" -ForegroundColor Yellow
}

# 7. Analyze deals and generate markdown report
$analyzeScript = Join-Path $ScriptDir "analyze_mt5_report.py"
$dealsCsvPath = Join-Path $absoluteReportDir "deals.csv"
if (Test-Path $dealsCsvPath) {
    Write-Host "Running MT5 deals analysis..."
    & $mt5Python $analyzeScript $dealsCsvPath
} else {
    Write-Host "WARNING: deals.csv not found, skipping analysis." -ForegroundColor Yellow
}

Write-Host "========================================="
Write-Host "Backtest finished. Timestamp: $timestamp"
Write-Host "Reports saved to: $absoluteReportDir"
Write-Host "  - report.html           (visual backtest report)"
Write-Host "  - deals.csv             (deal log for strategy analysis)"
Write-Host "  - analysis_report_*.md  (Markdown analysis results)"
Write-Host "========================================="
