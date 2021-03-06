<?xml version="1.0" encoding="UTF-8" ?>
<stylesheet version="2.0"
 xpath-default-namespace="http://www.bibletechnologies.net/2003/OSIS/namespace"
 xmlns="http://www.w3.org/1999/XSL/Transform"
 xmlns:oc="http://github.com/JohnAustinDev/osis-converters"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 exclude-result-prefixes="#all">
 
  <!-- This XSLT takes an OSIS Bible file which was fitted to a SWORD standard verse  
  system by fitToVerseSystem() and reverts it back to its custom verse system. This means
  all references are also reverted (including cross-references from external sources) so 
  that the resulting OSIS file's references are correct according to the custom verse 
  system. Also, markup associated with only the fixed verse system is removed, leaving 
  just the source verse system. !-->
 
  <import href="../functions.xsl"/>
  
  <!-- By default copy everything as is -->
  <template match="node()|@*" name="identity" mode="#all">
    <copy><apply-templates select="node()|@*" mode="#current"/></copy>
  </template>
  
  <!-- Revert saved x-vsys tags to what they were before fitToVerseSystem() -->
  <template match="milestone[starts-with(@type, 'x-vsys')][ends-with(@type, '-start') or ends-with(@type, '-end')]" priority="8">
    <variable name="elemName" select="replace(@type, '^x\-vsys\-(.*?)\-(start|end)$', '$1')"/>
    <element name="{$elemName}" namespace="http://www.bibletechnologies.net/2003/OSIS/namespace">
      <if test="ends-with(@type, '-start')">
        <attribute name="osisID" select="@annotateRef"/>
        <attribute name="sID" select="@annotateRef"/>
      </if>
      <if test="ends-with(@type, '-end')">
        <attribute name="eID" select="@annotateRef"/>
      </if>
    </element>
  </template>
  
  <!-- Remove x-vsys milestones -->
  <template match="milestone[starts-with(@type, 'x-vsys')]" priority="6"/>
  
  <!-- Remove x-vsys-source annotateRefs -->
  <template match="@annotateRef[parent::*[@annotateType= 'x-vsys-source']]" priority="6"/>
  
  <!-- Remove x-vsys attributes -->
  <template match="@*[starts-with(., 'x-vsys-')]" priority="6"/>
  
  <!-- Revert osisRefs to the source verse system -->
  <template match="*[@annotateType='x-vsys-source'][@annotateRef]" priority="4">
    <copy>
      <attribute name="osisRef" select="@annotateRef"/>
      <apply-templates select="node()|@*[not(name()=('osisRef', 'annotateRef', 'annotateType'))]"/>
    </copy>
  </template>
  
  <!-- Remove x-vsys tags that were added by fitToVerseSystem() -->
  <template match="verse[@type='x-vsys-fitted']"/>
  
  <!-- Remove only those <hi> tags that were added by fitToVerseSystem() !-->
  <template match="hi[@subType='x-alternate']">
    <if test="generate-id() != generate-id(
      preceding::milestone[starts-with(@type, 'x-vsys')][ends-with(@type, '-start')][1]/
      following::text()[normalize-space()][1]/
      ancestor-or-self::hi[@subType='x-alternate'][1])">
      <call-template name="identity"/>
    </if>
  </template>

</stylesheet>
