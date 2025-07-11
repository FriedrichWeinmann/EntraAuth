function Register-EntraFederationProvider {
	<#
	.SYNOPSIS
		Register logic to automatically retrieve the assertion needed in a Federated Credential authentication flow.
	
	.DESCRIPTION
		Register logic to automatically retrieve the assertion needed in a Federated Credential authentication flow.
		Federated credentials allow granting access to a trusted entity without requiring a secret.

		For example, with that it becomes possible, to authorize a github action to authenticate to Entra.
		However, in order for the Github Action to be able to do that, it first needs to authenticate to Github and get a special token.

		This provider defined here serves to implement that step - and to allow you to do the same for your own providers.

		More Resources on Federated Credentials:
		https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp
		https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow?wt.mc_id=SEC-MVP-5004985#third-case-access-token-request-with-a-federated-credential
	
	.PARAMETER Name
		The name of the Federation Provider.
		Pick something that represents the context the user would expect (e.g. "GithubAction", "FunctionApp", ...).
		It usually would be related to the environment from which you connect.
	
	.PARAMETER Description
		A description of the provider.
		Especially useful to explain non-intuitive setup steps that are required to get things started.
	
	.PARAMETER Priority
		How high the priority of the provider is.
		The lower the number, the earlier it is tested for.
		This property is used when auto-detecting which Federation Provider should be used.
		The first match will stop further processing.
	
	.PARAMETER Test
		A piece of code used to test, whether the Federation Provider can be used in the current situation.
		This is used when trying to automatically detect, which provider to use.
	
	.PARAMETER Code
		Code that generates a JWT token used as an Assertion for the Entra authentication, essentially serving as its secret.
	
	.EXAMPLE
		PS C:\> Register-EntraFederationProvider -Name GithubAction -Priority 10 -Description 'For use within a Github Action. Remember to configure your workflow to use the "id-token: write" permission' -Test $test -Code $authCode
		
		Configures the GithubAction Federation Provider.
		Assuming the scriptblocks provided work, this will allow simply running something like this within a Github Action:
		Connect-EntraService -ClientID $clientID -TenantID $tenantID -Federated
		Hint: This provider is preconfigured in EntraAuth, so this should work as it is. Use Get-EntraFederationProvider to inspect the actual implementing code.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[string]
		$Description,

		[int]
		$Priority = 50,

		[Parameter(Mandatory = $true)]
		[scriptblock]
		$Test,

		[Parameter(Mandatory = $true)]
		[scriptblock]
		$Code
	)
	process {
		$script:_FederationProviders[$Name] = [FederationProvider]@{
			Name        = $Name
			Description = $Description
			Priority    = $Priority
			Test        = $Test
			Code        = $Code
			Type        = 'Registered'
		}
	}
}