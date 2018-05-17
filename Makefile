SPID_ACS=$(shell cat myacs.xml | sed -e "s/^\s*//g" -e "s/$$\s*//g" | tr -d "\n")
VERSION=$(shell cat VERSION)

default: build

build:
	docker build --tag spid-auth-proxy:$(VERSION) . && \
	docker build --tag spid-auth-proxy:latest .

run: build
	docker run -ti --rm \
		-p 80:80 -p 443:443 \
		-e SPID_ACS='$(SPID_ACS)' \
		--env-file environment.env \
		-v "$(shell pwd)/certs/saml:/opt/shibboleth-sp/certs:ro" \
		-v "$(shell pwd)/certs/tls/server.crt:/etc/pki/tls/certs/server.crt:ro" \
		-v "$(shell pwd)/certs/tls/server.key:/etc/pki/tls/private/server.key:ro" \
		-v "$(shell pwd)/log:/var/log" \
		spid-auth-proxy

run-bash: build
	docker run -ti --rm \
		-p 80:80 -p 443:443 \
		-e SPID_ACS='$(SPID_ACS)' \
		--env-file environment.env \
		-v "$(shell pwd)/certs/saml:/opt/shibboleth-sp/certs:ro" \
		-v "$(shell pwd)/certs/tls/server.crt:/etc/pki/tls/certs/server.crt:ro" \
		-v "$(shell pwd)/certs/tls/server.key:/etc/pki/tls/private/server.key:ro" \
		-v "$(shell pwd)/log:/var/log" \
		spid-auth-proxy bash

first-run: build
	docker run -ti --rm \
		-p 80:80 -p 443:443 \
		-e SPID_ACS='$(SPID_ACS)' \
		--env-file environment.env \
		-v "$(shell pwd)/certs/saml:/opt/shibboleth-sp/certs" \
		-v "$(shell pwd)/certs/tls/server.crt:/etc/pki/tls/certs/server.crt:ro" \
		-v "$(shell pwd)/certs/tls/server.key:/etc/pki/tls/private/server.key:ro" \
		-v "$(shell pwd)/log:/var/log" \
		spid-auth-proxy

