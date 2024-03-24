# Application vs. Delegate Authentication

> [Back to Overview](overview.md)

|[Previous: Creating an Application](creating-applications.md)|[Next: API Permissions and you](api-permissions.md)|

## The Different Kinds of Authenticating

So, you have created an application and now want to connect, right?

Well, you are almost there, but first you need to declare what rights you want to use after connecting.
Which requires us to talk about the two different categories of authentication:

+ Application
+ Delegate

When we get to assigning permissions, this difference is critical, as the two categories have completely different sets of rights.

So ... what's the difference?

> Application

Application authentication flows assume, that there is no human being involved in the process.
This is the classic "Service Account" kind of authentication you might already know from task schedulers or cron jobs doing their thing automatically as a specified account or as the "System".

Whether that reference means something to you or not, this is basic unattended authentication, so no MFA prompt, no human interaction possible.

This means we usually connect using a certificate (preferred) or a Client Secret.

Using this mechanism, our code will act under the application itself - it basically becomes our service account - and all permissions assigned are _right grants_.
In other words, if I assign the api permission "Group.ReadWrite.All" this means we now have the permission to edit _every single group in the tenant!_

This usually means an Admin must provide consent to those rights (more on that in the next chapter).

> Delegate

In Delegate mode, the application acts in the name of the user connecting.
So if we use this to connect, we will log in as ourselves, the human user and the code will act in our own name - the application is now merely the configuration describing _how_ we connect.

This logon expects there to be a human in front of the computer, ready to interact - for example servicing MFA prompts.
Most flows require a browser, whether on the same machine that you are connecting from or another.

In opposite to Application mode, api permissions in this mode are not _right grants_.
They are a mask, a subset, of what your user account is already allowed to do.
The api permission "Group.ReadWrite.All" allows you to edit all the groups you already have permission to modify.
The api permission "Send.Mail" allows you to send emails as yourself only.

Consequently, not all those api permissions require admin consent - for some the user may consent for themselves.

## The right tool for the job

So, what authentication should I use when?
The first decision is Application vs. Delegate - is this going to run unattended?
If so, then Application it is.
Do we have a human being in front of the console, ready to interact?
Then consider using delegate mode.

In some cases, even though a human is available, due to the rights situation you still need to use Application mode, but try to minimize this where possible - in most cases, Application mode is more rights than actually needed.

There are different options within a given authentication mode however:

> Application

The two options are ...

+ Certificate
+ Client Secret (API Key)

Certificate is the technically better option and should be the default choice, the Client Secret only in rare cases where the certificate logistics are too challenging.

With Certificates, we sign the authentication request, while with Client Secret we send our secret over the network.
Hence Certificate is the more secure choice.
The Certificate can be a self-signed certificate.

> Delegate

The two main options are ...

+ Browser Logon (Authorization Code Flow)
+ Device Code Logon

If the computer executing the code has a user interface and a browser, then the former option (Browser Logon) is always the preferred option.
Device Code - in which you execute the authentication independent of the connecting computer - requires you to loosen security requirements and is more vulnerable to token theft.

On the other hand, if the computer executing the code has no user interface, it is still the best option available.

|[Previous: Creating an Application](creating-applications.md)|[Next: API Permissions and you](api-permissions.md)|
