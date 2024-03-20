function Get-EntraService {
	<#
	.SYNOPSIS
		Returns the list of available Entra ID services that can be connected to.
	
	.DESCRIPTION
		Returns the list of available Entra ID services that can be connected to.
		Includes for each the endpoint/service url and the default requested scopes.
	
	.PARAMETER Name
		Name of the service to return.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-EntraService

		List all available services.
	#>
	[CmdletBinding()]
	param (
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[string]
		$Name = '*'
	)
	process {
		$script:_EntraEndpoints.Values | Where-Object Name -like $Name
	}
}