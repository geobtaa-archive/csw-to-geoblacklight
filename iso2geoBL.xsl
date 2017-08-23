<!--
     iso2geoBl.xsl - Transformation from ISO 19139 XML into GeoBlacklight solr json
-->
<xsl:stylesheet xmlns="http://www.loc.gov/mods/v3" xmlns:gco="http://www.isotc211.org/2005/gco"
  xmlns:gmi="http://www.isotc211.org/2005/gmi" xmlns:gmd="http://www.isotc211.org/2005/gmd"
  xmlns:gml="http://www.opengis.net/gml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0" exclude-result-prefixes="gml gmd gco gmi xsl">
  <xsl:output method="text" version="1.0" omit-xml-declaration="yes" indent="no"
    media-type="application/json"/>
  <xsl:strip-space elements="*"/>




  <xsl:template match="/">
    <xsl:message terminate="no">STARTING</xsl:message>

    <xsl:variable name="vQ">"</xsl:variable>
    <xsl:variable name="sQ">'</xsl:variable>

    <!-- BOUNDING BOX VARIABLES-->
    <xsl:variable name="upperCorner">
      <xsl:value-of
        select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal)"/>
      <xsl:text> </xsl:text>
      <xsl:value-of
        select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal)"
      />
    </xsl:variable>

    <xsl:variable name="lowerCorner">
      <xsl:value-of
        select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal)"/>
      <xsl:text> </xsl:text>
      <xsl:value-of
        select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal)"
      />
    </xsl:variable>

    <xsl:variable name="x2"
      select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal)"/>
    <!-- E -->
    <xsl:variable name="x1"
      select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal)"/>
    <!-- W -->
    <xsl:variable name="y2"
      select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal)"/>
    <!-- N -->
    <xsl:variable name="y1"
      select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal)"/>
    <!-- S -->


    <!-- FORMAT VARIABLES-->
    <xsl:variable name="format">
      <xsl:choose>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Raster Dataset')">
          <xsl:text>Raster Dataset</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'GeoTIFF')">
          <xsl:text>GeoTIFF</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'TIFF')">
          <xsl:text>TIFF</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'JPEG')">
          <xsl:text>JPEG</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Arc')">
          <xsl:text>ArcGRID</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'ArcGRID')">
          <xsl:text>ArcGRID</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Shapefile')">
          <xsl:text>Shapefile</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'shapefile')">
          <xsl:text>Shapefile</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'KMZ')">
          <xsl:text>KMZ</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Geodatabase')">
          <xsl:text>Geodatabase</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Feature Class')">
          <xsl:text>Feature Class</xsl:text>
        </xsl:when>
        <xsl:when
          test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Text')">
          <xsl:text>Text</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>File</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="uuid">
      <xsl:value-of select="gmd:MD_Metadata/gmd:fileIdentifier"/>
    </xsl:variable>


    <!--ONE TO ONE CROSSWALKED ELEMENTS -->

    <xsl:text>{</xsl:text>
    <xsl:text>"uuid": "</xsl:text>
    <xsl:value-of select="$uuid"/>
    <xsl:text>",</xsl:text>
    <xsl:text>"dc_identifier_s": "</xsl:text>
    <xsl:value-of select="$uuid"/>
    <xsl:text>",</xsl:text>
    <xsl:text>"layer_slug_s": "</xsl:text>
    <xsl:value-of select="$uuid"/>
    <xsl:text>",</xsl:text>
    <xsl:text>"layer_id_s": "</xsl:text>
    <xsl:value-of select="$uuid"/>
    <xsl:text>",</xsl:text>

    <xsl:text>"dc_title_s": "</xsl:text>
    <xsl:value-of
      select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title"/>
    <xsl:text>",</xsl:text>
    
    <xsl:text>"dct_isPartOf_sm": "</xsl:text>
    <xsl:value-of
      select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:collectiveTitle"/>
    <xsl:text>",</xsl:text>
    
    <xsl:text>"layer_geom_type_s": "</xsl:text>
    <xsl:value-of
      select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:otherCitationDetails"/>
    <xsl:text>",</xsl:text>

    <!--new provenance using credit field-->
    <xsl:text>"dct_provenance_s": "</xsl:text>
    <xsl:value-of
      select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:credit"> </xsl:value-of>
    <xsl:text>",</xsl:text>

    <xsl:text>"dc_description_s": "</xsl:text>
    <xsl:value-of
      select="translate(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract, $vQ, '\' + $vQ)"/>
    <xsl:text>",</xsl:text>
    
    <xsl:text>"dc_rights_s": "</xsl:text>
    <xsl:text>Public",</xsl:text>

    <xsl:text>"dc_format_s": "</xsl:text>
    <xsl:value-of select="$format"/>
    <xsl:text>",</xsl:text>


    <xsl:choose>
      <xsl:when test="gmd:MD_Metadata/gmd:parentIdentifier">
        <xsl:text>"dc_source_sm": "</xsl:text>
        <xsl:value-of select="gmd:MD_Metadata/gmd:parentIdentifier"/>
        <xsl:text>",</xsl:text>
      </xsl:when>
    </xsl:choose>

    <xsl:choose>
      <xsl:when test="gmd:MD_Metadata/gmd:dateStamp/gco:DateTime">
        <xsl:text>"layer_modified_dt": "</xsl:text>
        <xsl:value-of select="gmd:MD_Metadata/gmd:dateStamp/gco:DateTime"/>
        <xsl:if test="not(contains(gmd:MD_Metadata/gmd:dateStamp/gco:DateTime, 'Z'))">
          <xsl:text>Z</xsl:text>
        </xsl:if>
        <xsl:text>",</xsl:text>
      </xsl:when>
      <xsl:when test="gmd:MD_Metadata/gmd:dateStamp/gco:Date">
        <xsl:text>"layer_modified_dt": "</xsl:text>
        <xsl:value-of select="gmd:MD_Metadata/gmd:dateStamp/gco:Date"/>
        <xsl:text>T00:00:00Z",</xsl:text>
      </xsl:when>
    </xsl:choose>


    <!--ORIGINATOR TO CREATOR -->
    <xsl:if
      test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = 'originator']">
      <xsl:text>"dc_creator_sm": [</xsl:text>

      <xsl:for-each
        select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = 'originator']">
        <xsl:choose>
          <xsl:when
            test="ancestor-or-self::*/gmd:organisationName and not(ancestor-or-self::*/gmd:individualName)">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
            <xsl:text>"</xsl:text>
            <xsl:if test="position() != last()">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:when>
          <xsl:when
            test="ancestor-or-self::*/gmd:individualName and not(ancestor-or-self::*/gmd:organisationName)">
            <xsl:for-each select="ancestor-or-self::*/gmd:individualName">
              <xsl:text>"</xsl:text>
              <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
              <xsl:text>"</xsl:text>
              <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
              </xsl:if>
            </xsl:for-each>
          </xsl:when>
          <xsl:when
            test="ancestor-or-self::*/gmd:individualName and ancestor-or-self::*/gmd:organisationName">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
            <xsl:text>", </xsl:text>
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
            <xsl:text>"</xsl:text>
          </xsl:when>
        </xsl:choose>
        <!--<xsl:if test="position() != last()">
          <xsl:text>,</xsl:text>
        </xsl:if>-->
      </xsl:for-each>

      <xsl:text>],</xsl:text>

      <!--PUBLISHER -->

    </xsl:if>
    <xsl:if
      test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue = 'publisher']]">
      <xsl:text>"dc_publisher_sm": [</xsl:text>

      <xsl:for-each
        select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode[@codeListValue = 'publisher']]">
        <xsl:choose>
          <xsl:when
            test="ancestor-or-self::*/gmd:organisationName and not(ancestor-or-self::*/gmd:individualName)">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
            <xsl:text>"</xsl:text>
            <xsl:if test="position() != last()">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:when>
          <xsl:when
            test="ancestor-or-self::*/gmd:individualName and not(ancestor-or-self::*/gmd:organisationName)">
            <xsl:for-each select="ancestor-or-self::*/gmd:individualName">
              <xsl:text>"</xsl:text>

              <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
              <xsl:text>"</xsl:text>
              <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
              </xsl:if>
            </xsl:for-each>
          </xsl:when>
          <xsl:when
            test="ancestor-or-self::*/gmd:individualName and ancestor-or-self::*/gmd:organisationName">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
            <xsl:text>", </xsl:text>
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
            <xsl:text>"</xsl:text>
          </xsl:when>
        </xsl:choose>
        <xsl:if test="position() != last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
      </xsl:for-each>

      <xsl:text>],</xsl:text>
    </xsl:if>



    <!-- TODO: add inputs for other languages -->
    <!-- <field name="dc_language_s">
          <xsl:if test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language | gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language/gmd:LanguageCode, 'eng')">
            <xsl:text>English</xsl:text>
          </xsl:if>
        </field> -->

    <!-- from DCMI type vocabulary -->
    <xsl:choose>
      <xsl:when
        test="contains(gmd:MD_Metadata/gmd:hierarchyLevelName/gco:CharacterString, 'dataset')">
        <xsl:text>"dc_type_s": "Dataset",</xsl:text>
      </xsl:when>

      <xsl:when
        test="contains(gmd:MD_Metadata/gmd:hierarchyLevelName/gco:CharacterString, 'Dataset')">
        <xsl:text>"dc_type_s": "Dataset",</xsl:text>
      </xsl:when>

      <xsl:when
        test="contains(gmd:MD_Metadata/gmd:hierarchyLevelName/gco:CharacterString, 'service')">
        <xsl:text>"dc_type_s": "Service",</xsl:text>
      </xsl:when>
    </xsl:choose>

    <!-- topic category -->
    <xsl:if
      test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode">
      <xsl:text>"dc_subject_sm": [</xsl:text>

      <xsl:for-each
        select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory">

        <xsl:choose>
          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'biota')">
            <xsl:text>"Biota"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'boundaries')">
            <xsl:text>"Boundaries"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'climatologyMeteorologyAtmosphere')">
            <xsl:text>"Climatology, Meteorology and Atmosphere"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'economy')">
            <xsl:text>"Economy"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'elevation')">
            <xsl:text>"Elevation"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'environment')">
            <xsl:text>"Environment"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'farming')">
            <xsl:text>"Farming"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'geoscientificInformation')">
            <xsl:text>"Geoscientific Information"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'health')">
            <xsl:text>"Health"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'imageryBaseMapsEarthCover')">
            <xsl:text>"Imagery and Base Maps"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'Imagery base maps earth cover')">
            <xsl:text>"Imagery and Base Maps"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'inlandWaters')">
            <xsl:text>"Inland Waters"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'Inland waters')">
            <xsl:text>"Inland Waters"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'intelligenceMilitary')">
            <xsl:text>"Intelligence and Military"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'location')">
            <xsl:text>"Location"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'oceans')">
            <xsl:text>"Oceans"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'planningCadastre')">
            <xsl:text>"Planning and Cadastral"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'society')">
            <xsl:text>"Society"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'structure')">
            <xsl:text>"Structure"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'transportation')">
            <xsl:text>"Transportation"</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_TopicCategoryCode, 'utilitiesCommunication')">
            <xsl:text>"Utilities and Communication"</xsl:text>
          </xsl:when>


          <xsl:otherwise>
            <xsl:text>"</xsl:text>
            <xsl:value-of select="gmd:MD_TopicCategoryCode"/>
            <xsl:text>"</xsl:text>
          </xsl:otherwise>

        </xsl:choose>

        <xsl:if test="position() != last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:if
          test="position() = last() and /gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'theme']">
          <xsl:text>,</xsl:text>
        </xsl:if>

      </xsl:for-each>
    </xsl:if>


    <!-- theme keywords -->
    <xsl:if
      test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'theme']">
      <xsl:if
        test="not(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode)">
        <xsl:text>"dc_subject_sm": [</xsl:text>
      </xsl:if>

      <xsl:choose>
        <!-- privilege GEMET keywords if they exist -->
        <xsl:when
          test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords[gmd:thesaurusName/gmd:CI_Citation/gmd:title/gco:CharacterString/text() = 'GEMET']">
          <xsl:for-each
            select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords[gmd:thesaurusName/gmd:CI_Citation/gmd:title/gco:CharacterString/text() = 'GEMET']">
            <xsl:for-each select="ancestor-or-self::*/gmd:keyword/*/text()">
              <xsl:text>"</xsl:text>
              <xsl:value-of select="."/>
              <xsl:text>"</xsl:text>
              <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
              </xsl:if>
            </xsl:for-each>
            <xsl:if test="position() != last()">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each
            select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'theme']">
            <xsl:for-each select="ancestor-or-self::*/gmd:keyword">
              <xsl:text>"</xsl:text>
              <xsl:value-of select="."/>
              <xsl:text>"</xsl:text>
              <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
              </xsl:if>
            </xsl:for-each>
            <xsl:if test="position() != last()">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>


    </xsl:if>

    <!-- close dc_subject_sm list -->
    <xsl:if
      test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode or gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'theme']">
      <xsl:text>],</xsl:text>
    </xsl:if>

    <xsl:if
      test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'place']">
      <xsl:text>"dct_spatial_sm": [</xsl:text>
      <xsl:choose>
        <!-- privilege geonames keywords -->
        <xsl:when
          test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords[gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'place']][gmd:thesaurusName/gmd:CI_Citation/gmd:title[text() = 'GeoNames']]">
          <xsl:for-each
            select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords[gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'place']][gmd:thesaurusName/gmd:CI_Citation/gmd:title[text() = 'GeoNames']]/gmd:keyword">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
            <xsl:if test="position() != last()">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:for-each>
          <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each
            select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue = 'place']">
            <xsl:for-each select="ancestor-or-self::*/gmd:keyword">
              <xsl:text>"</xsl:text>
              <xsl:value-of select="."/>
              <xsl:text>"</xsl:text>
              <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
              </xsl:if>
            </xsl:for-each>
            <xsl:if test="position() != last()">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:text>],</xsl:text>
    </xsl:if>

    <xsl:choose>
      <xsl:when
        test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 'T')">
        <xsl:text>"dct_issued_s": "</xsl:text>
        <xsl:value-of
          select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
        <xsl:text>Z",</xsl:text>
      </xsl:when>

      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime">
        <xsl:text>"dct_issued_s": "</xsl:text>
        <xsl:value-of
          select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
        <xsl:text>",</xsl:text>
      </xsl:when>

      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date">
        <xsl:text>"dct_issued_s": "</xsl:text>
        <xsl:value-of
          select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date"/>
        <xsl:text>",</xsl:text>
      </xsl:when>

      <!-- <xsl:otherwise>unknown</xsl:otherwise> -->
    </xsl:choose>


    <!-- content date: range YYYY-YYYY if dates differ  -->
    <xsl:choose>
      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition/text() != ''">
        <xsl:text>"dct_temporal_sm": "</xsl:text>
        <xsl:value-of
          select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
        <xsl:if
          test="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition, 1, 4) != substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition, 1, 4)">
          <xsl:text>-</xsl:text>
          <xsl:value-of
            select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition, 1, 4)"
          />
        </xsl:if>
        <xsl:text>",</xsl:text>
      </xsl:when>

      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant">
        <xsl:text>"dct_temporal_sm": "</xsl:text>
        <xsl:value-of
          select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant/gml:timePosition, 1, 4)"/>
        <xsl:text>",</xsl:text>
      </xsl:when>
    </xsl:choose>

    <!--<field name="georss_polygon_s">-->
    <xsl:text>"georss_polygon_s": "</xsl:text>
    <xsl:text/>
    <xsl:value-of select="$y1"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$x1"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$y2"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$x1"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$y2"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$x2"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$y1"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$x2"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$y1"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$x1"/>
    <xsl:text>",</xsl:text>

    <xsl:text>"solr_geom": "ENVELOPE(</xsl:text>
    <xsl:value-of select="$x1"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$x2"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$y2"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$y1"/>
    <xsl:text>)",</xsl:text>

    <xsl:text>"georss_box_s": "</xsl:text>
    <xsl:value-of select="$y1"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$x1"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$y2"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$x2"/>
    <xsl:text>",</xsl:text>

    <!--calculates centroid -->

    <xsl:text>"centroid_s": "</xsl:text>
    <xsl:value-of select="($y1 + $y2) div 2"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="($x1 + $x2) div 2"/>
    <xsl:text>",</xsl:text>



    <!-- content date: singular, or beginning date of range: YYYY -->
    <xsl:choose>
      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition/text() != ''">
        <xsl:text>"solr_year_i": </xsl:text>
        <xsl:value-of
          select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition, 1, 4)"
        />
      </xsl:when>
      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant/gml:timePosition and gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant/gml:timePosition/text() != ''">
        <xsl:text>"solr_year_i": </xsl:text>
        <xsl:value-of
          select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant/gml:timePosition, 1, 4)"
        />
      </xsl:when>
      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode/@codeListValue = 'publication'">
        <xsl:text>"solr_year_i": </xsl:text>
        <xsl:choose>
          <xsl:when
            test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date">
            <xsl:value-of
              select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date, 1, 4)"
            />
          </xsl:when>
          <xsl:when
            test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime">
            <xsl:value-of
              select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 1, 4)"
            />
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode/@codeListValue = 'creation'">

        <xsl:text>"solr_year_i": </xsl:text>
        <xsl:choose>
          <xsl:when
            test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date">
            <xsl:value-of
              select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date, 1, 4)"
            />
          </xsl:when>
          <xsl:when
            test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime">
            <xsl:value-of
              select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 1, 4)"
            />
          </xsl:when>
        </xsl:choose>
        <!--<xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date, 1,4)"/>-->
      </xsl:when>
      <xsl:when
        test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode/@codeListValue = 'revision'">
        <xsl:text>"solr_year_i": </xsl:text>
        <xsl:choose>
          <xsl:when
            test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date">
            <xsl:value-of
              select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date, 1, 4)"
            />
          </xsl:when>
          <xsl:when
            test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime">
            <xsl:value-of
              select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 1, 4)"
            />
          </xsl:when>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
        <xsl:text>"solr_year_i": 9999</xsl:text>
      </xsl:otherwise>

    </xsl:choose>

    <!-- Parsing References -->
    <xsl:text>,"dct_references_s": "{</xsl:text>
    <xsl:for-each select="//gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource">
      <xsl:choose>
        <xsl:when test="contains(gmd:linkage/gmd:URL, 'ImageServer')">
          <xsl:text>\"urn:x-esri:serviceType:ArcGIS#ImageMapLayer\":\"</xsl:text>
          <xsl:value-of select="gmd:linkage/gmd:URL"/>
          <xsl:text>\"</xsl:text>
        </xsl:when>

        <!--<!-\- <xsl:when
          test="gmd:protocol/gco:CharacterString/text() = 'ESRI:ArcGIS'">
          <!-\- TODO test url for which reference to utilize -\->
          <xsl:choose>
            <xsl:when test="contains(gmd:linkage/gmd:URL, 'FeatureServer')">
              <xsl:text>\"urn:x-esri:serviceType:ArcGIS#FeatureLayer\":\"</xsl:text>
            </xsl:when>
            <xsl:when test="contains(gmd:linkage/gmd:URL, 'MapServer')">
              <!-\-TODO need to distinguish between tiled/dynamic. Probably need to move
                all of this logic out of the XSL
                <xsl:text>"http://www.arcgis.com/rdf#TiledMapLayer":"</xsl:text>-\->
              <xsl:text>\"urn:x-esri:serviceType:ArcGIS#DynamicMapLayer\":\"</xsl:text>
            </xsl:when>
            <xsl:when test="contains(gmd:linkage/gmd:URL, 'ImageServer')">
              <xsl:text>\"urn:x-esri:serviceType:ArcGIS#ImageMapLayer\":\"</xsl:text>
            </xsl:when>
          </xsl:choose>
          <xsl:value-of select="gmd:linkage/gmd:URL"/>
          <xsl:text>\"</xsl:text>
        </xsl:when> -\->-->
        <xsl:when test="contains(gmd:protocol/gco:CharacterString/text(), 'download')">
          <xsl:text>\"http://schema.org/downloadUrl\":\"</xsl:text>
          <xsl:value-of select="gmd:linkage/gmd:URL"/>
          <xsl:text>\"</xsl:text>
        </xsl:when>
        <xsl:when test="contains(gmd:protocol/gco:CharacterString/text(), 'WWW:LINK')">
          <xsl:text>\"http://schema.org/url\":\"</xsl:text>
          <xsl:value-of select="gmd:linkage/gmd:URL"/>
          <xsl:text>\"</xsl:text>
        </xsl:when>
        <xsl:when test="contains(gmd:protocol/gco:CharacterString/text(), 'WWW:IIIF')">
          <xsl:text>\"http://iiif.io/api/image\":\"</xsl:text>
          <xsl:value-of select="gmd:linkage/gmd:URL"/>
          <xsl:text>\"</xsl:text>
        </xsl:when>
        <xsl:when test="contains(gmd:protocol/gco:CharacterString/text(), 'WMS')">
          <xsl:text>\"http://www.opengis.net/def/serviceType/ogc/wms\":\"</xsl:text>
          <xsl:value-of select="gmd:linkage/gmd:URL"/>
          <xsl:text>\"</xsl:text>
        </xsl:when>
        <xsl:when test="contains(gmd:protocol/gco:CharacterString/text(), 'WFS')">
          <xsl:text>\"http://www.opengis.net/def/serviceType/ogc/wfs\":\"</xsl:text>
          <xsl:value-of select="gmd:linkage/gmd:URL"/>
          <xsl:text>\"</xsl:text>
        </xsl:when>
        <xsl:when test="contains(gmd:protocol/gco:CharacterString/text(), 'metadata')">
          <xsl:text>\"http://www.isotc211.org/schemas/2005/gmd/\":\"</xsl:text>
          <xsl:value-of select="gmd:linkage/gmd:URL"/>
          <xsl:text>\"</xsl:text>
        </xsl:when>
      </xsl:choose>

      <!-- add a comma if not the last dist element -->
      <xsl:if test="position() != last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
    </xsl:for-each>

    <xsl:text>}"</xsl:text>
    <xsl:text>}</xsl:text>
  </xsl:template>


</xsl:stylesheet>
