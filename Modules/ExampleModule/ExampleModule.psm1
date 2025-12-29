## EXAMPLE MODULE

# Initialize module settings
if (-not $global:ServiceSettings) { throw "Service settings are not initialized." }
if (-not $script:Settings) { $script:Settings = (Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot ((Split-Path $PSScriptRoot -Leaf) + '.psd1'))).PrivateData }

# Import modules
Get-ChildItem -Path $PSScriptRoot -Filter '*.ps1' -File | ForEach-Object { . $_.FullName }