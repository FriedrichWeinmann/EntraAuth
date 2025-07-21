# Default Federation Providers, to enable easy automatic Federation Authentication

#-> Github Actions
$param = @{
	Name        = 'GithubAction'
	Description = 'For within the runtime of a Github Action runner. The workflow must define the permission "id-token: write", in order for the authentication to be valid.'
	Priority    = 10 # Lower = Attempted earlier
	Test        = {
		if ($env:ACTIONS_ID_TOKEN_REQUEST_URL -and $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN) { return $true }

		# If running in an Action but no token, warn about the misconfiguration
		if (-not $env:GITHUB_ACTION -or -not $env:GITHUB_REPOSITORY) { return }

		Write-Warning @'
Github Action Runner detected, but no token available.
This usually happens based on a misconfiguration, with the Workflow not being granted access to the id-token needed.
Permission needed:
  id-token: write
For more information on Github Action permission configuration, see this documentation:
https://docs.github.com/en/actions/how-tos/writing-workflows/choosing-what-your-workflow-does/controlling-permissions-for-github_token
'@
	}
	Code        = {
		$response = Invoke-RestMethod -Uri "$env:ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" -Headers @{
			Authorization = "Bearer $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN"
		} -ErrorAction Stop
		$response.Value
	}
}
Register-EntraFederationProvider @param

$param = @{
	Name = 'EntraMSI'
	Description = 'Authenticate as the Managed Identity in the current context.'
	Priority = 20
	Test = {
		try {
			$null = Connect-EntraService -Identity -Resource 'api://AzureADTokenExchange' -ErrorAction Stop
			$true
		}
		catch { $false }
	}
	code = {
		(Connect-EntraService -Identity -Resource 'api://AzureADTokenExchange').AccessToken
	}
}
Register-EntraFederationProvider @param