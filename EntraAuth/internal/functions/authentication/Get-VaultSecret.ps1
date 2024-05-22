function Get-VaultSecret {
	<#
	.SYNOPSIS
		Retrieve a secret from Azure Key Vault.
	
	.DESCRIPTION
		Retrieve a secret from Azure Key Vault.
		Works for both certificates and secrets.

		Requires one of ...
		- An established connection with the AzureKeyVault service.
		- An established AZ session via Az.Accounts with the Az.KeyVault module present.
	
	.PARAMETER VaultName
		Name of the Vault to query.
	
	.PARAMETER SecretName
		Name of the Secret to retrieve.
	
	.PARAMETER Cmdlet
		The $PSCmdlet object of the caller, enabling errors to happen within the scope of the caller.
		Defaults to the current command's $PSCmdlet
	
	.EXAMPLE
		PS C:\> Get-VaultSecret -VaultName myvault -SecretName mysecret
		
		Retrieves the latest enabled version of mysecret from myvault
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$VaultName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$SecretName,

		$Cmdlet = $PSCmdlet
	)

	process {
		#region Via EntraAuth
		if (Get-EntraToken -Service AzureKeyVault) {
			try {
				$secretVersion = Invoke-EntraRequest -Service AzureKeyVault -Path "secrets/$SecretName/versions?api-version=7.4" -VaultName $VaultName -ErrorAction Stop | Where-Object {
					$_.attributes.enabled
				} | Sort-Object { $_.attributes.created } -Descending | Select-Object -First 1
				$secretData = Invoke-EntraRequest -Service AzureKeyVault -Path "$($secretVersion.id)?api-version=7.4" -VaultName $VaultName -ErrorAction Stop
			}
			catch {
				Invoke-TerminatingException -Cmdlet $Cmdlet -ErrorRecord $_ -Message "Failed to retrieve secret '$SecretName' from '$VaultName'! $_"
			}

			if ($secretVersion.contentType) {
				$secretBytes = [convert]::FromBase64String($secretData)
				$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($secretBytes)
				[PSCustomObject]@{
					Type         = 'Certificate'
					Certificate  = $certificate
					ClientSecret = $null
				}
			}
			else {
				[PSCustomObject]@{
					Type         = 'ClientSecret'
					Certificate  = $null
					ClientSecret = $secretData | ConvertTo-SecureString -AsPlainText -Force
				}
			}

			return
		}
		#endregion Via EntraAuth

		#region Via Az.KeyVault
		if ((Get-Module Az.Accounts -ListAvailable) -and (Get-AzContext) -and (Get-Module Az.KeyVault -ListAvailable)) {
			try { $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName }
			catch { Invoke-TerminatingException -Cmdlet $Cmdlet -ErrorRecord $_ -Message "Error accessing the secret '$Secretname' from Vault '$VaultName'. $_" }

			$type = 'Certificate'
			if (-not $secret.ContentType) { $type = 'ClientSecret' }

			$certificate = $null
			$clientSecret = $secret.SecretValue

			if ($type -eq 'Certificate') {
				$certString = [PSCredential]::New("irrelevant", $secret.SecretValue).GetNetworkCredential().Password
				$bytes = [convert]::FromBase64String($certString)
				$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($bytes)
				$clientSecret = $null
			}
			
			[PSCustomObject]@{
				Type         = $type
				Certificate  = $certificate
				ClientSecret = $clientSecret
			}

			return
		}
		#endregion Via Az.KeyVault

		Invoke-TerminatingException -Cmdlet $Cmdlet -Message "Not connected to azure yet! Either use 'Connect-EntraService -Service AzureKeyVault' or 'Connect-AzAccount' before trying to connect via KeyVault!" -Category ConnectionError
	}
}