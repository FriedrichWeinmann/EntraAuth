function Set-EntraService {
	<#
	.SYNOPSIS
		Modify the settings on an existing Service configuration.
	
	.DESCRIPTION
		Modify the settings on an existing Service configuration.
		Service configurations are defined using Register-EntraService and define how connections and requests to a specific API service / endpoint are performed.
	
	.PARAMETER Name
		The name of the already existing Service configuration.
	
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
		PS C:\> Set-EntraService -Name Endpoint -ServiceUrl 'https://api-us.securitycenter.microsoft.com/api'

		Changes the service url for the "Endpoint" service to 'https://api-us.securitycenter.microsoft.com/api'.
		Note: It is generally recommened to select the service url most suitable for your tenant, geographically:
		https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api/exposed-apis-list?view=o365-worldwide#versioning
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[ValidateScript({ Assert-ServiceName -Name $_ })]
		[string]
		$Name,

		[string]
		$ServiceUrl,

		[string]
		$Resource,

		[AllowEmptyCollection()]
		[string[]]
		$DefaultScopes,

		[Hashtable]
		$Header,

		[string]
		$HelpUrl,

		[switch]
		$NoRefresh
	)
	process {
		$service = $script:_EntraEndpoints.$Name
		if ($PSBoundParameters.Keys -contains 'ServiceUrl') { $service.ServiceUrl = $ServiceUrl }
		if ($PSBoundParameters.Keys -contains 'Resource') { $service.Resource = $Resource }
		if ($PSBoundParameters.Keys -contains 'DefaultScopes') { $service.DefaultScopes = $DefaultScopes }
		if ($PSBoundParameters.Keys -contains 'Header') { $service.Header = $Header }
		if ($PSBoundParameters.Keys -contains 'HelpUrl') { $service.HelpUrl = $HelpUrl }
		if ($PSBoundParameters.Keys -contains 'NoRefresh') { $service.HelpUrl = $NoRefresh.ToBool() }
	}
}