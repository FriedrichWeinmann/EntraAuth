function Read-AuthResponse {
	<#
	.SYNOPSIS
		Produces a standard output representation of the authentication response received.
	
	.DESCRIPTION
		Produces a standard output representation of the authentication response received.
		This streamlines the token processing and simplifies the connection code.
	
	.PARAMETER AuthResponse
		The authentication response received.
	
	.EXAMPLE
		PS C:\> Read-AuthResponse -AuthResponse $authResponse

		Reads the authentication details received.
	#>
	[CmdletBinding()]
	param (
		$AuthResponse
	)
	process {
		if ($AuthResponse.expires_in) {
			$after = (Get-Date).AddMinutes(-5)
			$until = (Get-Date).AddSeconds($AuthResponse.expires_in)
		}
		else {
			if ($AuthResponse.not_before)  { $after = (Get-Date -Date '1970-01-01').AddSeconds($AuthResponse.not_before).ToLocalTime() }
			else { $after = Get-Date }
			$until = (Get-Date -Date '1970-01-01').AddSeconds($AuthResponse.expires_on).ToLocalTime()
		}
		$scopes = @()
		if ($AuthResponse.scope) { $scopes = $authResponse.scope -split " " }

		# If updating this layout, also update in Connect-ServiceAzure, which fakes this object
		[pscustomobject]@{
			AccessToken  = $AuthResponse.access_token
			ValidAfter   = $after
			ValidUntil   = $until
			Scopes       = $scopes
			RefreshToken = $AuthResponse.refresh_token
		}
	}
}