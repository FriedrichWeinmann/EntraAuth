function Resolve-EntraFederationProvider {
	<#
	.SYNOPSIS
		Resolves which Federation Provider to use to calculate the Federation Credentials to use.
		
	.DESCRIPTION
		Resolves which Federation Provider to use to calculate the Federation Credentials to use.
		This executes the test code for all registered providers (in the order of their priority) until one applies.

		Federation Providers are an EntraAuth concept and used to automatically do what is needed to access and use a Federated Credential, based on its environment.
		See the documentation on Register-EntraFederationProvider for more details.
	
	.PARAMETER Exclude
		The Federation Provider to skip.

	.PARAMETER Parameters
		Additional parameters to provide to a FederationProvider.
		In case a specific provider needs extra data to operate as desired.
		For example, the EntraMSI provider can receive "IdentityID" and "IdentityType" to support user-assigned managed identities.

		ALL providers receive the data, should only use their own needed parameters and handle incomplete parameters gracefully.
	
	.EXAMPLE
		PS C:\> Resolve-EntraFederationProvider

		Resolves which Federation Provider to use to calculate the Federation Credentials to use.
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
		[string[]]
		$Exclude,

		[AllowNull()]
		[hashtable]
		$Parameters
	)
	begin {
		if ($null -eq $Parameters) {
			$Parameters = @{}
		}
	}
	process {
		foreach ($provider in Get-EntraFederationProvider | Sort-Object Priority) {
			if ($provider.Name -in $Exclude) { continue }

			if (& $provider.Test $Parameters) { return $provider }
		}
	}
}