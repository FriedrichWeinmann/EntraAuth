function ConvertTo-Hashtable {
	<#
	.SYNOPSIS
		Converts input objects into hashtables.
	
	.DESCRIPTION
		Converts input objects into hashtables.
		Allows explicitly including some properties only and remapping key-names as required.
	
	.PARAMETER Include
		Only select the specified properties.
	
	.PARAMETER Mapping
		Remap hashtable/property keys.
		This allows you to rename parameters before passing them through to other commands.
		Example:
		@{ Select = '$select' }
		This will map the "Select"-property/key on the input object to be '$select' on the output item.
	
	.PARAMETER InputObject
		The object to convert.
	
	.EXAMPLE
		PS C:\> $__body = $PSBoundParameters | ConvertTo-Hashtable -Include Name, UserID -Mapping $__mapping

		Converts the object $PSBoundParameters into a hashtable, including the keys "Name" and "UserID" and remapping them as specified in $__mapping
	#>
	[OutputType([hashtable])]
    [CmdletBinding()]
    param (
        [AllowEmptyCollection()]
        [string[]]
        $Include,

        [Hashtable]
        $Mapping = @{ },

        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    process {
        $result = @{ }
        if ($InputObject -is [System.Collections.IDictionary]) {
            foreach ($pair in $InputObject.GetEnumerator()) {
                if ($pair.Key -notin $Include) { continue }
                if ($Mapping[$pair.Key]) { $result[$Mapping[$pair.Key]] = $pair.Value }
                else { $result[$pair.Key] = $pair.Value }
            }
        }
        else {
            foreach ($property in $InputObject.PSObject.Properties) {
                if ($property.Name -notin $Include) { continue }
                if ($Mapping[$property.Name]) { $result[$Mapping[$property.Name]] = $property.Value }
                else { $result[$property.Name] = $property.Value }
            }
        }
        $result
    }
}