function New-EntraFilterBuilder {
	<#
	.SYNOPSIS
		Creates a new OData-Filter construction helper.
	
	.DESCRIPTION
		Creates a new OData-Filter construction helper.
		This helper class was designed to simplify the creation of OData filters for APIs such as the Microsoft Graph API.
		Call the ".Add(...)" method to specify filter conditions.
		
		There are two ways to do so:
		A) .Add(property, operator, value)
		A single property comparison, with a specific operator and value.
		
		B) .Add(customFilter)
		A custom piece of OData filter text.

		Finally, call ".Get()" to retrieve the full OData filter string or ".GetHeader()" to retrieve the filter header hashtable.
		
		For more in-depth help with the type, call the '.GetHelp()' method on the object.

		Useful Resources:
		List of valid filter conditions:
		https://learn.microsoft.com/en-us/graph/filter-query-parameter?tabs=http#operators-and-functions-supported-in-filter-expressions
	
	.EXAMPLE
		PS C:\> $filter = New-EntraFilterBuilder
		PS C:\> $filter.Add('displayName', 'eq', 'John Doe')
		PS C:\> $filter.Add('organization', 'in', @('Contoso', 'Fabrikam'))
		PS C:\> $filter.Get()

		Will return: "displayName eq 'John Doe' and organization in ('Contoso', 'Fabrikam')"
	#>
	[OutputType([FilterBuilder])]
	[CmdletBinding()]
	param ()

	process {
		[FilterBuilder]::new()
	}
}