function Assert-ServiceName {
	<#
	.SYNOPSIS
		Asserts a service name actually exists.
	
	.DESCRIPTION
		Asserts a service name actually exists.
		Used in validation scripts to ensure proper service names were provided.
	
	.PARAMETER Name
		The name of the service to verify.
	
	.EXAMPLE
		PS C:\> Assert-ServiceName -Name $_
		
		Returns $true if the service exists and throws a terminating exception if not so.
	#>
	[OutputType([bool])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[AllowNUll()]
		[string]
		$Name
	)
	process {
		if ($script:_EntraEndpoints.Keys -contains $Name) { return $true }

		$serviceNames = $script:_EntraEndpoints.Keys -join ', '
		Write-Warning "Invalid service name: '$Name'. Legal service names: $serviceNames"
		Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Invalid service name: '$Name'. Legal service names: $serviceNames"
	}
}