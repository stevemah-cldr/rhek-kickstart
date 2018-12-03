#!/bin/bash

# cups settings
cat <<EOF>> /etc/cups/cupsd.conf
BrowsePoll cups-pao11.eng.vmware.com:631
BrowseInterval 120
EOF
#turn on Browsing for cups
cat /etc/cups/cupsd.conf|sed s/"Browsing Off"/"Browsing On"/g > /tmp/cupsd.conf
mv /tmp/cupsd.conf /etc/cups/cupsd.conf

#Configure LDAP
#CentOS 5.x and RHEL 5.x

authconfig --enableldap --enableldapauth --ldapserver ldaps://ldap1-pao11.eng.vmware.com,ldaps://ldap2-pao11.eng.vmware.com --ldapbasedn=dc=vmware,dc=com --update 

#echo "ssl on" >> /etc/ldap.conf ; echo "TLS_REQCERT never" >> /etc/openldap/ldap.conf 

#download ldap certificate
wget http://engweb.eng.vmware.com/sipublic/ldap/ldap-eng-vmware.pem -O /etc/openldap/cacerts/ldap-eng-vmware.pem
chown root:root /etc/openldap/cacerts/ldap-eng-vmware.pem
chmod 644 /etc/openldap/cacerts/ldap-eng-vmware.pem

# setup ldap.conf
cat <<EOF1>> /etc/ldap.conf
URI ldaps://ldap1-pao11.eng.vmware.com:636/ ldaps://ldap2-pao11.eng.vmware.com:636/
SSL             off
TLS             hard
TLS_REQCERT     demand
TLS_CACERT      /etc/openldap/cacerts/ldap-eng-vmware.pem
BIND_POLICY     soft
pam_password_prohibit_message Please use https://pa-psynch2.vmware.com/ to change your password.
EOF1

# copy to /etc/ldap, since auth-client-config only writes to /etc/ldap.conf
cp /etc/ldap.conf /etc/openldap/ldap.conf

cat <<EOF2>> /etc/sysconfig/autofs
MAP_OBJECT_CLASS="automountMap"
ENTRY_OBJECT_CLASS="automount"
MAP_ATTRIBUTE="ou"
ENTRY_ATTRIBUTE="cn"
VALUE_ATTRIBUTE="automountInformation"
EOF2

# fix autofs issue
rpm -e sssd sssd-client autofs ipa-client
rm -rf /var/lib/sss/db/*
yum install sssd sssd-client autofs ipa-client -y
unalias cp
cp /etc/sysconfig/autofs.rpmsave /etc/sysconfig/autofs
cp /etc/sssd/sssd.conf.rpmsave  /etc/sssd/sssd.conf
authconfig --enableldap --enableldapauth --ldapserver ldaps://ldap1-pao11.eng.vmware.com,ldaps://ldap2-pao11.eng.vmware.com --ldapbasedn=dc=vmware,dc=com --update
