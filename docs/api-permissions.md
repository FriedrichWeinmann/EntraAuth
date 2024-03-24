# API Permissions and you

> [Back to Overview](overview.md)

|[Previous: Application vs. Delegate Authentication](application-vs-delegate.md)|[Next: Managing an Application & Troubleshooting logins](managing-applications.md)|

So, understanding the difference between Application and Delegate authentication, you now want to get yourself some juicy permissions, right?

For that we first need to navigate to the "API permissions" section in our Application's page:

![A table of permissions, currently only showing the default "User.Read" delegate right and the option to add more rights](pictures/C-01-ApiPermission-Portal.png)

As we can see, this new application only has a single permission granted by default - "User.Read", the Delegate right for a user to retrieve information about themselves.

> Note on terminology: The individual API permissions are frequently called "Scopes".

To request more permissions, we need to first select the "Add a permission" button above the table.
This opens a new panel, where we first need to select, from _which_ service we want permissions:

![A grid of panels, each representing a service, the "Microsoft Graph" service prominently on the top](pictures/C-02-RequestPermissions.png)

If your service is listed here:
Great.
We will cover how to find unlisted services later.

Let us assume that for the purpose of our project we need the Microsoft Graph service, as we later want to modify the groups we have access to:

![A new section for Microsoft Graph, offering us the choice between two panels - Delegated permissions or Application permissions](pictures/C-03-ApplicationDelegate.png)

Again we are faced with the choice between Delegated and Application permissions.
As we are going for an interactive tool, we pick the Delegated permissions:

![The previous image expanded downwards with a search bar and permissions offered](pictures/C-04-ScopesFilter.png)

We can now search all the permissions the service - in this case Microsoft Graph - offers in Delegated mode.
Using the search panel we can make it easier to find what is needed, then select the permissions' checkboxes and select "Add permissions":

![The previous image continued, with the checkbox beside "Group.ReadWrite.All" checked and the mouse over a blue "Add permission" button, ready to click](pictures/C-05-ScopesAssign.png)

With that selected, we return to the main table of "API permissions":

![A table of permissions, now listing both "User.Read" and "Group.ReadWrite.All", a warning showing the new permission to require Admin Consent](pictures/C-06-ConsentPending.png)

As we can see, the new permission is listed, but there is a new warning:
ReadWrite for all groups appear a bit permissive and we now need the consent from a Global Administrator for the permission to apply.

Fortunately, in my test tenant that is not a problem - the user already is Global Administrator.
If you are not GA - most organizations try to minimize the number of accounts with that right - you will now have to ask one of them to perform the next steps.

Either way, with the "Grant admin consent for %tenantname%" a GA can now grant the consent and make the permissions apply:

![A simple "Grant admin consent confirmation" box with Yes/No options](pictures/C-07-ConsentGranting.png)

And with that, the consent has now been granted:

![A table of permissions, now both permissions flagged green as Consent having been granted](pictures/C-08-ConsentGranted.png)

## Service Not Found

So far, so good.
Some of the well-known APIs / Services are easy to find when trying to add API permissions.
But ... what if our service is not?
Whether it is some Defender API or maybe our own function app, not all services will be found on the main grid panel of services.

Still, it can be found:

![The top of the "Request API permissions" panel, showing three tabs with "Microsoft APIs" selected, "APIs my organization uses" and "My APIs" not selected](pictures/C-09-UnknownService.png)

The tab "APIs my organization uses" hides all the remaining services in a tenant:

![The second tab selected, we now have a table of services and a search box at the top](pictures/C-10-SearchingService.png)

Using the search box, we can now search for any service in our tenant.
Note, the search is not always convenient and a name that should match does not return anything.

+ If you have the Application ID of the service, searching by that will always be precise.
+ If you have some online guide with screenshots, the header above the individual permissions (in our last screenshot: "Microsoft Graph (2)") shows the name to search for.

|[Previous: Application vs. Delegate Authentication](application-vs-delegate.md)|[Next: Managing an Application & Troubleshooting logins](managing-applications.md)|
