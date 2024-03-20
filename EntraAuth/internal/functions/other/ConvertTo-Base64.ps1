function ConvertTo-Base64 {
<#
	.SYNOPSIS
		Converts the input-string to its base 64 encoded string form.
	
	.DESCRIPTION
		Converts the input-string to its base 64 encoded string form.
	
	.PARAMETER Text
		The text to convert.
	
	.PARAMETER Encoding
		The encoding of the input text.
		Used to correctly translate the input string into bytes before converting those to base 64.
		Defaults to UTF8
	
	.EXAMPLE
		PS C:\> Get-Content .\code.ps1 -Raw | ConvertTo-Base64
	
		Reads the input file and converts its content into base64.
#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]]
		$Text,
		
		[System.Text.Encoding]
		$Encoding = [System.Text.Encoding]::UTF8
	)
	
	process {
		foreach ($entry in $Text) {
			$bytes = $Encoding.GetBytes($entry)
			[Convert]::ToBase64String($bytes)
		}
	}
}