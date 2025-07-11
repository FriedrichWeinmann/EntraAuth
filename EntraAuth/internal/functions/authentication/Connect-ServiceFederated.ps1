function Connect-ServiceFederated {
	<#
	.SYNOPSIS
		Authenticate using the Federated Credentials flow.
	
	.DESCRIPTION
		Authenticate using the Federated Credentials flow.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.
	
	.PARAMETER ClientID
		The ID of the registered app used with this authentication request.
	
	.PARAMETER TenantID
		The ID of the tenant connected to with this authentication request.
	
	.PARAMETER Provider
		The name of the provider to use.
		Overrides auto-selection if provided.

	.PARAMETER Assertion
		An externally provided assertion from the federated authentication provider.
		This skips the internal assertion resolution process and moves straight to the authentication to Entra

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
	
	.EXAMPLE
		PS C:\> Connect-ServiceFederated -ClientID '<ClientID>' -TenantID '<TenantID>' -Resource '<Resource>' -AuthenticationUrl 'https://login.microsoftonline.com'

		Connects to the specified tenant using the specified client and automatically calculated federated credential.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,
		
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,
		
		[AllowEmptyString()]
		[string]
		$Provider,

		[AllowEmptyString()]
		[string]
		$Assertion,

		[Parameter(Mandatory = $true)]
		[string]
		$AuthenticationUrl
	)
	process {
		$providerObject = $null
		$myAssertion = $Assertion
		if (-not $myAssertion) {
			if ($Provider) { $providerObject = $script:_FederationProviders[$Provider] }
			else { $providerObject = Resolve-EntraFederationProvider }

			if (-not $providerObject) {
				Invoke-TerminatingException -Cmdlet $PSCmdlet -Category AuthenticationError -Message "Unable to find an applicable Federation Provider! Ensure you have a Federation Provider registered and are running in an environment where detection can work."
			}

			try { $myAssertion = & $providerObject.Code }
			catch { Invoke-TerminatingException -Cmdlet $PSCmdlet -ErrorRecord $_ -Message "Failed to access a token from the federated identity provider! $_" }
		}

		$body = @{
			resource              = $Resource
			client_id             = $ClientID
			client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
			client_assertion      = $myAssertion
			grant_type            = 'client_credentials'
		}
		try { $authResponse = Invoke-RestMethod -Method Post -Uri "$AuthenticationUrl/$TenantId/oauth2/token" -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop }
		catch { throw }
		
		Read-AuthResponse -AuthResponse $authResponse
		if ($providerObject) { return $providerObject }
		[FederationProvider]@{
			Assertion = $myAssertion
		}
	}
}