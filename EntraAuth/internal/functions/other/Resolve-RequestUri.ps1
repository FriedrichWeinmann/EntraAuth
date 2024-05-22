function Resolve-RequestUri {
	<#
	.SYNOPSIS
		Resolves the actual Uri used for a request in Invoke-EntraRequest.
	
	.DESCRIPTION
		Resolves the actual Uri used for a request in Invoke-EntraRequest.
		If the path provided is a full url, it will be returned as is.
		Otherwise, any present parameters will be resolved in the base service url before merging it with the specified path.
	
	.PARAMETER TokenObject
		The object representing the token used for the request.
	
	.PARAMETER ServiceObject
		The service object (if any) used with the request.
		The parameters to be inserted into the query will be read from here.
	
	.PARAMETER BoundParameters
		The parameters provided to Invoke-EntraRequest.
	
	.EXAMPLE
		PS C:\> Resolve-RequestUri -TokenObject $tokenObject -ServiceObject $script:_EntraEndpoints.$($tokenObject.Service) -BoundParameters $PSBoundParameters

		Resolves the uri for the needed request based on token, service and parameters provided
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$TokenObject,

		[Parameter(Mandatory = $true)]
		[AllowNull()]
		$ServiceObject,

		[Parameter(Mandatory = $true)]
		$BoundParameters
	)
	process {
		if ($BoundParameters.Path -match '^https{0,1}://') {
			return $BoundParameters.Path
		}

		$serviceUrlBase = $TokenObject.ServiceUrl.Trim()
		foreach ($key in $ServiceObject.Parameters.Keys) {
			$serviceUrlBase = $serviceUrlBase -replace "%$key%", $BoundParameters.$key
		}

		"$($serviceUrlBase.TrimEnd('/'))/$($Path.TrimStart('/'))"
	}
}