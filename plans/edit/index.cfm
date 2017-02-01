<!--- Edit Plan Controller --->
<!--- Thomas Dye, September 2016 --->
<cfif !(isDefined("session.studentId") || IsUserInRole("student"))>
	<cflocation url="..">
</cfif>

<cfset messageBean=createObject('#this.mappings['cfcMapping']#.messageBean').init()>

<!--- Do basic validation --->
<cfif !isDefined("url.plan") || !IsNumeric("#URLDecode(url.plan)#")>
	<cflocation url="..">
</cfif>

<!--- Prepare basic contents of the page --->
<cfquery name="qEditGetPlan">
	SELECT p.id, p.plan_name, s.degrees_id, d.degree_name, d.colleges_id, c.college_name, c.college_city, d.degree_type
	FROM PLANS p, PLAN_SELECTEDDEGREES s, DEGREES d, COLLEGES c
	WHERE p.id = s.plans_id
	AND d.id = s.degrees_id
	AND c.id = d.colleges_id
	AND p.id = <cfqueryparam value="#url.plan#" cfsqltype="cf_sql_integer">
	AND p.students_accounts_id = <cfqueryparam value="#session.accountId#" cfsqltype="cf_sql_integer">
</cfquery>

<!--- Back out if the plan ID is not valid --->
<cfif !qEditGetPlan.RecordCount>
	<cflocation url="..">
</cfif>

<!--- Define the "Save" button action --->
<cfif isDefined("form.saveButton")>
	<cfset planName=canonicalize(trim(form.planName), true, true)>
		
	<cfif planName NEQ qEditGetPlan.plan_name>
		
		<!--- Update college name --->
		<cfif len(trim(planName))>
			<cfquery>
				UPDATE PLANS
				SET plan_name = <cfqueryparam value="#planName#" cfsqltype="cf_sql_varchar">
				WHERE id = <cfqueryparam value="#qEditGetPlan.id#" cfsqltype="cf_sql_integer">
			</cfquery>
		<cfelse>
			<cfset messageBean.addError('A plan name is required.', 'planName')>
		</cfif>
	<cfelse>
		<!--- Exit edit screen --->
		<cflocation url="..">
	</cfif>
	
	<!--- Refresh if there were no errors --->
	<cfif !messageBean.hasErrors()>
		<cflocation url="./?plan=#URLEncodedFormat(qEditGetPlan.id)#">
	</cfif>
</cfif>

<!--- Display default contents of page --->
<cfquery name="qEditGetSelectDegreeCategories">
	SELECT id, category
	FROM DEGREE_CATEGORIES
	WHERE degrees_id = <cfqueryparam value="#qEditGetPlan.degrees_id#" cfsqltype="cf_sql_integer">
</cfquery>

<!--- Get all courses saved for this plan --->
<cfquery name="qEditGetCourses">
	SELECT c.course_number, c.title, sc.credit, sc.id AS sc_id,
		c.id AS c_id, c.departments_id, sc.degree_categories_id, dcat.category,
		gc.courses_id AS gc_id, cc.id AS cc_id, cc.credit AS cc_credit,
		c.min_credit, c.max_credit
	FROM PLAN_SELECTEDCOURSES sc
	JOIN COURSES c
	ON c.id = sc.courses_id
	JOIN DEGREE_CATEGORIES dcat
	ON dcat.id = sc.degree_categories_id
	LEFT JOIN (SELECT id, credit
		FROM STUDENTS_COMPLETEDCOURSES
		WHERE students_accounts_id = <cfqueryparam value="#session.accountId#" cfsqltype="cf_sql_integer">) AS cc
	ON sc.completedcourses_id = cc.id
	LEFT JOIN DEGREE_GRADUATION_COURSES gc
	ON c.id = gc.courses_id
	WHERE sc.plans_id = <cfqueryparam value="#qEditGetPlan.id#" cfsqltype="cf_sql_integer">
	ORDER BY c.course_number
</cfquery>

<cfquery dbtype="query" name="qEditGetCategories">
	SELECT DISTINCT degree_categories_id, category
	FROM qEditGetCourses
	ORDER BY degree_categories_id
</cfquery>

