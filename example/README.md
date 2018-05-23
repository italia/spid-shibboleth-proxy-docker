# Example of integration

This is an example of spid-auth-docker integration.

## Quick start

1.  Generate a `docker-compose.yml` according to your environment

        $ SERVER_NAME=mytest.example.com envsubst < docker-compose.yml.template > docker-compose.yml

    or

        $ SERVER_NAME=192.168.5.27 envsubst < docker-compose.yml.template > docker-compose.yml

    **Note:** set `SERVER_NAME` to a FQDN if it's already registered on the
    DNS. If not, use an IP address.

2.  Run

        $ docker-compose up --build

3.  In your browser, open the URL

        https://<SERVER_NAME>
