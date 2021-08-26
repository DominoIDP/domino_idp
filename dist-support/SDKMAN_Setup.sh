#!/usr/bin/bash
# Script settings:
# -e:  exit the scripts if any of the commands fail
# -x:  Echo the commands
set -ex

# Dependencies
sudo yum -y install curl
sudo yum -y install zip
sudo yum -y install unzip

curl -s "https://get.sdkman.io" | bash
source "/home/vagrant/.sdkman/bin/sdkman-init.sh"

# The old Java versions are constantly removed, so this is unreliable
#yes | sdk install java 8.0.232-zulu 
#sdk default java 8.0.232-zulu 
# Get the latest AdoptOpenJDK
LATEST_JDK=`sdk list java | grep "8.0.*.hs-adpt" | sed 's/^.*\(8.0.[0-9]\+.hs-adpt\)[ ]*$/\1/'`
sdk install java $LATEST_JDK
sdk default java $LATEST_JDK
# Instead, use the Domino JVM - FAILED - triggers Segmentation fault
#echo "" >> /home/vagrant/.bashrc
#echo "export JAVA_HOME=/opt/ibm/domino/notes/latest/linux/jvm/" >> /home/vagrant/.bashrc
#echo "export PATH=/opt/ibm/domino/notes/latest/linux/jvm/bin:$PATH" >> /home/vagrant/.bashrc


## Use pre-downloaded JRE at expected location
## I disabled this because it is a pain to get new JREs from Oracle
#tar xzvf /home/vagrant/jre-8u251-linux-x64.tar.gz -C /opt/java
#echo "" >> /home/vagrant/.bashrc
#echo "export JAVA_HOME=export JAVA_HOME=/opt/java/jre1.8.0_251/" >> /home/vagrant/.bashrc
#echo "export PATH=/opt/java/jre1.8.0_251/bin:$PATH" >> /home/vagrant/.bashrc
