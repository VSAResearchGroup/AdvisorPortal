<!--- Edit Department Controller --->
<!--- Karan Kalra, September 2016 --->
<cfif !IsUserInRole("editor") >
	<cflocation url="..">
</cfif>

<cfset messageBean=createObject('#this.mappings['cfcMapping']#.messageBean').init()>

<!--- Do basic validation --->
<cfif !IsNumeric("#URLDecode(url.department)#")>
	<cflocation url="..">
</cfif>

<!--- Prepare basic contents of the page --->
<cfquery name="qEditGetDepartment">
	SELECT id, department_name, see_also, dept_intro, abv_title, abv_title2, use_catalog
	FROM DEPARTMENTS
	WHERE id = <cfqueryparam value="#URLDecode(url.department)#" cfsqltype="cf_sql_integer">
</cfquery>

<!--- Back out if the department ID is not valid --->
<cfif !qEditGetDepartment.RecordCount>
	<cflocation url="..">
</cfif>

<!--- Set defaults for form data --->
<cfset status1="no">
<cfset status2="no">
<cfif qEditGetDepartment.use_catalog>
	<cfset status1="yes">
<cfelse>
	<cfset status2="yes">
</cfif>

<cfset checked="no">
<cfif qEditGetDepartment.RecordCount>
	<cfset checked="yes">
</cfif>

<!--- Define "Update department information" button behavior --->
<cfif isDefined("form.updateDepartmentInfoButton")>
	
	<!--- Evaluate update for department name --->
	<cfif isDefined("form.departmentName") && !messageBean.hasErrors()>
		<cfset departmentName=canonicalize(trim(form.departmentName), true, true)>
		
		<cfif departmentName NEQ qEditGetDepartment.department_name>
			
			<!--- Update department name --->
			<cfif len(trim(departmentName))>
				<cfquery>
					UPDATE DEPARTMENTS
					SET department_name = <cfqueryparam value="#departmentName#" cfsqltype="cf_sql_varchar">
					WHERE id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
				</cfquery>
			<cfelse>
				<cfset messageBean.addError('A department name is required.', 'departmentName')>
			</cfif>
		</cfif>
	</cfif>
	
	<!--- Evaluate update for see also --->
	<cfif isDefined("form.seeMore") && !messageBean.hasErrors()>
		<cfset seeAlso=canonicalize(trim(form.seeAlso), true, true)>
		
		<cfif seeAlso NEQ qEditGetDepartment.see_also>
			
			<!--- Update see also --->
			<cfif len(trim(seeAlso))>
				<cfquery>
					UPDATE DEPARTMENTS
					SET see_also = <cfqueryparam value="#seeAlso#" cfsqltype="cf_sql_varchar">
					WHERE id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
				</cfquery>
			<cfelse>
				<cfset messageBean.addError('A see also is required.', 'seeAlso')>
			</cfif>
		</cfif>
	</cfif>
	
	<!--- Evaluate update for dept intro --->
	<cfif isDefined("form.deptIntro") && !messageBean.hasErrors()>
		<cfset deptIntro=canonicalize(trim(form.deptIntro), true, true)>
		
		<cfif deptIntro NEQ qEditGetDepartment.dept_intro>
			
			<!--- Update dept intro --->
			<cfif len(trim(deptIntro))>
				<cfquery>
					UPDATE DEPARTMENTS
					SET dept_intro = <cfqueryparam value="#deptIntro#" cfsqltype="cf_sql_varchar">
					WHERE id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
				</cfquery>
			<cfelse>
				<cfset messageBean.addError('A dept intro is required.', 'deptIntro')>
			</cfif>
		</cfif>
	</cfif>
	
	<!--- Evaluate update for course department --->
	<cfif isDefined("form.courseDepartment") && !messageBean.hasErrors()>
		<cfif form.courseDepartment NEQ qEditGetDepartment.departments_id>
			<cfquery>
				UPDATE COURSES
				SET departments_id = <cfqueryparam value="#form.courseDepartment#" cfsqltype="cf_sql_integer">
				WHERE id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
			</cfquery>
		</cfif>
	</cfif>
	
	<!--- Evaluate update for availability status --->
	<cfif isDefined("form.courseAvailability") && !messageBean.hasErrors()>
		<cfif (status1 EQ "yes" && form.courseAvailability NEQ 1) || (status2 EQ "yes" && form.courseAvailability NEQ 2)>
			<!--- Update availability --->
			<cfquery>
				UPDATE COURSES
				<cfif form.courseAvailability EQ 1>
					SET use_catalog = 1
				<cfelse>
					SET use_catalog = 0
				</cfif>
				WHERE id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
			</cfquery>
		</cfif>
	</cfif>
	
	<!--- Evaluate update for course min credit --->
	<cfif isDefined("form.courseMinCredit") && !messageBean.hasErrors()>
		
		<!--- Do basic validation --->
		<cfif form.courseMinCredit NEQ qEditGetDepartment.min_credit>
			<cfif len(trim(form.courseMinCredit)) && !IsValid("numeric", trim(form.courseMinCredit))>
				<cfset messageBean.addError('Minimum variable credits must be a decimal number.', 'courseMinCredit')>
			<cfelseif len(trim(form.courseMinCredit)) && !(trim(form.courseMinCredit) GT 0)>
				<cfset messageBean.addError('The number of minimum variable credits must be a positive number.', 'courseMinCredit')>
			<cfelseif len(trim(form.courseMinCredit)) && trim(form.courseMinCredit) GTE trim(form.courseMaxCredit)>
				<cfset messageBean.addError('Minimum variable credits cannot be equal or greater than maximum credit.', 'courseMinCredit')>
			</cfif>

			<!--- Update min credit, allowing for nulls --->
			<cfif !messageBean.hasErrors()>
				<cfquery>
					UPDATE COURSES
					<cfif len(trim(courseMinCredit))>
						SET min_credit = <cfqueryparam value="#form.courseMinCredit#" cfsqltype="cf_sql_decimal">
					<cfelse>
						SET min_credit = NULL
					</cfif>
					WHERE id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
				</cfquery>
			</cfif>
		</cfif>
	</cfif>
	
	<!--- Evaluate update for course max credit --->
	<cfif isDefined("form.courseMaxCredit") && !messageBean.hasErrors()>
		
		<!--- Do basic validation --->
		<cfif form.courseMaxCredit NEQ qEditGetDepartment.max_credit>
			<cfif !len(trim(form.courseMaxCredit))>
				<cfset messageBean.addError('The maximum number of credits is required.', 'courseMaxCredit')>
			<cfelseif !IsValid("numeric", trim(form.courseMaxCredit))>
				<cfset messageBean.addError('Credits must be a decimal number.', 'courseMaxCredit')>
			<cfelseif !(trim(form.courseMaxCredit) GT 0)>
				<cfset messageBean.addError('The number of credits must be a positive number.', 'courseMaxCredit')>
			<cfelseif isDefined("form.courseMinCredit") && trim(form.courseMinCredit) GTE trim(form.courseMaxCredit)>
				<cfset messageBean.addError('Maximum credit cannot be equal or less than minimum credit.', 'courseMaxCredit')>
			</cfif>
		
			<!--- Update max credit --->
			<cfif !messageBean.hasErrors()>
				<cfquery>
					UPDATE COURSES
					SET max_credit = <cfqueryparam value="#form.courseMaxCredit#" cfsqltype="cf_sql_decimal">
					WHERE id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
				</cfquery>
			</cfif>
		</cfif>
	</cfif>
	
	<!--- Refresh page if there were no errors --->
	<cfif !messageBean.hasErrors()>
		<cflocation url="?course=#URLEncodedFormat(qEditGetDepartment.id)#">
	</cfif>
