function Assert-ServiceName {
	<#
	.SYNOPSIS
		Asserts a service name actually exists.
	
	.DESCRIPTION
		Asserts a service name actually exists.
		Used in validation scripts to ensure proper service names were provided.
	
	.PARAMETER Name
		The name of the service to verify.

	.PARAMETER IncludeTokens
		Also include registered token's services in the assertion.
		By default, the assertion will only verify the existence of registered services.
	
	.EXAMPLE
		PS C:\> Assert-ServiceName -Name $_
		
		Returns $true if the service exists and throws a terminating exception if not so.
	#>
	[OutputType([bool])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$Name,

		[switch]
		$IncludeTokens
	)
	process {
		if ($script:_EntraEndpoints.Keys -contains $Name) { return $true }
		if ($IncludeTokens -and $script:_EntraTokens.Keys -contains $Name) { return $true }

		$serviceNames = $script:_EntraEndpoints.Keys -join ', '
		Write-Warning "Invalid service name: '$Name'. Legal service names: $serviceNames"
		Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Invalid service name: '$Name'. Legal service names: $serviceNames"
	}
}