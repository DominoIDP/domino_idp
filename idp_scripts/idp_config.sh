#! /bin/sh

# make sure we use the system java
export JAVA_HOME=$(/bin/java -XshowSettings:properties -version 2>&1 | grep java.home | awk '{print $3}')

# copy in config files
cp -r /tmp/idp_config/idp/* /

# rebuild WAR file
echo | /opt/shibboleth-idp/bin/build.sh

# restart jetty
systemctl restart jetty

