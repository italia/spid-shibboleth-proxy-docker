# SPID Auth Docker

SPID Auth Docker is a service provider based on shibboleth that takes care of
the SPID authentication process with the Identity Provider and redirects the
attributes of the final response to the set address so that they can be used
by the application.

SPID Auth Docker has been developed and is maintained by AgID - Agenzia per
l'Italia Digitale.


**DISCLAIMER: Is highly recommended to update the installed version to the latest pubblished release.**


## How to quickly test it

1.  Create a directory to store SAML certificates and another to store log
    files

        $ mkdir -vp /tmp/certs /tmp/log/{httpd,shibboleth,shibboleth-www}

2.  Create a docker compose file (`docker-compose.yml`) with the following
    content. **Note:** set `SERVER_NAME` to a publicly reachable IP or FQDN.

    ```.yaml
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
          ORGANIZATION: 'My eGov Service'
          SERVER_NAME: 'my.auth.proxy.com'
          ENTITY_ID: 'https://my.auth.proxy.com'
          TARGET_BACKEND: 'https://mytargetapp.my.cloud.provider.com'
          TARGET_LOCATION: '/login'
          ACS_INDEXES: '1;2'
          ACS_1_LABEL: 'set 1'
          ACS_1_ATTRS: 'name;familyName;fiscalNumber;email'
          ACS_2_LABEL: 'set 2'
          ACS_2_ATTRS: 'spidCode;fiscalNumber'
    ```

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

    ```.yaml
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
          MODE: 'prod'
          ORGANIZATION: 'My eGov Service'
          SERVER_NAME: 'my.auth.proxy.com'
          ERROR_URL: 'https://my.auth.proxy.com/error'
          ENTITY_ID: 'https://my.auth.proxy.com'
          TARGET_BACKEND: 'https://mytargetapp.my.cloud.provider.com'
          TARGET_LOCATION: '/login'
          ACS_INDEXES: '1;2'
          ACS_1_LABEL: 'set 1'
          ACS_1_ATTRS: 'name;familyName;fiscalNumber;email'
          ACS_2_LABEL: 'set 2'
          ACS_2_ATTRS: 'spidCode;fiscalNumber'
    ```

    Be sure that `MODE` envvar is set to `prod`.

    The URL specified in `ERROR_URL` should be an endpoint that is able
    to manage errors as mentioned in

        https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPErrors#NativeSPErrors-Redirection

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

## How to define AttributeConsumingService elements

The `AttributeConsumingService` (ACS) elements can be defined by using a set
of properly named environment variables.

Firstly, you have to declare the indexes of your ACSs by defining the
`ACS_INDEXES` variable with all the indexes separated by a `;`.

Then, for each ACS, you have to define the label with `ACS_<INDEX>_LABEL` and
the list of the attributes with `ACS_<INDEX>_ATTRS`. The attributes must be
specified as `;` separated list.

For instance, to the define two ACSs (with index `1` and `27`) where the
first includes the attributes `spidCode` and `fiscalNumber` while the latter
`name` and `placeOfBirth`, the environment variables must be defined and set
as follows

```.yaml
environment:
  ACS_INDEXES: '1;27'
  ACS_1_LABEL: 'My First Set'
  ACS_1_ATTRS: 'spidCode;fiscalNumber'
  ACS_27_LABEL: 'My Second Set'
  ACS_27_ATTRS: 'name;placeOfBirth'
```

