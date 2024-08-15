function Connect-ServiceRefreshToken {
	<#
	.SYNOPSIS
		Connect with the refresh token provided previously.
	
	.DESCRIPTION
		Connect with the refresh token provided previously.
		Used mostly for delegate authentication flows to avoid interactivity.

	.PARAMETER Token
		The EntraToken object with the refresh token to use.
		The token is then refreshed in-place with no output provided.
	
	.EXAMPLE
		PS C:\> Connect-ServiceRefreshToken
		
		Connect with the refresh token provided previously.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$Token
	)
	process {
		if (-not $Token.RefreshToken) {
			throw "Failed to refresh token: No refresh token found!"
		}

		$scopes = $Token.Scopes

		$body = @{
			client_id = $Token.ClientID
			scope = @($scopes).ForEach{"$($Token.Audience)/$($_)"} -join " "
			refresh_token = $Token.RefreshToken
			grant_type = 'refresh_token'
		}
		$uri = "$($Token.AuthenticationUrl)/$($Token.TenantID)/oauth2/v2.0/token"
		$authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body
		$Token.SetTokenMetadata((Read-AuthResponse -AuthResponse $authResponse))
	}
}