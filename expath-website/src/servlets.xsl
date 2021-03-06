<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:web="http://expath.org/ns/webapp"
                xmlns:app="http://expath.org/ns/website"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="#all"
                version="2.0">

   <xsl:import href="http://expath.org/ns/website/webpage.xsl"/>

   <pkg:import-uri>http://expath.org/ns/website/servlets.xsl</pkg:import-uri>

   <xsl:param name="menus" as="element(menu)+" select="doc('sitemap.xml')/sitemap/menu"/>

   <!--
       Display the download area page, from the files repository.
   -->
   <xsl:function name="app:download-area-servlet">
      <!-- the http request -->
      <xsl:param name="request" as="element(web:request)"/>
      <!-- the list of files -->
      <xsl:variable name="list" select="
         doc(resolve-uri('files.xml', web:config-param('web-files-dir')))/files"/>
      <web:response status="200" message="Ok">
         <web:body content-type="text/html" method="xhtml"/>
      </web:response>
      <xsl:variable name="doc" as="element(webpage)">
         <webpage menu="main" xmlns="">
            <title>EXPath - Download</title>
            <section>
               <title>Download</title>
               <para>Here are the latest version of the available components.  For
                  earlier versions, please check individual download areas.</para>
               <divider/>
               <xsl:apply-templates select="$list/area"/>
            </section>
         </webpage>
      </xsl:variable>
      <xsl:apply-templates select="$doc">
         <xsl:with-param name="page-name" select="'download'"/>
      </xsl:apply-templates>
   </xsl:function>

   <xsl:template match="area[@dir]">
      <primary xmlns="">
         <title>
            <xsl:value-of select="name"/>
         </title>
         <para>
            <xsl:text>See the dedicated download </xsl:text>
            <link href="files/{ @dir }">
               <xsl:text>area</xsl:text>
            </link>
            <xsl:text> for all versions.</xsl:text>
         </para>
         <xsl:for-each select="desc">
            <para>
               <xsl:copy-of select="node()"/>
            </para>
         </xsl:for-each>
         <list>
            <xsl:for-each select="component">
               <item>
                  <xsl:value-of select="name"/>
                  <xsl:text>: </xsl:text>
                  <link href="file/{ ../@dir }/{ file/@href }">
                     <xsl:value-of select="file/@href"/>
                  </link>
               </item>
            </xsl:for-each>
         </list>
      </primary>
   </xsl:template>

   <!--
       Display a specific download area page, from the files repository.
   -->
   <xsl:function name="app:download-page-servlet">
      <!-- the http request -->
      <xsl:param name="request" as="element(web:request)"/>
      <!-- the name of the specific area -->
      <xsl:variable name="area-name" as="xs:string" select="
          $request/web:path/web:match[@name eq 'area']"/>
      <!-- the list of files -->
      <xsl:variable name="area" select="
         doc(resolve-uri(concat($area-name, '/__files.xml'), web:config-param('web-files-dir')))/area"/>
      <web:response status="200" message="Ok">
         <web:body content-type="text/html" method="xhtml"/>
      </web:response>
      <xsl:variable name="doc" as="element(webpage)">
         <webpage menu="download" xmlns="" root="..">
            <title>EXPath - Download</title>
            <section>
               <title>
                  <xsl:text>Download: </xsl:text>
                  <xsl:value-of select="$area/name"/>
               </title>
               <xsl:apply-templates select="$area/component"/>
            </section>
         </webpage>
      </xsl:variable>
      <xsl:apply-templates select="$doc">
         <xsl:with-param name="page-name" select="'download'"/>
      </xsl:apply-templates>
   </xsl:function>

   <xsl:template match="component">
      <primary xmlns="">
         <title>
            <xsl:value-of select="name"/>
         </title>
         <list>
            <xsl:for-each select="file">
               <item>
                  <link href="../file/{ ../../@dir }/{ @href }">
                     <xsl:value-of select="@href"/>
                  </link>
               </item>
            </xsl:for-each>
         </list>
      </primary>
   </xsl:template>

   <!--
       Return a file straight from the web-files repository.
   -->
   <xsl:function name="app:download-file-servlet">
      <!-- the http request -->
      <xsl:param name="request" as="element(web:request)"/>
      <!-- the url param 'resource' -->
      <xsl:variable name="area" select="$request/web:path/web:match[@name eq 'area']"/>
      <xsl:variable name="file" select="$request/web:path/web:match[@name eq 'file']"/>
      <!-- the resolved file for the resource -->
      <xsl:variable name="href" select="
         resolve-uri(
           concat($area, '/', $file),
           web:config-param('web-files-dir'))"/>
      <!-- TODO: Is there a way to test the file exists? -->
      <!-- TODO: Find a way to set the proper content-type...  In __files.xml, maybe? -->
      <web:response status="200" message="Ok">
         <web:body content-type="application/octet-stream" src="{ $href }"/>
      </web:response>
   </xsl:function>

   <!--
       Display a page from the page repository, which must be a 'webpage' XML document.
   -->
   <xsl:function name="app:page-servlet">
      <!-- the http request -->
      <xsl:param name="request" as="element(web:request)"/>
      <!-- the page name, where "*/" translated to "*/index" -->
      <xsl:variable name="page" as="xs:string">
         <xsl:variable name="param" select="$request/web:path/web:match[@name eq 'page']"/>
         <xsl:sequence select="
             if ( not($param) or ends-with($param, '/') ) then
               concat($param, 'index')
             else
               $param"/>
      </xsl:variable>
      <!-- the resolved file for the page -->
      <xsl:variable name="file" select="app:resolve-page($page)"/>
      <xsl:choose>
         <!-- the page exists -->
         <xsl:when test="doc-available($file)">
            <web:response status="200" message="Ok">
               <web:body content-type="text/html" method="xhtml"/>
            </web:response>
            <xsl:variable name="doc" as="element(webpage)" select="doc($file)/*"/>
            <xsl:apply-templates select="$doc">
               <xsl:with-param name="page-name" select="tokenize($page, '/')[last()]"/>
            </xsl:apply-templates>
         </xsl:when>
         <!-- the page does not exist -->
         <xsl:otherwise>
            <web:response status="404" message="Not found">
               <web:body content-type="text/plain" method="text">
                  <xsl:text>Resource not found: </xsl:text>
                  <xsl:value-of select="$page"/>
               </web:body>
            </web:response>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!--
       Return the atom feed from the page repository.
   -->
   <xsl:function name="app:xml-resource">
      <!-- the http request -->
      <xsl:param name="request" as="element(web:request)"/>
      <!-- the url param 'resource' -->
      <xsl:variable name="param" select="$request/web:path/web:match[@name eq 'resource']"/>
      <!-- the resolved file for the resource -->
      <xsl:variable name="file" select="app:resolve-page($param)"/>
      <xsl:choose>
         <!-- the page exists -->
         <xsl:when test="doc-available($file)">
            <web:response status="200" message="Ok">
               <web:body content-type="application/xml" method="xml"/>
            </web:response>
            <xsl:sequence select="doc($file)"/>
         </xsl:when>
         <!-- the page does not exist -->
         <xsl:otherwise>
            <web:response status="404" message="Not found">
               <web:body content-type="text/plain" method="text">
                  <xsl:text>Resource not found: </xsl:text>
                  <xsl:value-of select="$param"/>
                  <xsl:text>.xml</xsl:text>
               </web:body>
            </web:response>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="app:resolve-page" as="xs:string">
      <xsl:param name="page" as="xs:string"/>
      <xsl:sequence select="
         resolve-uri(
           concat($page, '.xml'),
           web:config-param('web-content-dir'))"/>
   </xsl:function>

   <!--
       The addresses have changed, propose to redirect *.html to *.
   -->
   <xsl:function name="app:old-page-servlet">
      <xsl:param name="request" as="element(web:request)"/>
      <xsl:variable name="page" select="$request/web:path/web:match[@name eq 'page']"/>
      <web:response status="404" message="Not found">
         <web:body content-type="text/html" method="xhtml"/>
      </web:response>
      <html>
         <head>
            <title>EXPath - Oops</title>
         </head>
         <body>
            <p>
               <xsl:text>The page you requested does not exist.  Did you mean </xsl:text>
               <a href="{ tokenize($page, '/')[last()] }">
                  <xsl:value-of select="$page"/>
               </a>
               <xsl:text> instead?</xsl:text>
            </p>
         </body>
      </html>
   </xsl:function>

   <xsl:function name="app:search-servlet">
      <xsl:param name="request" as="element(web:request)"/>
      <xsl:variable name="page" as="element(webpage)">
         <webpage menu="main" xmlns="">
            <title>EXPath - Search</title>
            <section>
               <title>Search</title>
               <image src="images/machine.jpg" alt="Machine"/>
               <para>The search is not available yet...</para>
            </section>
         </webpage>
      </xsl:variable>
      <web:response status="200" message="Ok">
         <web:body content-type="text/html" method="xhtml"/>
      </web:response>
      <xsl:apply-templates select="$page">
         <xsl:with-param name="page-name" select="'[null]'"/>
      </xsl:apply-templates>
   </xsl:function>

   <!--
       List all the specs.
   -->
   <xsl:function name="app:specs-page-servlet">
      <xsl:param name="request" as="element(web:request)"/>
      <xsl:variable name="specs" as="element(spec)+" select="app:get-specs()"/>
      <xsl:variable name="page" as="element(webpage)">
         <webpage menu="main" xmlns="">
            <title>EXPath - Specifications</title>
            <section>
               <title>Specifications</title>
               <!--image src="images/machine.jpg" alt="Machine"/>
               <para>Page under construction...</para-->
               <divider/>
               <xsl:for-each select="$specs">
                  <xsl:sort select="@name"/>
                  <xsl:variable name="spec-name" select="@name"/>
                  <primary>
                     <title>
                        <xsl:value-of select="$spec-name"/>
                     </title>
                     <list>
                        <item>
                           <xsl:text>Latest: </xsl:text>
                           <link href="spec/{ $spec-name }">
                              <xsl:value-of select="$spec-name"/>
                           </link>
                        </item>
                        <xsl:variable name="file-re" select="concat('^', $spec-name, '-[0-9]{8}.xml$')"/>
                        <!-- TODO: Display in reverse order... (newest on top) -->
                        <xsl:for-each select="revision">
                           <xsl:sort select="position()" order="descending"/>
                           <item>
                              <link href="spec/{ $spec-name }/{ @version }">
                                 <xsl:value-of select="concat($spec-name, '/', @version)"/>
                              </link>
                           </item>
                        </xsl:for-each>
                        <xsl:for-each select="editor">
                           <item>
                              <xsl:text>editor's </xsl:text>
                              <link href="spec/{ $spec-name }/editor">
                                 <xsl:text>draft</xsl:text>
                              </link>
                           </item>
                        </xsl:for-each>
                     </list>
                  </primary>
               </xsl:for-each>
            </section>
         </webpage>
      </xsl:variable>
      <web:response status="200" message="Ok">
         <web:body content-type="text/html" method="xhtml"/>
      </web:response>
      <xsl:apply-templates select="$page">
         <xsl:with-param name="page-name" select="'specs'"/>
      </xsl:apply-templates>
   </xsl:function>

   <!--
       ...
       
       TODO: Try to see if the address does resolve to a spec, and if
       not try to suggest a correct one (e.g. the latest one for the
       spec, because we allow only addresses starting with a valid
       spec name...)
   -->
   <xsl:function name="app:spec-servlet">
      <xsl:param name="request" as="element(web:request)"/>
      <xsl:variable name="spec"    select="$request/web:path/web:match[@name eq 'spec']"/>
      <xsl:variable name="editor"  select="$request/web:path/web:match[@name eq 'editor']"/>
      <xsl:variable name="version" select="$request/web:path/web:match[@name eq 'version']"/>
      <xsl:variable name="diff"    select="$request/web:path/web:match[@name eq 'diff']"/>
      <xsl:variable name="xml"     select="$request/web:path/web:match[@name eq 'xml']"/>
      <xsl:variable name="resolved" as="xs:anyURI?" select="
          app:resolve-spec(
             $spec,
             $spec,
             exists($editor),
             $version,
             exists($diff),
             exists($xml))"/>
      <xsl:choose>
         <xsl:when test="exists($resolved)">
            <web:response status="200" message="Ok">
               <!-- TODO: Add a 'Link:' header (RFC 5988) to point to the current
                    version of the spec, alternate versions, copyright, etc.  Must
                    be easy using 'spec-list.xml'. -->
               <web:body content-type="text/html" src="{ $resolved }"/>
            </web:response>
         </xsl:when>
         <xsl:otherwise>
            <web:response status="404" message="Not found">
               <web:body content-type="text/plain" method="text">
                  <xsl:text>Specification not found: </xsl:text>
                  <xsl:value-of select="string-join($request/web:path/*[position() gt 1], '')"/>
               </web:body>
            </web:response>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="app:latest-servlet">
      <xsl:param name="request" as="element(web:request)"/>
      <xsl:variable name="spec"   select="$request/web:path/web:match[@name eq 'spec']"/>
      <xsl:variable name="latest" select="app:latest-spec($spec)"/>
      <xsl:choose>
         <xsl:when test="exists($latest)">
            <web:response status="302" message="Found">
               <!-- TODO: Add a 'Link:' header (RFC 5988) to point to the current
                    version of the spec, alternate versions, copyright, etc.  Must
                    be easy using 'spec-list.xml'. -->
               <web:header name="Location" value="{ $latest/(self::revision/@version, self::editor/'editor') }"/>
            </web:response>
         </xsl:when>
         <xsl:otherwise>
            <web:response status="404" message="Not found">
               <web:body content-type="text/plain" method="text">
                  <xsl:text>Specification not found: </xsl:text>
                  <xsl:value-of select="string-join($request/web:path/*[position() gt 1], '')"/>
               </web:body>
            </web:response>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="app:resolve-spec" as="xs:anyURI?">
      <xsl:param name="module"  as="xs:string"/>
      <xsl:param name="spec"    as="xs:string"/>
      <xsl:param name="editor"  as="xs:boolean"/>
      <xsl:param name="version" as="xs:string?"/>
      <xsl:param name="diff"    as="xs:boolean"/>
      <xsl:param name="xml"     as="xs:boolean"/>
      <xsl:variable name="info"     as="element(spec)?" select="app:get-specs()[@name eq $spec]"/>
      <xsl:variable name="revision" as="element()?"     select="
         if ( empty($info) ) then
           ()
         else if ( $editor ) then
           $info/editor
         else if ( exists($version) ) then
           $info/revision[@version eq $version]
         else
           app:latest-spec($spec)"/>
      <xsl:if test="exists($revision)">
         <xsl:sequence select="
            app:select-spec-file($revision, $diff, $xml)/resolve-uri(@href, base-uri(.))"/>
      </xsl:if>
   </xsl:function>

   <xsl:function name="app:latest-spec" as="element()?"> <!-- element(revision|editor)? -->
      <xsl:param name="spec" as="xs:string"/>
      <xsl:sequence select="
         app:get-specs()[@name eq $spec]/revision[@latest/xs:boolean(.)]"/>
   </xsl:function>

   <xsl:function name="app:select-spec-file" as="element(file)?">
      <xsl:param name="revision" as="element()"/> <!-- element(revision|editor) -->
      <xsl:param name="diff"     as="xs:boolean"/>
      <xsl:param name="xml"      as="xs:boolean"/>
      <xsl:variable name="format" select="
         if ( $xml ) then
           $revision/file[@format eq 'xml']
         else
           $revision/file[@format eq 'html']"/>
      <xsl:sequence select="
         $format[(not($diff) and empty(@diff)) or (@diff/xs:boolean(.) eq $diff)]"/>
   </xsl:function>

   <xsl:function name="app:get-specs" as="element(spec)+">
      <xsl:sequence select="
         ( app:get-spec-list('org-spec-dir'), app:get-spec-list('w3c-spec-dir') )/spec"/>
   </xsl:function>

   <xsl:function name="app:get-spec-list" as="element(specs)">
      <xsl:param name="param" as="xs:string"/>
      <xsl:variable name="dir" as="xs:string" select="web:config-param($param)"/>
      <xsl:sequence select="
         doc(resolve-uri('list.xml', $dir))/specs"/>
   </xsl:function>

   <!--
       The wiki redirection must be configured in Apache.
       
       In case it is not properly configured (or in case we are in a
       dev environment, without Apache), display a user-friednly error
       message.
   -->
   <xsl:function name="app:wiki-servlet">
      <xsl:param name="request" as="element(web:request)"/>
      <xsl:variable name="page" select="$request/web:path/web:match[@name eq 'page']"/>
      <web:response status="404" message="Not found">
         <web:body content-type="text/html" method="xhtml"/>
      </web:response>
      <html>
         <head>
            <title>EXPath - Oops</title>
         </head>
         <body>
            <p>
               <xsl:text>Oops, it seems the wiki is not available for
               now.  Please try again later, and think to report the
               problem to the list or directly to the
               webmaster.</xsl:text>
            </p>
         </body>
      </html>
   </xsl:function>

</xsl:stylesheet>
