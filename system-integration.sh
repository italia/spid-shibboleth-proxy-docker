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

_INSTALL_DIR=${INSTALL_DIR:-"/opt/authproxy"}

if [ ! -d "${_INSTALL_DIR}/spid-auth-docker" ]; then
    cat<<EOF
ERROR: INSTALL_DIR must be set to the path where
       https://github.com/italia/spid-auth-docker has been
       cloned.

       For instance, ff you cloned the repository under
       "/tmp/spid-auth-docker", INSTALL_DIR must be set
       to "/tmp".
EOF
    exit 1
fi

_SERVER_NAME=${SERVER_NAME:-"my.auth.proxy.it"}
_ENTITY_ID=${ENTITY_ID:-"https://my.auth.proxy.it"}
_TARGET_BACKEND=${TARGET_BACKEND:-"http://backend_app:8080"}
_TARGET_LOCATION=${TARGET_LOCATION:-"/login"}
_ORGANIZATION=${ORGANIZATION:-"A Company Making Everything"}
_MODE=${MODE:-"dev"}

LOG_DIR="${_INSTALL_DIR}/log"
CERT_DIR="${_INSTALL_DIR}/certs"
LOGROTATE_DIR="${_INSTALL_DIR}/etc/logrotate.d"
SYSTEMD_DIR="${_INSTALL_DIR}/lib/systemd/system"

# create log dirs
mkdir -vp ${LOG_DIR}/{httpd,shibboleth,shibboleth-www}

# create cert dirs
mkdir -vp ${CERT_DIR}/{saml,tls}

# create system dirs
mkdir -vp ${LOGROTATE_DIR} ${SYSTEMD_DIR}

#
# generate docker compose file
#
cat > ${_INSTALL_DIR}/docker-compose.yml <<EOF
version: '3'
services:
  authproxy:
    image: spid-auth-proxy
    restart: always
    build:
      context: ${_INSTALL_DIR}/spid-auth-docker
      dockerfile: Dockerfile
      args:
        http_proxy: ${http_proxy}
        https_proxy: ${https_proxy}
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - '${CERT_DIR}/saml:/opt/shibboleth-sp/certs'
      - '${CERT_DIR}/tls/server.crt:/etc/pki/tls/certs/server.crt:ro'
      - '${CERT_DIR}/tls/server.key:/etc/pki/tls/private/server.key:ro'
      - '${LOG_DIR}:/var/log'
    environment:
      MODE: '${_MODE}'
      ORGANIZATION: '${_ORGANIZATION}'
      SERVER_NAME: '${_SERVER_NAME}'
      ENTITY_ID: '${_ENTITY_ID}'
      TARGET_BACKEND: '${_TARGET_BACKEND}'
      TARGET_LOCATION: '${_TARGET_LOCATION}'
      SPID_ACS: |
        <md:AttributeConsumingService index="0">
          <md:ServiceName xml:lang="it">all SPID attributes</md:ServiceName>
          <md:RequestedAttribute Name="address" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="companyName" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="countyOfBirth" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="dateOfBirth" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="digitalAddress" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="expirationDate" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="familyName" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="fiscalNumber" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="gender" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="idCard" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="ivaCode" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="mobilePhone" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="placeOfBirth" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="registeredOffice" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="spidCode" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
        </md:AttributeConsumingService>
    networks:
      - authproxy
    depends_on:
      - backend_app
  backend_app:
    build:
      context: ${_INSTALL_DIR}/spid-auth-docker/example
      dockerfile: Dockerfile
      args:
        http_proxy: ${http_proxy}
        https_proxy: ${https_proxy}
    environment:
      SERVER_NAME: ${_SERVER_NAME}
    networks:
      - authproxy
networks:
  authproxy:
    driver_opts:
      com.docker.network.driver.mtu: 1500
EOF

#
# generate systemd unit file
#
cat > ${SYSTEMD_DIR}/spid-auth-proxy.service <<EOF
[Unit]
Description=SPID Authentication Proxy
Requires=docker.service
After=docker.service
[Service]
Restart=always
WorkingDirectory=${_INSTALL_DIR}
# stop and remove existing containers
ExecStartPre=/usr/local/bin/docker-compose stop
ExecStartPre=/usr/local/bin/docker-compose rm -f
# start
ExecStart=/usr/local/bin/docker-compose up --build
# stop
ExecStop=/usr/local/bin/docker-compose stop
[Install]
WantedBy=multi-user.target
EOF

cat <<EOF

Run the following command to enable the systemd unit file
    cd /lib/systemd/system
    sudo ln -s ${SYSTEMD_DIR}/spid-auth-proxy.service .
    sudo systemctl enable spid-auth-proxy.service

EOF

#
# generate logrotate file
#
cat > ${LOGROTATE_DIR}/spid-auth-proxy <<EOF
${LOG_DIR}/httpd/*_log
${LOG_DIR}/shibboleth/*.log
${LOG_DIR}/shibboleth-www/*.log
{
    rotate 4
    weekly
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
}
EOF

cat <<EOF

Run the following command to enable the logrotate configuration
    cd /etc/logrotate.d
    sudo ln -s ${LOGROTATE_DIR}/spid-auth-proxy .

EOF
