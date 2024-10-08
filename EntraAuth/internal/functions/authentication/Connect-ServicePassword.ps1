function Connect-ServicePassword {
	<#
    .SYNOPSIS
        Connect to graph using username and password.
    
    .DESCRIPTION
        Connect to graph using username and password.
        This logs into graph as a user, not as an application.
        Only cloud-only accounts can be used for this workflow.
        Consent to scopes must be granted before using them, as this command cannot show the consent prompt.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.

    .PARAMETER Credential
        Credentials of the user to connect as.
        
    .PARAMETER TenantID
        The Guid of the tenant to connect to.

    .PARAMETER ClientID
        The ClientID / ApplicationID of the application to use.
    
    .PARAMETER Scopes
        The permission scopes to request.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
    
    .EXAMPLE
        PS C:\> Connect-ServicePassword -Credential max@contoso.com -ClientID $client -TenantID $tenant -Scopes 'user.read','user.readbasic.all'
        
        Connect as max@contoso.com with the rights to read user information.
    #>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$Credential,
        
		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,
        
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,
        
		[string[]]
		$Scopes = '.default',

		[Parameter(Mandatory = $true)]
        [string]
		$AuthenticationUrl
	)

	$actualScopes = $Scopes | Resolve-ScopeName -Resource $Resource
    
	$request = @{
		client_id  = $ClientID
		scope      = $actualScopes -join " "
		username   = $Credential.UserName
		password   = $Credential.GetNetworkCredential().Password
		grant_type = 'password'
	}
    
	try { $authResponse = Invoke-RestMethod -Method POST -Uri "$AuthenticationUrl/$TenantID/oauth2/v2.0/token" -Body $request -ErrorAction Stop }
	catch { throw }
	
	Read-AuthResponse -AuthResponse $authResponse
}