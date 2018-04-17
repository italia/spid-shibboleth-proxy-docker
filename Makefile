default: build

build:
	docker build --tag spid-auth-proxy .

run: build
	docker run -ti --rm -p 8080:80 spid-auth-proxy

run-bash: build
	docker run -ti --rm -p 8080:80 spid-auth-proxy bash