<!--- Define "Update" button behavior --->
<cfif isDefined("form.updateCourseButton")>

	<!--- Process credit select boxes --->
	<cfif isDefined("form.courseCredit")>
		<cfset aCredit=listToArray(trim(form.courseCredit), ",", false, false)>
		<cfset aCreditId=listToArray(trim(form.creditId), ",", false, false)>
		
		<cfloop from="1" to="#arrayLen(aCredit)#" index="row">
			<cfif aCredit[row]>
				<cfquery>
					UPDATE PLAN_SELECTEDCOURSES
					SET credit = <cfqueryparam value="#aCredit[row]#" cfsqltype="cf_sql_decimal">
					WHERE id = <cfqueryparam value="#aCreditId[row]#" cfsqltype="cf_sql_integer">
				</cfquery>
			</cfif>
		</cfloop>
	</cfif>
	
	<!--- Process status select boxes --->
	<cfif isDefined("form.status")>
		<cfset aStatus=listToArray(trim(form.status), ",", false, false)>
		<cfset aStatusId=listToArray(trim(form.statusId), ",", false, false)>
		
		<cfloop from="1" to="#arrayLen(aStatus)#" index="row">
			<cfif aStatus[row]>
				<cfquery>
					UPDATE PLAN_SELECTEDCOURSES
					SET completedcourses_id = <cfqueryparam value="#aStatus[row]#" cfsqltype="cf_sql_integer">
					WHERE id = <cfqueryparam value="#aStatusId[row]#" cfsqltype="cf_sql_integer">
				</cfquery>
			</cfif>
		</cfloop>
	</cfif>
	
	<!--- Process remove checkboxes last --->
	<cfif isDefined("form.remove")>
		<cfset aRemove=listToArray(trim(form.remove), ",", false, false)>

		<!--- Build a singe query to delete one to many rows --->
		<cfquery>
			<cfloop from="1" to="#arrayLen(aRemove)#" index="row">
				DELETE
				FROM PLAN_SELECTEDCOURSES
				WHERE id = <cfqueryparam value="#aRemove[row]#" cfsqltype="cf_sql_integer">
			</cfloop>
		</cfquery>
	</cfif>
	
	<!--- Refresh page --->
	<cflocation url="./?plan=#URLEncodedFormat(qEditGetPlan.id)#">
</cfif>

<!--- Define "Add" button behavior --->
<cfif isDefined("form.addCourseButton")>
	
	<!--- Perform simple validation on form fields --->
	<cfif !len(trim(form.courseNumber))>
		<cfset messageBean.addError('A course number is required.', 'courseNumber')>
	</cfif>
	
	<cfif form.category EQ 0>
		<cfset messageBean.addError('Please select a category.', 'category')>
	</cfif>
	
	<!--- Stop here if errors were detected --->
	<cfif messageBean.hasErrors()>
		<cfinclude template="model/editPlan.cfm">
		<cfreturn>
	</cfif>
	
	<!--- Find the course, if exists --->
	<cfquery name="qEditGetCourse">
		SELECT id, min_credit, max_credit
		FROM COURSES
		WHERE use_catalog = 1
		AND course_number = <cfqueryparam value="#trim(form.courseNumber)#" cfsqltype="cf_sql_varchar">
	</cfquery>
	
	<cfif !qEditGetCourse.RecordCount>
		<cfset messageBean.addError('The course could not be found.', 'courseNumber')>
	</cfif>
	
	<!--- Stop here if errors were detected --->
	<cfif messageBean.hasErrors()>
		<cfinclude template="model/editPlan.cfm">
		<cfreturn>
	</cfif>
	
	<!--- Looks good, so add course to plan --->
	<cfquery>
		INSERT INTO PLAN_SELECTEDCOURSES (
			plans_id, courses_id, categories_id, credit
		) VALUES (
			<cfqueryparam value="#qEditGetPlan.id#" cfsqltype="cf_sql_integer">,
			<cfqueryparam value="#qEditGetCourse.id#" cfsqltype="cf_sql_integer">,
			<cfqueryparam value="#form.category#" cfsqltype="cf_sql_integer">,
			<cfif len(qEditGetCourse.min_credit)>
				NULL
			<cfelse>
				<cfqueryparam value="#qEditGetCourse.max_credit#" cfsqltype="cf_sql_decimal">
			</cfif>
		)
	</cfquery>
	
	<!--- Refresh the page --->
	<cflocation url="./?plan=#URLEncodedFormat(qEditGetPlan.id)#">
</cfif>

<!--- Load page --->
<cfinclude template="model/editPlan.cfm">
<cfreturn>