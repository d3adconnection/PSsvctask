####################################################################
##	Example task
#
#	Provide an example for PSsvctask tasks
##
####################################################################

function ExampleFunction {
	param (
		[Parameter(Position = 0, ValueFromPipeline=$true, Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ExampleParameter1,
		
		[Parameter(Position = 1)]
		[string]$ExampleParameter2
	)
	
	# Example of test mode
	if ($global:ServiceTestMode) { Write-ServiceLog "Test mode is on, no changes will be made" }
	else { Write-ServiceLog "Test mode is off, changes can be made" }
	
	# Example of parameter usage
	Write-ServiceLog "Example parameter 1 result: $($ExampleParameter1)" -Status $true
	
	if ($ExampleParameter2) {
		Write-ServiceLog "Example parameter 2 result: $($ExampleParameter2)" -Status $true
	} else { Write-ServiceLog "Example parameter 2 was not provided." -Status $false }	
}

##
####################################################################

Write-ServiceLog "Starting Example task."

# Example of using settings from .psd1 file
if ($TaskSettings.ExampleSetting) {
	Write-ServiceLog "Example setting from Example.psd1: $($TaskSettings.ExampleSetting)" -Status $true
} else { throw "Example.psd1 is not configured correctly. Ensure there is a value for ExampleSetting." }


# Example of module function
Write-ServiceLog -Line
Write-ServiceLog "Running ExampleFunction with 1 parameter."
ExampleFunction "1stParameterExample"

Write-ServiceLog -Line
Write-ServiceLog "Running ExampleFunction with 2 parameter."
ExampleFunction "1stParameterExample" "2ndParameterExample"