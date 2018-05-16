# SPID Auth Docker

SPID Auth Docker is a service provider based on shibboleth that takes care of
the SPID authentication process with the Identity Provider and redirects the
attributes of the final response to the set address so that they can be used
by the application.

SPID Auth Docker has been developed and is maintained by AgID - Agenzia per
l'Italia Digitale.

## How to quickly test it

1.  Create a directory to store SAML certificates and another to store log
    files

        $ mkdir -vp /tmp/certs /tmp/log/{httpd,shibboleth,shibboleth-www}

2.  Create a docker compose file (`docker-compose.yml`) with the following
    content. **Note:** set `SERVER_NAME` to a publicly reachable IP or FQDN.

        version: '3'

        services:
          authproxy:
            image: spid-auth-proxy
            build:
              context: .
              dockerfile: Dockerfile
            ports:
              - '80:80'
              - '443:443'
            volumes:
              - '/tmp/certs:/opt/shibboleth-sp/certs'
              - '/tmp/log:/var/log'
            environment:
              SERVER_NAME: 'my.auth.proxy.com'
              ENTITY_ID: 'https://my.auth.proxy.com'
              TARGET_BACKEND: 'https://mytargetapp.my.cloud.provider.com'
              TARGET_LOCATION: '/login'
              SPID_ACS: |
                <md:AttributeConsumingService index="1">
                  <md:ServiceName xml:lang="it">set1</md:ServiceName>
                  <md:RequestedAttribute Name="name"/>
                  <md:RequestedAttribute Name="familyName"/>
                  <md:RequestedAttribute Name="fiscalNumber"/>
                  <md:RequestedAttribute Name="email"/>
                </md:AttributeConsumingService>
                <md:AttributeConsumingService index="2">
                  <md:ServiceName xml:lang="it">set2</md:ServiceName>
                  <md:RequestedAttribute Name="spidCode"/>
                  <md:RequestedAttribute Name="fiscalNumber"/>
                </md:AttributeConsumingService>

    You can use `docker-compose.quickstart.yml`, which is available in this
    repository.

3.  Execute the Docker environmnet with the following command

        $ docker-compose up --build

    It will

    *   build the docker image

    *   generate a self-signed certificate for TLS (`SERVER_NAME` used
        as `CN`), SAML assertions signature (`SAML Signature` as `CN`) and
        SAML metadata signature (`SAML Metadata Signature` as `CN`)

    *   generate the Shibboleth/Httpd configuration according to the
        environment variables

    *   execure `shibd` and `httpd`

4.  If everything gone well, you should be able to access the URL

        https://<SERVER_NAME>/metadata

    Open it and use the following information

    *   `entityID` under `<md:EntityDescriptor>` tag
    *   `<ds:X509Certificate>` under `<md:SPSSODescriptor>` tag
    *   `Location` under `<md:SingleLogoutService>` tag
    *   `Location` under `<md:AssertionConsumerService>` tag
    *   attributes names under `<md:AttributeConsumingService>` tags

    to register you authentication proxy on

        https://idp.spid.gov.it:8080

5.  Open the URL

        https://<SERVER_NAME>/access

    and click on

       Test on /whoami (lucia/password123)

    It starts an authentication process that will end on `/whoami` endpoint
    where all the information about the authentication will be dumped.

## How to use it in production-like environment

1.  Create a directory to store SAML certificates and another to store log
    files

        $ mkdir -vp \
            /opt/authproxy/certs/{saml,tls} \
            /opt/authproxy/log/{httpd,shibboleth,shibboleth-www}

2.  Create/Obtain X509 certificates for TLS and SAML signatures and store them
    as follows

        /opt/authproxy/certs
        ├── saml
        │   ├── sp-cert.pem
        │   ├── sp-key.pem
        │   ├── sp-meta-cert.pem
        │   └── sp-meta-key.pem
        └── tls
            ├── server.crt
            └── server.key

3.  Create a docker compose file as follows. Be sure to set environment
    variables to values reflecting your real environment.

        version: '3'

        services:
          authproxy:
            image: spid-auth-proxy
            build:
              context: .
              dockerfile: Dockerfile
            ports:
              - '80:80'
              - '443:443'
            volumes:
              - '/opt/authproxy/certs/saml:/opt/shibboleth-sp/certs:ro'
              - '/opt/authproxy/certs/tls/server.crt:/etc/pki/tls/certs/server.crt:ro'
              - '/opt/authproxy/certs/tls/server.key:/etc/pki/tls/private/server.key:ro'
              - '/opt/authproxy/log:/var/log'
            environment:
              SERVER_NAME: 'my.auth.proxy.com'
              ENTITY_ID: 'https://my.auth.proxy.com'
              TARGET_BACKEND: 'https://mytargetapp.my.cloud.provider.com'
              TARGET_LOCATION: '/login'
              SPID_ACS: |
                <md:AttributeConsumingService index="1">
                  <md:ServiceName xml:lang="it">set1</md:ServiceName>
                  <md:RequestedAttribute Name="name"/>
                  <md:RequestedAttribute Name="familyName"/>
                  <md:RequestedAttribute Name="fiscalNumber"/>
                  <md:RequestedAttribute Name="email"/>
                </md:AttributeConsumingService>
                <md:AttributeConsumingService index="2">
                  <md:ServiceName xml:lang="it">set2</md:ServiceName>
                  <md:RequestedAttribute Name="spidCode"/>
                  <md:RequestedAttribute Name="fiscalNumber"/>
                </md:AttributeConsumingService>

4.  If necessary, revise the `httpd` configuration files under `etc/httpd/conf.d`
    in order to fit with your requirements

5.  Execute the Docker environmnet with the following command

        $ docker-compose up --build

6.  Register your authentication proxy on the IdP by providing the information
    contained at

        https://<SERVER_NAME>/metadata

7.  In order to use the authentication proxy, you application should
    initialise the the authentication by calling

        https://<SERVER_NAME>/iam/Login?target=https://<SERVER_NAME>/login&entityID=<IDP ENTITY_ID>

    Once authenticated, the callback (`/login`) will proxy the response to
    your backend (`TARGET_BACKEND`) by including within the request headers
    the authentication result.
