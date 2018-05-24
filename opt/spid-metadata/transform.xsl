<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata">

    <xsl:strip-space elements="*"/>

    <xsl:template match="@*|/md:EntityDescriptor">
        <xsl:copy>
            <xsl:attribute name="ID">_%ID%</xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|md:KeyDescriptor">
        <xsl:copy>
            <xsl:attribute name="use">signing</xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|md:SPSSODescriptor">
        <xsl:copy>
            <xsl:attribute name="AuthnRequestsSigned">true</xsl:attribute>
            <xsl:attribute name="WantAssertionsSigned">true</xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
            %ACS%
        </xsl:copy>
    </xsl:template>

    <xsl:template match="node() | @*" name="identity">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="md:SingleLogoutService[not(@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST') and not(@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect')]"/>
    <xsl:template match="md:AssertionConsumerService[not(@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST') and not(@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect')]"/>
</xsl:stylesheet>
