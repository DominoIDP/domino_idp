#! /bin/sh

JETTY_VERSION=9.4.43.v20210629

# Install java 11 for jetty

yum -y install java-11-openjdk

# Add jetty user/group

groupadd -f -g 110 -r jetty
useradd -r -u 110 -g jetty -d  /opt/jetty -s /sbin/nologin -c "Jetty web server" jetty

# Download and unpack jetty

curl -o /tmp/jetty.tgz https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz
tar -C /opt -xzvf /tmp/jetty.tgz
mv /opt/jetty-distribution-$JETTY_VERSION /opt/jetty

# Clean up install

chown -R root:root /opt/jetty
rm -rf /opt/jetty/README.TXT /opt/jetty/VERSION.txt /opt/jetty/bin/jetty.service /opt/jetty/demo-base /opt/jetty/license-eplv10-aslv20.html
rm -rf /opt/jetty/logs
mkdir /var/log/jetty
chgrp jetty /var/log/jetty
chmod 771 /var/log/jetty
ln -s /var/log/jetty /opt/jetty/logs

# Set up jetty base
mkdir /var/lib/jetty
mkdir /var/lib/jetty/etc
mkdir /var/lib/jetty/start.d
mkdir /var/lib/jetty/tmp
mkdir /var/lib/jetty/webapps
mkdir /var/lib/jetty/lib
mkdir /var/lib/jetty/resources
mkdir /var/lib/jetty/modules
chown -R jetty:jetty /var/lib/jetty
chmod -R 770 /var/lib/jetty
ln -s /var/log/jetty /var/lib/jetty/logs
su -s /bin/bash - jetty -c "cd /var/lib/jetty; java -jar /opt/jetty/start.jar --approve-all-licenses --add-to-start=deploy,http,logging-logback,console-capture,logback-access,session-cache-hash,server,jsp,jstl,annotations"
su -s /bin/bash - jetty -c "cd /var/lib/jetty; java -jar /opt/jetty/start.jar --update-ini jetty.deploy.scanInterval=0"
su -s /bin/bash - jetty -c "cd /var/lib/jetty; java -jar /opt/jetty/start.jar --update-ini jetty.session.evictionPolicy=900"

# Install jetty config files
cp -r /tmp/idp_config/jetty/* /
chgrp jetty /var/lib/jetty/etc/console-capture.xml
chmod 440 /var/lib/jetty/etc/console-capture.xml
chgrp jetty /var/lib/jetty/modules/logging-logback.mod
chmod 440 /var/lib/jetty/modules/logging-logback.mod
systemd-tmpfiles --create
systemctl daemon-reload

# Let'er rip
systemctl enable jetty
systemctl start jetty
