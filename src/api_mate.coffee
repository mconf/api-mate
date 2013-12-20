# Content shown in the middle of the page with the list of links generated
resultsTemplate =
  "<div class='result-set'>
     <div class='result-title'>
       <h5 class='label-title'>Results {{title}}:</h5>
     </div>
     <div class='result-links'>
       {{#urls}}
         <div class='result-link-wrapper'>
         <div class='result-link {{urlClass}}'>
           <a href='#' data-url='{{url}}' class='api-link-post tooltipped label' title='Send \"{{name}}\" using a POST request' data-api-method='{{name}}', >
             post
           </a>
           <span class='method-name'>{{description}}</span>
           <a class='api-link' href='{{url}}'>{{url}}</a>
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

    # button to clear the inputs
    $(".api-mate-clearall").on "click", (e) =>
      @clearAllFields()
      @generateUrls()

    # generate the links already on setup
    @generateUrls()

    # binding elements
    @bindPostRequests()
    @bindTooltips()

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
    for item in urls
      desc = item.description
      if desc.match(/recordings/i)
        item.urlClass = "url-recordings"
      else if desc.match(/from mobile/i)
        item.urlClass = "url-from-mobile"
      else if desc.match(/mobile:/i)
        item.urlClass = "url-mobile-api"
      else if desc.match(/custom call/i)
        item.urlClass = "url-custom-call"
      else
        item.urlClass = "url-standard"
    opts =
      title: new Date().toTimeString()
      urls: urls
    html = Mustache.to_html(resultsTemplate, opts)
    $(placeholder).html(html)
    @expandLinks($("#view-type-input").hasClass("active"))

    # rebind tooltips for the new elements
    @bindTooltips()

    # mark the items as updated
    placeholder.addClass("updated")
    clearTimeout(@updatedTimer)
    @updatedTimer = setTimeout( ->
      placeholder.removeClass("updated")
    , 300)

  # Returns a BigBlueButtonApi configured with the server set by the user in the inputs.
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
    params.redirectClient = $("#input-redirect-client").val() if isFilled("#input-redirect-client")
    params.clientURL = $("#input-client-url").val() if isFilled("#input-client-url")
    params.configToken = $("#input-config-token").val() if isFilled("#input-config-token")
    params.avatarURL = $("#input-avatar-url").val() if isFilled("#input-avatar-url")
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

    # TODO: apparently BigBlueButton receives these parameters from the URL and not from
    #   the body of the POST request as stated in the docs, need to check it better
    #   see getPostData() as well
    params.configXML = $("#input-config-xml").val()

    # get the list of links and add them to the page
    api = @getApi()
    urls = api.getUrls(params, customCalls)
    @addUrlsToPage(urls)

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

  # Logic for when a button to send a request via POST is clicked.
  bindPostRequests: ->
    _apiMate = this
    $(document).on 'click', 'a.api-link-post', (e) ->
      $target = $(this)
      href = $target.attr('data-url')

      # get the data to be posted for this method
      method = $target.attr('data-api-method')
      data = _apiMate.getPostData(method)

      $('.api-link-post').addClass('disabled')
      $.ajax
        url: href
        type: "POST"
        crossDomain: true
        contentType:"application/xml; charset=utf-8"
        dataType: "xml"
        data: data
        complete: (jqxhr, status) ->
          # TODO: show the result properly formatted and highlighted in the modal

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

  bindTooltips: ->
    defaultOptions =
      container: 'body'
      placement: 'top'
    $('.tooltipped').tooltip(defaultOptions)

  getPostData: (method) ->
    if method is 'create'
      if isFilled("#input-pre-upload-url")
        urls = $("#input-pre-upload-url").val().replace(/\r\n/g, "\n").split("\n")
        urls = _.map(urls, (u) -> { url: u })
      if urls?
        opts = { urls: urls }
        Mustache.to_html(preUploadUrl, opts)
    else if method is 'setConfigXML'
      # TODO: apparently BigBlueButton receives these parameters from the URL and not from
      #   the body of the POST request as stated in the docs, need to check it better
      null
      # if isFilled("#input-config-xml")
      #   api = @getApi()
      #   query  = "meetingID=#{api.encodeForUrl($("#input-id").val())}"
      #   query += "&configXML=#{api.encodeForUrl($("#input-config-xml").val())}"
      #   checksum = api.checksum('setConfigXML', query)
      #   query + "&checksum=" + checksum

# Check if an input text field has a valid value (not empty).
isFilled = (field) ->
  value = $(field).val()
  value? and not _.isEmpty(value.trim())

# Pads a number `num` with zeros up to `size` characters. Returns a string with it.
# Example:
#   pad(123, 5)
#   > '00123'
pad = (num, size) ->
  s = ''
  s += '0' for [0..size-1]
  s += num
  s.substr(s.length-size)

$ ->
  apiMate = new ApiMate()
  apiMate.configure()
