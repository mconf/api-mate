# Mustache.js templates that are used as default by ApiMate if they
# are not set by the user.

# Content shown in the middle of the page with the list of links generated
resultsTemplate =
  "<div class='api-mate-results'>
     <div class='api-mate-links'>
       {{#urls}}
         <div class='api-mate-link-wrapper'>
           <div class='api-mate-link {{urlClass}}'>
             <a class='label' href='{{url}}' target='_blank'>GET</a>
             <a href='#' data-url='{{url}}' class='tooltipped label'
                title='Send \"{{name}}\" using a POST request'
                data-api-mate-post='{{name}}'>POST</a>
             <span class='api-mate-method-name'>{{description}}</span>
             <a href='{{url}}' target='_blank'>{{url}}</a>
           </div>
         </div>
       {{/urls}}
     </div>
     <div class='api-mate-result-title'>
       <h5 class='label-title'>Results {{title}}:</h5>
     </div>
   </div>"

# Content of the dialog when a POST request succeeds
postSuccessTemplate = "<pre>{{response}}</pre>"

# Content of the dialog when a POST request fails
postErrorTemplate =
  "<p>Server responded with status: <code>{{status}}: {{statusText}}</code>.</p>
   {{#response}}
     <p>Content:</p>
     <pre>{{response}}</pre>
   {{/response}}
   {{^response}}
     <p>Content: <code>-- no content --</code></p>
   {{/response}}
   <p>If you don't know the reason for this error, check these possibilities:</p>
   <ul>
     <li>
       Your server does not allow <strong>cross-domain requests</strong>.
       By default BigBlueButton and Mconf-Live <strong>do not</strong> allow cross-domain
       requests, so you have to enable it to test this request via POST. Check our
       <a href=\"https://github.com/mconf/api-mate/tree/master#allow-cross-domain-requests\">README</a>
       for instructions on how to do it.
     </li>
     <li>
       This API method cannot be accessed via POST.
     </li>
     <li>
       Your server is down or malfunctioning. Log into it and check if everything is OK with
       <code>bbb-conf --check</code>.
     </li>
   <ul>"

# Body of a POST request to use pre-upload of slides.
preUploadUrl =
  "<?xml version='1.0' encoding='UTF-8'?>
     <modules>
       <module name='presentation'>
         {{#urls}}
           <document url='{{url}}' />
         {{/urls}}
       </module>
     </modules>"
