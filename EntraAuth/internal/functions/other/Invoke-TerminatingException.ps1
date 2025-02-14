function Invoke-TerminatingException {
	<#
	.SYNOPSIS
		Throw a terminating exception in the context of the caller.
	
	.DESCRIPTION
		Throw a terminating exception in the context of the caller.
		Masks the actual code location from the end user in how the message will be displayed.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command.
	
	.PARAMETER Message
		The message to show the user.
	
	.PARAMETER Exception
		A nested exception to include in the exception object.
	
	.PARAMETER Category
		The category of the error.
	
	.PARAMETER ErrorRecord
		A full error record that was caught by the caller.
		Use this when you want to rethrow an existing error.
	
	.EXAMPLE
		PS C:\> Invoke-TerminatingException -Cmdlet $PSCmdlet -Message 'Unknown calling module'
	
		Terminates the calling command, citing an unknown caller.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		$Cmdlet,
		
		[string]
		$Message,
		
		[System.Exception]
		$Exception,
		
		[System.Management.Automation.ErrorCategory]
		$Category = [System.Management.Automation.ErrorCategory]::NotSpecified,
		
		[System.Management.Automation.ErrorRecord]
		$ErrorRecord
	)
	
	process {
		if ($ErrorRecord -and -not $Message) {
			$Cmdlet.ThrowTerminatingError($ErrorRecord)
		}
		
		$exceptionType = switch ($Category) {
			default { [System.Exception] }
			'InvalidArgument' { [System.ArgumentException] }
			'InvalidData' { [System.IO.InvalidDataException] }
			'AuthenticationError' { [System.Security.Authentication.AuthenticationException] }
			'InvalidOperation' { [System.InvalidOperationException] }
		}
		
		
		if ($Exception) { $newException = $Exception.GetType()::new($Message, $Exception) }
		elseif ($ErrorRecord) {
			try { $newException = $ErrorRecord.Exception.GetType()::new($Message, $ErrorRecord.Exception) }
			catch { $newException = [System.Exception]::new($Message, $ErrorRecord.Exception) }
		}
		else { $newException = $exceptionType::new($Message) }
		$record = [System.Management.Automation.ErrorRecord]::new($newException, (Get-PSCallStack)[1].FunctionName, $Category, $Target)
		$Cmdlet.ThrowTerminatingError($record)
	}
}