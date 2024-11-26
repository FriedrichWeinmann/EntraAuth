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
		[Parameter(Mandatory = $true, ParameterSetName = 'Token')]
		$Token,

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[string]
		$RefreshToken,

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[string]
		$TenantID,

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[string]
		$ClientID,

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[string]
		$Resource,

		[Parameter(ParameterSetName = 'Details')]
		[string[]]
		$Scopes = '.default',

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
        [string]
		$AuthenticationUrl
	)
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'Token' {
				if (-not $Token.RefreshToken) {
					throw "Failed to refresh token: No refresh token found!"
				}
		
				$effectiveScopes = $Token.Scopes
		
				$body = @{
					client_id = $Token.ClientID
					scope = @($effectiveScopes).ForEach{"$($Token.Audience)/$($_)"} -join " "
					refresh_token = $Token.RefreshToken
					grant_type = 'refresh_token'
				}
				$uri = "$($Token.AuthenticationUrl)/$($Token.TenantID)/oauth2/v2.0/token"
				$authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body
				$Token.SetTokenMetadata((Read-AuthResponse -AuthResponse $authResponse))
			}
			'Details' {
				$effectiveScopes = foreach ($scope in $Scopes) {
					if ($scope -like "$Resource*") { $scope }
					else { "$Resource/$scope" }
				}

				$body = @{
					client_id = $ClientID
					scope = $effectiveScopes -join " "
					refresh_token = $RefreshToken
					grant_type = 'refresh_token'
				}
				$uri = "$($AuthenticationUrl)/$($TenantID)/oauth2/v2.0/token"
				$authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body
				Read-AuthResponse -AuthResponse $authResponse
			}
		}
	}
}