# Windows Log Cleaner - PowerShell Edition
# For authorized pentesting only - Run as Administrator!

Write-Host "=== Windows Log Cleaner v3.0 (PowerShell) ===" -ForegroundColor Green
Write-Host "For authorized pentesting cleanup only" -ForegroundColor Yellow

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "[-] ERROR: Must run as Administrator!" -ForegroundColor Red
    Write-Host "    Right-click PowerShell -> 'Run as administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "[+] Running with Administrator privileges..." -ForegroundColor Green
Write-Host ("-" * 50) -ForegroundColor Cyan

# 1. Clear ALL Windows Event Logs
Write-Host "[+] Clearing Windows Event Logs..." -ForegroundColor Cyan
$eventLogs = @(
    "Application", "Security", "System", "Setup", "ForwardedEvents",
    "HardwareEvents", "Internet Explorer", "Power-Troubleshooter",
    "Microsoft-Windows-DriverFrameworks-UserMode/Operational",
    "Microsoft-Windows-PowerShell/Operational"
)

$clearedLogs = 0
foreach ($log in $eventLogs) {
    try {
        wevtutil cl $log | Out-Null
        Write-Host "    [OK] Cleared $log" -ForegroundColor Green
        $clearedLogs++
    }
    catch {
        Write-Host "    - Skipped $log" -ForegroundColor Gray
    }
}
Write-Host "    Total: $clearedLogs logs cleared" -ForegroundColor Green

# 2. Delete EVTX backup files
Write-Host "`n[+] Deleting EVTX backup files..." -ForegroundColor Cyan
$evtxPaths = @(
    "C:\Windows\System32\winevt\Logs\*.evtx",
    "C:\Windows\System32\config\*.evt"
)

$evtxDeleted = 0
foreach ($path in $evtxPaths) {
    $files = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        try {
            Remove-Item $file.FullName -Force
            $evtxDeleted++
        }
        catch {}
    }
}
Write-Host "    Deleted: $evtxDeleted EVTX files" -ForegroundColor Green

# 3. Clear system logs and common files
Write-Host "`n[+] Clearing system logs..." -ForegroundColor Cyan
$systemLogs = @(
    "C:\Windows\debug\NetSetup.LOG",
    "C:\Windows\Panther\*.log",
    "C:\Windows\inf\setupapi.*",
    "C:\Windows\SoftwareDistribution\Reports\*"
)

$sysDeleted = 0
foreach ($log in $systemLogs) {
    $files = Get-ChildItem -Path $log -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        try {
            Remove-Item $file.FullName -Force -Recurse
            $sysDeleted++
        }
        catch {}
    }
}
Write-Host "    Deleted: $sysDeleted system files" -ForegroundColor Green

# 4. Clear Prefetch
Write-Host "`n[+] Clearing Prefetch..." -ForegroundColor Cyan
$prefetchFiles = Get-ChildItem "C:\Windows\Prefetch\*.pf" -ErrorAction SilentlyContinue
foreach ($pf in $prefetchFiles) {
    Remove-Item $pf.FullName -Force
}
Write-Host "    [OK] Prefetch cleared ($($prefetchFiles.Count) files)" -ForegroundColor Green

# 5. Clear Recent Files
Write-Host "`n[+] Clearing Recent Files..." -ForegroundColor Cyan
$recentPath = "$env:USERPROFILE\Recent"
if (Test-Path $recentPath) {
    Remove-Item "$recentPath\*" -Force -Recurse
    Write-Host "    [OK] Recent files cleared" -ForegroundColor Green
}

# 6. Clear Temp folders
Write-Host "`n[+] Clearing Temp folders..." -ForegroundColor Cyan
$tempPaths = @($env:TEMP, $env:TMP, "C:\Windows\Temp", "C:\Windows\SoftwareDistribution\Download")

foreach ($tempPath in $tempPaths) {
    if (Test-Path $tempPath) {
        Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | 
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "    [OK] All Temp folders cleared" -ForegroundColor Green

# 7. Empty Recycle Bin
Write-Host "`n[+] Emptying Recycle Bin..." -ForegroundColor Cyan
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "    [OK] Recycle Bin emptied" -ForegroundColor Green
}
catch {}

# 8. Clear DNS Cache & ARP Cache
Write-Host "`n[+] Clearing Network caches..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null
netsh interface ip delete arpcache | Out-Null
Write-Host "    [OK] DNS/ARP caches cleared" -ForegroundColor Green

Write-Host ("-" * 50) -ForegroundColor Cyan
Write-Host "[+] ALL TRACES CLEANED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "[+] Perfect for post-exploitation cleanup!" -ForegroundColor Yellow

Read-Host "`nPress Enter to exit"