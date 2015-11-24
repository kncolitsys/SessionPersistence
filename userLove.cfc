<!--- 
Description: This CFC is designed to trap the URL and FORM data a user submitted to the site when their session expired. It is possible that you may not wish to trap the FORM data submitted (if you're worried a user might walk away from their computer - someone else comes along and enters data into the form they were looking at, clicks submit, the system notes their session expired so sends them to the login screen, the other person walks away, real user comes back, logs in, and the system would auto-submit what that other person entered), in that case, just ensure that all processing pages in your site use cfparams (we all do anyway right? right?) then dont pass the formVars argument into the CFC.

usage WITH FORM VARS PASSED IN:

<!--- preserve location and form data user was moving towards prior to session expiry --->
<!--- CHECK SESSION PAGE USES THIS after session failure but before generic redirect:--->
<!--- var to hold whether or not site is secure --->
<cfif cgi.https eq "on"><cfset httpsTrap="s"><cfelse><cfset httpsTrap=""></cfif>
<cfset urlVar="http#httpsTrap#://#cgi.server_name##cgi.SCRIPT_NAME#?#cgi.QUERY_STRING#">
<cfif isDefined("form")>
<cfset formVar=structCopy(form)>
<cfelse>
<cfset formVar="">
</cfif>
<cfinvoke component="CFCs.userLove" method="preserveDest" urlVar="#urlVar#" formVars="#formVar#">


<!--- CHECK PASSWORD PAGE USES THIS after successful login check, but before generic login page:--->
<cfif isDefined("session.prsrvURL")>
<cfset urlVar=session.prsrvURL>
<cfelse>
<cfset urlVar="">
</cfif>
<cfif isDefined("session.prsrvform")>
<cfset formVar=session.prsrvform>
<cfelse>
<cfset formVar=structNew()>
</cfif>
<cfinvoke component="CFCs.userLove" method="redirector" urlVar="#urlVar#" formVars="#formVar#">



usage WITHOUT FORM VARS PASSED IN:

<!--- preserve location and form data user was moving towards prior to session expiry --->
<!--- CHECK SESSION PAGE USES THIS after session failure but before generic redirect:--->
<!--- var to hold whether or not site is secure --->
<cfif cgi.https eq "on"><cfset httpsTrap="s"><cfelse><cfset httpsTrap=""></cfif>
<cfset urlVar="http#httpsTrap#://#cgi.server_name##cgi.SCRIPT_NAME#?#cgi.QUERY_STRING#">
<cfinvoke component="CFCs.userLove" method="preserveDest" urlVar="#urlVar#">


<!--- CHECK PASSWORD PAGE USES THIS after successful login check, but before generic login page:--->
<cfif isDefined("session.prsrvURL")>
<cfset urlVar=session.prsrvURL>
<cfelse>
<cfset urlVar="">
</cfif>
<cfinvoke component="CFCs.userLove" method="redirector" urlVar="#urlVar#">



CFC that maintains form and URL data across expired logins
Copyright (C) 2009  Lars Gronholt

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Contact: aegis@legalwarfare.com
--->

<cfcomponent hint="component to preserve location and form data user was moving towards prior to session expiry">
	<cffunction name="preserveDest" hint="function to preserve the destination the user wanted to get to when their session expired" output="no">
		<cfargument name="urlVar" required="no">
		<cfargument name="formVars" required="no" type="struct">
		
		<cfset session.prsrvForm=structNew()>
		<cfif IsDefined("arguments.urlVar") and arguments.urlVar neq "">
			<cfset session.prsrvURL=arguments.urlVar>
			<cfif IsStruct(arguments.formVars) AND NOT structIsEmpty(arguments.formVars)>
				<cfset session.prsrvFORM=arguments.formVars>
			</cfif>
		</cfif>
		
	</cffunction>



<cffunction name="redirector" hint="function to redirect current page to original location user wanted prior to relogging in" output="yes">
		<cfargument name="urlVar" required="no">
		<cfargument name="formVars" required="no" type="struct">
		<cfset serverAddy=cgi.server_name>
		
		<!--- clear session vars --->
		<cfif isDefined("session.prsrvform")>
			<cfset temp=structDelete(session, "prsrvform")>
		</cfif>
		<cfif isDefined("session.prsrvURL")>
			<cfset temp=structDelete(session, "prsrvURL")>
		</cfif>
		
		<!--- check the arguments.urlVar has decent length and that the server address matches --->
		<cfif IsDefined("arguments.urlVar") and listLen(arguments.urlVar, "/") gte 2 and listGetAt(arguments.urlVar, 2, "/") eq serverAddy>
				
				<cfif IsStruct(arguments.formVars) AND NOT structIsEmpty(arguments.formVars)>
					<cfhttp url="#arguments.urlVar#&#session.urltoken#" redirect="no" method="post" useragent="#cgi.user_agent#">
							<cfloop item="key" collection="#arguments.formVars#">
								<cfhttpparam name="#key#" type="FORMFIELD" value="#arguments.formVars[key]#">
							</cfloop>
					</cfhttp>
					
					<!--- if form was submitted, go for a wander to the redirected page --->
					<cfif structKeyExists(cfhttp.responseHeader, "Location")>
						<cflocation url="#cfhttp.responseHeader.location#" addtoken="no">
					</cfif>
				</cfif>
				<!--- form wasn't submitted so go to plain old vanilla URL --->
				<cflocation url="#arguments.urlVar#" addtoken="No">
		
			<!--- END check the arguments.urlVar has decent length and that the server address matches --->		
		</cfif>
		
		
	</cffunction>
</cfcomponent>