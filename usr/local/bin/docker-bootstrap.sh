#!/bin/bash

export LD_LIBRARY_PATH=/opt/shibboleth/lib64:${LD_LIBRARY_PATH}

##
## envvars starting with '_' represent variables that can be set
## by the user to customise the environment
##
_ENTITY_ID=${ENTITY_ID:-"https://auth.example.com/sp"}
_SPID_ACS=${SPID_ACS:-""}
_SERVER_NAME=${SERVER_NAME:-"www.to.be.set.it"}
_TARGET_BACKEND=${TARGET_BACKEND:-"https://backend.to.be.set.it"}
_TARGET_LOCATION=${TARGET_LOCATION:-"/login"}


##
## HTTPD configuration
##

#
# set httpd envvars
#
HTTPD_ENVVAR="/etc/httpd/conf.d/z00-envvar.conf"

if [ ! -f ${HTTPD_ENVVAR} ]; then
    echo "Define X_SERVER_NAME ${_SERVER_NAME}" >> ${HTTPD_ENVVAR}
    echo "Define X_TARGET_BACKEND ${_TARGET_BACKEND}" >> ${HTTPD_ENVVAR}
fi

#
# setup TLS certificates
#
TLS_CERT="/etc/pki/tls/certs/server.crt"
TLS_KEY="/etc/pki/tls/private/server.key"
if [ ! -f ${TLS_CERT} ] && [ ! -f ${TLS_KEY} ]; then
    openssl req -x509 -nodes -days 3650 \
        -newkey rsa:2048 -keyout ${TLS_KEY} \
        -out ${TLS_CERT} \
        -subj "/CN=${_SERVER_NAME}"
fi

#
# generate access page
#
pushd /var/www/html/access
sed \
    -e "s|%TARGET_LOCATION%|${_TARGET_LOCATION}|g" \
    -e "s|%SERVER_NAME%|${_SERVER_NAME}|g" \
    index.html.tpl > index.html
popd

##
## SHIBD configuration
##

#
# setup SAML certificates
#

SAML_CERT_DIR="/opt/shibboleth-sp/certs"
SAML_CERT="${SAML_CERT_DIR}/sp-cert.pem"
SAML_KEY="${SAML_CERT_DIR}/sp-key.pem"
SAML_META_CERT="${SAML_CERT_DIR}/sp-meta-cert.pem"
SAML_META_KEY="${SAML_CERT_DIR}/sp-meta-key.pem"

pushd /etc/shibboleth
if [ ! -f ${SAML_CERT} ] && [ ! -f ${SAML_KEY} ]
then
    ./keygen.sh -f \
        -e ${_ENTITY_ID} \
        -h "SAML Signature" \
        -o ${SAML_CERT_DIR}
fi

if [ ! -f ${SAML_META_CERT} ] && [ ! -f ${SAML_META_KEY} ]
then
    ./keygen.sh -f \
        -e ${_ENTITY_ID} \
        -h "SAML Metadata Signature" \
        -o ${SAML_CERT_DIR} \
        -n "sp-meta"
fi
popd

#
# generate, revise and sign metadata
#

TMP_METADATA_1=`mktemp`
TMP_METADATA_2=`mktemp`
TMP_METADATA_3=`mktemp`

ID=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 43 | head -n 1`

pushd /etc/shibboleth
./metagen.sh \
    -c ${SAML_CERT} \
    -h ${_SERVER_NAME} \
    -e ${_ENTITY_ID} \
    -L \
    -f urn:oasis:names:tc:SAML:2.0:nameid-format:transient \
    > ${TMP_METADATA_1}
popd

pushd /opt/shibboleth-sp/metadata
echo $_SPID_ACS > acs.xml
xsltproc /opt/spid-metadata/transform.xsl ${TMP_METADATA_1} > ${TMP_METADATA_2}
sed \
    -e "s/%ID%/${ID}/g" \
    -e "s/Shibboleth.sso/iam/g" \
    -f /opt/spid-metadata/sed.rules ${TMP_METADATA_2} > ${TMP_METADATA_3}
rm -f acs.xml
popd

pushd /opt/shibboleth-sp/metadata
samlsign \
    -s -k ${SAML_META_KEY} -c ${SAML_META_CERT} -f ${TMP_METADATA_3} \
    -alg http://www.w3.org/2001/04/xmldsig-more#rsa-sha256 \
    -dig http://www.w3.org/2001/04/xmlenc#sha256 \
    > metadata.xml
popd

#
# generate Shibboleth SP configuration
#
pushd /etc/shibboleth
sed \
    -e "s|%ENTITY_ID%|${_ENTITY_ID}|g" \
    shibboleth2.xml.tpl > shibboleth2.xml
popd


#
# killing existing shibd (if any)
#
shibd_pid=`pgrep shibd`
if [ ${shibd_pid} ]; then
    echo "Killing Shibboleth daemon (${shibd_pid})"
    kill -9 ${shibd_pid}
    rm -vf /var/run/shibboleth/*
fi

#
# run shibd
#
/usr/sbin/shibd

#
# run httpd
#
exec apachectl -DFOREGROUND
