function Write-ServiceLog {
	param (
		[Parameter(Position=0)]
		[string]$Message,
		
		[Parameter()]
		[bool]$Status,  # Optional Boolean for PASS/FAIL
		
		[Parameter()]
		[switch]$Line  # Add line break
	)
	
	if ([string]::IsNullOrWhitespace($Message) -And (-Not $Line)) { return }
	
	# Ensure the log file path is available
	if (-not $script:LogFile) { throw "Log file is not specified." }
	
	# If -Line specified, ignore anything else
	if ($Line) { $LogEntry = "==============================================================================" }
	else {
		# Determine the status text based on the input
		if ($PSBoundParameters.ContainsKey('Status')) {
			if ($Status -eq $true) {
				$StatusText = "PASS"
			} elseif ($Status -eq $false) {
				$StatusText = "FAIL"
			}
		} else {
			$StatusText = "INFO"
		}
		
		# Write the log entry and to the console
		$Timestamp = Get-Date -Format "h:mm:ss tt"
		$LogEntry = " $Timestamp [$StatusText] $Message"
	}
	
	Add-Content -Path $script:LogFile -Value $LogEntry
	Write-Output $LogEntry
}
