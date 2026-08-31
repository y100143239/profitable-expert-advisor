<#
run_bt.ps1 - one-shot local MT5 backtest runner for the v5_iter campaign.
Broker/data: uses the D3027A terminal (ICMarketsSC-MT5-6 tick cache). Model=4 real ticks.

Example:
  .\run_bt.ps1 -Set champion.set -From 2026.01.01 -To 2026.08.31 -Report base_2026 -Label "baseline 2026"
  .\run_bt.ps1 -Set champion.set -From 2026.01.01 -To 2026.08.31 -Report nobrk_2026 -Label "no breakers" `
     -Overrides @{ 'GRM_MonthlyLossLimitFreeMarginPct'='0.0'; 'GRM_DailyLossLimitUSD'='0.0' }
#>
param(
  [string]$Set = "",
  [Parameter(Mandatory=$true)][string]$From,
  [Parameter(Mandatory=$true)][string]$To,
  [Parameter(Mandatory=$true)][string]$Report,
  [string]$Label = "",
  [int]$Leverage = 1000,
  [int]$Deposit = 3000,
  [string]$Symbol = "EURUSD",
  [string]$Overrides = "",
  [int]$TimeoutSec = 1800
)
$ErrorActionPreference = "Stop"
$data = "C:\Users\82204\AppData\Roaming\MetaQuotes\Terminal\D3027A7456F1BED80051EF2A0D0DD331"
$cf   = "$data\MQL5\Experts\Advisors\y100143239\profitable-expert-advisor\frontline\cluster-fuck"
$exe  = "C:\Users\82204\AppData\Roaming\MetaTrader 5\terminal64.exe"
$py   = "C:\Users\82204\.conda\envs\mt5\python.exe"
$expert = "Advisors\y100143239\profitable-expert-advisor\frontline\cluster-fuck\v5_iter\ea\main.ex5"
$runs = "$cf\v5_iter\runs"; New-Item -ItemType Directory -Force -Path "$runs\$Report" | Out-Null

# --- build [TesterInputs] body from a .set with overrides applied ---
$body = @()
if($Set -ne ""){
  $setPath = if(Test-Path $Set){ $Set } else { "$cf\v4opt\releases\champion_final_20260731\$Set" }
  $body = Get-Content $setPath
}
foreach($pair in ($Overrides -split ';')){
  if($pair.Trim() -eq ""){ continue }
  $kv = $pair -split '=', 2
  $k = $kv[0].Trim(); $v = $kv[1].Trim()
  $line = "$k=$v"
  if(($body | Select-String -Pattern "^$([regex]::Escape($k))=" -Quiet)){
    $body = $body -replace "^$([regex]::Escape($k))=.*", $line
  } else { $body += $line }
}
$hdr = @('[Tester]',"Expert=$expert","Symbol=$Symbol",'Period=H1','Optimization=0','Model=4',
  "FromDate=$From","ToDate=$To",'ForwardMode=0',"Deposit=$Deposit",'Currency=USD','ProfitInPips=0',
  "Leverage=$Leverage",'ExecutionMode=150',"Report=rep_$Report",'ReplaceReport=1','ShutdownTerminal=1','Visual=0','[TesterInputs]')
$ini = "$runs\$Report\$Report.ini"
($hdr + $body) | Set-Content $ini -Encoding ASCII
Write-Host "[run_bt] $Label | $From..$To | lev 1:$Leverage | ini=$ini"

# --- clear old report, launch, wait ---
Get-ChildItem $data -Filter "rep_$Report*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
$p = Start-Process -FilePath $exe -ArgumentList "/config:`"$ini`"" -PassThru
if(-not $p.WaitForExit($TimeoutSec*1000)){ Write-Host "[run_bt] TIMEOUT ${TimeoutSec}s"; try{$p.Kill()}catch{}; return }
Write-Host "[run_bt] terminal exited code $($p.ExitCode)"

# --- collect + parse ---
$rep = "$data\rep_$Report.htm"
if(-not (Test-Path $rep)){ Write-Host "[run_bt] NO REPORT at $rep"; return }
Copy-Item $rep "$runs\$Report\ReportTester.htm" -Force
Get-ChildItem $data -Filter "rep_$Report*.png" -ErrorAction SilentlyContinue | Copy-Item -Destination "$runs\$Report\" -Force
& $py "$cf\v5_iter\parse_report.py" "$runs\$Report\ReportTester.htm" $Label
