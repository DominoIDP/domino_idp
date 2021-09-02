Introduction
------------

This repository contains a vagrant configuration for spinning up a domino
server with an integrated shibboleth idp authenticating against and
returning attributes from domino.

Prerequisites to using it include an installation of vagrant itself, the
vagrant-vbguest plugin, and virtualbox. Only the virtualbox provider
has been tested and at this time it is not recommended to use any other
vagrant provider. The vagrant configuration has been tested under Mac OS X
and Windows, and is known to have issues under Linux, which is also not
recommended to use at this time (in particular, vagrant under linux
does not support the reboot guest capability natively, and while there
is a plugin to add it
(https://github.com/secret104278/vagrant_reboot_linux/tree/master) it
didn't seem to work reliably).

Download and install virtualbox on your chosen platform:

	https://www.virtualbox.org/wiki/Downloads


Next, download and install vagrant on your chosen platform:

	https://www.vagrantup.com/downloads


Once vagrant has been installed, provision the vbguest plugin by running:

	vagrant plugin install vagrant-vbguest


Clone this git repository onto your system:

	git clone https://github.com/DominoIDP/domino_idp.git


You will need to supply the Domino installer and optional fix pack files
yourself (eg, Domino_12.0_Linux_English.tar, Domino_1101FP2_Linux.tar).
Copy these files into or create symlinks to them in the
vagrant_cached_domino_mfa_files subdirectory of the git checkout.

At this point, you can execute 'vagrant up' in the git checkout directory
to spin up a vm instance, or use the utility scripts
vagrant_up.sh/vagrant_up.ps1 to create a log file with the initialization
output in addition to showing on the screen.

Once the system has been provisioned, you can use 'vagrant ssh' to access
it, or again the utility scripts vagrant_ssh.sh/vagrant_ssh.ps1 to create
a log file of the ssh session.

View the contents of the dist-support/CommandHelp.text for more details.
This file will also be displayed followed each vagrant up operation for
your continued reference.


Provisioning details
--------------------

The vagrant configuration begins with a CentOS 7 box image and initially
installs/configures the virtual box guest tools on it.

It then proceeds to install/configure the domino server [need more detail here
from someone familiar with this process].

Next, it installs the CentOS openjdk 11 package as well as installs/configures
the jetty servlet container. The configuration files found in the
idp_config/jetty directory are deployed and jetty is started.

Finally, it installs/configures the shibboleth idp. The configuration files
found in the idp_config/idp directory are deployed and jetty is restarted to
load the idp war. In addition to the initial configuration performed by a
vagrant up, the idp config files will be redeployed via vagrant provision,
allowing a simple mechanism to update the files and push them to the running
vagrant instance.

Currently jetty is listening using plaintext http on port 8080, which is NAT'd
from port 8080 on the host running vagrant. It can be accessed either via
http://localhost:8080/ on that system, or from another system using the IP
address of the vagrant host http://<host_ip>:8080/. Once initial testing and
development has been completed SSL support will be added.


Authentication integration design
---------------------------------

The end goal of this project is to allow Domino to provide SAML SSO identity
provider functionality leveraging the shibboleth idp to expose the users and
user information contained in Domino.

The expected authentication flow is:

* A user accesses a service configured to use Domino as the SSO identity
  provider (eg, http://some.service/content).

* The service redirects the user via either redirect or post to the shibboleth
  idp running on the domino server with an authentication request (eg,
  http://domino.server/idp/profile/SAML/...).

* The shibboleth idp redirects the user to the external authentication handler
  (http://domino.server/idp/external.jsp).

* The external authentication handler redirects the user to the domino
  authentication page, including an identifier key
  (http://domino.server/some_domino_url/auth?idp_key=<key>). This key should be
  considered an opaque value and needs to be passed back after successfull
  authentication. Currently the key is a spring webflow execution key of the
  form "s<integer>e<integer>" but this is implementation dependent and might
  change. This URL will be accessed directly by the user's browser after following
  the redirect.

* The domino authentication page needs to authenticate the user and then
  redirect them back to the idp external authentication page along with the key
  that was provided and some form of authentication/session token
  (http://domino.server/idp/external.jsp?idp_key=<key>&auth_token=<token>). The
  auth token could potentially be an explicitly provided value, or it might be
  an existing cookie such as an LTPA token. The auth token is provided through
  the end user browser and as such can not be implicitly trusted. The final
  step of the authentication process will be a callback from the idp to the
  domino authentication mechanism to validate the auth token and retrieve the
  username and other attributes for them
  (http://domino.server/some_domino_url/validate?auth_token=<token>). Again,
  the token might be provided as an explicit parameter, or it might be provided
  as a cookie, these implementation decisions have yet to be made. If the token
  is valid, the domino server should respond with information about the user in
  XML or JSON or similar format. The validation URL will *only* be called by
  the idp, it will not be accessed directly by the user. This URL can
  potentially be restricted to local access.

* The idp external authentication mechanism will parse the user information and
  return control to the idp SSO mechanism, which will assemble an assertion and
  return it to the client.

* Finally, the client will provide the assertion to the original service and be
  provided the content requested.


Note: to simplify testing, the idp has a built in service that will exercise
the authentication and attribute resolution process without requiring an
external service to be integrated. This can be accessed via the URL

	http://domino.server/idp/admin/hello


Pending implementation of the domino side of the authentication integration,
the idp external auth mechanism currently returns a hard coded user/attributes
when this is called.


idp configuration
-----------------

Most of the idp configuration will be static and not change over time during
the operation of the server. During the install, a domain and a hostname must
be provided. For now, the idp is just using "example.com" and "idp.example.com"
for this purpose for testing. We'll need to update the deployment to have
domino and the idp use the same data. The also needs a value called the "Entity
ID" which uniquely defines the instance of the idp when it is integrated into
remote services. The usual convention for this when using the shibboleth idp is
"https://$IDP_HOSTNAME/idp/shibboleth", but is sometimes changed to be more
generic such as "https://$IDP_HOSTNAME/idp/saml2".

However, there are a few parts of the idp which will potentially need to be
managed as services are integrated.

First, the attribute-resolver.xml file defines what attributes are available to
be provided to services. We added a DataConnector to this config which pulls
the attributes from the external authentication mechanism, with the id
"externalAttributes". Any standard/predefined attributes which will be provided
by domino will need to be listed in the "exportAttributes" parameter of this
DataConnector. Any non-standard attributes will need an AttributeDefinition
configuration in this file.

Next, the metadata for integrated services will need to be added. There are a
number of different ways to accomplish this, from joining federations that
maintain central metadata repositories to adding local ad-hoc metadata bundled
together in a single file or placed in separate files in a directory. This will
need to be designed once further requirements have been decided upon.

After that, the attribute-filter.xml file controls what attributes are released
to what services, and will need to be updated appropriately based on the
configured services and attributes. Depending on requirements, this could be a
simple configuration that just releases the username and basic attributes to
all services, or a more complicated one releasing specific sets of attributes
to specific services.

The shibboleth idp provides a lot of functionality and can be configured in
many ways; please reference the [upstream documentation](https://shibboleth.atlassian.net/wiki/spaces/IDP4/overview).

There will likely be additional configuration necessary or desired as the
project progresses and this section will be revisited and updated over time.
