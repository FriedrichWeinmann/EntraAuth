function Resolve-ScopeName {
	<#
	.SYNOPSIS
		Normalizes scope names.
	
	.DESCRIPTION
		Normalizes scope names.
		To help manage correct scopes naming with services that don't map directly to their urls.
	
	.PARAMETER Scopes
		The scopes to normalize.
	
	.PARAMETER Resource
		The Resource the scopes are meant for.
	
	.EXAMPLE
		PS C:\> $scopes | Resolve-ScopeName -Resource $Resource
		
		Resolves all them scopes
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$Scopes,

		[Parameter(Mandatory = $true)]
		[string]
		$Resource
	)
	process {
		foreach ($scope in $Scopes) {
			foreach ($scope in $Scopes) {
				if ($scope -like 'https://*/*') { $scope }
				elseif ($scope -like 'api:/') { $scope }
				else { "{0}/{1}" -f $Resource, $scope }
			}
		}
	}
}