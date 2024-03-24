# Managing an Application & Troubleshooting logins

> [Back to Overview](overview.md)

|[Previous: API Permissions and you](api-permissions.md)|[Back to Overview](overview.md)|

Our application is now prepared and ready to rock!
Well ... almost.

We have not yet configured authentication itself.
If we did, then _every_ user in the tenant could use our Application.

This is usually something we want to avoid, so lot us restrict it to members of a specific group!

In the overview section of our App Registration, there is a link to the manageability panel ("Enterprise Application") of our application.
Not going into the details here, but it is where we configure who can use it.

To do so, first select the link behind the "Managed application" section:

![Overview panel of the App registration, highlighting the section under Essentials labeled "Managed application"](pictures/D-01-Overview.png)

Once in the new menu, switch to Properties:

![New settings panel, with the tab vertical "Properties" selected. The option "Assignment required?" is highlighted, but not yet enabled](pictures/D-02-Properties.png)

Enable "Assignment required?" and remember to save:

![The same panel with "Assignment required?" selected, mouse hovering over the "save" button](pictures/D-03-RememberToSave.png)

Alright, that done, now nobody (other than yourself) can use the Application.
To add more people to it, switch to "Users and groups":

![A simple table for users & groups, with only a single entry](pictures/D-04-AssignUsersGroups.png)

To add a group, select "Add user/group" at the top, opening the assignment menu:

![A simple web formular with the header "Add Assignment" and two sections - "Users and Groups" and "Select a role", the link under the latter greyed out](pictures/D-05-Selection.png)

To add a group, select the "None Selected" link.

> The "Select a role" option is greyed out. More complex applications could define their own permissions, allowing us to assign different permissions to different groups.
> A topic for another day.

![A new panel on the right side, offering a search bar and a filtered view of results, showing the single match found to the query. At the bottom there is a blue "Select" button, but nothing has been selected yet](pictures/D-06-Selection2.png)

The new panel allows us to search for any user or group in the tenant.
Set the checkbox for all entries we want to add and confirm with "Select" at the bottom.

![The same old previous web formular, only this time the "Users and Groups" section shows "1 Group Selected"](pictures/D-07-Assign.png)

Once done, select "Assign" to complete the assignment:

![Back in the table view of assignments, we now have two entries, one the user creating the Application and one the group just selected](pictures/D-08-Assigned.png)

And that is it!
We have now limited just who is allowed to use our application and the rights associated.

## Troubleshooting SignIns

Not really critical for configuring our Application, if we later want to troubleshoot logon problems or check usage, there is another useful section in this menu:

Sign-in logs:

![Lower in the main menu, the vertical tab "Sign-in Logs" was selected. It shows a table that will likely show signins, but is yet empty, with filter options at the top](pictures/D-09-SigninLogs.png)

Nothing to see here yet, but useful if you later fail to login and can't figure out why.

|[Previous: API Permissions and you](api-permissions.md)|[Back to Overview](overview.md)|
