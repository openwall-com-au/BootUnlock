<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="text"/>
  <xsl:template match="/">
    <xsl:apply-templates select="/plist/dict[key = 'Containers']/array/dict[key = 'Volumes']/array/dict[key = 'Encryption']"/>
  </xsl:template>
  <xsl:template match="dict">
    <xsl:apply-templates match="key|string|true|false" mode="dict" select="string[preceding-sibling::key[1]/text() = 'Name']"/>
    <xsl:text>:</xsl:text>
    <xsl:apply-templates match="key|string|true|false" mode="dict" select="string[preceding-sibling::key[1]/text() = 'APFSVolumeUUID']"/>
    <xsl:text>:</xsl:text>
    <xsl:apply-templates match="key|string|true|false" mode="dict" select="string[preceding-sibling::key[1]/text() = 'DeviceIdentifier']"/>
    <xsl:text>:</xsl:text>
    <xsl:apply-templates match="true|false" mode="dict" select="true[preceding-sibling::key[1]/text() = 'Encryption']"/>
    <xsl:text>:</xsl:text>
    <xsl:apply-templates match="true|false" mode="dict" select="true[preceding-sibling::key[1]/text() = 'Locked']"/>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>
  <xsl:template match="true|false" mode="dict">
    <xsl:value-of select="name()"/>
  </xsl:template>
</xsl:stylesheet>
