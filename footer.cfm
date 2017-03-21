<!--- Footer Model --->
<!--- Thomas Dye, August 2016 --->

<cfset path=ListToArray(GetCurrentTemplatePath(), "\") />
<cfif ArrayLen(path) LTE 1>
	<cfset path="/">
<cfelse>
	<cfset folderName=path[DecrementValue(ArrayLen(path))] />
	<cfset path="/#folderName#/">
</cfif>

	</div>
	<!-- //CONTENT -->
</main>
	
	<div id=footer-wrap>
    	<!-- FOOTER -->
    	<footer id=footer role=contentinfo>
	        <div id=bookmark-top><a href="#top" title="Back to Top" aria-label="Back to Top">&uarr;</a>
	        </div>
			<div class="footerblock block1">
				
			</div>

			<div class="footerblock block2">	
				<p>Use of the Everett Community College logo and branding is for demonstration purposes only and this website not affiliated with Everett Community College in any way.</p>
			</div>
			
			<div class="footerblock block3">
	            
            </div>
	        <div id=footer-final>
	        
	        </div>

	    </footer>
    	<!-- //FOOTER -->
    </div>

</body>
</html>