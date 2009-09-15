<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sch:schema xmlns:sch="http://www.ascc.net/xml/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--

This Schematron schema merges three sets of Schematron rules
1. Schematron rules embedded in the GML 3.2 schema
2. Schematron rules implementing the Additional Constraints described in 
   ISO 19139 Table A.1

This script was written by CSIRO for the Australia-New Zealand Land 
Information Council (ANZLIC) as part of a project to develop an XML 
implementation of the ANZLIC ISO Metadata Profile. 

December 2006, March 2007

Port back to good old Schematron-1.5 for use with schematron-report.xsl
and change titles for use as bare bones 19115/19139 schematron checker 
in GN 2.2 onwards.

Simon Pigot, 2007

This work is licensed under the Creative Commons Attribution 2.5 License. 
To view a copy of this license, visit 
    http://creativecommons.org/licenses/by/2.5/au/ 

or send a letter to:

Creative Commons, 
543 Howard Street, 5th Floor, 
San Francisco, California, 94105, 
USA.

-->

	<sch:title xmlns="http://www.w3.org/2001/XMLSchema">Schematron validation for ISO 19115(19139)</sch:title>
	<sch:ns prefix="gml" uri="http://www.opengis.net/gml" />
	<sch:ns prefix="gmd" uri="http://www.isotc211.org/2005/gmd"/>
    <sch:ns prefix="srv" uri="http://www.isotc211.org/2005/srv"/>
	<sch:ns prefix="gco" uri="http://www.isotc211.org/2005/gco"/>
	<sch:ns prefix="geonet" uri="http://www.fao.org/geonetwork"/>
	<sch:ns prefix="xlink" uri="http://www.w3.org/1999/xlink"/>

	<!-- Test that every CharacterString element has content or it's parent has a
   		 valid nilReason attribute value - this is not necessary for geonetwork 
			 because update-fixed-info.xsl supplies a gco:nilReason of missing for 
			 all gco:CharacterString elements with no content and removes it if the
			 user fills in a value - this is the same for all gco:nilReason tests 
			 used below - the test for gco:nilReason in 'inapplicable....' etc is
			 "mickey mouse" for that reason. -->
    <sch:pattern name="$loc/strings/M6">
      <sch:rule context="*[gco:CharacterString]">
        <sch:report test="(normalize-space(gco:CharacterString) = '') and (not(@gco:nilReason) or not(contains('inapplicable missing template unknown withheld',@gco:nilReason)))">$loc/strings/alert.M6.characterString</sch:report>
      </sch:rule>
    </sch:pattern>

	<sch:pattern name="$loc/strings/M7">
		<!-- UNVERIFIED -->
		<sch:rule id="CRSLabelsPosType" context="//gml:DirectPositionType">
			<sch:report test="not(@srsDimension) or @srsName">$loc/strings/alert.M6.directPosition</sch:report>
			<sch:report test="not(@axisLabels) or @srsName">$loc/strings/alert.M7.axisAndSrs</sch:report>
			<sch:report test="not(@uomLabels) or @srsName">$loc/strings/alert.M7.uomAndSrs</sch:report>
			<sch:report test="(not(@uomLabels) and not(@axisLabels)) or (@uomLabels and @axisLabels)">$loc/strings/alert.M7.uomAndAxis</sch:report>
		</sch:rule>
	</sch:pattern>

	<!--anzlic/trunk/gml/3.2.0/gmd/citation.xsd-->
	<!-- TEST 21 -->
	<sch:pattern name="$loc/strings/M8">
		<sch:rule context="//gmd:CI_ResponsibleParty">
			<sch:assert test="(count(gmd:individualName) + count(gmd:organisationName) + count(gmd:positionName)) > 0">$loc/strings/alert.M8</sch:assert>
		</sch:rule>
	</sch:pattern>
	<!-- anzlic/trunk/gml/3.2.0/gmd/constraints.xsd-->
	<!-- TEST  4 -->
	<sch:pattern name="$loc/strings/M9">
		<sch:rule context="//gmd:MD_LegalConstraints">
			<sch:report test="gmd:accessConstraints/gmd:MD_RestrictionCode/@codeListValue='otherRestrictions' and not(gmd:otherConstraints)">$loc/strings/alert.M8.access</sch:report>
			<sch:report test="gmd:useConstraints/gmd:MD_RestrictionCode/@codeListValue='otherRestrictions' and not(gmd:otherConstraints)">$loc/strings/alert.M8.use</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- anzlic/trunk/gml/3.2.0/gmd/content.xsd-->
	<!-- TEST 13 -->
	<sch:pattern name="$loc/strings/M10">
		<sch:rule context="//gmd:MD_Band">
			<sch:report test="(gmd:maxValue or gmd:minValue) and not(gmd:units)">$loc/strings/alert.M9</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- anzlic/trunk/gml/3.2.0/gmd/dataQuality.xsd -->
	<!-- TEST 10 -->
	<sch:pattern name="$loc/strings/M11">
		<sch:rule context="//gmd:LI_Source">
			<sch:assert test="gmd:description or gmd:sourceExtent">$loc/strings/alert.M11</sch:assert>
		</sch:rule>
	</sch:pattern>
	<!-- TEST 11 -->
	<sch:pattern name="$loc/strings/M12">
		<sch:rule context="//gmd:LI_Source">
			<sch:assert test="gmd:description or gmd:sourceExtent">$loc/strings/alert.M12</sch:assert>
		</sch:rule>
	</sch:pattern>
	<!-- TEST  7 -->
	<sch:pattern name="$loc/strings/M13">
		<sch:rule context="//gmd:DQ_DataQuality">
			<sch:report test="(((count(*/gmd:LI_Lineage/gmd:source) + count(*/gmd:LI_Lineage/gmd:processStep)) = 0) and (gmd:scope/gmd:DQ_Scope/gmd:level/gmd:MD_ScopeCode/@codeListValue='dataset' or gmd:scope/gmd:DQ_Scope/gmd:level/gmd:MD_ScopeCode/@codeListValue='series')) and not(gmd:lineage/gmd:LI_Lineage/gmd:statement) and (gmd:lineage)">$loc/strings/alert.M13</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- TEST  8 -->
	<sch:pattern name="$loc/strings/M14">
		<sch:rule context="//gmd:LI_Lineage">
			<sch:report test="not(gmd:source) and not(gmd:statement) and not(gmd:processStep)">$loc/strings/alert.M14</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- TEST  9 -->
	<sch:pattern name="$loc/strings/M15">
		<sch:rule context="//gmd:LI_Lineage">
			<sch:report test="not(gmd:processStep) and not(gmd:statement) and not(gmd:source)">$loc/strings/alert.M15</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- TEST 5 -->
	<sch:pattern name="$loc/strings/M16">
		<sch:rule context="//gmd:DQ_DataQuality">
			<sch:report test="gmd:scope/gmd:DQ_Scope/gmd:level/gmd:MD_ScopeCode/@codeListValue='dataset' and not(gmd:report) and not(gmd:lineage)">$loc/strings/alert.M16</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- TEST  6 -->
	<sch:pattern name="$loc/strings/M17">
		<sch:rule context="//gmd:DQ_Scope">
			<sch:assert test="gmd:level/gmd:MD_ScopeCode/@codeListValue='dataset' or gmd:level/gmd:MD_ScopeCode/@codeListValue='series' or (gmd:levelDescription and ((normalize-space(gmd:levelDescription) != '') or (gmd:levelDescription/gmd:MD_ScopeDescription) or (gmd:levelDescription/@gco:nilReason and contains('inapplicable missing template unknown withheld',gmd:levelDescription/@gco:nilReason))))">$loc/strings/alert.M17</sch:assert>
		</sch:rule>
	</sch:pattern>
	<!-- anzlic/trunk/gml/3.2.0/gmd/distribution.xsd-->
	<!-- TEST 14 -->
	<sch:pattern name="$loc/strings/M18">
		<sch:rule context="//gmd:MD_Medium">
			<sch:report test="gmd:density and not(gmd:densityUnits)">$loc/strings/alert.M18</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- TEST15 -->
	<sch:pattern name="$loc/strings/M19">
		<sch:rule context="//gmd:MD_Distribution">
			<sch:assert test="count(gmd:distributionFormat)>0 or count(gmd:distributor/gmd:MD_Distributor/gmd:distributorFormat)>0">$loc/strings/alert.M19</sch:assert>
		</sch:rule>
	</sch:pattern>
	<!-- anzlic/trunk/gml/3.2.0/gmd/extent.xsd-->
	<!-- TEST 20 -->
	<sch:pattern name="$loc/strings/M20">
		<sch:rule context="//gmd:EX_Extent">
			<sch:assert test="count(gmd:description)>0 or count(gmd:geographicElement)>0 or count(gmd:temporalElement)>0 or count(gmd:verticalElement)>0">$loc/strings/alert.M20</sch:assert>
		</sch:rule>
	</sch:pattern>
	<!-- TEST  1 -->
	<sch:pattern name="$loc/strings/M21">
		<sch:rule context="//*[gmd:identificationInfo/gmd:MD_DataIdentification]">
			<sch:report test="(not(gmd:hierarchyLevel) or gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue='dataset') and (count(//gmd:MD_DataIdentification/gmd:extent/*/gmd:geographicElement/gmd:EX_GeographicBoundingBox) + count (//gmd:MD_DataIdentification/gmd:extent/*/gmd:geographicElement/gmd:EX_GeographicDescription)) =0 ">$loc/strings/alert.M21</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- TEST  2 -->
	<sch:pattern name="$loc/strings/M22">
		<sch:rule context="//gmd:MD_DataIdentification">
			<sch:report test="(not(../../gmd:hierarchyLevel) or (../../gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue='dataset') or (../../gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue='series')) and (not(gmd:topicCategory))">$loc/strings/alert.M6</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- TEST  3 -->
	<sch:pattern name="$loc/strings/M23">
		<sch:rule context="//gmd:MD_AggregateInformation">
			<sch:assert test="gmd:aggregateDataSetName or gmd:aggregateDataSetIdentifier">$loc/strings/alert.M22</sch:assert>
		</sch:rule>
	</sch:pattern>
	<!-- anzlic/trunk/gml/3.2.0/gmd/metadataEntity.xsd: -->
	<sch:pattern name="$loc/strings/M24">
    <!-- UNVERIFIED -->
    <sch:rule context="//gmd:MD_Metadata|//*[@gco:isoType='gmd:MD_Metadata']">
      <sch:assert test="gmd:language and ((normalize-space(gmd:language) != '')  or (normalize-space(gmd:language/gco:CharacterString) != '') or (gmd:language/gmd:LanguageCode) or (gmd:language/@gco:nilReason and contains('inapplicable missing template unknown withheld',gmd:language/@gco:nilReason)))">$loc/strings/alert.M23</sch:assert>
      <!-- language: documented if not defined by the encoding standard. 
					 It can't be documented by the encoding because GML doesn't 
					 include xml:language. -->
    </sch:rule>
  </sch:pattern>
	<sch:pattern name="$loc/strings/M25">
    <!-- UNVERIFIED -->
    <sch:rule context="//gmd:MD_Metadata|//*[@gco:isoType='gmd:MD_Metadata']">
      <!-- characterSet: documented if ISO/IEC 10646 not used and not defined by
        the encoding standard. Can't tell if XML declaration has an encoding
        attribute. -->
    </sch:rule>
  </sch:pattern>

	<!-- anzlic/trunk/gml/3.2.0/gmd/metadataExtension.xsd-->
	<!-- TEST 16 -->
	<sch:pattern name="$loc/strings/M26">
		<sch:rule context="//gmd:MD_ExtendedElementInformation">
			<sch:assert test="(gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='codelist' or gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='enumeration' or gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='codelistElement') or (gmd:obligation and ((normalize-space(gmd:obligation) != '')  or (gmd:obligation/gmd:MD_ObligationCode) or (gmd:obligation/@gco:nilReason and contains('inapplicable missing template unknown withheld',gmd:obligation/@gco:nilReason))))">$loc/strings/alert.M26.obligation</sch:assert>
			<sch:assert test="(gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='codelist' or gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='enumeration' or gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='codelistElement') or (gmd:maximumOccurrence and ((normalize-space(gmd:maximumOccurrence) != '')  or (normalize-space(gmd:maximumOccurrence/gco:CharacterString) != '') or (gmd:maximumOccurrence/@gco:nilReason and contains('inapplicable missing template unknown withheld',gmd:maximumOccurrence/@gco:nilReason))))">$loc/strings/alert.M26.minimumOccurence</sch:assert>
			<sch:assert test="(gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='codelist' or gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='enumeration' or gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='codelistElement') or (gmd:domainValue and ((normalize-space(gmd:domainValue) != '')  or (normalize-space(gmd:domainValue/gco:CharacterString) != '') or (gmd:domainValue/@gco:nilReason and contains('inapplicable missing template unknown withheld',gmd:domainValue/@gco:nilReason))))">$loc/strings/alert.M26.domainValue</sch:assert>
		</sch:rule>
	</sch:pattern>
	<!-- TEST 17 -->
	<sch:pattern name="$loc/strings/M27">
		<sch:rule context="//gmd:MD_ExtendedElementInformation">
			<sch:report test="gmd:obligation/gmd:MD_ObligationCode='conditional' and not(gmd:condition)">$loc/strings/alert.M27</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- TEST 18 -->
	<sch:pattern name="$loc/strings/M28">
		<sch:rule context="//gmd:MD_ExtendedElementInformation">
			<sch:report test="gmd:dataType/gmd:MD_DatatypeCode/@codeListValue='codelistElement' and not(gmd:domainCode)">$loc/strings/alert.M28</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- TEST 19 -->
	<sch:pattern name="$loc/strings/M29">
		<sch:rule context="//gmd:MD_ExtendedElementInformation">
			<sch:report test="gmd:dataType/gmd:MD_DatatypeCode/@codeListValue!='codelistElement' and not(gmd:shortName)">$loc/strings/alert.M29</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- anzlic/trunk/gml/3.2.0/gmd/spatialRepresentation.xsd-->
	<!-- TEST 12 -->
	<sch:pattern name="$loc/strings/M30">
		<sch:rule context="//gmd:MD_Georectified">
			<sch:report test="(gmd:checkPointAvailability/gco:Boolean='1' or gmd:checkPointAvailability/gco:Boolean='true') and not(gmd:checkPointDescription)">$loc/strings/alert.M30</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- =============================================================
		GeoNetwork schematron rules:
		=============================================================
		* Language:
		 * Do not declare a language twice in gmd:locale section.	
			This should not happen due to XSD error
			which is usually made before schematron validation:
			"The value 'XX' of attribute 'id' on element 'gmd:PT_Locale' is not valid with respect to its type, 'ID'. 
			(Element: gmd:PT_Locale with parent element: gmd:locale)"
		 * gmd:LocalisedCharacterString locale="#FR" id exist in gmd:locale.
		 * Check that main language is not defined and gmd:locale element exist.		 
	-->
	<sch:pattern name="$loc/strings/M500">
		<sch:rule context="//gmd:MD_Metadata/gmd:language|//*[@gco:isoType='gmd:MD_Metadata']/gmd:language">
			<sch:report test="../gmd:locale and @gco:nilReason='missing'">$loc/strings/alert.M500</sch:report>
		</sch:rule>
	</sch:pattern>
	<!-- 
		* Check that main language is defined and does not exist in gmd:locale.
	-->
	<sch:pattern name="$loc/strings/M501">
		<sch:rule context="//gmd:MD_Metadata/gmd:locale|//*[@gco:isoType='gmd:MD_Metadata']/gmd:locale">
			<sch:report test="gmd:PT_Locale/gmd:languageCode/gmd:LanguageCode/@codeListValue=../gmd:language/gco:CharacterString">$loc/strings/alert.M501</sch:report>
		</sch:rule>
	</sch:pattern>
</sch:schema>
