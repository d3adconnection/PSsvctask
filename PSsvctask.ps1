## PSsvctask
# 1.251229

[CmdletBinding(DefaultParameterSetName = 'Task')]
param (
	[Parameter(Position = 0, ValueFromPipeline=$true, Mandatory = $true, ParameterSetName = 'Task')]
	[ValidateNotNullOrEmpty()]
	[string]$Task,

	[Parameter(Mandatory = $true, ParameterSetName = 'Module')]
	[ValidateNotNullOrEmpty()]
	[string]$Module
)

# Import global service settings
try { $global:ServiceSettings = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "ServiceSettings.psd1") }
catch { throw "Unable to import service settings: $_" }

# Validate required settings exist
@('ServiceAccount', 'ServiceHost', 'ModulesPath', 'TasksPath') | ForEach-Object {
	if (-not $global:ServiceSettings.ContainsKey($_)) {	throw "ServiceSettings.psd1 is missing required key: $_" }
}

# Check if set folders exist
if (-not (Test-Path $global:ServiceSettings.ModulesPath)) { throw "Modules path is invalid: $($global:ServiceSettings.ModulesPath)" }
if (-not (Test-Path $global:ServiceSettings.TasksPath)) { throw "Tasks path is invalid: $($global:ServiceSettings.TasksPath)" }

# Ensure ServiceLog module exists
if (-not (Test-Path (Join-Path $global:ServiceSettings.ModulesPath "ServiceLog\ServiceLog.psm1"))) {
	throw "ServiceLog module cannot be found under $($global:ServiceSettings.ModulesPath)"
}

# Import module function
function Import-PSsvctaskModule {
	param (
		[Parameter(Position = 0, Mandatory=$true, ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ServiceModule
	)
	$ModulePath = (Join-Path $global:ServiceSettings.ModulesPath "$ServiceModule\$ServiceModule.psm1")
	if (Test-Path $ModulePath) { 
		try { 
			Import-Module $ModulePath -Scope Global -Force -ErrorAction Stop
			Write-ServiceLog "Imported service module $ServiceModule." -Status $true
		}
		catch {
			if (-not $Module) {
				Write-ServiceLog "Unable to import $ServiceModule - $_" -Status $false
				$TaskError = $true
			} else { throw "Unable to import $ServiceModule - $_" }
		}
	} else {
		if (-not $Module) { 
			Write-ServiceLog "Unable to find $ServiceModule." -Status $false
			$TaskError = $true
		} else { throw "Unable to find $ServiceModule." }
	}
}

# If Module specified, just import module
if ($Module) { Import-PSsvctaskModule $Module }
elseif ($Task) {
	# Check task exists
	$TaskScript = (Join-Path $global:ServiceSettings.TasksPath "$Task.ps1")
	$TaskSettingsPath = (Join-Path $global:ServiceSettings.TasksPath "$Task.psd1")
	if (-not (Test-Path $TaskScript)) { throw "Unable to find $Task.ps1." }
	if (-not (Test-Path $TaskSettingsPath)) { throw "Unable to find $Task.psd1." }
	
	# Import task settings
	try { $TaskSettings = Import-PowerShellDataFile $TaskSettingsPath }
	catch { throw "Unable to import task settings: $_" }
	
	# Create log file
	try {
		Import-Module (Join-Path $global:ServiceSettings.ModulesPath "ServiceLog\ServiceLog.psm1") -Scope Global -Force -ErrorAction Stop 
		Start-ServiceLog $Task -IncludeTime $TaskSettings.LogFileNameTime
	}
	catch { throw "Unable to start service log: $_" }
	
	# Check if required parameters exist
	if ($TaskSettings.ContainsKey('ServiceModules') -and $TaskSettings.ContainsKey('PowerShellModules')) {
		# Import service modules needed for this service
		# ServiceLog is always loaded, so exclude it here
		$TaskSettings.ServiceModules = $TaskSettings.ServiceModules -ne 'ServiceLog'
		if ($TaskSettings.ServiceModules) {	$TaskSettings.ServiceModules | ForEach-Object { Import-PSsvctaskModule $_ } }
		
		# Import PowerShell modules needed for this service
		$TaskSettings.PowerShellModules | ForEach-Object {
			if (-not (Get-Module -ListAvailable $_)) { Write-ServiceLog "Unable to find PowerShell module $_." -Status $false; $TaskError = $true }
			else {
				try {
					Import-Module $_ -Scope Global -ErrorAction Stop
					Write-ServiceLog "Imported PowerShell module $_." -Status $true
				}
				catch { Write-ServiceLog "Unable to import PowerShell module - $_" -Status $false; $TaskError = $true }
			}
		}
		
		# Enable test mode if service account or host is not being used
		$global:ServiceTestMode = (($env:USERNAME -ne $global:ServiceSettings.ServiceAccount) -or ($env:COMPUTERNAME -ne $global:ServiceSettings.ServiceHost))
		if ($global:ServiceTestMode) { Write-ServiceLog ("Service test mode active, running under " + $env:USERNAME + " on " + $env:COMPUTERNAME) }
		if ([Environment]::UserInteractive) { Write-ServiceLog "Running in interactive mode." }
	
		if (-not $TaskError) {
			# Start task
			try { . $TaskScript; Write-ServiceLog "Task $Task exited with no terminating error." -Status $true }
			catch { Write-ServiceLog $_ -Status $false }
		}
	} else { Write-ServiceLog "$Task.psd1 file is damaged or invalid." -Status $false }
	
	# Task ended
	if ([Environment]::UserInteractive) {
		Write-ServiceLog "Pausing console in interactive mode."
		pause
	}
	Write-ServiceLog -Line
}