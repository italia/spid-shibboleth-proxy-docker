# Changelog

## devel

* Refine checks on returned attributes

## 1.0.0 (2018-12-18)

* Generate `<SessionInitiator>` elements according to `ACS_*` environment variables
* Add check on returned AuthnContextClassRef and attributes
* Add backend-side checks
* Update SPID registry certificate
* Make logging and security policy configurable
* Revise Shibboleth SP configuration (align to 3.x branch)
* Enable SPID SP validator
* Enable the use of `TARGET_LOCATION` environment variable
* Generate the `<AttributeConsumingService>` elements according to the
  defined environment variables
* Remove `AllowCreate` from `NameIDPolicy` according to
  [SPID - Avviso 5](https://www.agid.gov.it/sites/default/files/repository_files/documentazione/spid-avviso-n5-regole-tecniche-errata-corrige.pdf)
* Revise httpd security configuration (TLS, security headers)

## 0.4.0 (2018-07-06)

* Fix the order of SP metadata elements
* Substitute `samlsign` with `xmlsectool`
* Update signing (rsa-sha512) and digest (sha512) algorithm
* Remove double KeyName in SP requests signature
* Fix Shibboleth SP configuration
* Hack the metagen.sh script (cloned under /usr/local/bin) in order to match
  the SPID requirements

## 0.3.1 (2018-06-22)

* Fix metadata signing process

## 0.3.0 (2018-06-18)

* Add script for system integration
* Allow to run the container in production mode
* Add checking of the aggregate IdP metadata signature

## 0.2.0 (2018-05-24)

* Declare only SAML 2.0 as supported protocol
* Include organization details in metadata
* Fix typo in metadata tranformation (see #1)

## 0.1.1 (2018-05-23)

* Fix IdP metadata aggregator URI in Shibboleth SP configuration

## 0.1.0 (2018-05-17)

* First release
