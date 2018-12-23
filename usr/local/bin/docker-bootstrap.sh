#!/bin/bash

# Copyright 2018 AgID - Agenzia per l'Italia Digitale
#
# Licensed under the EUPL, Version 1.2 or - as soon they will be approved by
# the European Commission - subsequent versions of the EUPL (the "Licence").
#
# You may not use this work except in compliance with the Licence.
#
# You may obtain a copy of the Licence at:
#
#    https://joinup.ec.europa.eu/software/page/eupl
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the Licence is distributed on an "AS IS" basis, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# Licence for the specific language governing permissions and limitations
# under the Licence.

export LD_LIBRARY_PATH=/opt/shibboleth/lib64:${LD_LIBRARY_PATH}

##
## envvars starting with '_' represent variables that can be set
## by the user to customise the environment
##
_ENTITY_ID=${ENTITY_ID:-"https://auth.example.com/sp"}
_SPID_ACS=${SPID_ACS:-""}
_SERVER_NAME=${SERVER_NAME:-"www.to.be.set.it"}
_ERROR_URL=${ERROR_URL:-"https://${_SERVER_NAME}/error"}
_TARGET_BACKEND=${TARGET_BACKEND:-"https://backend.to.be.set.it"}
_TARGET_LOCATION=${TARGET_LOCATION:-"/login"}
_ORGANIZATION=${ORGANIZATION:-"A Company Making Everything (A.C.M.E)"}
_MODE=${MODE:-'dev'}


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
    echo "Define X_TARGET_LOCATION ${_TARGET_LOCATION}" >> ${HTTPD_ENVVAR}
fi

#
# enable the proxy configuration according to the mode
#
pushd /etc/httpd/conf.d
    case "${_MODE}" in
        prod)
            ln -s z20-auth-proxy.conf.${_MODE} z20-auth-proxy.conf
            ;;
        *)
            ln -s z20-auth-proxy.conf.dev z20-auth-proxy.conf
            ;;
    esac
popd

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
# delete development mode files or generate access page
#
if [ "${_MODE}" == "prod" ]; then
    rm -fr \
        /var/www/html/access \
        /var/www/html/whoami
else
    pushd /var/www/html/access
    sed \
        -e "s|%TARGET_LOCATION%|${_TARGET_LOCATION}|g" \
        -e "s|%SERVER_NAME%|${_SERVER_NAME}|g" \
        index.html.tpl > index.html
    popd
fi

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
        -h "${_ORGANIZATION} - SAML Signature" \
        -o ${SAML_CERT_DIR}
fi

if [ ! -f ${SAML_META_CERT} ] && [ ! -f ${SAML_META_KEY} ]
then
    ./keygen.sh -f \
        -h "${_ORGANIZATION} - SAML Metadata Signature" \
        -o ${SAML_CERT_DIR} \
        -n "sp-meta"
fi
popd

#
# generate, revise and sign metadata
#

