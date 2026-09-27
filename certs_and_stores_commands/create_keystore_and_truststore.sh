#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
WHITE='\033[1;97m'
RESET='\033[0m'

echo -e "$CYAN[+] Source environment vars from .env file $RESET"
source .env
echo -e "$GREEN[+] File .env sourced $RESET"

# change directory to ./ephemeral-keys/ by default
cd ./ephemeral-keys/

# create a PKCS12 (.p12) file from the jenkins web app's x509 cert
openssl pkcs12 -export -name ${CERT_PREFIX}_jenkins -in ${CERT_PREFIX}_jenkins.crt -inkey ${CERT_PREFIX}_jenkins.key -certfile aws_dummy_ops_ca.crt -name aws_dummy_ops_jenkins -out ${CERT_PREFIX}_jenkins.p12 -password pass:${P12_PASSPHRASE}

# create a PKCS12 (.p12) file from the tomcat web app's x509 cert
openssl pkcs12 -export -name ${CERT_PREFIX}_tomcat -in ${CERT_PREFIX}_tomcat.crt -inkey ${CERT_PREFIX}_tomcat.key -certfile aws_dummy_ops_ca.crt -name aws_dummy_ops_tomcat -out ${CERT_PREFIX}_tomcat.p12 -password pass:${P12_PASSPHRASE}

# create a PKCS12 (.p12) file from the docker's tomcat web app's x509 cert
openssl pkcs12 -export -name ${CERT_PREFIX}_docker_tomcat -in ${CERT_PREFIX}_docker_tomcat.crt -inkey ${CERT_PREFIX}_docker_tomcat.key -certfile aws_dummy_ops_ca.crt -name aws_dummy_ops_docker_tomcat -out ${CERT_PREFIX}_docker_tomcat.p12 -password pass:${P12_PASSPHRASE}

# import the jenkins web app's .p12 in a keystore, to be used by jenkins
keytool -importkeystore -srcstorepass ${P12_PASSPHRASE} -deststorepass ${JENKINS_HTTPS_KEYSTORE_PASSWORD} -destkeystore ${CERT_PREFIX}_jenkins.keystore -srckeystore ${CERT_PREFIX}_jenkins.p12 -srcstoretype pkcs12 -alias ${CERT_PREFIX}_jenkins

# import the tomcat web app's .p12 in a keystore, to be used by tomcat
keytool -importkeystore -srcstorepass ${P12_PASSPHRASE} -deststorepass ${TOMCAT_HTTPS_KEYSTORE_PASSWORD} -destkeystore ${CERT_PREFIX}_tomcat.keystore -srckeystore ${CERT_PREFIX}_tomcat.p12 -srcstoretype pkcs12 -alias ${CERT_PREFIX}_tomcat

# import the tomcat web app's .p12 in a keystore, to be used by docker
keytool -importkeystore -srcstorepass ${P12_PASSPHRASE} -deststorepass ${DOCKER_TOMCAT_KEYSTORE_PASSPHRASE} -destkeystore ${CERT_PREFIX}_docker_tomcat.keystore -srckeystore ${CERT_PREFIX}_docker_tomcat.p12 -srcstoretype pkcs12 -alias ${CERT_PREFIX}_docker_tomcat
