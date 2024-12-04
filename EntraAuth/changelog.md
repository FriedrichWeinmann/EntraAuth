﻿# Changelog

## 1.4.22 (2024-12-04)

+ Upd: Connect-EntraService - added `-UseRefreshToken` parameter for delegate flows, showing the interactive prompts only if needed.

## 1.4.21 (2024-11-26)

+ Upd: Added support for authenticating using an existing refresh token
+ Fix: Invoke-EntraRequest - "body not supported with this method" error when using Get requests with a body (#23)

## 1.3.19 (2024-10-13)

+ Upd: Invoke-EntraRequest - `-Body` parameter now supports raw string or custom objects.

## 1.3.18 (2024-10-08)

+ Upd: Added support for authenticating using the current Az.Accounts session
+ Upd: Added support for Sovereign Clouds (USGov, USGovDOD, China) and custom authentication urls.
+ Fix: Certificate Logon fails on timezones after UTC

## 1.2.15 (2024-07-31)

+ Fix: Refresh token may fail to authenticate to correct application
+ Fix: Managed Identity authentication fails on Azure VMs

## 1.2.13 (2024-05-22)

+ New: Supporting Managed Identity (User-Assigned or System Managed)
+ Upd: Service Configuration - can specify default query parameters.

## 1.1.11 (2024-05-21)

+ New: Service configurations - Added configurations for Azure & AzureKeyVault.
+ Upd: Connect-EntraService - Added support for direct Key Vault integration.
+ Upd: Service configurations - Added capability to require additional parameters that modify the base Service Url.
+ Fix: Token Renewal - bad parameter ServiceUrl.
+ Fix: Asset-EntraConnection - bad error message when assertion fails.

## 1.0.6 (2024-05-15)

+ Upd: Invoke-EntraRequest - added -NoPaging parameter to support disabling paging.
+ Upd: Invoke-EntraRequest - added -Raw parameter to support returning unprocessed results.

## 1.0.4 (2024-04-19)

+ Fix: Connect-EntraService - fails to register new sessions (#10)

## 1.0.3 (2024-03-24)

+ Upd: Connect-EntraService - added -Resource parameter to allow creating tokens without requiring a service (#7)
+ Upd: Connect-EntraService - added -BrowserMode parameter to allow pasting the link to whatever browser you prefer (#3)
+ Fix: Connect Browser - unknown command when PSFramework is not installed

## 1.0.0 (2024-03-20)

+ Initial Release
