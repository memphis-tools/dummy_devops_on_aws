#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
WHITE='\033[1;97m'
RESET='\033[0m'

echo -e "$CYAN[+] Source environment vars from .env file $RESET"
source .env
echo -e "$GREEN[+] File .env sourced $RESET"

# create a CA private key
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_ca.key -algorithm RSA -aes256 -pass pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# create a CA public key
openssl req -x509 -new -days 3650 \
  -key ./ephemeral-keys/${CERT_PREFIX}_ca.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -pkeyopt rsa_keygen_bits:2048 \
  -config ./openssl_cnf/san.ca.cnf \
  -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE \
  -extensions v3_ca

# create a jenkins KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_jenkins.key -algorithm RSA

# create a CSR for jenkins
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_jenkins.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_jenkins.csr \
  -config ./openssl_cnf/san_jenkins.cnf -extensions req_ext

# sign the CSR for jenkins
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_jenkins.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_jenkins.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_jenkins.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# concatenate CA and CERT (ensure it makes sense)
cat ./ephemeral-keys/${CERT_PREFIX}_jenkins.crt  ./ephemeral-keys/${CERT_PREFIX}_ca.crt > ./ephemeral-keys/${CERT_PREFIX}_jenkins_fullchain.crt

# create a tomcat KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_tomcat.key -algorithm RSA

# create a CSR for tomcat
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_tomcat.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_tomcat.csr \
  -config ./openssl_cnf/san_tomcat.cnf -extensions req_ext

# sign the CSR for tomcat
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_tomcat.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_tomcat.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_tomcat.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# concatenate CA and CERT (ensure it makes sense)
cat ./ephemeral-keys/${CERT_PREFIX}_tomcat.crt  ./ephemeral-keys/${CERT_PREFIX}_ca.crt > ./ephemeral-keys/${CERT_PREFIX}_tomcat_fullchain.crt

# create a docker KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_docker_tomcat.key -algorithm RSA

# create a CSR for docker
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_docker_tomcat.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_docker_tomcat.csr \
  -config ./openssl_cnf/san_docker_tomcat.cnf -extensions req_ext

# sign the CSR for docker
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_docker_tomcat.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_docker_tomcat.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_docker_tomcat.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# concatenate CA and CERT (ensure it makes sense)
cat ./ephemeral-keys/${CERT_PREFIX}_docker_tomcat.crt  ./ephemeral-keys/${CERT_PREFIX}_ca.crt > ./ephemeral-keys/${CERT_PREFIX}_docker_tomcat_fullchain.crt

# create a nginx_jenkins KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins.key -algorithm RSA

# create a CSR for nginx_jenkins
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins.csr \
  -config ./openssl_cnf/san_nginx_jenkins.cnf -extensions req_ext

# sign the CSR for nginx_jenkins
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_nginx_jenkins.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# concatenate CA and CERT (ensure it makes sense)
cat ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins.crt  ./ephemeral-keys/${CERT_PREFIX}_ca.crt > ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins_fullchain.crt

# create a nginx_jenkins_proxy_client KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins_proxy_client.key -algorithm RSA

# create a CSR for nginx_jenkins_proxy_client
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins_proxy_client.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins_proxy_client.csr \
  -config ./openssl_cnf/san_nginx_jenkins_proxy_client.cnf -extensions req_ext

# sign the CSR for nginx_jenkins_proxy_client
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins_proxy_client.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins_proxy_client.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_nginx_jenkins_proxy_client.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# concatenate CA and CERT (ensure it makes sense)
cat ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins_proxy_client.crt  ./ephemeral-keys/${CERT_PREFIX}_ca.crt > ./ephemeral-keys/${CERT_PREFIX}_nginx_jenkins_proxy_client_fullchain.crt

# create a wazuh_dashboard KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_dashboard.key -algorithm RSA

# create a CSR for wazuh_dashboard
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_wazuh_dashboard.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_dashboard.csr \
  -config ./openssl_cnf/san_wazuh_dashboard.cnf -extensions req_ext

