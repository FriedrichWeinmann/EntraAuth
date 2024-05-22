# Registers the default service configurations
$endpointCfg = @{
	Name          = 'Endpoint'
	ServiceUrl    = 'https://api.securitycenter.microsoft.com/api'
	Resource      = 'https://api.securitycenter.microsoft.com'
	DefaultScopes = @()
	Header        = @{ 'Content-Type' = 'application/json' }
	HelpUrl       = 'https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api/apis-intro?view=o365-worldwide'
}
Register-EntraService @endpointCfg

$securityCfg = @{
	Name          = 'Security'
	ServiceUrl    = 'https://api.security.microsoft.com/api'
	Resource      = 'https://security.microsoft.com/mtp/'
	DefaultScopes = @('AdvancedHunting.Read')
	Header        = @{ 'Content-Type' = 'application/json' }
	HelpUrl       = 'https://learn.microsoft.com/en-us/microsoft-365/security/defender/api-create-app-web?view=o365-worldwide'
}
Register-EntraService @securityCfg

$graphCfg = @{
	Name          = 'Graph'
	ServiceUrl    = 'https://graph.microsoft.com/v1.0'
	Resource      = 'https://graph.microsoft.com'
	DefaultScopes = @()
	HelpUrl       = 'https://developer.microsoft.com/en-us/graph/quick-start'
}
Register-EntraService @graphCfg

$graphBetaCfg = @{
	Name          = 'GraphBeta'
	ServiceUrl    = 'https://graph.microsoft.com/beta'
	Resource      = 'https://graph.microsoft.com'
	DefaultScopes = @()
	HelpUrl       = 'https://developer.microsoft.com/en-us/graph/quick-start'
}
Register-EntraService @graphBetaCfg

$azureCfg = @{
	Name          = 'Azure'
	ServiceUrl    = 'https://management.azure.com'
	Resource      = 'https://management.core.windows.net/'
	DefaultScopes = @()
	HelpUrl       = 'https://learn.microsoft.com/en-us/rest/api/azure/?view=rest-resources-2022-12-01'
}
Register-EntraService @azureCfg

$azureKeyVaultCfg = @{
	Name          = 'AzureKeyVault'
	ServiceUrl    = 'https://%VAULTNAME%.vault.azure.net'
	Resource      = 'https://vault.azure.net'
	DefaultScopes = @()
	HelpUrl       = 'https://learn.microsoft.com/en-us/rest/api/keyvault/?view=rest-keyvault-secrets-7.4'
	Parameters    = @{
		VaultName = 'Name of the Key Vault to execute against'
	}
	Query         = @{
		'api-version' = '7.4'
	}
}
Register-EntraService @azureKeyVaultCfg