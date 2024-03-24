# Delegated: Using the Browser directly

> [Back to Overview](overview.md)

## Configure

Setting up the default login via Browser is fortunately not too complex:
In our App Registration configuration page, we select the "Authentication" tab:

![The App Registration Configuration page for Authentication: Shows the default settings, highlighting the "Add a platform" button](pictures/01-01-Authentication.png)

Select "Add a platform" from this page.

![A grid of options, what kind of platform to configure. The panel for "Mobile and desktop applications" has been highlighted](pictures/01-02-Platform.png)

Choose "Mobile and desktop applications".
In the follow up menu we can now configure what adjustments we need to add:

![A panel allowing us to configure "Desktop + devices" redirect uris. There are three links already configured and an input textbox for your own entry](pictures/01-03-RedirectUri.png)

All we need to do now, is to add "http://localhost" and select "configure":

![The same panel, with the textbox now filled out with "http://localhost". The "Configure" button is no longer greyed out.](pictures/01-04-localhost.png)

And with that we are done!

![Again the authentication main screen, the "Platform configurations" section now has a "Mobile and desktop applications" panel with the url we just configured](pictures/01-05-Done.png)

## Authentication & Executing Queries

Using the EntraAuth PowerShell module, we can now connect using our Application, authenticating in our Browser window:

```powershell
$clientID = '63a71861-498b-46ae-0000-6b5c142010e1'
$tenantID = 'a948c2b3-8eb2-498a-0000-c32aeeaa0f90'

Connect-EntraService -ClientID $clientID -TenantID $tenantID
```

Once connected, we are now ready to use the connection to query all groups in our tenant:

```powershell
Invoke-EntraRequest -Path groups
```

> This example assumes, that we followed the guide on setting up App Registrations and granted the `Group.ReadWrite.All` API permission for Microsoft Graph
