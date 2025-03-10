function New-EntraCustomToken {
	<#
	.SYNOPSIS
		Create a custom token compatible with EntraAuth.
	
	.DESCRIPTION
		Create a custom token compatible with EntraAuth.
		This allows directly integrating APIs that do not operate with default OAuth into the EntraAuth toolset.
	
	.PARAMETER ServiceUrl
		The URL requests are sent against.
	
	.PARAMETER HeaderCode
		The code that calculates the header (including authentication information) to include in the request.
		The scriptblock receives one argument: The token itself.
		Must return a single hashtable.
	
	.PARAMETER Service
		The name of the service to register the token under.
		Does not have to be a formally registered service, can be an arbitrary name.
		Specifying this parameter prevents the token from being returned as output, unless combined with -PassThru.
	
	.PARAMETER PassThru
		Return the token as output.
		By default, when specifying a service name, this command produces no output.
	
	.PARAMETER TenantID
		TenantID to connect to.
		Purely cosmetic, unless accessed from the header code.
	
	.PARAMETER ClientID
		ClientID to connect as.
		Purely cosmetic, unless accessed from the header code.
	
	.PARAMETER Header
		Header information to include in all requests against this API.
		Additional header entries to include in every request.
		Will be added to those returned from the HeaderCode and need not be considered within that code.
	
	.PARAMETER Query
		Additional query parameters to include in all requests against this API.
	
	.PARAMETER Data
		Additional information to store in the token object.
		Used by the HeaderCode scriptblock.
		Use this parameter to include information such as PATs, API keys or similar pieces of information.
	
	.PARAMETER RawOnly
		All requests throug this token should not use the default response processing.
		This will prevent Invoke-EntraRequest from providing most of its usual assistance.
	
	.EXAMPLE
		PS C:\> New-EntraCustomToken -Service AzDevMyProject -ServiceUrl 'https://dev.azure.com/contoso/myproject/_apis/wit' -Data @{ PAT = $pat } -HeaderCode {
			param ($Token)
			$base64AuthInfo = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(':' + $($Token.Data.PAT | ConvertFrom-SecureString -AsPlainText)))
	        return @{
	            Authorization  = "Basic $base64AuthInfo"
	            'Content-Type' = 'application/json'
	        }
		}

		Registers a new token for Azure DevOps, using PAT to authenticate.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$ServiceUrl,

		[Parameter(Mandatory = $true)]
		[scriptblock]
		$HeaderCode,

		[string]
		$Service,

		[switch]
		$PassThru,

		[string]
		$TenantID = '<Not Specified>',

		[string]
		$ClientID = '<Not Specified>',

		[hashtable]
		$Header = @{},

		[hashtable]
		$Query = @{},

		[hashtable]
		$Data = @{},

		[switch]
		$RawOnly
	)
	process {
		$newToken = [EntraToken]::new()
		$newToken.Type = 'Custom'
		$newToken.ServiceUrl = $ServiceUrl
		$newToken.HeaderCode = $HeaderCode
		if ($Service) { $newToken.Service = $Service }
		else { $newToken.Service = '<Custom>' }
		$newToken.TenantID = $TenantID
		$newToken.ClientID = $ClientID
		$newToken.Header = $Header.Clone()
		$newToken.Query = $Query.Clone()
		$newToken.Data = $Data.Clone()
		$newToken.RawOnly = $RawOnly.ToBool()

		if ($Service) {
			$script:_EntraTokens[$Service] = $newToken
		}
		if ($PassThru -or -not $Service) {
			$newToken
		}
	}
}