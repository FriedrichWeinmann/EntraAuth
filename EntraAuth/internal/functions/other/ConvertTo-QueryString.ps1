function ConvertTo-QueryString {
	<#
    .SYNOPSIS
        Convert conditions in a hashtable to a Query string to append to a webrequest.
    
    .DESCRIPTION
        Convert conditions in a hashtable to a Query string to append to a webrequest.
    
    .PARAMETER QueryHash
        Hashtable of query modifiers - usually filter conditions - to include in a web request.
    
    .EXAMPLE
        PS C:\> ConvertTo-QueryString -QueryHash $Query

        Converts the conditions in the specified hashtable to a Query string to append to a webrequest.
    #>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[Hashtable]
		$QueryHash,

		[AllowNull()]
		[hashtable]
		$DefaultQuery
	)

	process {
		if ($DefaultQuery) { $query = $DefaultQuery.Clone() }
		else { $query = @{} }

		foreach ($key in $QueryHash.Keys) {
			$query[$key] = $QueryHash[$key]
		}
		if ($query.Count -lt 1) { return '' }


		$elements = foreach ($pair in $query.GetEnumerator()) {
			'{0}={1}' -f $pair.Name, ($pair.Value -join ",")
		}
		'?{0}' -f ($elements -join '&')
	}
}