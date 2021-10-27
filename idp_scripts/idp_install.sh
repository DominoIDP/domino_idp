#! /bin/sh

. /tmp/idp_config/DEFAULTS.sh

if [ -f /tmp/idp_config/CONFIG.sh ] ; then
	. /tmp/idp_config/CONFIG.sh
fi

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
echo "idp.scope=$IDP_SCOPE" >> /tmp/idp.properties
echo "idp.keystore.password=$IDP_PASSWORD" >> /tmp/idp.properties
echo "idp.sealer.password=$IDP_PASSWORD" >> /tmp/idp.properties
echo "idp.entityID=$IDP_ENTITY_ID" > /tmp/idp-merge.properties

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
rm /opt/shibboleth-idp/credentials/idp-backchannel.*
chgrp -R jetty /opt/shibboleth-idp/conf /opt/shibboleth-idp/credentials
find /opt/shibboleth-idp/conf /opt/shibboleth-idp/credentials -type d -exec chmod 750 {} \;
find /opt/shibboleth-idp/conf /opt/shibboleth-idp/credentials -type f -exec chmod 640 {} \;
chgrp jetty /opt/shibboleth-idp/metadata
chmod 775 /opt/shibboleth-idp/metadata
chgrp jetty /opt/shibboleth-idp/metadata/*
chmod 664 /opt/shibboleth-idp/metadata/*

# copy in config files
cp -r /tmp/idp_config/idp/* /
chown jetty /opt/shibboleth-idp/metadata/keycloak-sp.xml

sed -i -e "s#__ENTITY_ID__#$IDP_ENTITY_ID#; s/__IDP_SCOPE__/$IDP_SCOPE/" /opt/shibboleth-idp/conf/domino.properties

# tune up metadata config
sed -i -e '2,7d' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e '/<EntityDescriptor/ s/validUntil="[^"]*" //' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e "/shibmd:Scope/ s/example.org/$IDP_SCOPE/" /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e '8,16d' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e '10,41d' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e '/ArtifactResolutionService/ d' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e '73,80d' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e '/HTTP-POST-SimpleSign/ d' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e '75,76d' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e '76,184d' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e 's/https/http/g' /opt/shibboleth-idp/metadata/idp-metadata.xml
sed -i -e 's#/idp/profile#:8080/idp/profile#' /opt/shibboleth-idp/metadata/idp-metadata.xml

# set random salt for persistent id
sed -i -e "s#^\#idp.persistentId.salt.*#idp.persistentId.salt = $(dd status=none if=/dev/urandom bs=1 count=32 | base64)#" /opt/shibboleth-idp/credentials/secrets.properties

# rebuild WAR file
echo | /opt/shibboleth-idp/bin/build.sh

# restart jetty
systemctl restart jetty
