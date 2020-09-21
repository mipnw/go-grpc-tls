#!/bin/bash

# This script generates a self signed CA certificate, then generates
# certificates signed by this CA for the server and clients.
#
# This should be all that is needed for all types of TLS scenarios:
# - server-only authentication
# - mutual authentication
# except that we need to augment this script if we want TLS with Diffie-Hellman.


set -e

SECRET_ROOT_PATH=secrets/root
CSR_SUBJECT="/C=US/ST=TX/L=Dallas/O=mipnw"

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

create_private_key () {
    KEY_FILE=$1

    echo "  Creating private key"
    openssl genrsa -out $KEY_FILE 4096 &>/dev/null
}

create_csr () {
    KEY_FILE=$1
    CSR_FILE=$2
    CONFIG_FILE=$3

    echo "  Creating certificate signing request"
    openssl req -new \
        -key $KEY_FILE \
        -out $CSR_FILE \
        -config $CONFIG_FILE &>/dev/null
}

create_certificate () {
    CSR_FILE=$1
    CA_CERT_FILE=$2
    CA_KEY=$3
    CERT_FILE=$4
    CONFIG_FILE=$5

    echo "  Creating certificate"
    openssl x509 -req \
        -in $CSR_FILE  \
        -CA $CA_CERT_FILE \
        -CAkey $CA_KEY \
        -CAcreateserial \
        -out $CERT_FILE \
        -days 365 \
        -sha256 \
        -extfile $CONFIG_FILE \
        -extensions req_ext &>/dev/null
}

create_certificate_key_pair () {
    SECRET_PATH=$1
    CONFIG_FILE=$2

    echo
    echo "Generating certificate for $SECRET_PATH"
    mkdir -p \
        $SECRET_PATH/public \
        $SECRET_PATH/private

    create_private_key \
        $SECRET_PATH/private/service.key

    create_csr \
        $SECRET_PATH/private/service.key \
        $SECRET_PATH/private/service.csr \
        $CONFIG_FILE

    create_certificate \
        $SECRET_PATH/private/service.csr \
        $SECRET_ROOT_PATH/public/ca.cert \
        $SECRET_ROOT_PATH/private/ca.key \
        $SECRET_PATH/public/service.pem \
        $CONFIG_FILE
}

mkdir -p $SECRET_ROOT_PATH/public
mkdir -p $SECRET_ROOT_PATH/private

echo "Generating root CA certificate"
create_private_key \
    $SECRET_ROOT_PATH/private/ca.key

echo "  Creating self-signed CA certificate"
openssl req -new -x509 \
    -key $SECRET_ROOT_PATH/private/ca.key \
    -sha256 \
    -subj $CSR_SUBJECT \
    -days 365 \
    -out $SECRET_ROOT_PATH/public/ca.cert &>/dev/null

create_certificate_key_pair  secrets/server  $THIS_DIR/server.conf
create_certificate_key_pair  secrets/client  $THIS_DIR/client.conf
