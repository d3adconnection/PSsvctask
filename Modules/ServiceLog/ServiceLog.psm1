# SERVICE LOGGING POWERSHELL

if (-not $global:ServiceSettings) { throw "Service settings are not initialized." }
if (-not $script:Settings) { $script:Settings = (Test-ModuleManifest -Path (Join-Path $PSScriptRoot 'ServiceLog.psd1')).PrivateData }

$script:LogPath = if ($env:COMPUTERNAME -eq $global:ServiceSettings.ServiceHost) { $script:Settings.LocalLogPath } else { $script:Settings.RemoteLogPath }

. (Join-Path $PSScriptRoot 'Start-ServiceLog.ps1')
. (Join-Path $PSScriptRoot 'Write-ServiceLog.ps1')