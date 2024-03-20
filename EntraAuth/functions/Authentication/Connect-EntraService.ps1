function Connect-EntraService {
	<#
	.SYNOPSIS
		Establish a connection to an Entra Service.
	
	.DESCRIPTION
		Establish a connection to an Entra Service.
		Prerequisite before executing any requests / commands.
	
	.PARAMETER ClientID
		ID of the registered/enterprise application used for authentication.
	
	.PARAMETER TenantID
		The ID of the tenant/directory to connect to.
	
	.PARAMETER Scopes
		Any scopes to include in the request.
		Only used for interactive/delegate workflows, ignored for Certificate based authentication or when using Client Secrets.

	.PARAMETER Browser
		Use an interactive logon in your default browser.
		This is the default logon experience.

	.PARAMETER DeviceCode
		Use the Device Code delegate authentication flow.
		This will prompt the user to complete login via browser.
	
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

	.PARAMETER Service
		The service to connect to.
		Individual commands using Invoke-EntraRequest specify the service to use and thus identify the token needed.
		Defaults to: Graph

	.PARAMETER ServiceUrl
		The base url for requests to the service connecting to.
		Overrides the default service url configured with the service settings.

	.PARAMETER MakeDefault
		Makes this service the new default service for all subsequent Connect-EntraService & Invoke-EntraRequest calls.

	.PARAMETER PassThru
		Return the token received for the current connection.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID
	
		Establish a connection to the graph API, prompting the user for login on their default browser.
	
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
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
	[CmdletBinding(DefaultParameterSetName = 'Browser')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,
		
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,
		
		[string[]]
		$Scopes,

		[Parameter(ParameterSetName = 'Browser')]
		[switch]
		$Browser,

		[Parameter(ParameterSetName = 'DeviceCode')]
		[switch]
		$DeviceCode,
		
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

		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[ValidateScript({ Assert-ServiceName -Name $_ })]
		[string[]]
		$Service = $script:_DefaultService,

		[string]
		$ServiceUrl,

		[switch]
		$MakeDefault,

		[switch]
		$PassThru
	)
	process {
		foreach ($serviceName in $Service) {
			$serviceObject = Get-EntraService -Name $serviceName

			$commonParam = @{
				ClientID = $ClientID
				TenantID = $TenantID
				Resource = $serviceObject.Resource
			}
			$effectiveServiceUrl = $ServiceUrl
			if (-not $ServiceUrl) { $effectiveServiceUrl = $serviceObject.ServiceUrl }
			
			#region Connection
			switch ($PSCmdlet.ParameterSetName) {
				#region Browser
				Browser {
					$scopesToUse = $Scopes
					if (-not $Scopes) { $scopesToUse = $serviceObject.DefaultScopes }

					Write-Verbose "[$serviceName] Connecting via Browser ($($scopesToUse -join ', '))"
					try { $result = Connect-ServiceBrowser @commonParam -SelectAccount -Scopes $scopesToUse -NoReconnect:$($serviceObject.NoRefresh) -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}
					
					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $false)
					if ($serviceObject.Header.Count -gt 0) { $token.Header = $serviceObject.Header.Clone() }
					$token.SetTokenMetadata($result)
					$script:_EntraTokens[$serviceName] = $token
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

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $true)
					if ($serviceObject.Header.Count -gt 0) { $token.Header = $serviceObject.Header.Clone() }
					$token.SetTokenMetadata($result)
					$script:_EntraTokens[$serviceName] = $token
					Write-Verbose "[$serviceName] Connected via DeviceCode ($($token.Scopes -join ', '))"
				}
				#endregion DeviceCode

				#region ROPC
				UsernamePassword {
					Write-Verbose "[$serviceName] Connecting via Credential"
					try { $result = Connect-ServicePassword @commonParam -Credential $Credential -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $Credential, $effectiveServiceUrl)
					if ($serviceObject.Header.Count -gt 0) { $token.Header = $serviceObject.Header.Clone() }
					$token.SetTokenMetadata($result)
					$script:_EntraTokens[$serviceName] = $token
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

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $ClientSecret, $effectiveServiceUrl)
					if ($serviceObject.Header.Count -gt 0) { $token.Header = $serviceObject.Header.Clone() }
					$token.SetTokenMetadata($result)
					$script:_EntraTokens[$serviceName] = $token
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

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $certificateObject, $effectiveServiceUrl)
					if ($serviceObject.Header.Count -gt 0) { $token.Header = $serviceObject.Header.Clone() }
					$token.SetTokenMetadata($result)
					$script:_EntraTokens[$serviceName] = $token
					Write-Verbose "[$serviceName] Connected via Certificate ($($token.Scopes -join ', '))"
				}
				#endregion AppCertificate
			}
			#endregion Connection

			if ($MakeDefault) {
				$script:_DefaultService = $serviceName
			}
			if ($PassThru) { $token }
		}
	}
}