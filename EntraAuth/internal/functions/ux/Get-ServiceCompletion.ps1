function global:Get-ServiceCompletion {
	<#
	.SYNOPSIS
		Returns the values to complete for.service names.
	
	.DESCRIPTION
		Returns the values to complete for.service names.
		Use this command in argument completers.
	
	.PARAMETER ArgumentList
		The arguments an argumentcompleter receives.
		The third item will be the word to complete.
	
	.EXAMPLE
		PS C:\> Get-ServiceCompletion -ArgumentList $args
		
		Returns the values to complete for.service names.
	#>
	[CmdletBinding()]
	param (
		$ArgumentList
	)
	process {
		$wordToComplete = $ArgumentList[2].Trim("'`"")
		foreach ($service in Get-EntraService) {
			if ($service.Name -notlike "$($wordToComplete)*") { continue }

			$text = if ($service.Name -notmatch '\s') { $service.Name }	else { "'$($service.Name)'" }
			[System.Management.Automation.CompletionResult]::new(
				$text,
				$text,
				'Text',
				$service.ServiceUrl
			)
		}
	}
}
$ExecutionContext.InvokeCommand.GetCommand("Get-ServiceCompletion","Function").Visibility = 'Private'