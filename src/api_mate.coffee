updatedTimer = null

template =
  "<div class='result-set'>
     <div class='result-title'>
       <h4 class='label-title'>Results {{title}}:</h4>
     </div>
     <div class='result-links'>
       {{#urls}}
         <div class='result-link-wrapper'>
         <div class='result-link {{urlClass}}'>
           <div class='result-show'>
           </div>
           <a href='' action='{{url}}' class='result-form tooltipped' title='POST request to {{name}}' data-original-title='POST request to {{name}}'>
              <i class='icon-upload'></i>
           </a>
           <span class='method-name'>{{name}}</span>
           <a class='api-link' href='{{url}}'>{{urlName}}</a>
         </div>
         </div>
       {{/urls}}
     </div>
   </div>"

post_template_file =
  ""

post_template_url =
  "<?xml version='1.0' encoding='UTF-8'?>
     <modules>
       <module name='presentation'>
         <document url='{{url}}' />
       </module>
     </modules>"

# Check if an input text field has a valid value (not empty).
isFilled = (field) ->
  value = $(field).val()
  return value? and value.trim() != ""

# Add a div with all links and a close button to the global
# results container
addUrlsToPage = (urls) ->
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
  expandLinks($("#view-type-input").hasClass("active"))

  # mark the items as updated
  placeholder.addClass("updated")
  clearTimeout(updatedTimer)
  updatedTimer = setTimeout( ->
    placeholder.removeClass("updated")
  , 300)

# Generate urls for all BBB calls and add them to the page.
generateUrls = () ->
  server = {}
  server.url = $("#input-custom-server-url").val()
  server.salt = $("#input-custom-server-salt").val()
  server.mobileSalt = $("#input-custom-server-mobile-salt").val()

  # Do some cleanups on the server URL to that pasted URLs in various formats work better
  # Remove trailing /, and add /api on the end if missing.
  server.url = server.url.replace(/(\/api)?\/?$/, '/api')
  server.name = server.url

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
  api = new BigBlueButtonApi(server.url, server.salt, server.mobileSalt)
  urls = api.getUrls(params, customCalls)
  addUrlsToPage(urls)

# Empty all inputs inside #config-fields
clearAllFields = ->
  $("#config-fields input, #config-fields textarea").each -> $(this).val("")
  $("#config-fields input[type=checkbox]").each -> $(this).attr("checked", null)

# Expand (if `selected` is true) or collapse the links.
expandLinks = (selected) ->
  if selected
    $("#api-mate-results .result-link").css("word-break", "break-all")
    $("#api-mate-results .result-link").css("white-space", "normal")
    $("#api-mate-results .method-name").css("display", "block")
  else
    $("#api-mate-results .result-link").css("word-break", "normal")
    $("#api-mate-results .result-link").css("white-space", "nowrap")
    $("#api-mate-results .method-name").css("display", "inline-block")

bindTooltips = ->
  defaultOptions =
    # append tooltips to the <body> element to prevent problems with tooltips inside
    # elements with `overflow:hidden` set, for example.
    container: 'body'
    placement: 'top'

  $('.tooltipped').tooltip(defaultOptions)

bindPostRequests = ->
  $("a.result-form").click ->
    alert("yeeeash")
    action = $(this).attr('action')
    opts =
      url: 'http://fc03.deviantart.net/fs71/f/2010/154/7/b/Big_Blue_Button_Logo_by_ThanRi.jpg'
    data =
      body: Mustache.to_html(post_template_url, opts)

    $.post action, data, (data) ->
      alert(data)
      $(".result-show", this).html(data)

pad = (num, size) ->
  s = "0000" + num
  s.substr(s.length-size)

$ ->
  # set random values in some inputs
  vbridge = "7" + pad(Math.floor(Math.random() * 10000 - 1).toString(), 4)
  $("#input-voice-bridge").val(vbridge)
  name = "random-" + Math.floor(Math.random() * 10000000).toString()
  $("#input-name").val(name)
  $("#input-id").val(name)
  user = "User " + Math.floor(Math.random() * 10000000).toString()
  $("#input-fullname").val(user)

  # when the meeting name is changed, change the id also
  $("#input-id").on "keyup", -> $("#input-name").val $(this).val()

  # triggers to generate the links
  $("input, select, textarea", "#config-fields").on "change keyup", (e) ->
    generateUrls()
  $("input, select, textarea", "#config-server").on "change keyup", (e) ->
    generateUrls()

  # expand or collapse links
  $("#view-type-input").on "click", ->
    selected = !$("#view-type-input").hasClass("active")
    expandLinks(selected)

  $("input[name='document']").on "change", ->
    val = $("input[name='document']:checked").attr('value')
    if val == 'file'
      $("#pre-upload-file").show()
      $("#pre-upload-url").hide()
    else if val == 'url'
      $("#pre-upload-url").show()
      $("#pre-upload-file").hide()

  # button to clear the inputs
  $(".api-mate-clearall").on "click", (e) ->
    clearAllFields()
    generateUrls()

  generateUrls()
