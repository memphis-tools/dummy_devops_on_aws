#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[1;32m'
WHITE='\033[1;97m'
RESET='\033[0m'

echo -e "$CYAN[+] Trying to source the .env file $RESET"
source .env
echo -e "$GREEN[+] .env file exists $RESET"

# before changing directory, we get the current project path
PROJECT_PATH=$PWD

# change directory to ./ephemeral-keys/ by default
cd ./ephemeral-keys/

if [[ -z '/usr/local/share/ca-certificates/' ]]
then
	echo -e "$CYAN[+] Trying to update trusted authorities, running a Debian base OS $RESET"
  sudo rm -f /usr/local/share/ca-certificates/${CERT_PREFIX}_ca.crt
  sudo update-ca-certificates
  sudo cp ${CERT_PREFIX}_ca.crt /usr/local/share/ca-certificates/
  sudo update-ca-certificates
else
	echo -e "$CYAN[+] Trying to update trusted authorities, running a RHEL based OS $RESET"
  sudo rm -f /usr/share/pki/ca-trust-source/anchors/${CERT_PREFIX}_ca.crt
	sudo rm -f /etc/pki/ca-trust/source/anchors/${CERT_PREFIX}_ca.der
  sudo update-ca-trust extract
  sudo cp ${CERT_PREFIX}_ca.crt /usr/share/pki/ca-trust-source/anchors/
	sudo cp ${CERT_PREFIX}_ca.der /etc/pki/ca-trust/source/anchors/
  sudo update-ca-trust extract
fi
echo -e "$GREEN[+] Trusted authorities updated $RESET"

echo -e "$CYAN[+] Trying to update trusted authorities, running a RHEL/DEBIAN based OS $RESET"
cd
cd $LOCAL_DEFAULT_FIREFOX_PROFILE
echo -e "$GREEN[+] Trying to remove/untrust $SELF_SIGNED_CA_NAME $RESET"
CA_REMOVAL_STATE=$(certutil -D -n "$SELF_SIGNED_CA_NAME" -d sql:. 2>&1)
CA_REMOVAL_STATE=$(echo "$CA_REMOVAL_STATE" | grep 'could not find certificate')
if [[ $CA_REMOVAL_STATE != "" ]]
then
	echo -e "$CYAN[+] CA $SELF_SIGNED_CA_NAME does not exists, nothing to do $RESET"
else
	echo -e "$GREEN[+] CA $SELF_SIGNED_CA_NAME removed $RESET"
fi
certutil -A -n "$SELF_SIGNED_CA_NAME" -t "C,," -i $PROJECT_PATH/ephemeral-keys/${CERT_PREFIX}_ca.der -d sql:.
echo -e "$GREEN[+] CA $SELF_SIGNED_CA_NAME imported and trusted $RESET"
echo -e "$CYAN[+] List trusted authorities $RESET"
certutil -L -d sql:.
echo -e "$GREEN[+] Successfully update trusted authorities $RESET"
