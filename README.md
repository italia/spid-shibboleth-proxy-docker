# spid-auth-proxy

1.  Build the image

        $ make build

        or

        $ docker build --tag spid-auth-proxy .

2.  Create a file (e.g. `myacs.xml`) with the following content

    ```xml
    <md:AttributeConsumingService index="0">
        <md:ServiceName xml:lang="it">my_service</md:ServiceName>
        <md:RequestedAttribute Name="name"/>
        <md:RequestedAttribute Name="familyName"/>
        <md:RequestedAttribute Name="fiscalNumber"/>
        <md:RequestedAttribute Name="email"/>
    </md:AttributeConsumingService>
    ```

    then run the container

        $ docker run -ti --rm -p 8080:80 \
            -e SPID_ACS="`cat myacs.xml`" \
            -e TARGET_LOCATION="/myapp" \
            -e TARGET_BACKEND="https://myapp.mycloud.com" \
            -v "$(pwd)/certs:/opt/shibboleth-sp/certs" \
            -v "$(pwd)/log:/var/log" \
            spid-auth-proxy

3.  Open your browser (or `curl`) and check if the metadata were generated

        $ curl -L http://localhost:8080/metadata

4.  Open in your browser

        http://localhost:8080/access

    and start the authentication process with `lucia` and `password123`
    as username and password. The link will use as target the `/whoami` page.

5.  To test your `TARGET` configuration, use the following URL to initialise
    a new authentication

        http://131.1.253.175:8080/iam/Login?\
            target=http://131.1.253.175:8080/<TARGET_LOCATION>\
            &entityID=https://idp.spid.gov.it
