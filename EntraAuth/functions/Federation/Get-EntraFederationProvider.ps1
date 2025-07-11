function Get-EntraFederationProvider {
	<#
	.SYNOPSIS
		Lists all registered Federation Providers.
		
	.DESCRIPTION
		Lists all registered Federation Providers.
		Federation Providers are an EntraAuth concept and used to automatically do what is needed to access and use a Federated Credential, based on its environment.
		See the documentation on Register-EntraFederationProvider for more details.
	
	.PARAMETER Name
		The name of the provider to filter by.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-EntraFederationProvider

		Lists all registered Federation Providers.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding()]
	param (
		[ArgumentCompleter({
			param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
			foreach ($provider in Get-EntraFederationProvider) {
				if ($provider.Name -notlike "$wordToComplete*") { continue }
				$text = $provider.Name
				if ($text -match '\s') { $text = "'$($provider.Name -replace "'", "''")'" }

				[System.Management.Automation.CompletionResult]::new($text, $text, 'ParameterValue', $provider.Description)
			}
		})]
		[string]
		$Name = '*'
	)
	process {
		($script:_FederationProviders.Values) | Where-Object Name -Like $Name | Sort-Object Priority
	}
}