# sign the CSR for wazuh_dashboard
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_wazuh_dashboard.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_dashboard.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_wazuh_dashboard.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# concatenate CA and CERT (ensure it makes sense)
cat ./ephemeral-keys/${CERT_PREFIX}_wazuh_dashboard.crt  ./ephemeral-keys/${CERT_PREFIX}_ca.crt > ./ephemeral-keys/${CERT_PREFIX}_wazuh_dashboard_fullchain.crt

# create a wazuh_indexer KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_indexer.key -algorithm RSA

# create a CSR for wazuh_indexer
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_wazuh_indexer.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_indexer.csr \
  -config ./openssl_cnf/san_wazuh_indexer.cnf -extensions req_ext

# sign the CSR for wazuh_indexer
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_wazuh_indexer.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_indexer.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_wazuh_indexer.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# concatenate CA and CERT (ensure it makes sense)
cat ./ephemeral-keys/${CERT_PREFIX}_wazuh_indexer.crt  ./ephemeral-keys/${CERT_PREFIX}_ca.crt > ./ephemeral-keys/${CERT_PREFIX}_wazuh_indexer_fullchain.crt

# create a wazuh_server KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_server.key -algorithm RSA

# create a CSR for wazuh_server
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_wazuh_server.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_server.csr \
  -config ./openssl_cnf/san_wazuh_server.cnf -extensions req_ext

# sign the CSR for wazuh_server
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_wazuh_server.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_server.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_wazuh_server.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# concatenate CA and CERT (ensure it makes sense)
cat ./ephemeral-keys/${CERT_PREFIX}_wazuh_server.crt  ./ephemeral-keys/${CERT_PREFIX}_ca.crt > ./ephemeral-keys/${CERT_PREFIX}_wazuh_server_fullchain.crt

# create a wazuh_admin KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_admin.key -algorithm RSA

# create a CSR for wazuh_admin
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_wazuh_admin.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_admin.csr \
  -config ./openssl_cnf/san_wazuh_admin.cnf -extensions req_ext

# sign the CSR for wazuh_admin
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_wazuh_admin.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_wazuh_admin.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_wazuh_admin.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE

# concatenate CA and CERT (ensure it makes sense)
cat ./ephemeral-keys/${CERT_PREFIX}_wazuh_admin.crt  ./ephemeral-keys/${CERT_PREFIX}_ca.crt > ./ephemeral-keys/${CERT_PREFIX}_wazuh_admin_fullchain.crt

# create a k8s KEY (without the aes algorithm which implies a passphrase)
openssl genpkey -out ./ephemeral-keys/${CERT_PREFIX}_k8s.key -algorithm RSA

# create a CSR for k8s
openssl req -new \
  -key ./ephemeral-keys/${CERT_PREFIX}_k8s.key \
  -out ./ephemeral-keys/${CERT_PREFIX}_k8s.csr \
  -config ./openssl_cnf/san_k8s.cnf -extensions req_ext

# sign the CSR for k8s
openssl x509 -req \
  -in ./ephemeral-keys/${CERT_PREFIX}_k8s.csr \
  -CA ./ephemeral-keys/${CERT_PREFIX}_ca.crt \
  -CAkey ./ephemeral-keys/${CERT_PREFIX}_ca.key  \
  -CAcreateserial \
  -out ./ephemeral-keys/${CERT_PREFIX}_k8s.crt \
  -days 3650 -sha256 -extfile ./openssl_cnf/san_k8s.cnf -extensions req_ext -passin pass:$SELF_SIGNED_CA_PRIVATE_KEY_PASSPHRASE


# make a DER file from the web app's CA self-signed-cert AND import it into your firefox to be trusted
openssl x509 -in ./ephemeral-keys/${CERT_PREFIX}_ca.crt -outform DER -out ./ephemeral-keys/${CERT_PREFIX}_ca.der
