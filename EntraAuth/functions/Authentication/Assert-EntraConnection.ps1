function Assert-EntraConnection
{
<#
	.SYNOPSIS
		Asserts a connection has been established.
	
	.DESCRIPTION
		Asserts a connection has been established.
		Fails the calling command in a terminating exception if not connected yet.
		
	.PARAMETER Service
		The service to which a connection needs to be established.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command.
		Used to execute the terminating exception in the caller scope if needed.

	.PARAMETER RequiredScopes
		Scopes needed, for better error messages.
	
	.EXAMPLE
		PS C:\> Assert-EntraConnection -Service 'Endpoint' -Cmdlet $PSCmdlet
	
		Silently does nothing if already connected to the specified defender for endpoint service.
		Kills the calling command if not yet connected.
#>
	[CmdletBinding()]
	param (
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[Parameter(Mandatory = $true)]
		[string]
		$Service,
		
		[Parameter(Mandatory = $true)]
		$Cmdlet,
		
		[AllowEmptyCollection()]
		[string[]]
		$RequiredScopes
	)
	
	process
	{
		if ($script:_EntraTokens["$Service"]) { return }
		
		$message = "Not connected yet! Use Connect-EntraService to establish a connection to '$Service' first."
		if ($RequiredScopes) { $message = $message + " Scopes required for this call: $($RequiredScopes -join ', ')"}
		Invoke-TerminatingException -Cmdlet $Cmdlet -Message  -Category ConnectionError
	}
}