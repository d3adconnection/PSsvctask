# SERVICE LOGGING MODULE

# Initialize module settings
if (-not $global:ServiceSettings) { throw "Service settings are not initialized." }
if (-not $script:Settings) { $script:Settings = (Test-ModuleManifest -Path (Join-Path $PSScriptRoot ((Split-Path $PSScriptRoot -Leaf) + '.psd1'))).PrivateData }

# Determine log path based on ServiceHost setting
$script:LogPath = if ($env:COMPUTERNAME -eq $global:ServiceSettings.ServiceHost) { $script:Settings.LocalLogPath } else { $script:Settings.RemoteLogPath }

# Import modules
Get-ChildItem -Path $PSScriptRoot -Filter '*.ps1' -File | ForEach-Object { . $_.FullName }