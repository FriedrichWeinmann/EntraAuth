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
        $QueryHash
    )

    process {
        $elements = foreach ($pair in $QueryHash.GetEnumerator()) {
            '{0}={1}' -f $pair.Name, ($pair.Value -join ",")
        }
        '?{0}' -f ($elements -join '&')
    }
}