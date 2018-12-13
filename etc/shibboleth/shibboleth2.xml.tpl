<SPConfig xmlns="urn:mace:shibboleth:3.0:native:sp:config"
    xmlns:conf="urn:mace:shibboleth:3.0:native:sp:config"
    xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" clockSkew="180">

    <OutOfProcess tranLogFormat="%u|%s|%IDP|%i|%ac|%t|%attr|%n|%b|%E|%S|%SS|%L|%UA|%a" />

    <!--
    By default, in-memory StorageService, ReplayCache, ArtifactMap, and SessionCache
    are used. See example-shibboleth2.xml for samples of explicitly configuring them.
    -->

    <!-- The ApplicationDefaults element is where most of Shibboleth's SAML bits are defined. -->
    <ApplicationDefaults entityID="%ENTITY_ID%"
        REMOTE_USER="eppn persistent-id targeted-id" signing="true"
        signingAlg="http://www.w3.org/2001/04/xmldsig-more#rsa-sha512" encryption="false"
        digestAlg="http://www.w3.org/2001/04/xmlenc#sha512"
        authnContextClassRef="https://www.spid.gov.it/SpidL1" authnContextComparison="exact"
        NameIDFormat="urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
        policyId="default" requireSignedAssertions="true"
        cipherSuites="DEFAULT:!EXP:!LOW:!aNULL:!eNULL:!DES:!IDEA:!SEED:!RC4:!3DES:!kRSA:!SSLv2:!SSLv3:!TLSv1:!TLSv1.1">

        <!--
        Controls session lifetimes, address checks, cookie handling, and the protocol handlers.
        Each Application has an effectively unique handlerURL, which defaults to "/Shibboleth.sso"
        and should be a relative path, with the SP computing the full value based on the virtual
        host. Using handlerSSL="true" will force the protocol to be https. You should also set
        cookieProps to "https" for SSL-only sites. Note that while we default checkAddress to
        "false", this makes an assertion stolen in transit easier for attackers to misuse.
        -->
        <Sessions lifetime="1800" timeout="3600" relayState="ss:mem" handlerURL="/iam"
            checkAddress="false" handlerSSL="true" cookieProps="https">

            <!-- Login -->
            <SessionInitiator type="SAML2"
                Location="/Login"
                isDefault="true"
                entityID="%ENTITY_ID%"
                outgoingBinding="urn:oasis:names:tc:SAML:profiles:SSO:request-init"
                isPassive="false"
                signing="true">
                <samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                    Version="2.0" ID="placeholder.example.com" IssueInstant="1970-01-01T00:00:00Z"
                    AttributeConsumingServiceIndex="0" ForceAuthn="true">
                    <saml:Issuer
                        Format="urn:oasis:names:tc:SAML:2.0:nameid-format:entity"
                        NameQualifier="%ENTITY_ID%">
                        %ENTITY_ID%
                    </saml:Issuer>
                    <samlp:NameIDPolicy
                        Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
                    />
                </samlp:AuthnRequest>
            </SessionInitiator>

            <md:AssertionConsumerService
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                Location="/SAML2/POST" index="0"
                conf:policyId="default" conf:signing="true"/>

            <!-- Logout -->
            <LogoutInitiator type="Chaining" Location="/Logout">
                <LogoutInitiator type="SAML2"
                    outgoingBindings="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST
                                      urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                    signing="true"/>
                <LogoutInitiator type="Local" signing="true"/>
            </LogoutInitiator>

            <md:SingleLogoutService Location="/SLO/POST"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"/>
            <md:SingleLogoutService Location="/SLO/Redirect"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"/>

            <!-- Administrative logout. -->
            <LogoutInitiator type="Admin" Location="/Logout/Admin" acl="127.0.0.1 ::1" />

            <!-- Status reporting service. -->
            <Handler type="Status" Location="/Status" acl="127.0.0.1 ::1"/>

            <!-- Session diagnostic service. -->
            <Handler type="Session" Location="/Session" showAttributeValues="true"/>

            <!-- JSON feed of discovery information. -->
            <Handler type="DiscoveryFeed" Location="/DiscoFeed"/>
        </Sessions>

        <!--
        Allows overriding of error template information/filenames. You can
        also add your own attributes with values that can be plugged into the
        templates, e.g., helpLocation below.
        -->
        <Errors supportContact="spid.tech@agid.gov.it"
            redirectErrors="%ERROR_URL%" />

        <!-- IdPs metadata from the SPID Registry -->
        <MetadataProvider type="XML"
            validate="true"
            url="https://registry.spid.gov.it/metadata/idp/spid-entities-idps.xml"
            backingFilePath="spid-entities-idps.xml"
            reloadInterval="3600">
            <MetadataFilter
                type="Signature"
                certificate="/opt/shibboleth-sp/metadata/registry.pem"
                verifyBackup="false"/>
        </MetadataProvider>

        <!-- SPID Demo IdP -->
        <MetadataProvider
            type="XML"
            validate="true"
            path="/opt/shibboleth-sp/metadata/idp.spid.gov.it.xml"
            id="https://idp.spid.gov.it" />

        <!-- SPID SP Validator (online) -->
        <MetadataProvider
            type="XML"
            validate="true"
            url="https://validator.spid.gov.it/metadata.xml"
            backingFilePath="validator.xml"
            reloadInterval="3600">
            <MetadataFilter
                type="Signature"
                certificate="/opt/shibboleth-sp/metadata/validator.pem"/>
        </MetadataProvider>

        <!-- SPID SP Validator (local) -->
        <MetadataProvider
            type="XML"
            validate="true"
            path="/opt/shibboleth-sp/metadata/validator.xml"
            id="https://validator.spid.gov.it" />

        <!-- Map to extract attributes from SAML assertions. -->
        <AttributeExtractor type="XML" validate="true" reloadChanges="true" path="attribute-map.xml"/>

        <!-- Default filtering policy for recognized attributes, lets other data pass. -->
        <AttributeFilter type="XML" validate="true" path="attribute-policy.xml"/>

        <!-- Simple file-based resolvers for separate signing/encryption keys. -->
        <CredentialResolver type="File"
            key="/opt/shibboleth-sp/certs/sp-key.pem"
            certificate="/opt/shibboleth-sp/certs/sp-cert.pem"
            use="signing"/>
    </ApplicationDefaults>

    <!-- Policies that determine how to process and authenticate runtime messages. -->
    <SecurityPolicyProvider type="XML" validate="true" path="security-policy.xml"/>

    <!-- Low-level configuration about protocols and bindings available for use. -->
    <ProtocolProvider type="XML" validate="true" reloadChanges="true" path="protocols.xml"/>

</SPConfig>
