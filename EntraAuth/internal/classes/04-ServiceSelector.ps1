class ServiceSelector {
	[hashtable]$DefaultServices = @{ }

	ServiceSelector([Hashtable]$Services) {
		$this.DefaultServices = $Services
	}

	[string]GetService([hashtable]$ServiceMap, [string]$Name) {
		if ($ServiceMap[$Name]) { return $ServiceMap[$Name] }

		return $this.DefaultServices[$Name]
	}
	[hashtable]GetServiceMap([hashtable]$ServiceMap) {
		$map = $this.DefaultServices.Clone()
		if ($ServiceMap) {
			foreach ($pair in $ServiceMap.GetEnumerator()) {
				$map[$pair.Key] = $pair.Value
			}
		}
		return $map
	}
}