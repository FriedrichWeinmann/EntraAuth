class FilterBuilder {
	[System.Collections.ArrayList]$Entries = @()
	[System.Collections.ArrayList]$CustomFilter = @()
	
	[ValidateSet('AND','OR')][string]$Logic = 'AND'

	FilterBuilder()	{ }
	FilterBuilder([string]$Logic) {
		$this.Logic = $Logic
	}

	[void]Add([string]$Property, [string]$Operator, $Value) {
		$this.Add($Property, $Operator, $Value, $false)
	}
	[void]Add([string]$Property, [string]$Operator, $Value, [bool]$NoQuotes) {
		$null = $this.Entries.Add(
			@{
				Property = $Property
				Operator = $Operator
				Value    = $Value
				NoQuotes = $NoQuotes
			}
		)
	}
	[void]Add([string]$CustomFilter) {
		$null = $this.Entries.Add($CustomFilter)
	}
	[void]Add([FilterBuilder]$NestedFilter) {
		$null = $this.Entries.Add($NestedFilter)
	}

	[int]Count() {
		$myCount = $this.Entries.Count
		if ($this.CustomFilter) { $myCount += $this.CustomFilter.Count }
		return $myCount
	}
	[string]GetHelp() {
		return @'
OData Filter Builder Guidance

This tool _mostly_ maps / implements the OData filter system, as adapted by the Microsoft Graph API.
It may be relevant to any other API supporting OData filters, but that's what it was built for.

Filter Docs:
https://learn.microsoft.com/en-us/graph/filter-query-parameter

Adding Filter Conditions:
There are two ways to provide filter conditions:

A) .Add(property, operator, value)
The .Add method adds individual filter clauses, simple comparisons or some special behaviors.
For these special rules, see below.
But any operator that has a simple "<property> <operator> <value>" from this list should be valid:
https://learn.microsoft.com/en-us/graph/filter-query-parameter?tabs=http#operators-and-functions-supported-in-filter-expressions
Strings need not be provided in quotes.

B) .Add(customFilter)
Specifying a single string allows providing custom filter terms/expressions.
This can be any valid fragment of OData filter, giving you greater control ... but requires you to write the filter yourself.

All conditions from A) and B) are finally combined with an AND condition.


Special Rules:

eq
The "eq" Operator is converted into a 'startswith' or 'endswith' operator, depending on wildcard use.

leq
The "leq" Operator is not an actual OData operator, but was added by this tool.
It means "Literal Equals" and is converted into an "eq" operator, but without automatic conversion to 'startswith' or 'endswith'.

any
The "any" Operator is the OData equivalent to the PowerShell -contains.

none
The "none" fake-Operator is the OData equivalent to the PowerShell -notcontains.
It translates into an OData all(...) logic with the "ne" operator applied.
'@
	}
	[string]Get() {
		$segments = :entries foreach ($entry in $this.Entries) {
			# Nested Filters
			if ($entry -is [FilterBuilder]) {
				'(' + $entry.Get() + ')'
				continue
			}
			# Custom Filters
			if ($entry -is [string]) {
				$entry
				continue
			}


			$quotes = "'"
			if ($entry.NoQuotes) { $quotes = "" }

			$valueString = $entry.Value -as [string]
			if ($null -eq $entry.Value) { $valueString = "null" }
			if (
				$entry.Value -is [string] -or
				$entry.Value -is [guid]
			) {
				$valueString = "$($quotes)$($entry.Value)$($quotes)"
			}
			if ($entry.Value -is [DateTime]) {
				$valueString = $entry.Value.ToString('u') -replace ' ', 'T'
			}

			switch ($entry.Operator) {
				'eq' {
					# Case: eq with Wildcard
					if ($entry.Value -match '\*$' -and $entry.Operator -eq 'eq') {
						"startswith($($entry.Property), $($quotes)$($entry.Value.TrimEnd('*'))$($quotes))"
						continue entries
					}
					if ($entry.Value -match '^\*' -and $entry.Operator -eq 'eq') {
						"endswith($($entry.Property), $($quotes)$($entry.Value.TrimStart('*'))$($quotes))"
						continue entries
					}
					'{0} eq {1}' -f $entry.Property, $valueString
				}
				'leq' {
					'{0} eq {1}' -f $entry.Property, $valueString
				}
				'in' {
					'{0} in ({1})' -f $entry.Property, (@($entry.Value).ForEach{ "$($quotes)$_$($quotes)" } -join ', ')
				}
				'any' {
					'{0}/any(x:x eq {1})' -f $entry.Property, $valueString
				}
				'none' {
					'{0}/all(x:x ne {1})' -f $entry.Property, $valueString
				}
				default {
					'{0} {1} {2}' -f $entry.Property, $entry.Operator, $valueString
				}
			}
		}
		if ($this.CustomFilter) {
			if ($segments) { $segments = @($segments) + $this.CustomFilter }
			else { $segments = $this.CustomFilter }
		}

		if ($this.Logic -eq 'OR') { return $segments -join ' or ' }
		return $segments -join ' and '
	}
	[hashtable]GetHeader() {
		return @{ '$filter' = $this.Get() }
	}
}