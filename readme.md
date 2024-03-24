# Entra Authentication Module

Welcome to the Entra Authentication Module project.
Your one stop for authenticating to any service behind Microsoft Entra Authentication.

Whether you just want a token ... or for someone to deal with all of the nasty details of executing API requests.

Functionally, if you liked the good old MSAL.PS and are looking for a successor, look no further.

## Installing

To use this module, run the following command:

```powershell
Install-Module EntraAuth -Scope CurrentUser
```

Or if you have PowerShell 7.4 or later:

```powershell
Install-PSResource EntraAuth
```

## Overview

To profit from the module, you basically ...

+ Connect to a service
+ Then execute requests against it or retrieve its token

Some common services come preconfigured (e.g. Graph, GraphBeta or the Security API), for others you might first need to register the service.

> Note for module developers: There is a dedicated chapter at the bottom with important advice.

## Preparing to Authenticate

For those new to connecting to and executing against APIs that require Entra authentication, we have prepared a guide, explaining the different authentication options, which to chose when and what you need to do to prepare outside of the code.

> [Guide to Authentication](docs/overview.md)

## Connect

To connect you always need a ClientID and a TenantID for the App Registration you are using for logon.
Depending on how you want to authenticate, this App Registration may need some configuration:

+ Browser (default): In the `Authentication` tab in the portal, register a 'Mobile and Desktop Applications' Platform with the 'http://localhost' redirect uri.
+ DeviceCode: In the `Authentication` tab in the portal, register a 'Web' Platform with the 'http://localhost' redirect uri and enable `Allow public client flows`.
+ ClientSecret: In the `certificate & secrets` tab create a secret and provide it as a SecureString when connecting
+ Certificate: In the `certificate & secrets` tab register a certificate and provide it when connecting

Example connect calls for each flow:

```powershell
# Example values, fill in the appropriate ones from your App Registration
$ClientID = 'd6a3ffb9-6217-40d6-bfb2-f5769b65970a'
$TenantID = 'a948c2b3-8eb2-498a-9108-c32aeeaa0f97'

# Browser Based
Connect-EntraService -ClientID $ClientID -TenantID $TenantID
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -Service Endpoint

# DeviceCode authentication
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -DeviceCode
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -DeviceCode -Service Endpoint

# Client Secret Based
$secret = Get-ClipBoard | ConvertTo-SecureString -AsPlainText -Force # Assuming the secret is in your clipboard
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -ClientSecret $secret
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -ClientSecret $secret -Service Endpoint

## Certificate Based
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -Certificate $cert
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -CertificateThumbprint E1AE5158CA92CC9AA53D955217567B30E68647BD
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -CertificateName 'CN=Whatever'
```

> Default Service

By default, the service connected to is the Microsoft Graph API.
The same default is also used for requests.
To change the default, you can use the `-MakeDefault` parameter when connecting:

```powershell
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -Service Endpoint -MakeDefault
```

This would make the `Endpoint` service the new default service for new connections or requests.

> Multiple Services

It is quite possible to be connected to multiple services in parallel.
Even if you use the same app registration for both services, you need to connect for each service individually.
You can however perform all connections using the same app registration in the same call:

```powershell
Connect-EntraService -ClientID $ClientID -TenantID $TenantID -ClientSecret $secret -Service Endpoint, Graph
```

> Graph & Graph Beta

The Graph and the Graph Beta are registered as separate services.
However, both can theoretically use the same token data ... but this module can't unify them properly without additional inconsistencies.

However, when specifying the request (see below), rather than providing the relative api path, you can provide the full http-starting url instead.
So if you mostly want to use v1.0 but have this one request that must be made in beta, you can specify the full url for that call and don't need separate connections.

## Requests

Once connected to a service, executing requests against that service becomes quite simple:

```powershell
# Request information from the default service
Invoke-EntraRequest -Path me

# Request information from the GraphBeta service
Invoke-EntraRequest -Service GraphBeta -Path me
```

> Query Modifiers

You can modify requests by adding query parameters.
Either you specify them in your path, or you use the `-Query` parameter:

```powershell
Invoke-EntraRequest -Path 'users?$select=displayName,givenName,id'

Invoke-EntraRequest -Path users -Query @{
    '$select' = 'displayName', 'givenName', 'id'
}
```

## Using the Token

Sometimes you want direct access to the token and just do your own thing.
There are two ways to get a token:

+ Ask for it during the request
+ Retrieve it after connecting

All tokens are maintained in the module for its runtime, but it will only maintain the latest iteration for a single service.

```powershell
# During the Connectiong
$token = Connect-EntraService -ClientID $ClientID -TenantID $TenantID -Service GraphBeta -PassThru

# After already being connected
$token = Get-EntraToken -Service GraphBeta
```

