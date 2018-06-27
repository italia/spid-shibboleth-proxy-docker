<SPConfig xmlns="urn:mace:shibboleth:2.0:native:sp:config"
    xmlns:conf="urn:mace:shibboleth:2.0:native:sp:config"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" clockSkew="180">

    <ApplicationDefaults entityID="%ENTITY_ID%"
        REMOTE_USER="eppn persistent-id targeted-id" signing="true"
        signingAlg="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256" encryption="false"
        authnContextClassRef="https://www.spid.gov.it/SpidL1" authnContextComparison="exact"
        NameIDFormat="urn:oasis:names:tc:SAML:2.0:nameid-format:transient">

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
                    AttributeConsumingServiceIndex="1" ForceAuthn="true">
                    <saml:Issuer
                        Format="urn:oasis:names:tc:SAML:2.0:nameid-format:entity"
                        NameQualifier="%ENTITY_ID%">
                        %ENTITY_ID%
                    </saml:Issuer>
                </samlp:AuthnRequest>
            </SessionInitiator>

            <md:AssertionConsumerService
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                Location="/SAML2/POST" index="0"/>

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

            <!-- Handler -->
            <Handler type="Status" Location="/Status"/>
            <Handler type="Session" Location="/Session" showAttributeValues="true"/>
        </Sessions>

        <!-- Error page settings -->
        <Errors supportContact="spid.tech@agid.gov.it"
            redirectErrors="%ERROR_URL%" />

        <MetadataProvider type="XML"
            validate="true"
            uri="https://registry.spid.gov.it/metadata/idp/spid-entities-idps.xml"
            backingFilePath="spid-entities-idps.xml"
            reloadInterval="3600">
            <MetadataFilter
                type="Signature"
                certificate="/opt/shibboleth-sp/metadata/registry.pem"/>
        </MetadataProvider>

        <MetadataProvider
            type="XML"
            validate="true"
            file="/opt/shibboleth-sp/metadata/idp.spid.gov.it.xml"
            id="https://idp.spid.gov.it" />

        <!-- Attributes -->
        <AttributeExtractor type="XML" validate="true" reloadChanges="true" path="attribute-map.xml"/>
        <AttributeResolver type="Query" subjectMatch="true"/>
        <AttributeFilter type="XML" validate="true" path="attribute-policy.xml"/>

        <!-- Assertion signing cert -->
        <CredentialResolver type="File"
            key="/opt/shibboleth-sp/certs/sp-key.pem"
            certificate="/opt/shibboleth-sp/certs/sp-cert.pem"
            use="signing"/>
    </ApplicationDefaults>
    <!-- Security policies -->
    <SecurityPolicyProvider type="XML" validate="true" path="security-policy.xml"/>
    <!-- Protocols and binding -->
    <ProtocolProvider type="XML" validate="true" reloadChanges="true" path="protocols.xml"/>
</SPConfig>
