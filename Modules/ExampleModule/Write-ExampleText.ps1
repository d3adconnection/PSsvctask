function Write-ExampleText {
	param (
		[Parameter(Position = 0)]
		[bool]$IncludeVersion
	)

	# Build example text
	$ExampleText = "Host: $($env:COMPUTERNAME)"
	if ($IncludeVersion) { $ExampleText += " ExampleModuleSetting: $($script:Settings.ExampleModuleSetting)" }

	# Example of using settings from .psd1 file
	if ($script:Settings.ExampleModuleSetting) {
	   	return $ExampleText
	} else { throw "ExampleModule.psd1 is not configured correctly. Ensure there is a value for ExampleModuleSetting." }
}