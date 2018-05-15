# spid-auth-proxy

1.  Build the image

        $ make build

        or

        $ docker build --tag spid-auth-proxy .

2.  Create a file (e.g. `myacs.xml`) with the following content

    ```xml
    <md:AttributeConsumingService index="1">
        <md:ServiceName xml:lang="it">my_service</md:ServiceName>
        <md:RequestedAttribute Name="name"/>
        <md:RequestedAttribute Name="familyName"/>
        <md:RequestedAttribute Name="fiscalNumber"/>
        <md:RequestedAttribute Name="email"/>
    </md:AttributeConsumingService>
    ```

3.  Create an environment file (e.g. `environment.env`) like the following

        SERVER_NAME=<REACHABLE IP OR FQDN>
        ENTITY_ID=https://my.auth.proxy.com
        TARGET_BACKEND=https://mytargetapp.my.cloud.provider.com
        TARGET_LOCATION=/login

4.  Create a directory (e.g. `certs`) to store SAML/TLS certificatestls. The
    repository already provides this directory just of testing. Feel free to
    customise it according to your environment

        $ mkdir -vp certs/{tls,saml}

    then create (or upload) your TLS certificate

        $ cd certs/tls
        $ make

5.  Run the container as follows (remember to check the mounted paths)

        $ make run

        or

        $ docker run -ti --rm \
            -p 80:80 -p 443:443 \
            -e SPID_ACS="`cat myacs.xml`" \
            --env-file environment.env \
            -v "$(pwd)/certs/saml:/opt/shibboleth-sp/certs" \
            -v "$(pwd)/certs/tls/server.crt:/etc/pki/tls/certs/server.crt:ro" \
            -v "$(pwd)/certs/tls/server.key:/etc/pki/tls/private/server.key:ro" \
            -v "$(pwd)/log:/var/log" \
            spid-auth-proxy

6.  Open your browser (or `curl`) and check if the metadata were generated

        $ curl -L -k https://11.22.33.44/metadata

    If you like pretty printing

        $ curl -L -k https://11.22.33.44/metadata | xmllint --format -

7.  Before going ahead, you need to register your authentication proxy as
    service provider. Go to https://idp.spid.gov.it:8080 and register your
    proxy by reading the information from the metadata. If you do not change
    the value of `ENTITY_ID` and `SERVER_NAME` as well as the certificates,
    this step has to be executed just the first time.

8.  Open in your browser

        https://<SERVER_NAME>/access

    and start the authentication process with `lucia` and `password123`
    as username and password by using one of the two links.