The `ACS_*` environment variables are also used to configure the [`AttributeChecker`](https://wiki.shibboleth.net/confluence/display/SP3/Attribute+Checker+Handler) handler.
The environment variables of the example will generate the following configuration
(nested in the resulting `/etc/shibboleth/shibboleth2.xml`)

```.xml
<!-- Check the returned attributes -->
<Handler type="AttributeChecker" Location="/AttrChecker" template="attrChecker.html" flushSession="true">
    <AND>
        <OR>
            <Rule require="authnContextClassRef">https://www.spid.gov.it/SpidL1</Rule>
            <Rule require="authnContextClassRef">https://www.spid.gov.it/SpidL2</Rule>
            <Rule require="authnContextClassRef">https://www.spid.gov.it/SpidL3</Rule>
        </OR>
        <OR>
            <!-- Check AttributeConsumingService with index 1 -->
            <AND>
                <AND>
                    <Rule require="SPIDCODE"/>
                    <Rule require="FISCALNUMBER"/>
                </AND>
                <AND>
                    <NOT><Rule require="ADDRESS"/></NOT>
                    <NOT><Rule require="COMPANYNAME"/></NOT>
                    <NOT><Rule require="COUNTYOFBIRTH"/></NOT>
                    <NOT><Rule require="DATEOFBIRTH"/></NOT>
                    <NOT><Rule require="DIGITALADDRESS"/></NOT>
                    <NOT><Rule require="EMAIL"/></NOT>
                    <NOT><Rule require="EXPIRATIONDATE"/></NOT>
                    <NOT><Rule require="FAMILYNAME"/></NOT>
                    <NOT><Rule require="GENDER"/></NOT>
                    <NOT><Rule require="IDCARD"/></NOT>
                    <NOT><Rule require="IVACODE"/></NOT>
                    <NOT><Rule require="MOBILEPHONE"/></NOT>
                    <NOT><Rule require="NAME"/></NOT>
                    <NOT><Rule require="PLACEOFBIRTH"/></NOT>
                    <NOT><Rule require="REGISTEREDOFFICE"/></NOT>
                </AND>
            </AND>
            <!-- Check AttributeConsumingService with index 27 -->
            <AND>
                <AND>
                    <Rule require="NAME"/>
                    <Rule require="PLACEOFBIRTH"/>
                </AND>
                <AND>
                    <NOT><Rule require="ADDRESS"/></NOT>
                    <NOT><Rule require="COMPANYNAME"/></NOT>
                    <NOT><Rule require="COUNTYOFBIRTH"/></NOT>
                    <NOT><Rule require="DATEOFBIRTH"/></NOT>
                    <NOT><Rule require="DIGITALADDRESS"/></NOT>
                    <NOT><Rule require="EMAIL"/></NOT>
                    <NOT><Rule require="EXPIRATIONDATE"/></NOT>
                    <NOT><Rule require="FAMILYNAME"/></NOT>
                    <NOT><Rule require="FISCALNUMBER"/></NOT>
                    <NOT><Rule require="GENDER"/></NOT>
                    <NOT><Rule require="IDCARD"/></NOT>
                    <NOT><Rule require="IVACODE"/></NOT>
                    <NOT><Rule require="MOBILEPHONE"/></NOT>
                    <NOT><Rule require="REGISTEREDOFFICE"/></NOT>
                    <NOT><Rule require="SPIDCODE"/></NOT>
                </AND>
            </AND>
        </OR>
    </AND>
</Handler>
```

Furthermore, `ACS_*` variables are used to generate [`SessionInitiator`](#https://wiki.shibboleth.net/confluence/display/SP3/SessionInitiator) elements.
The environment variables of the example will generate the following configuration
(nested in the resulting `/etc/shibboleth/shibboleth2.xml`)

```.xml
<!-- SessionInitiator for AttributeConsumingService 0 -->
<SessionInitiator type="SAML2"
    Location="/Login0"
    isDefault="true"
    entityID="https://sp.example.com"
    outgoingBinding="urn:oasis:names:tc:SAML:profiles:SSO:request-init"
    isPassive="false"
    signing="true">
    <samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
        xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
        Version="2.0" ID="placeholder0.example.com" IssueInstant="1970-01-01T00:00:00Z"
        AttributeConsumingServiceIndex="0" ForceAuthn="true">
        <saml:Issuer
            Format="urn:oasis:names:tc:SAML:2.0:nameid-format:entity"
            NameQualifier="https://sp.example.com">
            https://sp.example.com
        </saml:Issuer>
        <samlp:NameIDPolicy
            Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
        />
    </samlp:AuthnRequest>
</SessionInitiator>

<!-- SessionInitiator for AttributeConsumingService 27 -->
<SessionInitiator type="SAML2"
    Location="/Login27"
    isDefault="true"
    entityID="https://sp.example.com"
    outgoingBinding="urn:oasis:names:tc:SAML:profiles:SSO:request-init"
    isPassive="false"
    signing="true">
    <samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
        xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
        Version="2.0" ID="placeholder27.example.com" IssueInstant="1970-01-01T00:00:00Z"
        AttributeConsumingServiceIndex="27" ForceAuthn="true">
        <saml:Issuer
            Format="urn:oasis:names:tc:SAML:2.0:nameid-format:entity"
            NameQualifier="https://sp.example.com">
            https://sp.example.com
        </saml:Issuer>
        <samlp:NameIDPolicy
            Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
        />
    </samlp:AuthnRequest>
</SessionInitiator>
```

With this mechanism, you can dynamically specify the `AttributeConsumingService` by using the URLs `/iam/Login0`, `/iam/Login27` and so on. For instance

```
https://sp.example.com/iam/Login0?target=https://sp.example.com/login&entityID=https://idp.spid.gov.it
                           ^^^^^^
```
