function Import-EntraToken {
	<#
	.SYNOPSIS
		Imports a token into the local token store.
	
	.DESCRIPTION
		Imports a token into the local token store.
		This command is intended for use in a runspace scenario, for passing tokens from the main runspace into background environments.
		The input-token object is cloned into a runspace-local token object and registered to its service.

		After performing the conversion, it will try to renew the token object.
	
	.PARAMETER Token
		The token object to import.
		Should be a token object created by EntraAuth's Connect-EntraService command.
		Usually returned by Get-EntraToken, after finishing the connection.
	
	.PARAMETER PassThru
		Rather than registering the token into the Entra token store in memory, return it as an object.
		Useful for ronspace-localizing a token not associated with any given service.
	
	.PARAMETER NoRenew
		Do not renew the token after importing it.
		By default, newly localized tokens will try to renew themselves, to avoid parallel use of the same access token instance.
	
	.EXAMPLE
		PS C:\> Import-EntraToken -Token $using:tokens

		Imports all tokens stored in $tokens of the calling runspace.
		For use in scenarios such as background runspaces within "ForEach-Object -Parallel"
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[object[]]
		$Token,

		[switch]
		$PassThru,

		[switch]
		$NoRenew
	)
	process {
		foreach ($tokenObject in $Token) {
			$newToken = [EntraToken]::new()
			foreach ($propertyName in $newToken.PSObject.Properties.Name) {
				if ($null -eq $tokenObject.$propertyName) { continue }
				if ($tokenObject.$propertyName -is [hashtable]) {
					$newToken.$propertyName = $tokenObject.$propertyName.Clone()
				}
				else {
					$newToken.$propertyName = $tokenObject.$propertyName
				}
			}

			if (
				-not $newToken.Service -or
				-not $newToken.AccessToken -or
				-not $newToken.ClientID -or
				-not $newToken.TenantID
			) {
				Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Invalid Input Object! An Entra token object must have a Service, AccessToken, ClientID and TenantID. Item received: $tokenObject"
			}

			#region Renew Token
			if (
				-not $NoRenew -and
				(
					$newToken.Type -notin 'DeviceCode', 'Browser' -or
					$newToken.RefreshToken
				)
			) {
				$newToken.RenewToken()
			}
			#endregion Renew Token

			if ($PassThru) { $newToken }
			else { $script:_EntraTokens[$newToken.Service] = $newToken }
		}
	}
}