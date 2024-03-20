function Get-EntraToken {
	<#
	.SYNOPSIS
		Returns the session token of an Entra ID connection.
	
	.DESCRIPTION
		Returns the session token of an Entra ID connection.
		The main use for those token objects is calling their "GetHeader()" method to get an authentication header
		that automatically refreshes tokens as needed.
	
	.PARAMETER Service
		The service for which to retrieve the token.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-EntraToken
		
		Returns all current session tokens
	#>
	[CmdletBinding()]
	param (
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[string]
		$Service = '*'
	)
	process {
		$script:_EntraTokens.Values | Where-Object Service -like $Service
	}
}