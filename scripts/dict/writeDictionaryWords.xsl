<?xml version="1.0" encoding="UTF-8" ?>
<stylesheet version="2.0"
 xpath-default-namespace="http://www.bibletechnologies.net/2003/OSIS/namespace"
 xmlns="http://www.w3.org/1999/XSL/Transform"
 xmlns:oc="http://github.com/JohnAustinDev/osis-converters"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"
 exclude-result-prefixes="#all">
 
  <!-- This XSLT writes a default (initial) DictionaryWords.xml file for a glossary OSIS file -->
 
  <import href="../functions.xsl"/>
  
  <!-- Call with DEBUG='true' to turn on debug messages -->
  <param name="DEBUG" select="'false'"/>
  
  <param name="notXPATH_default" select="'ancestor-or-self::*[self::osis:caption or self::osis:figure or self::osis:title or self::osis:name or self::osis:lb or self::osis:hi]'"/>
  
  <output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  
  <variable name="MOD" select="//osisText/@osisIDWork"/>
  
  <template match="/">
  <comment>
  IMPORTANT: 
  For case insensitive matches using /match/i to work, ALL text MUST be surrounded 
  by the \\Q...\\E quote operators. If a match is failing, consider this first!
  This is not a normal Perl rule, but is required because Perl doesn't properly handle case for Turkish-like languages.

  USE THE FOLLOWING BOOLEAN &amp; NON-BOOLEAN ATTRIBUTES TO CONTROL LINK PLACEMENT:

  Boolean:
  IMPORTANT: default is false for boolean attributes
  onlyNewTestament="true|false"
  onlyOldTestament="true|false"
  dontLink="true|false" to specify matched text should NOT get linked to ANY entry
  multiple="true|false" to allow match elements to link more than once per entry or chapter
  notExplicit="true|false" selects if match(es) should NOT be applied to explicitly marked glossary entries in the text
  onlyExplicit="true|false" selects if match(es) should ONLY be applied to explicitly marked glossary entries in the text

  Non-Boolean:
  IMPORTANT: non-boolean attribute values are CUMULATIVE, so if the same 
  attribute appears in multiple ancestors, each ancestor value is 
  accumalated. Also, 'context' and 'XPATH' attributes CANCEL the effect   
  of ancestor 'notContext' and 'notXPATH' attributes respectively.

  context="space separated list of osisRefs or comma separated list of Paratext refs" in which to create links
  notContext="space separated list of osisRefs or comma separated list of Paratext refs" in which not to create links
  XPATH="xpath expression" to be applied on each text node to keep text nodes that return non-null
  notXPATH="xpath expression" to be applied on each text node to skip text nodes that return non-null

  ENTRY ELEMENTS MAY ALSO CONTAIN THE FOLLOWING ATTRIBUTES:
  &#60;entry osisRef="The osisID of a keyword to link to. This attribute is required."
         noOutboundLinks="true|false: Set to true and the entry's text with not contain links to other entries."&#62;

  Match patterns can be any perl match regex. The last matching 
  parenthetical group, or else a group named 'link' with (?'link'...), 
  will become the link's inner text.
  </comment><text>
</text>
  <dictionaryWords version="1.0" xmlns="http://github.com/JohnAustinDev/osis-converters">
    <div multiple="false"><xsl:attribute name="notXPATH" select="$notXPATH_default"/>
      <xsl:variable name="keywords_with_context"    select="//seg[@type='keyword'][not(ancestor::div[@subType='x-aggregate'])][ancestor::div[@type][@scope]]"/>
      <xsl:variable name="keywords_without_context" select="//seg[@type='keyword'][not(ancestor::div[@subType='x-aggregate'])] except $keywords_with_context"/>
      
      <!-- First, write entries which specify context -->
      <xsl:for-each-group group-by="ancestor::div[@type][@scope][1]/@scope" select="$keywords_with_context">
        <div><xsl:attribute name="context" select="current-grouping-key()"/>
          <xsl:for-each select="current-group()">
            <xsl:sort select="string-length(.)" data-type="number" order="descending"/>
            <xsl:call-template name="writeEntry"/>
          </xsl:for-each>
        </div>
      </xsl:for-each-group>
      
      <!-- Then, write entries with unspecified context -->
      <xsl:for-each select="$keywords_without_context">
        <xsl:sort select="string-length(.)" data-type="number" order="descending"/>
        <xsl:call-template name="writeEntry"/>
      </xsl:for-each>
      
    </div>
  </dictionaryWords>
  </template>

  <template name="writeEntry">
    <entry osisRef="{if (starts-with(@osisID, concat($MOD, ':'))) then @osisID else concat($MOD, ':', @osisID)}" xmlns="http://github.com/JohnAustinDev/osis-converters">
      <name><xsl:value-of select="."/></name>
      <xsl:variable name="matchesTmp" select="tokenize(., '\s*[,;\[\]\(\)]\s*')"/>
      <xsl:variable name="matches" as="xs:string+"><xsl:for-each select="$matchesTmp"><xsl:if test="."><xsl:sequence select="."/></xsl:if></xsl:for-each></xsl:variable>
      <xsl:for-each select="$matches">
        <match>/\b(\Q<xsl:value-of select="."/>\E)\b/i</match>
      </xsl:for-each>
      <xsl:if test="count($matches) &#62; 1">
        <xsl:call-template name="Debug"><xsl:with-param name="msg">writeDictionaryWords: Writing <xsl:value-of select="count($matches)"/> matches for entry "<xsl:value-of select="."/>"</xsl:with-param></xsl:call-template>
      </xsl:if>
    </entry>
  </template>
  
</stylesheet>
