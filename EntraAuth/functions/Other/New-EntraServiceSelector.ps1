function New-EntraServiceSelector {
	<#
	.SYNOPSIS
		Creates a helper type designed to help make a module implementing EntraAuth more flexible about what EntraAUth service to use.
	
	.DESCRIPTION
		Creates a helper type designed to help make a module implementing EntraAuth more flexible about what EntraAUth service to use.

		While a module can easily define what service to use when calling Invoke-EntraRequest, this has some concerns:
		+ If multiple modules require the same service, they may interfere with each other by trying to use separate applications or having different scope requirements.
		+ If each module defines their own service instance (e.g. "Graph.MyModule"), then a script using multiple modules needs to authenticate multiple times, even if they all could use the same connection/token.

		The Service Selector aims to be a simple solution to this problem.
		It is intended for _Modules_ that implement EntraAuth, not individual scripts.
		
		To fully execute on this, you will need to implement this in three locations:
		- During Module Import: Declare defaults & Selector.
		- At the beginning of your functions: Select chosen services.
		- When executing requests: Use service as chosen.

		#=======================================================================================================
		# During Module Import
		$script:_services = @{ Graph = 'Graph'; MDE = 'Endpoint' }
		$script:_serviceSelector = New-EntraServiceSelector -DefaultServices $script:_services

		# During the Begin stage of each function using EntraAuth
		begin {
			$services = $script:_serviceSelector.GetServiceMap($ServiceMap) # $ServiceMap is a hashtable parameter offered by your function
			Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Graph
		}

		# When executing the actual request, later in the function
		Invoke-EntraService -Service $services.Graph -Path users
		#=======================================================================================================

		With this, somebody could call your command - let's call it "Get-DepartmentUser" - like this:
		Get-DepartmentUser -ServiceMap @{ Graph = 'GraphBeta' }
		And your function would use the beta version of the Graph api, without affecting any other script or module calling your function.

		Example Implementations:
		- During Module Import:
		  https://github.com/FriedrichWeinmann/EntraAuth.Graph.Application/blob/master/EntraAuth.Graph.Application/internal/scripts/variables.ps1
		- Used in Functions:
		  https://github.com/FriedrichWeinmann/EntraAuth.Graph.Application/blob/3c5e9f3de31fd7946e6fe9ebdb938986165ff5ca/EntraAuth.Graph.Application/functions/Get-EAGAppRegistration.ps1#L78
	
	.PARAMETER DefaultServices
		The Default services to use.
		Provide a hashtable of Labels mapping to EntraAuth services.
		Example:
		@{ Graph = 'Graph'; MDE = 'Endpoint' }
		The key is what you use in your code as a label, the Value is the actual service in EntraAuth.
	
	.EXAMPLE
		PS C:\> $script:_serviceSelector = New-EntraServiceSelector -DefaultServices $script:_services
		
		Creates a new ServiceSelector object and stores it in $script:_serviceSelector
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	#%UNCOMMENT%[OutputType([ServiceSelector])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[hashtable]
		$DefaultServices
	)
	process {
		[ServiceSelector]::new($DefaultServices)
	}
}