# PSsvctask

Lightweight PowerShell framework providing logging and configuration for automated tasks.

## Quick Start

1. Clone or copy this folder anywhere on your server or network share (e.g., C:\PSsvctask, D:\Scripts\PSsvctask, \\server\share\PSsvctask)
2. Edit `ServiceSettings.psd1` (must be in same folder as PSsvctask.ps1) and set your paths, hostname, and service account
3. Edit `ServiceLog.psd1` (see Basic Configuration) and set your paths for logging
4. Run a task: `.\PSsvctask.ps1 ExampleTask`
5. Check logs in the `Logs\` folder

## Basic Configuration

Edit `ServiceSettings.psd1`:

```powershell
ServiceAccount = "YourServiceAccount"  # Tasks run in test mode if not this user
ServiceHost = "SERVERNAME"             # Tasks run in test mode if not this hostname
ModulesPath = "C:\PSsvctask\Modules"   # Where shared code lives
TasksPath = "C:\PSsvctask\Tasks"       # Where task scripts live
```

Edit `Modules\ServiceLog\ServiceLog.psd1` for log configuration:

```powershell
LocalLogPath  = "C:\PSsvctask\Logs"    # Log path when running on ServiceHost
RemoteLogPath = "C:\PSsvctask\Logs"    # Log path when running elsewhere
LogRetentionDays = 10                  # Auto-delete log folders older than this
```

Note: ModulesPath and TasksPath can be anywhere on the system or UNC paths (e.g., `\\server\share\Tasks`) - they don't have to be in the same folder as PSsvctask.ps1. You can also rename PSsvctask.ps1 to fit your naming conventions.

Test mode automatically activates when running under a different account or hostname. Use this to safely test and debug tasks without making actual changes. Test mode pauses at the end for review. Production mode (correct account + hostname) runs unattended.

## Running Tasks

From PowerShell:
```powershell
.\PSsvctask.ps1 ExampleTask
```

From Task Scheduler, set:
- Program: `powershell.exe`
- Arguments: `-ExecutionPolicy Bypass -File "<path>\PSsvctask.ps1" ExampleTask`
- Start in: `<path>` (folder containing PSsvctask.ps1)

Logs are created in `Logs\YYYY-MM-DD\TaskName.log` automatically.

## Creating a New Task

Example: Create a task that cleans old temporary files

1. Create `Tasks\CleanTempFiles.ps1`:
```powershell
$OldFiles = Get-ChildItem -Path $TaskSettings.CleanupPath -Recurse -File | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$TaskSettings.RetentionDays) }

Write-ServiceLog "Found $($OldFiles.Count) files older than $($TaskSettings.RetentionDays) days"

foreach ($File in $OldFiles) {
    if (-not $global:ServiceTestMode) {
        Remove-Item $File.FullName -Force
        Write-ServiceLog "Deleted: $($File.FullName)" -Status $true
    } else {
        Write-ServiceLog "Would delete: $($File.FullName)" -Status $true
    }
}
```

2. Create `Tasks\CleanTempFiles.psd1`:
```powershell
@{
    ServiceModules    = @()
    PowerShellModules = @()
    LogFileNameTime   = $false
    
    # Task-specific settings
    CleanupPath    = "C:\Temp"
    RetentionDays  = 30
}
```

Required Task settings:
- `ServiceModules` - Array of custom modules from your Modules folder to load
- `PowerShellModules` - Array of standard PowerShell modules to import
- `LogFileNameTime` - When `$true`, creates a task-specific subfolder and includes time in the log filename (e.g., `Logs\YYYY-MM-DD\TaskName\TaskName - HH MM TT.log`). When `$false` (default), logs go directly in the date folder (e.g., `Logs\YYYY-MM-DD\TaskName.log`). Use `$true` for tasks that run multiple times per day

3. Run it: `.\PSsvctask.ps1 CleanTempFiles`

Note: Any key you add to the task's .psd1 file is accessible via `$TaskSettings.YourKey` in your script.

### Write-ServiceLog Reference

```powershell
Write-ServiceLog "message"              # [INFO] with timestamp
Write-ServiceLog "message" -Status $true  # [PASS] with timestamp
Write-ServiceLog "message" -Status $false # [FAIL] with timestamp
Write-ServiceLog -Line                    # Adds separator line
```

Check `$global:ServiceTestMode` in your scripts to prevent changes during testing.

## Creating Shared Modules

Create modules when you have code used by multiple tasks. Example: An email notification module.

1. Create folder: `Modules\EmailNotify\`

2. Create `EmailNotify.psm1`:
```powershell
## EXAMPLE MODULE

# Initialize module settings
if (-not $script:Settings) { $script:Settings = (Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot ((Split-Path $PSScriptRoot -Leaf) + '.psd1'))).PrivateData }

# Import modules
Get-ChildItem -Path $PSScriptRoot -Filter '*.ps1' -File | ForEach-Object { . $_.FullName }
```

3. Create `EmailNotify.psd1`:
```powershell
@{
    RootModule = "EmailNotify.psm1"
    ModuleVersion = "1.0.0"
    PrivateData = @{
        SmtpServer = "smtp.company.com"
        FromAddress = "tasks@company.com"
        ToAddress = "admin@company.com"
    }
}
```

4. Create `Send-TaskAlert.ps1` in the same folder:
```powershell
function Send-TaskAlert {
    param([string]$Subject, [string]$Body)
    Send-MailMessage -SmtpServer $script:Settings.SmtpServer `
        -From $script:Settings.FromAddress `
        -To $script:Settings.ToAddress `
        -Subject $Subject -Body $Body
}
```

5. Reference in task .psd1 files: `ServiceModules = @("EmailNotify")`

6. Use in tasks: `Send-TaskAlert "Cleanup Complete" "Deleted 50 files"`

Note: ServiceLog module is required and automatically loaded for all tasks.
