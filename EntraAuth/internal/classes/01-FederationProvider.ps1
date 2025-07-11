class FederationProvider {
	[string]$Name
	[string]$Description
	[int]$Priority
	[scriptblock]$Test
	[scriptblock]$Code
	[string]$Assertion
	[string]$Type = 'Custom'

	[string]ToString() {
		return $this.Name
	}
}