</cfif>

<!--- Define "Update course information" button behavior --->
<cfif isDefined("form.updateCourseDescButton")>
	<cfset courseDescription=canonicalize(trim(form.courseDescription), true, true)>
		
	<cfif courseDescription NEQ qEditGetDepartment.course_description>
		
		<!--- Update course description notes --->
		<cfquery>
			UPDATE COURSES
			<cfif len(trim(courseDescription))>
				SET course_description = <cfqueryparam value="#courseDescription#" cfsqltype="cf_sql_varchar">
			<cfelse>
				SET course_description = NULL
			</cfif>
			WHERE id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cfif>
	
	<!--- Refresh page if there were no errors --->
	<cfif !messageBean.hasErrors()>
		<cflocation url="?course=#URLEncodedFormat(qEditGetDepartment.id)#">
	</cfif>
</cfif>

<!--- Define "Remove" button behavior for placement scores --->
<cfif isDefined("form.removePlacementButton")>
	<cfquery>
		DELETE
		FROM PREREQUISITE_PLACEMENTS
		WHERE courses_id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
	</cfquery>
	
	<!--- Refresh page --->
	<cflocation url="?course=#URLEncodedFormat(qEditGetDepartment.id)#">
</cfif>

<!--- Define "Add" button behavior for placement scores--->
<cfif isDefined("form.addPlacementButton")>
	
	<!--- Do basic validation --->
	<cfif !len(trim(form.coursePlacement))>
		<cfset messageBean.addError('A description of placement criteria is required.', 'coursePlacement')>
	</cfif>
	
	<!--- Add placement record --->
	<cfif !messageBean.hasErrors()>
		<cfset coursePlacement=canonicalize(trim(form.coursePlacement), true, true)>
		
		<cfquery>
			INSERT INTO PREREQUISITE_PLACEMENTS (
				courses_id, placement
			) VALUES (
				<cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">,
				<cfqueryparam value="#coursePlacement#" cfsqltype="cf_sql_varchar">
			)
		</cfquery>
	</cfif>
	
	<!--- Refresh page if there were no errors --->
	<cfif !messageBean.hasErrors()>
		<cflocation url="?course=#URLEncodedFormat(qEditGetDepartment.id)#">
	</cfif>
</cfif>

