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

	.PARAMETER Parameters
		Extra parameters a request will require.
		It expects a hashtable with the key being the parameter name, and the value being a description of that parameter.
		The ServiceUrl must include a placeholder for each parameter to insert into it.

		Example:
		Parameter: @{ VaultName = 'Name of the Key Vault to execute against' }
		ServiceUrl: https://%VAULTNAME%.vault.azure.net

	.PARAMETER Query
		Extra Query Parameters to automatically include on all requests.

	.PARAMETER RawOnly
		Disable default API response handling.
		By default, when executing a request via Invoke-EntraRequest, the response is processed as if it were a default Graph API standard response.
		Many other MS APIs follow the same standard, but not all do so.
		When enabling this setting on a service, all requests against that service will NOT have that processing applied and instead return raw responses.

	.PARAMETER Environment
		What environment this service should connect to.
		Defaults to: 'Global'

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
		Usually determined by the "Environment" parameter, but may be overridden in case of need.
	
	.EXAMPLE
		PS C:\> Register-EntraService -Name Endpoint -ServiceUrl 'https://api.securitycenter.microsoft.com/api' -Resource 'https://api.securitycenter.microsoft.com'

		Registers the defender for endpoint API as a service.

    .EXAMPLE
        PS C:\> Register-EntraService -Name 'PowerBI' -ServiceUrl 'https://api.powerbi.com/v1.0/myorg' -Resource 'https://analysis.windows.net/powerbi/api' -DefaultScopes @('Dataset.Read.All', 'Report.Read.All') -Header @{ 'Accept' = 'application/json' }

        Registers Power BI REST API service with common read scopes and required headers.

    .EXAMPLE
        PS C:\> Register-EntraService -Name 'SharePointOnline' -ServiceUrl 'https://%TENANT%.sharepoint.com/_api' -Resource 'https://%TENANT%.sharepoint.com' -Parameters @{ Tenant = 'SharePoint tenant name (e.g., contoso)' } -DefaultScopes @('Sites.Read.All') -Query @{ '$format' = 'json' }

        Registers SharePoint Online REST API with dynamic tenant URL, requiring a tenant parameter and automatically formatting responses as JSON.

    .EXAMPLE
        PS C:\> Register-EntraService -Name 'CustomCRM' -ServiceUrl 'https://crm.contoso.com/api/v2' -Resource 'api://contoso-crm-app' -NoRefresh -RawOnly -Header @{ 'X-API-Version' = '2.0'; 'Accept' = 'application/json' }

        Registers a custom CRM API that doesn't support refresh tokens and requires raw response handling with custom API versioning headers.

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
		$NoRefresh,

		[hashtable]
		$Parameters = @{},

		[Hashtable]
		$Query = @{},

		[switch]
		$RawOnly,

		[Environment]
		$Environment = 'Global',

		[string]
		$AuthenticationUrl
	)
	process {
		$command = Get-Command Invoke-EntraRequest
		$badParameters = $Parameters.Keys | Where-Object { $_ -in $command.Parameters.Keys }
		if ($badParameters) {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Cannot define parameters that collide with Invoke-EntraRequest: $($badParameters -join ', ')"
		}
		$authUrl = switch ("$Environment") {
			'China' { 'https://login.chinacloudapi.cn' }
			'USGov' { 'https://login.microsoftonline.us' }
			'USGovDOD' { 'https://login.microsoftonline.us' }
			default { 'https://login.microsoftonline.com' }
		}
		if ($AuthenticationUrl) { $authUrl = $AuthenticationUrl.TrimEnd('/') }

		$script:_EntraEndpoints[$Name] = [PSCustomObject]@{
			PSTypeName        = 'EntraAuth.Service'
			Name              = $Name
			ServiceUrl        = $ServiceUrl
			Resource          = $Resource
			DefaultScopes     = $DefaultScopes
			Header            = $Header
			HelpUrl           = $HelpUrl
			NoRefresh         = $NoRefresh.ToBool()
			Parameters        = $Parameters
			Query             = $Query
			RawOnly           = $RawOnly.ToBool()
			AuthenticationUrl = $authUrl
		}
	}
}