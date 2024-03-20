function Register-EntraService {
	<#
	.SYNOPSIS
		Define a new Entra ID Service to connect to.
	
	.DESCRIPTION
		Define a new Entra ID Service to connect to.
		This allows defining new endpoints to connect to ... or overriding existing endpoints to a different configuration.
	
	.PARAMETER Name
		Name of the Service.
	
	.PARAMETER ServiceUrl
		The base Url requests will use.
	
	.PARAMETER Resource
		The Resource ID. Used when connecting to identify which scopes of an App Registration to use.
	
	.PARAMETER DefaultScopes
		Default scopes to request.
		Used in interactive delegate flows to provide a good default user experience.
		Default scopes should usually include common read scenarios.

	.PARAMETER Header
		Header data to include in each request.
	
	.PARAMETER HelpUrl
		Link for more information about this service.
		Ideally to documentation that helps setting up the connection.

	.PARAMETER NoRefresh
		Delegate authentication flows should not request refresh tokens.
		By default, delegate authentication flows will automatically request offline_access to get a refresh token.
		This refresh token allows requesting new tokens when the current one is expiring without requiring additional
		interactive logon actions.
		However, not all services support this scope.
	
	.EXAMPLE
		PS C:\> Register-EntraService -Name Endpoint -ServiceUrl 'https://api.securitycenter.microsoft.com/api' -Resource 'https://api.securitycenter.microsoft.com'
		
		Registers the defender for endpoint API as a service.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[string]
		$ServiceUrl,

		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[AllowEmptyCollection()]
		[string[]]
		$DefaultScopes = @(),

		[hashtable]
		$Header = @{},

		[string]
		$HelpUrl,

		[switch]
		$NoRefresh
	)
	process {
		$script:_EntraEndpoints[$Name] = [PSCustomObject]@{
			PSTypeName    = 'EntraAuth.Service'
			Name          = $Name
			ServiceUrl    = $ServiceUrl
			Resource      = $Resource
			DefaultScopes = $DefaultScopes
			Header        = $Header
			HelpUrl       = $HelpUrl
			NoRefresh     = $NoRefresh.ToBool()
		}
	}
}