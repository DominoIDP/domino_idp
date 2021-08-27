#! /bin/sh

IDP_VERSION=4.1.4
IDP_DOMAIN=example.com
IDP_HOSTNAME=idp.$IDP_DOMAIN
IDP_PASSWORD=password

# make sure we use the system java
export JAVA_HOME=$(/bin/java -XshowSettings:properties -version 2>&1 | grep java.home | awk '{print $3}')

# download/extract idp distribution

curl -o /tmp/idp.tgz https://shibboleth.net/downloads/identity-provider/$IDP_VERSION/shibboleth-identity-provider-$IDP_VERSION.tar.gz
tar -C /tmp -xzvf /tmp/idp.tgz

# set up config for non-interactive install

echo "idp.src.dir=/tmp/shibboleth-identity-provider-$IDP_VERSION" > /tmp/idp.properties
echo "idp.target.dir=/opt/shibboleth-idp" >> /tmp/idp.properties
echo "idp.host.name=$IDP_HOSTNAME" >> /tmp/idp.properties
echo "idp.merge.properties=/tmp/idp-merge.properties" >> /tmp/idp.properties
echo "idp.scope=$IDP_DOMAIN" >> /tmp/idp.properties
echo "idp.keystore.password=$IDP_PASSWORD" >> /tmp/idp.properties
echo "idp.sealer.password=$IDP_PASSWORD" >> /tmp/idp.properties
echo "idp.entityID=https://$IDP_HOSTNAME/idp/shibboleth" > /tmp/idp-merge.properties

# install/enable modules

/tmp/shibboleth-identity-provider-$IDP_VERSION/bin/install.sh -Didp.property.file=/tmp/idp.properties
/opt/shibboleth-idp/bin/module.sh -e idp.authn.External
/opt/shibboleth-idp/bin/module.sh -d idp.authn.Password

# clean up install

rm -rf /opt/shibboleth-idp/logs
mkdir /var/log/idp
chgrp jetty /var/log/idp
chmod 770 /var/log/idp
ln -s /var/log/idp /opt/shibboleth-idp/logs
chgrp -R jetty /opt/shibboleth-idp/conf /opt/shibboleth-idp/credentials
find /opt/shibboleth-idp/conf /opt/shibboleth-idp/credentials -type d -exec chmod 750 {} \;
find /opt/shibboleth-idp/conf /opt/shibboleth-idp/credentials -type f -exec chmod 640 {} \;
chgrp jetty /opt/shibboleth-idp/metadata
chmod 775 /opt/shibboleth-idp/metadata
chgrp jetty /opt/shibboleth-idp/metadata/*
chmod 664 /opt/shibboleth-idp/metadata/*

# copy in config files
cp -r /tmp/idp_config/idp/* /

# rebuild WAR file
echo | /opt/shibboleth-idp/bin/build.sh

# restart jetty
systemctl restart jetty
