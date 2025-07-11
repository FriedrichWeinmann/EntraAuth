﻿function Connect-EntraService {
	<#
	.SYNOPSIS
		Establish a connection to an Entra Service.
	
	.DESCRIPTION
		Establish a connection to an Entra Service.
		Prerequisite before executing any requests / commands.
	
	.PARAMETER ClientID
		ID of the registered/enterprise application used for authentication.

		Supports providing special labels as "ID":
		+ Azure: Resolves to the actual ID of the first party app used by Connect-AzAccount
		+ Graph: Resolves to the actual ID of the first party app used by Connect-MgGraph
	
	.PARAMETER TenantID
		The ID of the tenant/directory to connect to.
	
	.PARAMETER Scopes
		Any scopes to include in the request.
		Only used for interactive/delegate workflows, ignored for Certificate based authentication or when using Client Secrets.

	.PARAMETER Browser
		Use an interactive logon in your default browser.
		This is the default logon experience.

	.PARAMETER BrowserMode
		How the browser used for authentication is selected.
		Options:
		+ Auto (default): Automatically use the default browser.
		+ PrintLink: The link to open is printed on console and user selects which browser to paste it into (must be used on the same machine)

	.PARAMETER DeviceCode
		Use the Device Code delegate authentication flow.
		This will prompt the user to complete login via browser.

	.PARAMETER RefreshToken
		Use an already existing RefreshToken to authenticate.
		Can be used to connect to multiple services using a single interactive delegate auth flow.

	.PARAMETER RefreshTokenObject
		Use the full token object of a delegate session with a refresh token, to authenticate to another service with this object.
		Can be used to connect to multiple services using a single interactive delegate auth flow.
	
	.PARAMETER Certificate
		The Certificate object used to authenticate with.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificateThumbprint
		Thumbprint of the certificate to authenticate with.
		The certificate must be stored either in the user or computer certificate store.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificateName
		The name/subject of the certificate to authenticate with.
		The certificate must be stored either in the user or computer certificate store.
		The newest certificate with a private key will be chosen.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificatePath
		Path to a PFX file containing the certificate to authenticate with.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificatePassword
		Password to use to read a PFX certificate file.
		Only used together with -CertificatePath.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER ClientSecret
		The client secret configured in the registered/enterprise application.
		
		Part of the Client Secret Certificate authentication workflow.

	.PARAMETER Credential
		The username / password to authenticate with.

		Part of the Resource Owner Password Credential (ROPC) workflow.

	.PARAMETER VaultName
		Name of the Azure Key Vault from which to retrieve the certificate or client secret used for the authentication.
		Secrets retrieved from the vault are not cached, on token expiration they will be retrieved from the Vault again.
		In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
		or are connected via Connect-AzAccount.

	.PARAMETER SecretName
		Name of the secret to use from the Azure Key Vault specified through the '-VaultName' parameter.
		In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
		or are connected via Connect-AzAccount.
		Supports specifying _multiple_ secret names, in which case the first one that works will be used.

	.PARAMETER Identity
		Log on as the Managed Identity of the current system.
		Only works in environments with managed identities, such as Azure Function Apps or Runbooks.

	.PARAMETER IdentityID
		ID of the User-Managed Identity to connect as.
		https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity

	.PARAMETER IdentityType
		Type of the User-Managed Identity.

	.PARAMETER FallBackAzAccount
		When logon as Managed Identity fails, try logging in as current AzAccount.
		This is intended to allow easier local testing of code intended for an MSI environment, such as an Azure Function App.

	.PARAMETER AsAzAccount
		Reuse the existing Az.Accounts session to authenticate.
		This is convenient as no further interaction is needed, but also limited in what scopes are available.
		This authentication flow requires the 'Az.Accounts' module to be present, loaded and connected.
		Use 'Connect-AzAccount' to connect first.

	.PARAMETER ShowDialog
		Whether to show an interactive dialog when connecting using the existing Az.Accounts session.
		Defaults to: "auto"

		Options:
		- auto: Shows dialog only if needed.
		- always: Will always show the dialog, forcing interaction.
		- never: Will never show the dialog. Authentication will fail if interaction is required.

	.PARAMETER Federated
		Use federated credentials to authenticate.
		This authentication flow is specific to a given environment and can for example enable a Github Action in a specific repository on a specific branch to authenticate, without needing to provide (and manage) a credential.
		Some setup is required.

		By default, this command is going to check all provided configurations ("Federation Providers") registered to EntraAuth and use the first that applies.
		Use "-FederationProvider" to pick a specific one to use.
		Use "-Assertion" to handle the federated identity provider outside of EntraAuth and simply provide the result for logon.

	.PARAMETER FederationProvider
		The name of the Federation Provider to use. Overrides the automatic selection.
		Federation Providers are an EntraAuth concept and used to automatically do what is needed to access and use a Federated Credential, based on its environment.
		See the documentation on Register-EntraFederationProvider for more details.

	.PARAMETER Assertion
		The credentials from the federated identity provider to use in an Federated Credentials authentication flow.

	.PARAMETER Service
		The service to connect to.
		Individual commands using Invoke-EntraRequest specify the service to use and thus identify the token needed.
		Defaults to: Graph

	.PARAMETER ServiceUrl
		The base url for requests to the service connecting to.
		Overrides the default service url configured with the service settings.

	.PARAMETER Resource
		The resource to authenticate to.
		Used to authenticate to a service without requiring a full service configuration.
		Automatically implies PassThru.
		This token is not registered as a service and cannot be implicitly  used by Invoke-EntraRequest.
		Also provide the "-ServiceUrl" parameter, if you later want to use this token explicitly in Invoke-EntraRequest.

	.PARAMETER UseRefreshToken
		Use a refresh token if available.
		Only applicable when connecting using a delegate authentication flow.
		If specified, it will look to reuse an existing refresh token for that same client ID & tenant ID, if present,
		making the authentication process non-interactive.
		By default, it would always do the fully interactive authentication flow via Browser.

	.PARAMETER MakeDefault
		Makes this service the new default service for all subsequent Connect-EntraService & Invoke-EntraRequest calls.

	.PARAMETER PassThru
		Return the token received for the current connection.

	.PARAMETER Environment
		What environment this service should connect to.
		Defaults to: 'Global'

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
		Usually determined by service connected to or the "Environment" parameter, but may be overridden in case of need.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID
	
		Establish a connection to the graph API, prompting the user for login on their default browser.

	.EXAMPLE
		PS C:\> connect-EntraService -AsAzAccount

		Establish a connection to the graph API, using the current Az.Accounts session.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -Certificate $cert
	
		Establish a connection to the graph API using the provided certificate.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -CertificatePath C:\secrets\certs\mde.pfx -CertificatePassword (Read-Host -AsSecureString)
	
		Establish a connection to the graph API using the provided certificate file.
		Prompts you to enter the certificate-file's password first.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -Service Endpoint -ClientID $clientID -TenantID $tenantID -ClientSecret $secret
	
		Establish a connection to Defender for Endpoint using a client secret.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -VaultName myVault -Secretname GraphCert
	
		Establish a connection to the graph API, after retrieving the necessary certificate from the specified Azure Key Vault.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding(DefaultParameterSetName = 'Browser')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Browser')]
		[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppCertificate')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppSecret')]
		[Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Federated')]
		[ArgumentCompleter({ 'Graph', 'Azure' })]
		[string]
		$ClientID,
		
		[Parameter(ParameterSetName = 'Browser')]
		[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppCertificate')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppSecret')]
		[Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Federated')]
		[string]
		$TenantID = 'organizations',
		
		[Parameter(ParameterSetName = 'Browser')]
		[Parameter(ParameterSetName = 'DeviceCode')]
		[Parameter(ParameterSetName = 'Refresh')]
		[Parameter(ParameterSetName = 'RefreshObject')]
		[string[]]
		$Scopes,

		[Parameter(ParameterSetName = 'Browser')]
		[switch]
		$Browser,

		[Parameter(ParameterSetName = 'Browser')]
		[ValidateSet('Auto', 'PrintLink')]
		[string]
		$BrowserMode = 'Auto',

		[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
		[switch]
		$DeviceCode,

		[Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
		[string]
		$RefreshToken,

		[Parameter(Mandatory = $true, ParameterSetName = 'RefreshObject')]
		[EntraToken]
		$RefreshTokenObject,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]
		$Certificate,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[string]
		$CertificateThumbprint,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[string]
		$CertificateName,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[string]
		$CertificatePath,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[System.Security.SecureString]
		$CertificatePassword,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'AppSecret')]
		[System.Security.SecureString]
		$ClientSecret,

		[Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
		[PSCredential]
		$Credential,

		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[string]
		$VaultName,

		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[string[]]
		$SecretName,

		[Parameter(Mandatory = $true, ParameterSetName = 'Identity')]
		[switch]
		$Identity,

		[Parameter(ParameterSetName = 'Identity')]
		[string]
		$IdentityID,

		[Parameter(ParameterSetName = 'Identity')]
		[ValidateSet('ClientID', 'ResourceID', 'PrincipalID')]
		[string]
		$IdentityType = 'ClientID',

		[Parameter(ParameterSetName = 'Identity')]
		[Parameter(ParameterSetName = 'Federated')]
		[switch]
		$FallBackAzAccount,

		[Parameter(Mandatory = $true, ParameterSetName = 'AzAccount')]
		[switch]
		$AsAzAccount,

		[Parameter(ParameterSetName = 'AzAccount')]
		[ValidateSet('Auto', 'Always', 'Never')]
		[string]
		$ShowDialog = 'Auto',

		[Parameter(ParameterSetName = 'Federated')]
		[switch]
		$Federated,

		[Parameter(ParameterSetName = 'Federated')]
		[ArgumentCompleter({
			param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
			foreach ($provider in Get-EntraFederationProvider) {
				if ($provider.Name -notlike "$wordToComplete*") { continue }
				$text = $provider.Name
				if ($text -match '\s') { $text = "'$($provider.Name -replace "'", "''")'" }

				[System.Management.Automation.CompletionResult]::new($text, $text, 'ParameterValue', $provider.Description)
			}
		})]
		[ValidateScript({
			$providers = (Get-EntraFederationProvider).Name
			if ($_ -in $providers) { return $true }

			$message = "Unknown Federation Provider! '$_' - known providers: $($providers -join ', ')"
			Write-Warning $message
			throw $message
		})]
		[string]
		$FederationProvider,

		[Parameter(ParameterSetName = 'Federated')]
		[string]
		$Assertion,

		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[ValidateScript({ Assert-ServiceName -Name $_ })]
		[string[]]
		$Service = $script:_DefaultService,

		[string]
		$ServiceUrl,

		[string]
		$Resource,

		[Parameter(ParameterSetName = 'Browser')]
		[Parameter(ParameterSetName = 'DeviceCode')]
		[switch]
		$UseRefreshToken,

		[switch]
		$MakeDefault,

		[switch]
		$PassThru,

		[Environment]
		$Environment,

		[string]
		$AuthenticationUrl
	)
	begin {
		$doRegister = $PSBoundParameters.Keys -notcontains 'Resource'
		$doPassThru = $PassThru -or $Resource

		switch ($ClientID) {
			'Graph' { $ClientID = '14d82eec-204b-4c2f-b7e8-296a70dab67e' }
			'Azure' { $ClientID = '1950a258-227b-4e31-a9cf-717495945fc2' }
		}
	}
	process {
		#region UseRereshToken
		$availableToken = $null
		if ($UseRefreshToken) {
			$availableToken = Get-EntraToken | Where-Object {
				$_.ClientID -eq $ClientID -and
				(
					$_.TenantID -eq $TenantID -or
					$TenantID -eq 'organizations'
				) -and
				$_.RefreshToken
			} | Sort-Object ValidUntil -Descending | Select-Object -First 1
		}
		if ($availableToken) {
			$param = @{ }
			foreach ($parameterName in $PSCmdlet.MyInvocation.MyCommand.ParameterSets.Where{ $_.Name -eq 'RefreshObject' }.Parameters.Name) {
				if ($PSBoundParameters.Keys -contains $parameterName) { $param[$parameterName] = $PSBoundParameters[$parameterName] }
			}
			Connect-EntraService @param -RefreshTokenObject $availableToken
			return
		}
		#endregion UseRereshToken

		foreach ($serviceName in $Service) {
			$serviceObject = $null
			if (-not $Resource) {
				$serviceObject = Get-EntraService -Name $serviceName
			}
			else {
				$serviceName = '<custom>'
			}

			#region AuthenticationUrl
			$authUrl = switch ("$Environment") {
				'China' { 'https://login.chinacloudapi.cn' }
				'USGov' { 'https://login.microsoftonline.us' }
				'USGovDOD' { 'https://login.microsoftonline.us' }
				default { 'https://login.microsoftonline.com' }
			}
			if ($AuthenticationUrl) { $authUrl = $AuthenticationUrl.TrimEnd('/') }

			if (
				$serviceObject.AuthenticationUrl -and
				$PSBoundParameters.Keys -notcontains 'Environment' -and
				$PSBoundParameters.Keys -notcontains 'AuthenticationUrl'
			) {
				$authUrl = $serviceObject.AuthenticationUrl
			}
			#endregion AuthenticationUrl

			$commonParam = @{
				ClientID          = $ClientID
				TenantID          = $TenantID
				Resource          = $serviceObject.Resource
				AuthenticationUrl = $authUrl
			}

			#region Service Url
			$effectiveServiceUrl = $ServiceUrl
			if (-not $ServiceUrl -and $serviceObject) { $effectiveServiceUrl = $serviceObject.ServiceUrl }
			if ($Resource) { $commonParam.Resource = $Resource }

			# If users explicitly provide a service URL, who are we to override that?
			if (-not $ServiceUrl) {
				if ('USGovDOD' -eq $Environment) { $effectiveServiceUrl = $effectiveServiceUrl -replace '^https://graph.microsoft.com', 'https://dod-graph.microsoft.us' -replace '^https://manage.azure.com', 'https://manage.usgovcloudapi.net' }
				elseif ($authUrl -eq 'https://login.microsoftonline.us') { $effectiveServiceUrl = $effectiveServiceUrl -replace '^https://graph.microsoft.com', 'https://graph.microsoft.us' -replace '^https://manage.azure.com', 'https://manage.usgovcloudapi.net' }
				elseif ($authUrl -eq 'https://login.chinacloudapi.cn') { $effectiveServiceUrl = $effectiveServiceUrl -replace '^https://graph.microsoft.com', 'https://microsoftgraph.chinacloudapi.cn' -replace '^https://manage.azure.com', 'https://management.core.chinacloudapi.cn' }
			}
			#endregion Service Url
			
			#region Connection
			:main switch ($PSCmdlet.ParameterSetName) {
				#region Browser
				Browser {
					$scopesToUse = $Scopes
					if (-not $Scopes) { $scopesToUse = $serviceObject.DefaultScopes }

					Write-Verbose "[$serviceName] Connecting via Browser ($($scopesToUse -join ', '))"
					try { $result = Connect-ServiceBrowser @commonParam -SelectAccount -Scopes $scopesToUse -NoReconnect:$($serviceObject.NoRefresh) -BrowserMode $BrowserMode -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}
					
					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $false, $authUrl)
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via Browser ($($token.Scopes -join ', '))"
				}
				#endregion Browser

				#region DeviceCode
				DeviceCode {
					$scopesToUse = $Scopes
					if (-not $Scopes) { $scopesToUse = $serviceObject.DefaultScopes }

					Write-Verbose "[$serviceName] Connecting via DeviceCode ($($scopesToUse -join ', '))"
					try { $result = Connect-ServiceDeviceCode @commonParam -Scopes $scopesToUse -NoReconnect:$($serviceObject.NoRefresh) -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $true, $authUrl)
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via DeviceCode ($($token.Scopes -join ', '))"
				}
				#endregion DeviceCode

				#region RefreshToken
				Refresh {
					$scopesToUse = $Scopes
					if (-not $Scopes) { $scopesToUse = $serviceObject.DefaultScopes }
					if (-not $scopesToUse) { $scopesToUse = '.default' }

					Write-Verbose "[$serviceName] Connecting via RefreshToken ($($scopesToUse -join ', '))"
					try { $result = Connect-ServiceRefreshToken @commonParam -RefreshToken $RefreshToken -Scopes $scopesToUse -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $false, $authUrl)
					$token.Type = 'Refresh'
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via RefreshToken ($($token.Scopes -join ', '))"
				}
				#endregion RefreshToken

				#region RefreshObject
				RefreshObject {
					$scopesToUse = $Scopes
					if (-not $Scopes) { $scopesToUse = $serviceObject.DefaultScopes }
					if (-not $scopesToUse) { $scopesToUse = '.default' }

					Write-Verbose "[$serviceName] Connecting via RefreshToken ($($scopesToUse -join ', '))"
					try { $result = Connect-ServiceRefreshToken -ClientID $RefreshTokenObject.ClientID -TenantID $RefreshTokenObject.TenantID -Resource $commonParam.Resource -AuthenticationUrl $RefreshTokenObject.AuthenticationUrl -RefreshToken $RefreshTokenObject.RefreshToken -Scopes $scopesToUse -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $RefreshTokenObject.ClientID, $RefreshTokenObject.TenantID, $effectiveServiceUrl, $false, $RefreshTokenObject.AuthenticationUrl)
					$token.Type = 'Refresh'
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via RefreshToken ($($token.Scopes -join ', '))"
				}
				#endregion RefreshObject

				#region ROPC
				UsernamePassword {
					Write-Verbose "[$serviceName] Connecting via Credential"
					try { $result = Connect-ServicePassword @commonParam -Credential $Credential -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $Credential, $effectiveServiceUrl, $authUrl)
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via Credential ($($token.Scopes -join ', '))"
				}
				#endregion ROPC

				#region AppSecret
				AppSecret {
					Write-Verbose "[$serviceName] Connecting via AppSecret"
					try { $result = Connect-ServiceClientSecret @commonParam -ClientSecret $ClientSecret -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $ClientSecret, $effectiveServiceUrl, $authUrl)
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via AppSecret ($($token.Scopes -join ', '))"
				}
				#endregion AppSecret

				#region AppCertificate
				AppCertificate {
					Write-Verbose "[$serviceName] Connecting via Certificate"
					try { $certificateObject = Resolve-Certificate -BoundParameters $PSBoundParameters }
					catch {
						Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Cannot resolve certificate" -ErrorRecord $_ -Category InvalidArgument
					}

					try { $result = Connect-ServiceCertificate @commonParam -Certificate $certificateObject -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $certificateObject, $effectiveServiceUrl, $authUrl)
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via Certificate ($($token.Scopes -join ', '))"
				}
				#endregion AppCertificate
			
				#region KeyVault
				KeyVault {
					Write-Verbose "[$serviceName] Connecting via KeyVault"
					$failure = $null
					foreach ($secretEntry in $SecretName) {
						try { $secret = Get-VaultSecret -VaultName $VaultName -SecretName $secretEntry }
						catch {
							Write-Warning "[$serviceName] Failed to retrieve secret from KeyVault: $_"
							$PSCmdlet.ThrowTerminatingError($_)
						}
						try {
							$result = switch ($secret.Type) {
								Certificate { Connect-ServiceCertificate @commonParam -Certificate $secret.Certificate -ErrorAction Stop }
								ClientSecret { Connect-ServiceClientSecret @commonParam -ClientSecret $secret.ClientSecret -ErrorAction Stop }
							}
						}
						catch {
							Write-Verbose "[$serviceName] Failed to connect using secret $($secretEntry): $_"
							if (-not $failure) { $failure = $_ }
							continue
						}
						$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $VaultName, $secretEntry, $authUrl)
						$token.SetTokenMetadata($result)

						Write-Verbose "[$serviceName] Connected via KeyVault ($($token.Scopes -join ', '))"
						break main
					}
					# Only reached if all secrets failed
					$PSCmdlet.ThrowTerminatingError($failure)
				}
				#endregion KeyVault

				#region Identity
				Identity {
					Write-Verbose "[$serviceName] Connecting via Managed Identity"

					try { $result = Connect-ServiceIdentity -Resource $commonParam.Resource -IdentityID $IdentityID -IdentityType $IdentityType -ErrorAction Stop }
					catch {
						if (-not $FallBackAzAccount) { $PSCmdlet.ThrowTerminatingError($_) }

						try {
							$newParam = @{}
							$validParam = $PSCmdlet.MyInvocation.MyCommand.ParameterSets.Where{$_.Name -eq 'AzAccount'}.Parameters.Name
							foreach ($pair in $PSBoundParameters.GetEnumerator()) {
								if ($pair.Key -notin $validParam) { continue }
								$newParam[$pair.Key] = $pair.Value
							}
							$newParam.AsAzAccount = $true
							Connect-EntraService @newParam

							break main # Successfully connected
						}
						catch {
							Write-Warning "Fallback to AzAccount failed: $_"
						}

						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $effectiveServiceUrl, $IdentityID, $IdentityType)
					$token.SetTokenMetadata($result)

					Write-Verbose "[$serviceName] Connected via Managed Identity ($($token.Scopes -join ', '))"
				}
				#endregion Identity

				#region Federated
				Federated {
					Write-Verbose "[$serviceName] Connecting via Federated Credential"

					try { $result,$provider = Connect-ServiceFederated @commonParam -Assertion $Assertion -Provider $FederationProvider -ErrorAction Stop }
					catch {
						if (-not $FallBackAzAccount) { $PSCmdlet.ThrowTerminatingError($_) }

						try {
							$newParam = @{}
							$validParam = $PSCmdlet.MyInvocation.MyCommand.ParameterSets.Where{$_.Name -eq 'AzAccount'}.Parameters.Name
							foreach ($pair in $PSBoundParameters.GetEnumerator()) {
								if ($pair.Key -notin $validParam) { continue }
								$newParam[$pair.Key] = $pair.Value
							}
							$newParam.AsAzAccount = $true
							Connect-EntraService @newParam

							break main # Successfully connected
						}
						catch {
							Write-Warning "Fallback to AzAccount failed: $_"
						}

						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $provider, $effectiveServiceUrl, $authUrl)
					$token = [EntraToken]::new($serviceName, $effectiveServiceUrl, $IdentityID, $IdentityType)
					$token.SetTokenMetadata($result)

					Write-Verbose "[$serviceName] Connected via Federated Credential ($($token.Scopes -join ', '))"
				}
				#endregion Federated

				#region AzAccount
				AzAccount {
					Write-Verbose "[$serviceName] Connecting via existing Az.Accounts session"

					try { $result = Connect-ServiceAzure -Resource $commonParam.Resource -ShowDialog $ShowDialog -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $effectiveServiceUrl, $ShowDialog)
					$token.TenantID = $result.TenantID
					$token.ClientID = $result.ClientID
					$token.SetTokenMetadata($result)

					Write-Verbose "[$serviceName] Connected via existing Az.Accounts session ($($token.Scopes -join ', '))"
				}
				#endregion AzAccount
			}
			#endregion Connection

			#region Copy Service Metadata
			if ($serviceObject) {
				if ($serviceObject.Query.Count -gt 0) {
					$token.Query = $serviceObject.Query.Clone()
				}
				if ($serviceObject.Header.Count -gt 0) {
					$token.Header = $serviceObject.Header.Clone()
				}
				if ($serviceObject.RawOnly) {
					$token.RawOnly = $true
				}
			}
			if ($doRegister) { $script:_EntraTokens[$serviceName] = $token }
			#endregion Copy Service Metadata

			if ($MakeDefault -and -not $Resource) {
				$script:_DefaultService = $serviceName
			}
			if ($doPassThru) { $token }
		}
	}
}