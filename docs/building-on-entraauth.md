# Building on EntraAuth

So, let's assume you have been converted to this project and now want to migrate your module to use it.
Or build a new module based on top of it.

In either case, you will now be faced with some design considerations, but there is one major one that overshadows it all:

> How do I deal with EntraAuth services?

What is a fairly simple thing in a standalone script can suddenly become a lot more frustrating when a few issues start popping up...

## The problems we face

It all starts with how we decide to deal with the services we use.
There are a few common decision option ... and they all have their consequences:

> 1.: Just use the defaults

_Your module wants to do Graph requests? Just specify the "Graph" services, it works._

This is basically what we do in our scripts, so why not in a module?

Any other module also doing this might lead to service conflicts.
Imagine a script calling three separate modules. Unless the modules are called after each other only and we reconnect inbetween, this means that we need one token that meets the scope prerequisite of them all.
This can be organizationally difficult.

Also, if you do not control all of those modules, it becomes simple for one of them prompt the user to reconnect to another application (or even tenant!), without the user realizing this impact.
This problem becomes even more troublesome as adoption of EntraAuth increases and modules take dependencies on other modules that also use EntraAuth.

> 2.: Define your own service

_Conflicts are bad, so let us define our own dedicated services._

Registering your own instances of services - even for services already part of the baseline - is a solid way to avoid most conflicts.

The main issue with this approach is, that we now force the user to log into each service separately, which can be a bit of a bother.
There are ways to "clone" delegate tokens into another service, but few users would be aware of that ... and it still needs managing.

Conflict-wise, this is a fairly clean solution, but we still only have a single set of services we can use.
This can be a problem if our module uses a wide range of APIs, depending on which command we call, which may use separate API permissions/scopes.

A script may only want to use a limited application with fewer scopes for just what is needed, while another module using it may need a different set of scopes.
Since the module can only hold a single service state / a single token per service, these will now be in conflict and force us to once again configure one large application with all scopes combined.

Also, this means we do not use the default services, which is going to be unintuitive for newer users, who will not understand the entire service concept of EntraAuth (or even be aware of EntraAuth to begin with).

> 3.: Define a module-wide default Service that can be changed

_Why hardcode when we can give the user may chose?_

We can define a module-wide variable with the service(s) we plan to use.
With that, we can allow script authors or other modules to change that and either merge or split service use as needed.

This would allow a script to define, which modules should use the same service and which should go separate ways.
That way, we eliminate redundant logon steps, but each module can still only have a single service configured at any given time.

This would not be too bad of a problem right now, but as modules depend on other modules that use EntraAuth, this might lead to conflicts.

> 4.: Expose the service to use on commands of the module

If we expose the choice of service on our module's functions, each caller can pick their own service to use.
Our own module becomes stateless when it comes to services used.

This has the great advantage of conclusively eliminating all service/token conflicts.
It also is fairly well documentable, using PowerShell command-help.

Which leaves one last issue - forcing us to always specify the service is a lot more verbose and raises the minimum barrier for use.

## A hybrid approach: Module-wide default & Parameters as override

The probably most viable solution to these concerns is to define a module-wide default, then in our functions offer a way to override this default.
Script authors can then use the `$PSDefaultParameterValue` system variable to declutter their code.

Of course, that brings some overhead in implementing this in your module, which is where EntraAuth and the ServiceSelector come in:

### Example Implementation

We are building the module `ContosoTools`.
In it we need to interact with the Graph API (Default service: `Graph`) and the Defender for Endpoint API (Default service: `Endpoint`)

> File 1: variables.ps1

This is some random file we load during our module's import.
After the import is over, that's it, the file will not be run again.

```powershell
$script:_services = @{
    Graph = 'Graph'
    MDE = 'Endpoint'
}

$script:_serviceSelector = New-EntraServiceSelector -DefaultServices $script:_services
```

> File 2: Set-CTServiceConnection.ps1

The default services to use are now defined during import - the values of the hashtable we just defined (Here: `Graph` and `Endpoint`).
Now we need a convenient way for a human user to change those defaults:

```powershell
function Set-CTServiceConnection {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ (Get-EntraService).Name })]
        [string]
        $Graph,

        [ArgumentCompleter({ (Get-EntraService).Name })]
        [string]
        $Mde
    )

    if ($Graph) {
        $script:_services.Graph = $Graph
    }
    if ($Mde) {
        $script:_services.MDE = $Mde
    }
}
```