TMP_METADATA_1=`mktemp`
TMP_METADATA_2=`mktemp`
ID=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 43 | head -n 1`

pushd /etc/shibboleth
/usr/local/bin/metagen.sh \
    -c ${SAML_CERT} \
    -h ${_SERVER_NAME} \
    -e ${_ENTITY_ID} \
    -L \
    -f urn:oasis:names:tc:SAML:2.0:nameid-format:transient \
    -2 \
    -o "${_ORGANIZATION}" \
    > ${TMP_METADATA_1}
popd

pushd /opt/shibboleth-sp/metadata
cat /dev/null > acs.xml
for idx in $(echo ${ACS_INDEXES} | tr ';' ' '); do
    _label="ACS_${idx}_LABEL"
    _attrs="ACS_${idx}_ATTRS"

    cat >> acs.xml <<EOF
<md:AttributeConsumingService index="${idx}">
  <md:ServiceName xml:lang="it">${!_label}</md:ServiceName>
EOF

    for attr in $(echo ${!_attrs} | tr ';' ' '); do
        echo "  <md:RequestedAttribute Name=\"${attr}\"/>" >> acs.xml
    done

    cat >> acs.xml <<EOF
</md:AttributeConsumingService>
EOF
done

sed \
    -e "s/Shibboleth.sso/iam/g" \
    -f /opt/spid-metadata/sed.rules ${TMP_METADATA_1} > ${TMP_METADATA_2}
rm -f acs.xml
popd

pushd /opt/shibboleth-sp/metadata
JAVA_HOME=/usr/lib/jvm/jre /opt/xmlsectool/xmlsectool.sh --sign \
    --inFile ${TMP_METADATA_2} --outFile ./metadata.xml \
    --digestAlgorithm http://www.w3.org/2001/04/xmlenc#sha512 \
    --signatureAlgorithm http://www.w3.org/2001/04/xmldsig-more#rsa-sha512 \
    --key ${SAML_META_KEY} --certificate ${SAML_META_CERT} \
    --referenceIdAttributeName ID
popd

rm ${TMP_METADATA_1} ${TMP_METADATA_2}

#
# generate Shibboleth SP configuration
#

ATTRIBUTES=(\
    "ADDRESS" \
    "COMPANYNAME" \
    "COUNTYOFBIRTH" \
    "DATEOFBIRTH" \
    "DIGITALADDRESS" \
    "EMAIL" \
    "EXPIRATIONDATE" \
    "FAMILYNAME" \
    "FISCALNUMBER" \
    "GENDER" \
    "IDCARD" \
    "IVACODE" \
    "MOBILEPHONE" \
    "NAME" \
    "PLACEOFBIRTH" \
    "REGISTEREDOFFICE" \
    "SPIDCODE" \
)

# define attribute checker rules
ATTR_CHECK="/tmp/attr-check.xml"
cat /dev/null > ${ATTR_CHECK}

echo "                    <OR>" >> ${ATTR_CHECK}
for idx in $(echo ${ACS_INDEXES} | tr ';' ' '); do
    _label="ACS_${idx}_LABEL"
    _attrs="ACS_${idx}_ATTRS"

    cat >> ${ATTR_CHECK} <<EOF
                        <!-- Check AttributeConsumingService with index ${idx} -->
                        <AND>
EOF

    for attr in ${ATTRIBUTES[*]}; do
        if echo ${!_attrs} | tr [:lower:] [:upper:] | grep -w -q "${attr}"; then
            echo "                            <Rule require=\"$(echo ${attr} | tr [:lower:] [:upper:])\"/>" >> ${ATTR_CHECK}
        else
            echo "                            <RuleRegex require=\"$(echo ${attr} | tr [:lower:] [:upper:])\">^\$</RuleRegex>" >> ${ATTR_CHECK}
        fi
    done

    cat >> ${ATTR_CHECK} <<EOF
                        </AND>
EOF
done
echo "                    </OR>" >> ${ATTR_CHECK}

# define session initiator(s)
SESSION_INITIATOR="/tmp/session-initiator.xml"
cat /dev/null > ${SESSION_INITIATOR}
for idx in $(echo ${ACS_INDEXES} | tr ';' ' '); do
    cat >> ${SESSION_INITIATOR} <<EOF
            <!-- SessionInitiator for AttributeConsumingService ${idx} -->
            <SessionInitiator type="SAML2"
                Location="/Login${idx}"
                isDefault="true"
                entityID="%ENTITY_ID%"
                outgoingBinding="urn:oasis:names:tc:SAML:profiles:SSO:request-init"
                isPassive="false"
                signing="true">
                <samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                    Version="2.0" ID="placeholder${idx}.example.com" IssueInstant="1970-01-01T00:00:00Z"
                    AttributeConsumingServiceIndex="${idx}" ForceAuthn="true">
                    <saml:Issuer
                        Format="urn:oasis:names:tc:SAML:2.0:nameid-format:entity"
                        NameQualifier="%ENTITY_ID%">
                        %ENTITY_ID%
                    </saml:Issuer>
                    <samlp:NameIDPolicy
                        Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
                    />
                </samlp:AuthnRequest>
            </SessionInitiator>
EOF
done

# generate shibboleth2.xml file
pushd /etc/shibboleth
sed \
    -f /tmp/attr-check.sed \
    -f /tmp/session-initiator.sed \
    shibboleth2.xml.tpl > shibboleth2.xml
sed -i \
    -e "s|%ENTITY_ID%|${_ENTITY_ID}|g" \
    -e "s|%ERROR_URL%|${_ERROR_URL}|g" \
    shibboleth2.xml
popd

# cleanup
rm -f ${ATTR_CHECK} ${SESSION_INITIATOR}

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
