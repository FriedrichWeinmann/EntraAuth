class EntraToken {
	#region Token Data
	[string]$AccessToken
	[System.DateTime]$ValidAfter
	[System.DateTime]$ValidUntil
	[string[]]$Scopes
	[string]$RefreshToken
	[string]$Audience
	[string]$Issuer
	[PSObject]$TokenData
	#endregion Token Data
	
	#region Connection Data
	[string]$Service
	[string]$Type
	[string]$ClientID
	[string]$TenantID
	[string]$ServiceUrl
	[Hashtable]$Header = @{}
	
	# Workflow: Client Secret
	[System.Security.SecureString]$ClientSecret
	
	# Workflow: Certificate
	[System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate

	# Workflow: Username & Password
	[PSCredential]$Credential
	#endregion Connection Data
	
	#region Constructors
	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [Securestring]$ClientSecret, [string]$ServiceUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ClientSecret = $ClientSecret
		$this.ServiceUrl = $ServiceUrl
		$this.Type = 'ClientSecret'
	}
	
	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate, [string]$ServiceUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.Certificate = $Certificate
		$this.ServiceUrl = $ServiceUrl
		$this.Type = 'Certificate'
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [pscredential]$Credential, [string]$ServiceUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.Credential = $Credential
		$this.ServiceUrl = $ServiceUrl
		$this.Type = 'UsernamePassword'
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [string]$ServiceUrl, [bool]$IsDeviceCode) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ServiceUrl = $ServiceUrl
		if ($IsDeviceCode) { $this.Type = 'DeviceCode' }
		else { $this.Type = 'Browser' }
	}
	#endregion Constructors

    [void]SetTokenMetadata([PSObject] $AuthToken) {
        $this.AccessToken = $AuthToken.AccessToken
        $this.ValidAfter = $AuthToken.ValidAfter
        $this.ValidUntil = $AuthToken.ValidUntil
        $this.Scopes = $AuthToken.Scopes
		if ($AuthToken.RefreshToken) { $this.RefreshToken = $AuthToken.RefreshToken }

		$tokenPayload = $AuthToken.AccessToken.Split(".")[1].Replace('-', '+').Replace('_', '/')
		while ($tokenPayload.Length % 4) { $tokenPayload += "=" }
		$bytes = [System.Convert]::FromBase64String($tokenPayload)
		$data = [System.Text.Encoding]::ASCII.GetString($bytes) | ConvertFrom-Json
		
		if ($data.roles) { $this.Scopes = $data.roles }
		elseif ($data.scp) { $this.Scopes = $data.scp -split " " }

		$this.Audience = $data.aud
		$this.Issuer = $data.iss
		$this.TokenData = $data
    }

	[hashtable]GetHeader() {
		if ($this.ValidUntil -lt (Get-Date).AddMinutes(5)) {
			$this.RenewToken()
		}

		$currentHeader = @{}
		if ($this.Header.Count -gt 0) {
			$currentHeader = $this.Header.Clone()
		}
		$currentHeader.Authorization = "Bearer $($this.AccessToken)"

		return $currentHeader
	}

	[void]RenewToken()
	{
		$defaultParam = @{
			ServiceUrl = $this.ServiceUrl
			TenantID = $this.TenantID
			ClientID = $this.ClientID
		}
		switch ($this.Type) {
			Certificate {
				$result = Connect-ServiceCertificate @defaultParam -Certificate $this.Certificate
				$this.SetTokenMetadata($result)
			}
			ClientSecret {
				$result = Connect-ServiceClientSecret @defaultParam -ClientSecret $this.ClientSecret
				$this.SetTokenMetadata($result)
			}
			UsernamePassword {
				$result = Connect-ServicePassword @defaultParam -Credential $this.Credential
				$this.SetTokenMetadata($result)
			}
			DeviceCode {
				if ($this.RefreshToken) {
					Connect-ServiceRefreshToken -Token $this
					return
				}

				$result = Connect-ServiceDeviceCode @defaultParam
				$this.SetTokenMetadata($result)
			}
			Browser {
				if ($this.RefreshToken) {
					Connect-ServiceRefreshToken -Token $this
					return
				}

				$result = Connect-ServiceBrowser @defaultParam -SelectAccount
				$this.SetTokenMetadata($result)
			}
		}
	}
}