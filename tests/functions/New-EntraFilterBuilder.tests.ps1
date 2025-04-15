Describe "Testing the command New-EntraFilterBuilder" -Tag unit {
	It "Will create a simple condition" {
		$filterBuilder = New-EntraFilterBuilder
		$filterBuilder.Add('name', 'eq', 'Fred')
		$filterBuilder.Get() | Should -Be "name eq 'Fred'"
	}
	It "Will create a simple filter query" {
		$filterBuilder = New-EntraFilterBuilder
		$filterBuilder.Add('name', 'eq', 'Fred')
		$filterBuilder.GetHeader().'$filter' | Should -Be "name eq 'Fred'"
		$filterBuilder.GetHeader().Count | Should -Be 1
	}

	It "Will merge conditions with an AND condition" {
		$filterBuilder = New-EntraFilterBuilder
		$filterBuilder.Add('name', 'eq', 'Fred')
		$filterBuilder.Add('country', 'eq', 'Germany')
		$filterBuilder.Get() | Should -Be "name eq 'Fred' and country eq 'Germany'"
	}
	It "Will merge conditions with an OR condition" {
		$filterBuilder = New-EntraFilterBuilder -Logic OR
		$filterBuilder.Add('name', 'eq', 'Fred')
		$filterBuilder.Add('name', 'eq', 'Max')
		$filterBuilder.Get() | Should -Be "name eq 'Fred' or name eq 'Max'"
	}

	It "Will support wildcard filtering correctly" {
		$filterBuilder = New-EntraFilterBuilder
		$filterBuilder.Add('displayName','eq','dept-000-*')
		$filterBuilder.Get() | Should -Be "startswith(displayName, 'dept-000-')"

		$filterBuilder = New-EntraFilterBuilder
		$filterBuilder.Add('displayName','eq','*-admin')
		$filterBuilder.Get() | Should -Be "endswith(displayName, '-admin')"
	}
	It "Will support searching in a multivalue field" {
		$filterBuilder = New-EntraFilterBuilder
		$filterBuilder.Add('servicePrincipalName', 'any', 'abc@contoso.com')
		$filterBuilder.Get() | Should -Be "servicePrincipalName/any(x:x eq 'abc@contoso.com')"
	}
	It "Will support matching against multiple values" {
		$filterBuilder = New-EntraFilterBuilder
		$filterBuilder.Add('name','in',@('Fred','Max'))
		$filterBuilder.Get() | Should -Be "name in ('Fred', 'Max')"
	}

	It "Will support nested filter builders & custom filters in the correct order" {
		$filterBuilder = New-EntraFilterBuilder
		$filterBuilder.Add('enabled', 'eq', $true)

		$filterBuilder2 = New-EntraFilterBuilder -Logic OR
		$filterBuilder2.Add('name','eq','Fred')
		$filterBuilder2.Add('name','eq','Max')
		$filterBuilder.Add($filterBuilder2)

		$filterBuilder.Add('(abc eq 42)')

		$filterBuilder.Get() | Should -Be "enabled eq True and (name eq 'Fred' or name eq 'Max') and (abc eq 42)"
	}
}