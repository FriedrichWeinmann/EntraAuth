﻿function Connect-ServiceIdentity {
	<#
	.SYNOPSIS
		Connect as the current Managed Identity.

	.DESCRIPTION
		Connect as the current Managed Identity.
		Only works from within the context of a managed environment, such as Azure Functions with enabled MSI.

	.PARAMETER Resource
		The resource to get a token for.

	.PARAMETER IdentityID
		ID of the User-Managed Identity to connect as.

	.PARAMETER IdentityType
		Type of the User-Managed Identity.

	.PARAMETER Cmdlet
		The $PSCmdlet of the calling command.
		If specified, errors are triggered in the caller's context.

	.EXAMPLE
		PS C:\> Connect-ServiceIdentity -Resource 'https://vault.azure.net'

		Connect as the current managed identity, retrieving a token for the Azure Key Vault.

	.LINK
		https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$IdentityID,

		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$IdentityType,

		$Cmdlet = $PSCmdlet
	)
	process {
		# Logic for Azure VMs
		try {
			$vmMetadata = $null
			$vmMetadata = Invoke-RestMethod -Headers @{Metadata = "true" } -Method GET -NoProxy -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
		}
		catch {
			$vmMetadata = $null
		}
		if ($vmMetadata.compute.azEnvironment -like "*Azure*") {
			Write-Verbose "We are running on an Azure VM. Setting Environment Variables"
			$isAzureVM = $true
			$env:IDENTITY_ENDPOINT = "http://169.254.169.254/metadata/identity/oauth2/token"
			$env:IDENTITY_API_VERSION = "2018-02-01"
		}

		if ((-not $env:IDENTITY_ENDPOINT) -or (-not $env:IDENTITY_HEADER)) {
			Invoke-TerminatingException -Cmdlet $Cmdlet -Message "Cannot identify a Managed Identity. MSI logon not possible!" -Category ConnectionError
		}

		$apiVersion = $env:IDENTITY_API_VERSION
		if (-not $apiVersion) { $apiVersion = '2019-08-01' }

		$url = "$($env:IDENTITY_ENDPOINT)?resource=$Resource&api-version=$apiVersion"
		if ($IdentityID) {
			$labels = @{
				ClientID    = 'client_id'
				ResourceID  = 'mi_res_id'
				PrincipalID = 'principal_id'
			}
			$url = $url + "&$($labels[$IdentityType])=$($IdentityID)"
		}

		try {
			Write-Verbose "$url"
			if ($isAzureVM) {
				$headers = @{Metadata = 'true' }
			}
			else {
				$headers = @{'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER }
			}
			$authResponse = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
		}
		catch {
			Invoke-TerminatingException -Cmdlet $Cmdlet -Message "Failed to connect via Managed Identity: $_" -ErrorRecord $_
		}

		Read-AuthResponse -AuthResponse $authResponse
	}
}