function Connect-ServiceCertificate {
    <#
	.SYNOPSIS
		Connects to AAD using a application ID and a certificate.
	
	.DESCRIPTION
		Connects to AAD using a application ID and a certificate.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.
	
	.PARAMETER Certificate
		The certificate to use for authentication.
	
	.PARAMETER TenantID
		The ID of the tenant/directory to connect to.
	
	.PARAMETER ClientID
		The ID of the registered application used to authenticate as.
	
	.EXAMPLE
		PS C:\> Connect-ServiceCertificate -Certificate $cert -TenantID $tenantID -ClientID $clientID
	
		Connects to the specified tenant using the specified app & cert.
	
	.LINK
		https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-certificate-credentials
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,
		
        [Parameter(Mandatory = $true)]
        [string]
        $TenantID,
		
        [Parameter(Mandatory = $true)]
        [string]
        $ClientID
    )
	
    #region Build Signature Payload
    $jwtHeader = @{
        alg = "RS256"
        typ = "JWT"
        x5t = [Convert]::ToBase64String($Certificate.GetCertHash()) -replace '\+', '-' -replace '/', '_' -replace '='
    }
    $encodedHeader = $jwtHeader | ConvertTo-Json | ConvertTo-Base64
    $claims = @{
        aud = "https://login.microsoftonline.com/$TenantID/v2.0"
        exp = ((Get-Date).AddMinutes(5) - (Get-Date -Date '1970.1.1')).TotalSeconds -as [int]
        iss = $ClientID
        jti = "$(New-Guid)"
        nbf = ((Get-Date) - (Get-Date -Date '1970.1.1')).TotalSeconds -as [int]
        sub = $ClientID
    }
    $encodedClaims = $claims | ConvertTo-Json | ConvertTo-Base64
    $jwtPreliminary = $encodedHeader, $encodedClaims -join "."
    $jwtSigned = ($jwtPreliminary | ConvertTo-SignedString -Certificate $Certificate) -replace '\+', '-' -replace '/', '_' -replace '='
    $jwt = $jwtPreliminary, $jwtSigned -join '.'
    #endregion Build Signature Payload
	
    $body = @{
        client_id             = $ClientID
        client_assertion      = $jwt
        client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        scope                 = '{0}/.default' -f $Resource
        grant_type            = 'client_credentials'
    }
    $header = @{
        Authorization = "Bearer $jwt"
    }
    $uri = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
	
    try { $authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body -Headers $header -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop }
    catch { throw }
	
    Read-AuthResponse -AuthResponse $authResponse
}