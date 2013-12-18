# Content shown in the middle of the page with the list of links generated
template =
  "<div class='result-set'>
     <div class='result-title'>
       <h5 class='label-title'>Results {{title}}:</h5>
     </div>
     <div class='result-links'>
       {{#urls}}
         <div class='result-link-wrapper'>
         <div class='result-link {{urlClass}}'>
           <a href='#' data-url='{{url}}' class='api-link-post tooltipped label' title='Send \"{{name}}\" using a POST request'>
             post
           </a>
           <span class='method-name'>{{name}}</span>
           <a class='api-link' href='{{url}}'>{{urlName}}</a>
         </div>
         </div>
       {{/urls}}
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
       Your server does not allow <strong>cross-domain requests</strong>. By default BigBlueButton and Mconf-Live <strong>do not</strong> allow cross-domain
       requests, so you have to enable it to test this request via POST. Check our <a href=\"https://github.com/mconf/api-mate/tree/master#allow-cross-domain-requests-for-post-requests\">README</a>
       for instructions on how to do it.
     </li>
     <li>
       This API method cannot be accessed via POST.
     </li>
     <li>
       Your server is down or malfunctioning. Log into it and check if everything is OK with <code>bbb-conf --check</code>.
     </li>
   <ul>"

post_template_file =
  ""

post_template_url =
  "<?xml version='1.0' encoding='UTF-8'?>
     <modules>
       <module name='presentation'>
         <document url='{{url}}' />
       </module>
     </modules>"

class ApiMate
  constructor: ->
    @updatedTimer = null

  configure: ->
    # set random values in some inputs
    @setInitialValues()

    # when the meeting name is changed, change the id also
    $("#input-id").on "keyup", -> $("#input-name").val $(this).val()

    # triggers to generate the links
    $("input, select, textarea", "#config-fields").on "change keyup", (e) =>
      @generateUrls()
    $("input, select, textarea", "#config-server").on "change keyup", (e) =>
      @generateUrls()

    # expand or collapse links
    $("#view-type-input").on "click", =>
      selected = !$("#view-type-input").hasClass("active")
      @expandLinks(selected)

    $("input[name='document']").on "change", ->
      val = $("input[name='document']:checked").attr('value')
      if val == 'file'
        $("#pre-upload-file").show()
        $("#pre-upload-url").hide()
      else if val == 'url'
        $("#pre-upload-url").show()
        $("#pre-upload-file").hide()

    # button to clear the inputs
    $(".api-mate-clearall").on "click", (e) =>
      @clearAllFields()
      @generateUrls()

    @generateUrls()

  setInitialValues: ->
    vbridge = "7" + pad(Math.floor(Math.random() * 10000 - 1).toString(), 4)
    $("#input-voice-bridge").val(vbridge)
    name = "random-" + Math.floor(Math.random() * 10000000).toString()
    $("#input-name").val(name)
    $("#input-id").val(name)
    user = "User " + Math.floor(Math.random() * 10000000).toString()
    $("#input-fullname").val(user)

  # Add a div with all links and a close button to the global
  # results container
  addUrlsToPage: (urls) ->
    placeholder = $("#api-mate-results")
    urls = _.map urls, (url, key) ->
      u = {name: key, url: url, urlName: url}
      if key.match(/recordings/i)
        u.urlClass = "url-recordings"
      else if key.match(/from mobile/i)
        u.urlClass = "url-from-mobile"
      else if key.match(/mobile:/i)
        u.urlClass = "url-mobile-api"
      else if key.match(/custom call/i)
        u.urlClass = "url-custom-call"
      else
        u.urlClass = "url-standard"
      u
    opts =
      title: new Date().toTimeString()
      urls: urls
    html = Mustache.to_html(template, opts)
    $(placeholder).html(html)
    @expandLinks($("#view-type-input").hasClass("active"))

    # mark the items as updated
    placeholder.addClass("updated")
    clearTimeout(@updatedTimer)
    @updatedTimer = setTimeout( ->
      placeholder.removeClass("updated")
    , 300)

  getApi: ->
    server = {}
    server.url = $("#input-custom-server-url").val()
    server.salt = $("#input-custom-server-salt").val()
    server.mobileSalt = $("#input-custom-server-mobile-salt").val()

    # Do some cleanups on the server URL to that pasted URLs in various formats work better
    # Remove trailing /, and add /api on the end if missing.
    server.url = server.url.replace(/(\/api)?\/?$/, '/api')
    server.name = server.url

    new BigBlueButtonApi(server.url, server.salt, server.mobileSalt)

  # Generate urls for all BBB calls and add them to the page.
  generateUrls: () ->

    # set ALL the parameters
    params = {}
    params.name = $("#input-name").val() if isFilled("#input-name")
    params.meetingID = $("#input-id").val() if isFilled("#input-id")
    params.moderatorPW = $("#input-moderator-password").val() if isFilled("#input-moderator-password")
    params.attendeePW = $("#input-attendee-password").val() if isFilled("#input-attendee-password")
    params.welcome = $("#input-welcome").val() if isFilled("#input-welcome")
    params.voiceBridge = $("#input-voice-bridge").val() if isFilled("#input-voice-bridge")
    params.dialNumber = $("#input-dial-number").val() if isFilled("#input-dial-number")
    params.webVoice = $("#input-web-voice").val() if isFilled("#input-web-voice")
    params.logoutURL = $("#input-logout-url").val() if isFilled("#input-logout-url")
    params.maxParticipants = $("#input-max-participants").val() if isFilled("#input-max-participants")
    params.duration = $("#input-duration").val() if isFilled("#input-duration")
    params.record = $("#input-record").is(":checked")
    params.fullName = $("#input-fullname").val() if isFilled("#input-fullname")
    params.userID = $("#input-user-id").val() if isFilled("#input-user-id")
    params.createTime = $("#input-create-time").val() if isFilled("#input-create-time")
    params.webVoiceConf = $("#input-web-voice-conf").val() if isFilled("#input-web-voice-conf")
    params.recordID = $("#input-id").val() if isFilled("#input-id")
    params.publish = $("#input-publish").is(":checked")
    if isFilled("#input-meta")
      lines = $("#input-meta").val().replace(/\r\n/g, "\n").split("\n")
      for line in lines
        separator = line.indexOf("=")
        if separator >= 0
          paramName = line.substring(0, separator)
          paramValue = line.substring(separator+1, line.length)
          params["meta_" + paramName] = paramValue
    if isFilled("#input-custom")
      lines = $("#input-custom").val().replace(/\r\n/g, "\n").split("\n")
      for line in lines
        separator = line.indexOf("=")
        if separator >= 0
          paramName = line.substring(0, separator)
          paramValue = line.substring(separator+1, line.length)
          params["custom_" + paramName] = paramValue

    customCalls = null
    if isFilled("#input-custom-calls")
      lines = $("#input-custom-calls").val().replace(/\r\n/g, "\n").split("\n")
      customCalls = lines

    # get the list of links and add them to the page
    api = @getApi()
    urls = api.getUrls(params, customCalls)
    @addUrlsToPage(urls)
    @bindPostRequests()
    bindTooltips()

  # Empty all inputs inside #config-fields
  clearAllFields: ->
    $("#config-fields input, #config-fields textarea").each -> $(this).val("")
    $("#config-fields input[type=checkbox]").each -> $(this).attr("checked", null)

  # Expand (if `selected` is true) or collapse the links.
  expandLinks: (selected) ->
    if selected
      $("#api-mate-results .result-link").addClass('expanded')
    else
      $("#api-mate-results .result-link").removeClass('expanded')

  bindPostRequests: ->
    $(document).on 'click', 'a.api-link-post', (e) ->
      $target = $(this)
      href = $target.attr('data-url')

      $('.api-link-post').addClass('disabled')
      $.ajax
        url: href
        type: "POST"
        crossDomain: true
        contentType:"application/xml; charset=utf-8"
        dataType: "xml"
        complete: (jqxhr, status) ->
          # TODO: show the result properly formatted and highlighted in the modal

          console.log jqxhr

          if jqxhr.status is 200
            $('#post-response-modal .modal-header').removeClass('alert-danger')
            $('#post-response-modal .modal-header').addClass('alert-success')
            html = Mustache.to_html(postSuccessTemplate, { response: jqxhr.responseText })
            $('#post-response-modal .modal-body').html(html)
          else
            $('#post-response-modal .modal-header h4').text('Ooops!')
            $('#post-response-modal .modal-header').addClass('alert-danger')
            $('#post-response-modal .modal-header').removeClass('alert-success')
            opts =
              status: jqxhr.status
              statusText: jqxhr.statusText
            opts['response'] = jqxhr.responseText unless _.isEmpty(jqxhr.responseText)
            html = Mustache.to_html(postErrorTemplate, opts)
            $('#post-response-modal .modal-body').html(html)

          $('#post-response-modal').modal({ show: true })
          $('.api-link-post').removeClass('disabled')

      e.preventDefault()
      false

# Check if an input text field has a valid value (not empty).
isFilled = (field) ->
  value = $(field).val()
  value? and value.trim() != ""

pad = (num, size) ->
  s = "0000" + num
  s.substr(s.length-size)

bindTooltips = ->
  defaultOptions =
    # append tooltips to the <body> element to prevent problems with tooltips inside
    # elements with `overflow:hidden` set, for example.
    container: 'body'
    placement: 'top'

  $('.tooltipped').tooltip(defaultOptions)

$ ->
  apiMate = new ApiMate()
  apiMate.configure()
