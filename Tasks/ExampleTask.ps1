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
	if ($global:ServiceTestMode) { Write-ServiceLog "Test mode is on, this should be checked in the script to ensure no changes will be made accidentally." }
	else { Write-ServiceLog "Test mode is off, this should be checked in the script to ensure changes can be made safely." }
	
	# Example of parameter usage
	Write-ServiceLog "Example parameter 1 result: $($ExampleParameter1)" -Status $true
	
	if ($ExampleParameter2) {
		Write-ServiceLog "Example parameter 2 result: $($ExampleParameter2)" -Status $true
	} else { Write-ServiceLog "Example parameter 2 was not provided." -Status $false }	
}

##
####################################################################

Write-ServiceLog "Starting ExampleTask."

# Example of using settings from .psd1 file
if ($TaskSettings.ExampleTaskSetting) {
	Write-ServiceLog "Example setting from ExampleTask.psd1: $($TaskSettings.ExampleTaskSetting)" -Status $true
} else { throw "ExampleTask.psd1 is not configured correctly. Ensure there is a value for ExampleTaskSetting." }


# Example of module function
Write-ServiceLog -Line
Write-ServiceLog "Running ExampleFunction with 1 parameter; it requires two, so the second will fail."
ExampleFunction "1stParameterExample"

Write-ServiceLog -Line
Write-ServiceLog "Running ExampleFunction with 2 parameters."
ExampleFunction "1stParameterExample" "2ndParameterExample"

Write-ServiceLog -Line
Write-ServiceLog ("Getting text from ExampleModule: " + (Write-ExampleText))
Write-ServiceLog ("Getting text from ExampleModule with parameter: " + (Write-ExampleText -IncludeVersion $true))