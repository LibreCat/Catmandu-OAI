<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="epicur">
        <xsl:element name="{//update_status/@type}">
            <xsl:attribute name="url">
                <xsl:value-of select="record/resource/identifier[@scheme='url' and @role='primary']"/>
            </xsl:attribute>
            <xsl:value-of select="record/identifier[@scheme='urn:nbn:de']"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