Once obtained, a token can be used either in `Invoke-EntraRequest` or in your own code:

```powershell
# Reuse token
Invoke-EntraRequest -Path me -Token $token

# Get Authentication header and use that
Invoke-RestMethod -Uri 'https://graph.microsoft.com/v1.0/users' -Headers $token.GetHeader()
```

> The `Getheader()` method will automatically refresh expiring tokens if needed.
> Directly accessing the `.AccessToken` property is possible, but will not refresh tokens.

## Registering Services

So, that whole thing is all nice and everything, but ... what if we want a token for a service not prepared in the module?
What if it's an app that only exists in your own tenant?
What if it's a function app only your team uses?
Or some Microsoft Product that was released a year after this module and we just never updated it?

Well, that is where our `*-EntraService` commands come in:

+ `Get-EntraService` to see all currently configured services
+ `Register-EntraService` to add new services
+ `Set-EntraService` to modify the configuration of an existing service

The main one is `Register-EntraService`:

```powershell
$graphCfg = @{
    Name          = 'Graph'
    ServiceUrl    = 'https://graph.microsoft.com/v1.0'
    Resource      = 'https://graph.microsoft.com'
    DefaultScopes = @()
    HelpUrl       = 'https://developer.microsoft.com/en-us/graph/quick-start'
    Header        = @{ }
    NoRefresh     = $false
}
Register-EntraService @graphCfg
```

> Name

The name the service is referenced by.

> Service Url

The base url all request from `Invoke-EntraRequest` using the service use, unless their requests specify the full web url.
If your API calls look like this:

```text
https://graph.microsoft.com/v1.0/users
https://graph.microsoft.com/v1.0/me
https://graph.microsoft.com/v1.0/messages
```

Then `https://graph.microsoft.com/v1.0` would be the Service url.
Effectively, you must provide any Url element after this value.

This property only matters when you use `Invoke-EntraRequest` or directly read it off the token properties.

> Resource

This is the ID of the resource connecting to.
To figure out the value needed here, go to the `API Permission` tab on the App Registration and click on the respective header in your list of scopes (e.g. `Microsoft Graph (##)`):
The value under the display name at the top is the Resource.
This could be a url such as `https://graph.microsoft.com` but can also be something like `api://<some weird guid>` and has no fixed relationship to the requests URLs.

> Default Scopes

In delegate mode, we sometimes ask for what scopes we need (which may lead to users being prompted to consent them).
If a service is a bit pointless to use without some minimal scopes and you want to make it more comfortable to use, you can provide the default set of scopes here.
If the user does not specify any scopes during the connect, then at least these are asked for.

+ Not used in application authentication flow or for the ROPC flow
+ Can lead to failure if the application does not have these scopes configured

> Help Url

Pure documentation in case you want to help users figure out how to use your service.

> Header

Additional values to include in the header for all requests.
For example, if you always must specify a specific content-type, this can be included here.

> NoRefresh

Tokens only last so long.
With a certificate or a Client Secret, that's no problem - just silently do the authentication again and that's it.
However, interactive logons using the browser would then force the user to logon again and again.

To make this less painful, a refresh token can be requested on the first interactive logon, allowing the silent renewal of tokens.
This is done automatically by default, so no need to meddle with that.
Usually.

Some services may not support this and some security policies interfere as well for administrative accounts, so refresh tokens may not be desired.
Configuring a service to not refresh means interactive logons will prompt again once the token has expired.

## Module building on EntraAuth

As a module author, building on EntraAuth for authentication purposes, there are two important aspects to using this module:

+ Default Service
+ What Service to use

> Default Service

Above, we described how to chose / override the default Service `Invoke-EntraRequest` is going to use.
_DO NOT USE THIS!_

This is going to risk confusing the user who may expect another default of their own choice.
It may also lead to conflict with other modules and unexpected errors.

If you do not always want to specify the service name or connection token, set the default value in your psm1 file like this:

```powershell
$PSDefaultParameterValues['Invoke-EntraRequest:Service'] = 'MyService'
```

This is going to apply to your entire module but not affect others.

> What Service to use

Let us assume your module wants to execute graph requests.
For this you could use the default Graph service.
If you do, that means the user only needs to log on once and all modules using EntraAuth can use the same connection.

However, that also means you have a single app and need all the scopes _all_ module need on the App Registration or you risk a lot of fun with insufficient scopes.

Instead we recommend registering your own, module-specific service (e.g. `"MyModule.Graph"`) with the exact same settings as the default graph service (see above).
That way, you can be sure that you have a dedicated connection and any errors about insufficient scopes are at least well earned and not a hard to troubleshoot conflict.
