function Start-ServiceLog {
    param (
        [Parameter(Position = 0, Mandatory=$true, ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$TaskName,
		
        [bool]$IncludeTime  # Optional boolean to include time in the log file name
    )
	
	# Purge old log folders
	if ($script:Settings.LogRetentionDays -gt 0) {
		Get-ChildItem $script:LogPath -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$script:Settings.LogRetentionDays) } | Remove-Item -Recurse -Force
	}

    # Create date-based log folder
    $DateFolder = Get-Date -Format "yyyy-MM-dd"
    $script:LogPath = if ($IncludeTime) { (Join-Path (Join-Path $script:LogPath -ChildPath $DateFolder) $ServiceName) } else { (Join-Path $script:LogPath $DateFolder) }
	
    if (-not (Test-Path -Path $script:LogPath)) {
        New-Item -ItemType Directory -Path $script:LogPath -Force | Out-Null
    }

    # Generate log file name
    $TimeSuffix = if ($IncludeTime) { (" - " + (Get-Date -Format "hh mm tt")) } else { "" }
    $script:LogFile = (Join-Path $script:LogPath "$TaskName$TimeSuffix.log")
    
    # Purge any preexisting log file in the same location if it exists
    if (Test-Path $script:LogFile) { Remove-Item $script:LogFile -Force }
	
	Write-ServiceLog -Line
	Write-ServiceLog ("Started log for " + $TaskName)
}