<!--- Define "Remove" button behavior for prerequisites --->
<cfif isDefined("form.removePrerequisiteButton")>
	<cfquery>
		DELETE
		FROM PREREQUISITES
		WHERE id = <cfqueryparam value="#form.prerequisiteId#" cfsqltype="cf_sql_integer">
	</cfquery>
	
	<!--- Refresh page --->
	<cflocation url="?course=#URLEncodedFormat(qEditGetDepartment.id)#">
</cfif>

<!--- Define "Add" button behavior for prerequisites --->
<cfif isDefined("form.addPrerequisiteButton")>
	
	<!--- Perform simple validation on form fields --->
	<cfif !len(trim(form.coursePrerequisite))>
		<cfset messageBean.addError('A prerequisite course number is required.', 'coursePrerequisite')>
	</cfif>
	
	<!--- Stop here if errors were detected --->
	<cfif messageBean.hasErrors()>
		<cfinclude template="model/editDepartment.cfm">
		<cfreturn>
	</cfif>
	
	<!--- Find the prerequisite course, if exists --->
	<cfquery name="qEditGetPrerequisiteCourse">
		SELECT id, course_number
		FROM COURSES
		WHERE course_number = <cfqueryparam value="#trim(form.coursePrerequisite)#" cfsqltype="cf_sql_varchar">
	</cfquery>
	
	<cfif !qEditGetPrerequisiteCourse.RecordCount>
		<cfset messageBean.addError('The prerequisite course could not be found.', 'coursePrerequisite')>
	</cfif>
	
	<!--- Stop here if errors were detected --->
	<cfif messageBean.hasErrors()>
		<cfinclude template="model/editDepartment.cfm">
		<cfreturn>
	</cfif>
	
	<!--- Ensure no duplicates in an existing group --->
	<cfif groupId NEQ 0>
		<cfquery name="qEditCheckPrerequisite" dbtype="query">
			SELECT id
			FROM qEditGetPrerequisites
			WHERE courses_id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
			AND group_id = <cfqueryparam value="#form.groupId#" cfsqltype="cf_sql_integer">
			AND courses_prerequisite_id = <cfqueryparam value="#qEditGetPrerequisiteCourse.id#" cfsqltype="cf_sql_integer">
		</cfquery>
		
		<cfif qEditCheckPrerequisite.RecordCount>
			<cfset messageBean.addError('This course is already a prerequisite for this group.', 'coursePrerequisite')>
		</cfif>
		
		<!--- Stop here if errors were detected --->
		<cfif messageBean.hasErrors()>
			<cfinclude template="model/editDepartment.cfm">
			<cfreturn>
		</cfif>
	</cfif>
	
	<!--- Looks good, so add prerequisite course --->
	<cfif groupId EQ 0>
		
		<!--- Prerequisite is part of a new group, so find the last group number --->
		<cfquery name="qEditGetLastGroup" dbtype="query" maxrows="1">
			SELECT group_id
			FROM qEditGetPrerequisites
			GROUP BY group_id
			ORDER BY group_id DESC
		</cfquery>
		
		<cfquery>
			INSERT INTO PREREQUISITES (
				courses_id, group_id, courses_prerequisite_id
			) VALUES (
				<cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">,
				<cfif qEditGetLastGroup.RecordCount>
					<!--- Increment the last group id --->
					<cfqueryparam value="#qEditGetLastGroup.group_id + 1#" cfsqltype="cf_sql_integer">,
				<cfelse>
					<!--- Create a new group id at value 1 --->
					1,
				</cfif>
				<cfqueryparam value="#qEditGetPrerequisiteCourse.id#" cfsqltype="cf_sql_integer">
			)
		</cfquery>
	<cfelse>
		
		<!--- Add prerequisite to existing group --->
		<cfquery>
			INSERT INTO PREREQUISITES (
				courses_id, group_id, courses_prerequisite_id
			) VALUES (
				<cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">,
				<cfqueryparam value="#form.groupId#" cfsqltype="cf_sql_integer">,
				<cfqueryparam value="#qEditGetPrerequisiteCourse.id#" cfsqltype="cf_sql_integer">
			)
		</cfquery>
	</cfif>
	
	<!--- Refresh page if there were no errors --->
	<cfif !messageBean.hasErrors()>
		<cflocation url="?course=#URLEncodedFormat(qEditGetDepartment.id)#">
	</cfif>
</cfif>

<!--- Define "Update enrollment" button behavior --->
<cfif isDefined("form.updateEnrollmentButton")>
	<cfif qEditGetPermission.RecordCount && !isDefined("courseEnrollment")>
		<cfquery>
			DELETE
			FROM PREREQUISITE_PERMISSIONS
			WHERE courses_id = <cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
		</cfquery>
	<cfelseif !qEditGetPermission.RecordCount && isDefined("courseEnrollment")>
		<cfquery>
			INSERT INTO PREREQUISITE_PERMISSIONS (
				courses_id
			) VALUES (
				<cfqueryparam value="#qEditGetDepartment.id#" cfsqltype="cf_sql_integer">
			)
		</cfquery>
	</cfif>
	
	<!--- Refresh page --->
	<cflocation url="?course=#URLEncodedFormat(qEditGetDepartment.id)#">
</cfif>

<!--- Load page --->
<cfinclude template="model/editDepartment.cfm">
<cfreturn>