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