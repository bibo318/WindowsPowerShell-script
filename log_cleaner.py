import os
import subprocess
import shutil
import sys
from pathlib import Path

# Fix Windows encoding
if sys.platform.startswith('win'):
    sys.stdout.reconfigure(encoding='utf-8')
    os.system('chcp 65001 >nul')

def clear_windows_logs():
    """Clear all Windows Event Logs and common log files"""
    
    # 1. Clear Windows Event Logs using wevtutil
    event_logs = [
        'Application', 'Security', 'System', 'Setup',
        'ForwardedEvents', 'HardwareEvents', 'Internet Explorer',
        'Power-Troubleshooter', 'Microsoft-Windows-DriverFrameworks-UserMode/Operational'
    ]
    
    print("[+] Clearing Windows Event Logs...")
    for log in event_logs:
        try:
            subprocess.run(['wevtutil', 'cl', log], 
                         capture_output=True, check=True, shell=True)
            print(f"    ✓ Cleared {log}")
        except subprocess.CalledProcessError:
            print(f"    - Skipped {log}")
    
    # 2. Delete EVTX backup files
    log_dirs = [
        r"C:\Windows\System32\winevt\Logs",
        r"C:\Windows\System32\config"
    ]
    
    for log_dir in log_dirs:
        path = Path(log_dir)
        if path.exists():
            try:
                for file in path.glob("*.evtx"):
                    file.unlink(missing_ok=True)
                print(f"[+] Cleared EVTX: {log_dir}")
            except Exception:
                pass
    
    # 3. Clear common system logs
    system_logs = [
        r"C:\Windows\debug\NetSetup.LOG",
        r"C:\Windows\Panther\setupact.log",
        r"C:\Windows\Panther\setuperr.log",
        r"C:\Windows\inf\setupapi.dev.log",
        r"C:\Windows\SoftwareDistribution\Reports",
        r"C:\$Recycle.Bin"
    ]
    
    cleared_count = 0
    for log_file in system_logs:
        path = Path(log_file)
        if path.exists():
            try:
                if path.is_dir():
                    shutil.rmtree(path, ignore_errors=True)
                else:
                    path.unlink(missing_ok=True)
                cleared_count += 1
            except:
                pass
    
    print(f"[+] Cleared {cleared_count} system log files")
    
    # 4. Clear Prefetch, Recent, Temp folders
    folders_to_clean = {
        "Prefetch": r"C:\Windows\Prefetch\*.pf",
        "Recent": os.path.expandvars(r"C:\Users\%USERNAME%\Recent\*"),
        "UserTemp": os.environ.get('TEMP', ''),
        "WinTemp": r"C:\Windows\Temp",
        "UpdateCache": r"C:\Windows\SoftwareDistribution\Download"
    }
    
    for name, pattern in folders_to_clean.items():
        try:
            path = Path(pattern)
            if '*' in str(pattern):
                files = list(path.parent.glob(path.name))
                for f in files:
                    f.unlink(missing_ok=True)
            else:
                for root, dirs, files in os.walk(pattern):
                    for f in files:
                        os.unlink(os.path.join(root, f))
                    for d in dirs:
                        shutil.rmtree(os.path.join(root, d), ignore_errors=True)
            print(f"[+] Cleared {name}")
        except:
            pass
    
    print("[+] Cleanup completed successfully!")

def check_admin():
    """Check administrator privileges"""
    try:
        result = subprocess.run('net session >nul 2>&1', shell=True, capture_output=True)
        return result.returncode == 0
    except:
        return False

def main():
    print("=== Windows Log Cleaner v2.0 ===")
    print("For authorized pentesting only")
    
    if not check_admin():
        print("[-] ERROR: Administrator privileges required!")
        print("    Right-click PowerShell/CMD -> 'Run as administrator'")
        input("Press Enter to exit...")
        return
    
    print("[+] Running with administrator rights...")
    print("-" * 50)
    
    clear_windows_logs()
    
    print("-" * 50)
    print("[+] ALL TRACES CLEANED!")
    input("Press Enter to exit...")

if __name__ == "__main__":
    main()