This allows a user to cleanly change the default services to use ... but it does not solve the conflict situation between other _modules_ trying to use our `ContosoTools`.
We also need to actually use these services yet.
Moving on to the actual implementation within our commands:

> File 3: Get-CTUser.ps1

This is just one of the many functions our module exposes to the public.
In its simple form, it will return all users in the tenant (we probably want to add filtering in V2, but let's not overcomplicate this example).

```powershell
function Get-CTUser {
    [CmdletBinding()]
    param (
        [hashtable]
        $ServiceMap = @{}
    )

    begin {
        $services = $script:_serviceSelector.GetServiceMap($ServiceMap)
        Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Graph
    }
    process {
        Invoke-EntraRequest -Service $services.Graph
    }
}
```

Let's go through this a bit:

```powershell
$services = $script:_serviceSelector.GetServiceMap($ServiceMap)
```

This is the line where the real magic happens:

+ It will pick up the default services we defined in File 1, potentially modified by the user through the command in File 2
+ Then it will merge that with any explicitly bound services from `$ServiceMap`

Thus a user can define their default now, without affecting other module's ability to pick their own services (and without those modules interfering with the user's choice).

That's it, our module is now using EntraAuth with flexible services.
Let's take a look at how this would then be used ...

### Example Use

> Interactive in the console

```powershell
Get-CTUser
```

```text
Get-CTUser: Not connected yet! Use Connect-EntraService to establish a connection to 'Graph' first.
```

```powershell
Connect-EntraService -ClientID Graph
Get-CTUser
```

```text
< lots of results >
```

> Script 1: Simple Script

A simple script that only uses our module as a dependency.

```powershell
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -CertificateName 'CN=MyScript'

foreach ($user in Get-CTUser) {
    # Do Something
}
```

> Script 2: Script that wants to use the Graph Beta

Sometimes we just get more out of the Beta API for Microsoft Graph and the script wants to do some calls of its own.
So, deciding to keep things simple, the script author wants _all_ Graph calls to go to the beta API:

```powershell
Connect-EntraService Service 'GraphBeta' -ClientID $ClientID -TenantID $TenantID -CertificateName 'CN=MyScript2'
$PSDefaultParameterValues['*-CT*:ServiceMap'] = @{ Graph = 'GraphBeta' }

foreach ($user in Get-CTUser) {
    # Do Something
}
```

> Script 3: Multiple modules that use EntraAuth

One of our experts is writing a complex script that needs to use not just our `ContosoTools`, but also the `NorthwindUtilities` and `FabrikamRobotics` modules.
These have slightly different requirements:

+ ContosoTools is supposed to use the default Graph v1 api, but its requests to Defender for Endpoint must go through our homebrew proxy for the Defender API.
+ NorthwindUtilities requires the GraphBeta and will not interact with Defender for Endpoint at all
+ FabrikamRobotics needs both the GraphBeta _and_ Defender for Endpoint through our proxy.

All three modules are implemented based on EntraAuth and use the setup presented above.
They also use consistent command prefixes (`CT`, `NW` and `FR` respectively).

```powershell
$param = @{
    Name = 'MDEProxy'
    ServiceUrl = 'https://mdeproxy.contoso.com/api'
    Resource = 'https://mdeproxy.contoso.com'
    Header = @{ 'Content-Type' = 'application/json' }
}
Register-EntraService @param

Connect-EntraService Service 'GraphBeta', 'Graph', 'MDEProxy' -ClientID $ClientID -TenantID $TenantID -CertificateName 'CN=MyScript3'
$PSDefaultParameterValues['*-CT*:ServiceMap'] = @{ MDE = 'MDEProxy' }
$PSDefaultParameterValues['*-NW*:ServiceMap'] = @{ Graph = 'GraphBeta' }
$PSDefaultParameterValues['*-FR*:ServiceMap'] = @{ Graph = 'GraphBeta'; MDE = 'MDEProxy' }

foreach ($user in Get-CTUser) {
    $authDetails = Get-NWUserDetails -Id $user.id
    if ($authDetails.Healthy) { continue }

    Send-FRAuthenticationReport -Data $authDetails -Recipiemnt $user.Manager
}
```
