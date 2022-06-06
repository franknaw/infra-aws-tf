#!/usr/bin/env bash

set -e

function generate_certificate() {

  if [ ! -d "certs" ]; then
    mkdir certs
  fi
  cd certs

  # Generate self-signed certificate - without prompts
  #openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout privateKey.key -out certificate.crt
  openssl req \
    -newkey rsa:4096 -nodes \
    -keyout "$REGION-$ENV-privateKey.key" \
    -x509 \
    -sha256 -days 365 \
    -subj "/C=US/ST=VA/L=Arlington/O=fnaw-dev/OU=CVLE/CN=[]" \
    -out "$REGION-$ENV-certificate.crt"

  # Verify key and certificate
  openssl rsa -in "$REGION-$ENV-privateKey.key" -check
  openssl x509 -in "$REGION-$ENV-certificate.crt" -text -noout

  cd ..
  # Not Needed
  # Convert the key and cert into pem encoded file
  #openssl rsa -in privateKey.key -text > private.pem
  #openssl x509 -inform PEM -in certificate.crt > public.pem
}

function arg_exception() {
  echo "2 args are required"
  echo "arg 1: provision environment (dev)"
  echo "arg 2: region to build (com-east|com-west)"
  exit 0
}

if [[ "$#" -ne 2 || "$1" != @(dev) || "$2" != @(com-west|com-east) ]]; then
  arg_exception
fi

# Generate the cert, set false to disable
GEN_CERT=false
ENV="$1"
REGION="$2"

if [[ "$GEN_CERT" == true ]]; then
  generate_certificate
fi

