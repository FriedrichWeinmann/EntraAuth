function Connect-ServiceAzure {
	<#
	.SYNOPSIS
		Authenticates using the established session from Az.Accounts.
	
	.DESCRIPTION
		Authenticates using the established session from Az.Accounts.
		This limits the scopes available to what is configured on the Az Application, but makes it easy to authenticate without active interaction.

		Pretty useful for authenticating to custom apps that do not actually implement scopes.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.
	
	.PARAMETER ShowDialog
		Whether to show a dialog in case of interaction being needed.
		Defaults to: auto
	
	.EXAMPLE
		PS C:\> Connect-ServiceAzure -Resource 'https://graph.microsoft.com'
		
		Connect to graph using the existing az.accounts session.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[ValidateSet('Auto', 'Always', 'Never')]
		[string]
		$ShowDialog = 'Auto'
	)
	process {
		try { $azContext = Get-AzContext -ErrorAction Stop }
		catch { Invoke-TerminatingException -Cmdlet $PSCmdlet -Message 'Error accessing azure context. Ensure the module "Az.Accounts" is installed and you have connected via "Connect-AzAccount"!' -ErrorRecord $_ }
	
		try {
			$result = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
				$azContext.Account,
				$azContext.Environment,
				"$($azContext.Tenant.id)",
				$null,
				$ShowDialog,
				$null,
				$Resource
			)
		
		}
		catch { Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Error retrieving token from Azure for '$Resource': $_" -ErrorRecord $_ }

		$tokenData = Read-TokenData -Token $result.AccessToken

		# A Fake AuthResponse result - Should keep the same layout as the result of Read-AuthResponse
		[PSCustomObject]@{
			AccessToken  = $result.AccessToken
			ValidAfter   = Get-Date
			ValidUntil   = $result.ExpiresOn.LocalDateTime
			Scopes       = $tokenData.scp -split ' '
			RefreshToken = $null

			# For Initial Connect Metadata
			ClientID = $tokenData.appid
			TenantID = $tokenData.tid
		}
	}
}