JETTY_VERSION=9.4.43.v20210629

IDP_VERSION=4.1.4
IDP_SCOPE=localhost
IDP_HOSTNAME=localhost
IDP_ENTITY_ID=http://$(cat /proc/sys/kernel/random/uuid).$IDP_HOSTNAME/idp/shibboleth
IDP_PASSWORD=password

