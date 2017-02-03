<!--- Dashboard Controller --->
<!--- Thomas Dye, September 2016, February 2017 --->
<cfif !(isDefined("session.studentId") || IsUserInRole("student")) >
	<cflocation url="..">
</cfif>

<cfset messageBean=createObject('#this.mappings['cfcMapping']#.messageBean').init()>

<!--- Prepare basic contents of the page --->
<cfquery name="qDashboardGetActivePlan">
	SELECT pla.id AS plans_id, pla.plan_name, deg.id AS degrees_id, deg.degree_name, deg.degree_type, col.id AS colleges_id, col.college_name, col.college_city
	FROM DEGREES deg, COLLEGES col, PLANS pla
	WHERE pla.id = (SELECT plans_id
		FROM PLAN_ACTIVEPLANS
		WHERE students_accounts_id = <cfqueryparam value="#session.accountId#" cfsqltype="cf_sql_integer">)
	AND deg.id = (SELECT degrees_id
		FROM PLAN_SELECTEDDEGREES
		WHERE plans_id = (SELECT plans_id
			FROM PLAN_ACTIVEPLANS
			WHERE students_accounts_id = <cfqueryparam value="#session.accountId#" cfsqltype="cf_sql_integer">))
	AND col.id = (SELECT colleges_id
		FROM DEGREES
		WHERE id = (SELECT degrees_id
			FROM PLAN_SELECTEDDEGREES
			WHERE plans_id = (SELECT plans_id
				FROM PLAN_ACTIVEPLANS
				WHERE students_accounts_id = <cfqueryparam value="#session.accountId#" cfsqltype="cf_sql_integer">)))
</cfquery>

<!--- Populate arrays to render display output --->
<cfif qDashboardGetActivePlan.RecordCount>
	<!--- Get all courses saved for this plan --->
	<cfquery name="qDashboardGetCourses">
		SELECT planSelectedCourses.id AS sc_id, planSelectedCourses.degree_categories_id, planSelectedCourses.credit,
			courses.id AS c_id, courses.course_number, courses.title, courses.min_credit, courses.max_credit, courses.departments_id,
			degreeCategories.category,
			degreeGraduationCourses.courses_id AS gc_id,
			studentCompletedCourses.id AS cc_id, studentCompletedCourses.credit AS cc_credit
		FROM PLAN_SELECTEDCOURSES planSelectedCourses
			JOIN COURSES courses
			ON planSelectedCourses.courses_id = courses.id
			JOIN DEGREE_CATEGORIES degreeCategories
			ON planSelectedCourses.degree_categories_id = degreeCategories.id
			LEFT JOIN (SELECT courses_id
				FROM DEGREE_GRADUATION_COURSES
				WHERE degrees_id = <cfqueryparam value="#qDashboardGetActivePlan.degrees_id#" cfsqltype="cf_sql_integer">) AS degreeGraduationCourses
			ON planSelectedCourses.courses_id = degreeGraduationCourses.courses_id
			LEFT JOIN (SELECT id, credit
				FROM STUDENTS_COMPLETEDCOURSES
				WHERE students_accounts_id = <cfqueryparam value="#session.accountId#" cfsqltype="cf_sql_integer">) AS studentCompletedCourses
			ON planSelectedCourses.completedcourses_id = studentCompletedCourses.id
		WHERE planSelectedCourses.plans_id = <cfqueryparam value="#qDashboardGetActivePlan.plans_id#" cfsqltype="cf_sql_integer">
		ORDER BY courses.id
	</cfquery>
	
	<cfquery dbtype="query" name="qDashboardGetCategories">
		SELECT DISTINCT degree_categories_id, category
		FROM qDashboardGetCourses
		ORDER BY degree_categories_id
	</cfquery>
</cfif>

<!--- Display page --->
<cfinclude template="model/dashboard.cfm">
<cfreturn>