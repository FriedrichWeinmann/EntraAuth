function Connect-ServiceBrowser {
	<#
	.SYNOPSIS
		Interactive logon using the Authorization flow and browser. Supports SSO.
	
	.DESCRIPTION
		Interactive logon using the Authorization flow and browser. Supports SSO.

		This flow requires an App Registration configured for the platform "Mobile and desktop applications".
		Its redirect Uri must be "http://localhost"

		On successful authentication
	
	.PARAMETER ClientID
		The ID of the registered app used with this authentication request.
	
	.PARAMETER TenantID
		The ID of the tenant connected to with this authentication request.
	
	.PARAMETER SelectAccount
		Forces account selection on logon.
		As this flow supports single-sign-on, it will otherwise not prompt for anything if already signed in.
		This could be a problem if you want to connect using another (e.g. an admin) account.
	
	.PARAMETER Scopes
        Generally doesn't need to be changed from the default '.default'

	.PARAMETER LocalPort
		The local port that should be redirected to.
		In order to process the authentication response, we need to listen to a local web request on some port.
		Usually needs not be redirected.
		Defaults to: 8080
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.

	.PARAMETER Browser
		The path to the browser to use for the authentication flow.
		Provide the full path to the executable.
		The browser must accept the url to open as its only parameter.
		Defaults to your default browser.

	.PARAMETER BrowserMode
		How the browser used for authentication is selected.
		Options:
		+ Auto (default): Automatically use the default browser.
		+ PrintLink: The link to open is printed on console and user selects which browser to paste it into (must be used on the same machine)
	
	.PARAMETER NoReconnect
		Disables automatic reconnection.
		By default, this module will automatically try to reaquire a new token before the old one expires.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
	
	.EXAMPLE
		PS C:\> Connect-ServiceBrowser -ClientID '<ClientID>' -TenantID '<TenantID>'
	
		Connects to the specified tenant using the specified client, prompting the user to authorize via Browser.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,

		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,

		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[switch]
		$SelectAccount,

		[AllowEmptyCollection()]
		[string[]]
		$Scopes,

		[int]
		$LocalPort = 8080,

		[string]
		$Browser,

		[Parameter(ParameterSetName = 'Browser')]
		[ValidateSet('Auto', 'PrintLink')]
		[string]
		$BrowserMode = 'Auto',

		[switch]
		$NoReconnect,

		[Parameter(Mandatory = $true)]
        [string]
		$AuthenticationUrl
	)
	process {
		Add-Type -AssemblyName System.Web
		if (-not $Scopes) { $Scopes = @('.default') }

		$redirectUri = "http://localhost:$LocalPort"
		$actualScopes = $Scopes | Resolve-ScopeName -Resource $Resource

		if (-not $NoReconnect) {
			$actualScopes = @($actualScopes) + 'offline_access'
		}

		$uri = "$AuthenticationUrl/$TenantID/oauth2/v2.0/authorize?"
		$state = Get-Random
		$parameters = @{
			client_id     = $ClientID
			response_type = 'code'
			redirect_uri  = $redirectUri
			response_mode = 'query'
			scope         = $actualScopes -join ' '
			state         = $state
		}
		if ($SelectAccount) {
			$parameters.prompt = 'select_account'
		}

		$paramStrings = foreach ($pair in $parameters.GetEnumerator()) {
			$pair.Key, ([System.Web.HttpUtility]::UrlEncode($pair.Value)) -join '='
		}
		$uriFinal = $uri + ($paramStrings -join '&')
		Write-Verbose "Authorize Uri: $uriFinal"

		#$redirectTo = 'https://raw.githubusercontent.com/FriedrichWeinmann/EntraAuth/master/nothing-to-see-here.txt'
		#$redirectTo = (Join-Path -Path $script:ModuleRoot -ChildPath 'nothing-to-see-here.txt') -replace '\\','/'
		$redirectTo = "http://localhost:$(Get-Random -Minimum 9800 -Maximum 9999)/"
		if ((Get-Random -Minimum 10 -Maximum 99) -eq 66) {
			$redirectTo = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
		}
		
		# Start local server to catch the redirect
		$http = [System.Net.HttpListener]::new()
		$http.Prefixes.Add("$redirectUri/")
		try { $http.Start() }
		catch { Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Failed to create local http listener on port $LocalPort. Use -LocalPort to select a different port. $_" -Category OpenError }

		switch ($BrowserMode) {
			Auto {
				# Execute in default browser
				if ($Browser) { & $Browser $uriFinal }
				else { Start-Process $uriFinal }
			}
			PrintLink {
				Write-Host @"
Ready to authenticate. Paste the following link into the browser of your choice on the local computer:
$uriFinal
"@
			}
		}

		# Get Result
		$task = $http.GetContextAsync()
		$authorizationCode, $stateReturn, $sessionState = $null
		try {
			while (-not $task.IsCompleted) {
				Start-Sleep -Milliseconds 200
			}
			$http2 = [System.Net.HttpListener]::new()
			$http2.Prefixes.Add($redirectTo)
			$http2.Start()

			$context = $task.Result
			$context.Response.Redirect($redirectTo)
			$context.Response.Close()
			$authorizationCode, $stateReturn, $sessionState = $context.Request.Url.Query -split "&"

			$task2 = $http2.GetContextAsync()
			while (-not $task2.IsCompleted) {
				Start-Sleep -Milliseconds 200
			}
			$context2 = $task2.Result
			$bytes = [System.Text.Encoding]::UTF8.GetBytes('Authentication flow completed, you can close the tab now.')
			$context2.Response.ContentEncoding = [System.Text.Encoding]::UTF8
			$context2.Response.OutputStream.Write($bytes,0,$bytes.Length)
			$context2.Response.Close()
		}
		finally {
			$http.Stop()
			$http.Dispose()
			if ($http2.IsListening) {
				$http2.Stop()
				$http2.Dispose()
			}
		}

		if (-not $stateReturn) {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Authentication failed (see browser for details)" -Category AuthenticationError
		}

		if ($stateReturn -match '^error_description=') {
			$message = $stateReturn -replace '^error_description=' -replace '\+',' '
			$message = [System.Web.HttpUtility]::UrlDecode($message)
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Error processing the request: $message" -Category InvalidOperation
		}

		if ($state -ne $stateReturn.Split("=")[1]) {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Received invalid authentication result. Likely returned from another flow redirecting to the same local port!" -Category InvalidOperation
		}

		$actualAuthorizationCode = $authorizationCode.Split("=")[1]

		$body = @{
			client_id    = $ClientID
			scope        = $actualScopes -join " "
			code         = $actualAuthorizationCode
			redirect_uri = $redirectUri
			grant_type   = 'authorization_code'
		}
		$uri = "$AuthenticationUrl/$TenantID/oauth2/v2.0/token"
		try { $authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ErrorAction Stop }
		catch {
			if ($_ -notmatch '"error":\s*"invalid_client"') { Invoke-TerminatingException -Cmdlet $PSCmdlet -ErrorRecord $_ }
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "The App Registration $ClientID has not been configured correctly. Ensure you have a 'Mobile and desktop applications' platform with redirect to 'http://localhost' configured (and not a 'Web' Platform). $_" -Category $_.CategoryInfo.Category
		}
		Read-AuthResponse -AuthResponse $authResponse
	}
}