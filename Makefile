SPID_ACS=$(shell cat myacs.xml | sed -e "s/^\s*//g" -e "s/$$\s*//g" | tr -d "\n")

default: build

build:
	docker build --tag spid-auth-proxy .

run: build
	docker run -ti --rm \
		-p 80:80 -p 443:443 \
		-e SPID_ACS='$(SPID_ACS)' \
		--env-file environment.env \
		-v "$(shell pwd)/certs:/opt/shibboleth-sp/certs" \
		-v "$(shell pwd)/log:/var/log" \
		spid-auth-proxy

run-bash: build
	docker run -ti --rm \
		-p 80:80 -p 443:443 \
		-e SPID_ACS='$(SPID_ACS)' \
		--env-file environment.env \
		-v "$(shell pwd)/certs:/opt/shibboleth-sp/certs" \
		-v "$(shell pwd)/log:/var/log" \
		spid-auth-proxy bash

