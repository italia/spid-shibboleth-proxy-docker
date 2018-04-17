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
            -e TARGET_BACKEND="https://backend.example.com:8443/myapp" \
            spid-auth-proxy

3.  Open your browser (or `curl`) and check if the metadata were generated

        $ curl -L http://localhost:8080/metadata
