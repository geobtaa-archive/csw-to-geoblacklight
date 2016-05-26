<!--
     iso2geoBl.xsl - Transformation from f ISO 19139 XML into GeoBlacklight solr json
-->
<xsl:stylesheet
  xmlns="http://www.loc.gov/mods/v3"
  xmlns:gco="http://www.isotc211.org/2005/gco"
  xmlns:gmi="http://www.isotc211.org/2005/gmi"
  xmlns:gmd="http://www.isotc211.org/2005/gmd"
  xmlns:gml="http://www.opengis.net/gml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0" exclude-result-prefixes="gml gmd gco gmi xsl">
  <xsl:output method="text" version="1.0" omit-xml-declaration="yes" indent="no" media-type="application/json"/>
  <xsl:strip-space elements="*"/>
  <xsl:param name="zipName" select="'data.zip'"/>
  <xsl:param name="institution"/>

  <xsl:template match="/">
    <xsl:message terminate="no">STARTING</xsl:message>

    <xsl:variable name="vQ">"</xsl:variable>
    <xsl:variable name="sQ">'</xsl:variable>

    <!-- bounding box -->
    <xsl:variable name="upperCorner">
      <xsl:value-of select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal)"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal)"/>
    </xsl:variable>

    <xsl:variable name="lowerCorner">
      <xsl:value-of select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal)"/>
        <xsl:text> </xsl:text>
      <xsl:value-of select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal)"/>
    </xsl:variable>

    <xsl:variable name="x2" select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal)"/><!-- E -->
    <xsl:variable name="x1" select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal)"/><!-- W -->
    <xsl:variable name="y2" select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal)"/><!-- N -->
    <xsl:variable name="y1" select="number(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal)"/><!-- S -->

    <xsl:variable name="format">
      <xsl:choose>
      <xsl:when test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Raster Dataset')">
        <xsl:text>GeoTIFF</xsl:text>
      </xsl:when>
        <xsl:when test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'GeoTIFF')">
          <xsl:text>GeoTIFF</xsl:text>
        </xsl:when>
        <xsl:when test="contains(gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name, 'Shapefile')">
          <xsl:text>Shapefile</xsl:text>
        </xsl:when>
        <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode/@codeListValue='vector'">
          <xsl:text>Shapefile</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="uuid">
        <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:identifier/gmd:MD_Identifier">
            <xsl:choose>
                <xsl:when test="contains(gmd:code, 'urn-')">
                    <xsl:value-of select="gmd:code"/>
                </xsl:when>
              <!-- temporarily added to avoid full URLs from scrape open data script kd 5/18/2016 -->
              <xsl:when test="contains(gmd:code, '/datasets/')">
                <xsl:value-of select="substring-after(gmd:code, '/datasets/')"/>
              </xsl:when>
                <!-- <xsl:when test="gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:linkage/gmd:URL">
                  <xsl:value-of select="gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:linkage/gmd:URL"/>
                </xsl:when> -->
            </xsl:choose>
        </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="identifier">
      <xsl:choose>
        <!-- for Stanford URIs -->
        <xsl:when test="contains($uuid, 'purl')">
          <xsl:value-of select="substring($uuid, string-length($uuid)-10)"/>
        </xsl:when>
        <!-- all others -->
        <xsl:otherwise>
          <!-- <xsl:value-of select="substring($uuid, string-length($uuid)-33)"/> -->
          <xsl:value-of select="$uuid"/>
        </xsl:otherwise>
         </xsl:choose>
    </xsl:variable>

    <!-- check if Esri WMS, and do some horrible things as a result-->
    <xsl:variable name="esri_ogc_layer_id">
      <xsl:for-each select="//gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource">
        <xsl:if test="contains(gmd:linkage/gmd:URL,'WMSServer')">
          <xsl:value-of select="gmd:name/gco:CharacterString"/>
        </xsl:if>
        <xsl:if test="contains(gmd:linkage/gmd:URL,'WFSServer')">
          <xsl:value-of select="gmd:name/gco:CharacterString"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="layer_id">
      <xsl:choose>
        <xsl:when test="$institution = 'Stanford'">
          <xsl:text>druid:</xsl:text>
          <xsl:value-of select="$identifier"/>
        </xsl:when>
        <xsl:when test="string-length($esri_ogc_layer_id) = 0">
          <xsl:text>urn:</xsl:text>
          <xsl:value-of select="$identifier"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$esri_ogc_layer_id"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:text>{</xsl:text>
      <xsl:text>"uuid": "</xsl:text><xsl:value-of select="$uuid"/><xsl:text>",</xsl:text>
      <xsl:text>"layer_geom_type_s": "</xsl:text>
         <xsl:choose>
           <xsl:when test="gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode">
             <xsl:choose>
               <xsl:when test="contains(gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode/@codeListValue, 'point')">
                    <xsl:text>Point</xsl:text>
                  </xsl:when>
               <xsl:when test="contains(gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode/@codeListValue, 'curve')">
                    <xsl:text>Line</xsl:text>
                  </xsl:when>
               <xsl:when test="contains(gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode/@codeListValue, 'surface')">
                    <xsl:text>Polygon</xsl:text>
               </xsl:when>
               <xsl:when test="contains(gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode/@codeListValue, 'composite')">
                 <xsl:text>Mixed</xsl:text>
               </xsl:when>
               <xsl:when test="contains(gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode/@codeListValue, 'complex')">
                 <xsl:text>Mixed</xsl:text>
               </xsl:when>
               <xsl:otherwise>
                 <xsl:text>Mixed</xsl:text>
               </xsl:otherwise>
             </xsl:choose>
           </xsl:when>

           <xsl:when test="gmd:MD_Metadata/gmd:spatialRepresentationInfo/gmd:MD_VectorSpatialRepresentation/gmd:geometricObjects/gmd:MD_GeometricObjects/gmd:geometricObjectType/gmd:MD_GeometricObjectTypeCode[@codeListValue='grid']">
            <xsl:text>Raster</xsl:text>
           </xsl:when>
           <xsl:otherwise>
             <xsl:text>Mixed</xsl:text>
           </xsl:otherwise>
         </xsl:choose><xsl:text>",</xsl:text>

      <xsl:text>"dc_identifier_s": "</xsl:text><xsl:value-of select="$uuid"/><xsl:text>",</xsl:text>
      <xsl:text>"dc_title_s": "</xsl:text><xsl:value-of select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title"/><xsl:text>",</xsl:text>
      <!--<xsl:text>"dc_description_s": "</xsl:text><xsl:value-of select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract"/><xsl:text>",</xsl:text>-->
      <xsl:text>"dc_description_s": "</xsl:text><xsl:value-of select="translate(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract,$vQ, '\'+ $vQ)"/><xsl:text>",</xsl:text>
      <xsl:text>"dc_rights_s": "</xsl:text>
          <xsl:choose>
            <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:accessConstraints/gmd:MD_RestrictionCode[@codeListValue='restricted']">
              <xsl:text>Restricted</xsl:text>
            </xsl:when>
            <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:accessConstraints/gmd:MD_RestrictionCode, 'restricted')">
              <xsl:text>Restricted</xsl:text>
            </xsl:when>
            <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:useConstraints/gmd:MD_RestrictionCode[@codeListValue='restricted']">
              <xsl:text>Restricted</xsl:text>
            </xsl:when>
            <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:useConstraints/gmd:MD_RestrictionCode, 'restricted')">
              <xsl:text>Restricted</xsl:text>
            </xsl:when>
            <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints">
              <xsl:choose>
                <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints, 'restricted')">
                  <xsl:text>Restricted</xsl:text>
                </xsl:when>
                <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints, 'public domain')">
                  <xsl:text>Public</xsl:text>
                </xsl:when>
                <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints, 'public')">
                  <xsl:text>Public</xsl:text>
                </xsl:when>
                <!--<xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints, $institution)">
                  <xsl:text>Restricted</xsl:text>
                </xsl:when>-->
                <xsl:otherwise>
                  <xsl:text>Public</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>Public</xsl:text>
            </xsl:otherwise>
          </xsl:choose><xsl:text>","dct_provenance_s": "</xsl:text>
      <xsl:value-of select="$institution"/>
      <xsl:text>","layer_id_s": "</xsl:text>
        <xsl:value-of select="$layer_id"/>
      <xsl:text>",</xsl:text>
      <xsl:text>"layer_slug_s": "</xsl:text>
        <xsl:value-of select="$institution"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$identifier"/>
      <xsl:text>",</xsl:text>
    <!-- TODO should this look to 'revision' under citation rather than the dateStamp? -->
        <xsl:choose>
          <xsl:when test="gmd:MD_Metadata/gmd:dateStamp/gco:DateTime">
                <xsl:text>"layer_modified_dt": "</xsl:text>
                <xsl:value-of select="gmd:MD_Metadata/gmd:dateStamp/gco:DateTime"/>
                <xsl:if test="not(contains(gmd:MD_Metadata/gmd:dateStamp/gco:DateTime,'Z'))">
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


    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='originator']">
      <xsl:text>"dc_creator_sm": [</xsl:text>

      <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='originator']">
        <xsl:choose>
          <xsl:when test="ancestor-or-self::*/gmd:organisationName and not(ancestor-or-self::*/gmd:individualName)">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
            <xsl:text>"</xsl:text>
            <xsl:if test="position() != last()">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:when>
          <xsl:when test="ancestor-or-self::*/gmd:individualName and not(ancestor-or-self::*/gmd:organizationName)">
            <xsl:for-each select="ancestor-or-self::*/gmd:individualName">
              <xsl:text>"</xsl:text>
              <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
              <xsl:text>"</xsl:text>
              <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
              </xsl:if>
            </xsl:for-each>
          </xsl:when>
          <xsl:when test="ancestor-or-self::*/gmd:individualName and ancestor-or-self::*/gmd:organizationName">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
            <xsl:text>", </xsl:text>
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
            <xsl:text>"</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>

      <xsl:text>],</xsl:text>
    </xsl:if>
    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='publisher']">
      <xsl:text>"dc_publisher_sm": [</xsl:text>

      <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='publisher']">
        <xsl:choose>
          <xsl:when test="ancestor-or-self::*/gmd:organisationName and not(ancestor-or-self::*/gmd:individualName)">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
            <xsl:text>"</xsl:text>
            <xsl:if test="position() != last()">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:when>
          <xsl:when test="ancestor-or-self::*/gmd:individualName and not(ancestor-or-self::*/gmd:organizationName)">
            <xsl:for-each select="ancestor-or-self::*/gmd:individualName">
              <xsl:text>"</xsl:text>
              <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
              <xsl:text>"</xsl:text>
              <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
              </xsl:if>
            </xsl:for-each>
          </xsl:when>
          <xsl:when test="ancestor-or-self::*/gmd:individualName and ancestor-or-self::*/gmd:organizationName">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
            <xsl:text>", </xsl:text>
            <xsl:text>"</xsl:text>
            <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
            <xsl:text>"</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
      <xsl:text>],</xsl:text>
    </xsl:if>

        <xsl:text>"dc_format_s": "</xsl:text><xsl:value-of select="$format"/><xsl:text>",</xsl:text>

        <!-- TODO: add inputs for other languages -->
        <!-- <field name="dc_language_s">
          <xsl:if test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language | gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language/gmd:LanguageCode, 'eng')">
            <xsl:text>English</xsl:text>
          </xsl:if>
        </field> -->

        <!-- from DCMI type vocabulary -->
        <xsl:choose>
          <xsl:when test="contains(gmd:MD_Metadata/gmd:hierarchyLevelName/gco:CharacterString, 'dataset')">
            <xsl:text>"dc_type_s": "Dataset",</xsl:text>
          </xsl:when>

          <xsl:when test="contains(gmd:MD_Metadata/gmd:hierarchyLevelName/gco:CharacterString, 'service')">
            <xsl:text>"dc_type_s": "Service",</xsl:text>
          </xsl:when>
       </xsl:choose>

    <!-- topic category -->
    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode">
      <xsl:text>"dc_subject_sm": [</xsl:text>
      <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>"</xsl:text>
        <xsl:if test="position() != last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:if test="position() = last() and /gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='theme']">
          <xsl:text>,</xsl:text>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>

      <!-- theme keywords -->
      <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='theme']">
        <xsl:if test="not(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode)">
          <xsl:text>"dc_subject_sm": [</xsl:text>
        </xsl:if>
        <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='theme']">
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

    </xsl:if>

    <!-- close dc_subject_sm list -->
    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode or gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='theme']">
      <xsl:text>],</xsl:text>
    </xsl:if>

    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']">
      <xsl:text>"dct_spatial_sm": [</xsl:text>
      <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']">
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
      <xsl:text>],</xsl:text>
    </xsl:if>

      <xsl:choose>
          <xsl:when test="contains(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 'T')">
            <xsl:text>"dct_issued_s": "</xsl:text>
              <xsl:value-of select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
            <xsl:text>Z",</xsl:text>
          </xsl:when>

          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime">
            <xsl:text>"dct_issued_s": "</xsl:text>
              <xsl:value-of select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
            <xsl:text>",</xsl:text>
          </xsl:when>

          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date">
            <xsl:text>"dct_issued_s": "</xsl:text>
              <xsl:value-of select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date"/>
            <xsl:text>",</xsl:text>
          </xsl:when>

          <!-- <xsl:otherwise>unknown</xsl:otherwise> -->
        </xsl:choose>


      <!-- content date: range YYYY-YYYY if dates differ  -->
        <xsl:choose>
          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition/text() != ''">
            <xsl:text>"dct_temporal_sm": "</xsl:text>
              <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition, 1,4)"/>
              <xsl:if test="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition, 1,4) != substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition,1,4)">
                <xsl:text>-</xsl:text>
              <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition, 1,4)"/>
              </xsl:if>
              <xsl:text>",</xsl:text>
          </xsl:when>

            <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant">
              <xsl:text>"dct_temporal_sm": "</xsl:text>
                <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant, 1,4)"/>
              <xsl:text>",</xsl:text>
            </xsl:when>
          </xsl:choose>

        <!-- collection -->
    <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='largerWorkCitation'] or gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:collectiveTitle">
      <xsl:text>"dct_isPartOf_sm": "</xsl:text>
      <xsl:choose>
        <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='largerWorkCitation']">
          <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='largerWorkCitation']">
              <xsl:value-of select="ancestor-or-self::*/gmd:aggregateDataSetName/gmd:CI_Citation/gmd:title"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:collectiveTitle">
          <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:collectiveTitle">
              <xsl:value-of select="."/>
          </xsl:for-each>
        </xsl:when>
      </xsl:choose>
      <xsl:text>", </xsl:text>
    </xsl:if>

        <!-- cross-references -->
        <xsl:if test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='crossReference']">
          <xsl:text>"dc_relation_sm": [</xsl:text>
          <xsl:for-each select="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='crossReference']">
            <xsl:text>"</xsl:text>
              <xsl:value-of select="ancestor-or-self::*/gmd:aggregateDataSetName/gmd:CI_Citation/gmd:title"/>
            <xsl:text>"</xsl:text>
            <xsl:if test="position() != last()">
              <xsl:text>,</xsl:text>
            </xsl:if>
           </xsl:for-each>
          <xsl:text>],</xsl:text>
        </xsl:if>

        <!--<field name="georss_polygon_s">-->
        <xsl:text>"georss_polygon_s": "</xsl:text>
          <xsl:text></xsl:text>
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

        <!-- content date: singular, or beginning date of range: YYYY -->
        <xsl:choose>
          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition/text() != ''">
            <xsl:text>"solr_year_i": </xsl:text>
              <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition, 1,4)"/>
          </xsl:when>
          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant and gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant/text() != ''">
            <xsl:text>"solr_year_i": </xsl:text>
              <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant, 1,4)"/>
          </xsl:when>
          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode/@codeListValue='publication'">
            <xsl:text>"solr_year_i": </xsl:text>
            <xsl:choose>
              <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date">
                <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date, 1,4)"/>
              </xsl:when>
              <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime">
                <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 1,4)"/>
              </xsl:when>
            </xsl:choose>
            </xsl:when>
          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode/@codeListValue='creation'">

            <xsl:text>"solr_year_i": </xsl:text>
            <xsl:choose>
              <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date">
                <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date, 1,4)"/>
              </xsl:when>
              <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime">
                <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 1,4)"/>
              </xsl:when>
            </xsl:choose>
            <!--<xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date, 1,4)"/>-->
          </xsl:when>
          <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode/@codeListValue='revision'">
            <xsl:text>"solr_year_i": </xsl:text>
            <xsl:choose>
              <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date">
                <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date, 1,4)"/>
              </xsl:when>
              <xsl:when test="gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime">
                <xsl:value-of select="substring(gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 1,4)"/>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>"solr_year_i": 9999</xsl:text>
          </xsl:otherwise>
        </xsl:choose>

    <!-- let's try parsing references!!!!!!!! YEEEESSSS -->
    <xsl:text>,"dct_references_s": "{</xsl:text>
    <!-- TODO: Add metadata reference using FileIdentifier up here before digging into online resources -->
    <xsl:for-each select="//gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource">
      <xsl:choose>
        <xsl:when test="gmd:protocol/gco:CharacterString/text() = 'ESRI:ArcGIS'">
          <!-- TODO test url for which reference to utilize -->
            <xsl:choose>
              <xsl:when test="contains(gmd:linkage/gmd:URL,'FeatureServer')">
                <xsl:text>\"urn:x-esri:serviceType:ArcGIS#FeatureLayer\":\"</xsl:text>
              </xsl:when>
              <xsl:when test="contains(gmd:linkage/gmd:URL,'MapServer')">
                <!--TODO need to distinguish between tiled/dynamic. Probably need to move
                all of this logic out of the XSL
                <xsl:text>"http://www.arcgis.com/rdf#TiledMapLayer":"</xsl:text>-->
                <xsl:text>\"urn:x-esri:serviceType:ArcGIS#DynamicMapLayer\":\"</xsl:text>
              </xsl:when>
              <xsl:when test="contains(gmd:linkage/gmd:URL,'ImageServer')">
                <xsl:text>\"urn:x-esri:serviceType:ArcGIS#ImageMapLayer\":\"</xsl:text>
              </xsl:when>
            </xsl:choose>
          <xsl:value-of select="gmd:linkage/gmd:URL"/>
          <xsl:text>\"</xsl:text>
        </xsl:when>
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
