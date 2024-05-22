# Changelog

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
