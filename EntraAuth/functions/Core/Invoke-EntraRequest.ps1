function Invoke-EntraRequest {
	<#
	.SYNOPSIS
		Executes a web request against an entra-based service
	
	.DESCRIPTION
		Executes a web request against an entra-based service
		Handles all the authentication details once connected using Connect-EntraService.
	
	.PARAMETER Path
		The relative path of the endpoint to query.
		For example, to retrieve Microsoft Graph users, it would be a plain "users".
		To access details on a particular defender for endpoint machine instead it would look thus: "machines/1e5bc9d7e413ddd7902c2932e418702b84d0cc07"
	
	.PARAMETER Body
		Any body content needed for the request.

    .PARAMETER Query
        Any query content to include in the request.
        In opposite to -Body this is attached to the request Url and usually used for filtering.
	
	.PARAMETER Method
		The Rest Method to use.
		Defaults to GET
	
	.PARAMETER RequiredScopes
		Any authentication scopes needed.
		Used for documentary purposes only.

	.PARAMETER Header
		Any additional headers to include on top of authentication and content-type.
	
	.PARAMETER Service
		Which service to execute against.
		Determines the API endpoint called to.
		Defaults to "Graph"

	.PARAMETER SerializationDepth
		How deeply to serialize the request body when converting it to json.
		Defaults to: 99

	.PARAMETER Token
		A Token as created and maintained by this module.
		If specified, it will override the -Service parameter.

	.PARAMETER NoPaging
		Do not automatically page through responses sets.
		By default, Invoke-EntraRequest is going to keep retrieving result pages until all data has been retrieved.

	.PARAMETER Raw
		Do not process the response object and instead return the raw result returned by the API.
	
	.EXAMPLE
		PS C:\> Invoke-EntraRequest -Path 'alerts' -RequiredScopes 'Alert.Read'
	
		Return a list of defender alerts.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		[Hashtable]
		$Body = @{ },

		[Hashtable]
		$Query = @{ },
		
		[string]
		$Method = 'GET',
		
		[string[]]
		$RequiredScopes,

		[hashtable]
		$Header = @{},
		
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[ValidateScript({ Assert-ServiceName -Name $_ })]
		[string]
		$Service = $script:_DefaultService,

		[ValidateRange(1, 666)]
		[int]
		$SerializationDepth = 99,

		[EntraToken]
		$Token,

		[switch]
		$NoPaging,

		[switch]
		$Raw
	)
	
	DynamicParam {
		if ($Resource) { return }

		$actualService = $Service
		if (-not $actualService) { $actualService = $script:_DefaultService }
		$serviceObject = $script:_EntraEndpoints.$actualService
		if (-not $serviceObject) { return }
		if ($serviceObject.Parameters.Count -lt 1) { return }

		$results = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
		foreach ($pair in $serviceObject.Parameters.GetEnumerator()) {
			$parameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
			$parameterAttribute.ParameterSetName = '__AllParameterSets'
			$parameterAttribute.Mandatory = $true
			$parameterAttribute.HelpMessage = $pair.Value
			$attributesCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
			$attributesCollection.Add($parameterAttribute)
			$RuntimeParam = [System.Management.Automation.RuntimeDefinedParameter]::new($pair.Key, [object], $attributesCollection)

			$results.Add($pair.Key, $RuntimeParam)
		}

		$results
	}

	begin {
		if ($Token) {
			$tokenObject = $Token
		}
		else {
			Assert-EntraConnection -Service $Service -Cmdlet $PSCmdlet -RequiredScopes $RequiredScopes
			$tokenObject = $script:_EntraTokens.$Service
		}
		
		$serviceObject = $script:_EntraEndpoints.$($tokenObject.Service)
	}
	process {
		$parameters = @{
			Method = $Method
			Uri    = Resolve-RequestUri -TokenObject $tokenObject -ServiceObject $script:_EntraEndpoints.$($tokenObject.Service) -BoundParameters $PSBoundParameters
		}
		
		if ($Body.Count -gt 0) {
			$parameters.Body = $Body | ConvertTo-Json -Compress -Depth $SerializationDepth
		}
		$parameters.Uri += ConvertTo-QueryString -QueryHash $Query -DefaultQuery $serviceObject.Query

		do {
			$parameters.Headers = $tokenObject.GetHeader() + $Header # GetHeader() automatically refreshes expried tokens
			Write-Verbose "Executing Request: $($Method) -> $($parameters.Uri)"
			try { $result = Invoke-RestMethod @parameters -ErrorAction Stop }
			catch {
				$letItBurn = $true
				$failure = $_

				if ($_.ErrorDetails.Message) {
					$details = $_.ErrorDetails.Message | ConvertFrom-Json
					if ($details.Error.Code -eq 'TooManyRequests') {
						Write-Verbose "Throttling: $($details.error.message)"
						$delay = 1 + ($details.error.message -replace '^.+ (\d+) .+$', '$1' -as [int])
						if ($delay -gt 5) { Write-Warning "Request is being throttled for $delay seconds" }
						Start-Sleep -Seconds $delay
						try {
							$result = Invoke-RestMethod @parameters -ErrorAction Stop
							$letItBurn = $false
						}
						catch {
							$failure = $_
						}
					}
				}

				if ($letItBurn) {
					Write-Warning "Request failed: $($Method) -> $($parameters.Uri)"
					$PSCmdlet.ThrowTerminatingError($failure)
				}
			}
			if (-not $Raw -and $result.PSObject.Properties.Where{ $_.Name -eq 'value' }) { $result.Value }
			else { $result }
			$parameters.Uri = $result.'@odata.nextLink'
		}
		while ($parameters.Uri -and -not $NoPaging)
	}
}