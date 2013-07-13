template =
  "<table class='table table-condensed result-set'>
     <thead>
       <tr>
         <th colspan='2'><h3 class='label-title'>Results {{title}}:</h5></th>
       </tr>
     </thead>
     <tbody>
       {{#urls}}
         <tr class='{{urlClass}}'>
           <td class='column-name'>
             <span class='method-name'>{{name}}</span>
           </td>
           <td class='column-url'>
             <a class='api-link' href='{{url}}'>{{urlName}}</a>
           </td>
         </tr>
       {{/urls}}
     </tbody>
   </table>"

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
    else
      u.urlClass = "url-standard"
    u
  opts =
    title: new Date().toTimeString()
    urls: urls
  html = Mustache.to_html(template, opts)
  $(placeholder).html html

# Generate urls for all BBB calls and add them to the page.
generateUrls = () ->
  server = {}
  server.url = $("#input-custom-server-url").val()
  server.name = server.url
  server.salt = $("#input-custom-server-salt").val()
  server.mobileSalt = $("#input-custom-server-mobile-salt").val()

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

  # get the list of links and add them to the page
  api = new BigBlueButtonApi(server.url, server.salt, server.mobileSalt)
  urls = api.getUrls(params)
  addUrlsToPage urls

# Empty all inputs inside #fields
clearAllFields = ->
  $("#fields").children().each -> $(this).val("")

$ ->
  $("#api-mate-results").affix { offset: { top: 100 } }

  # set random values in some inputs
  vbridge = "7" + Math.floor(Math.random() * 10000 - 1).toString()
  $("#input-voice-bridge").val(vbridge)
  name = "random-" + Math.floor(Math.random() * 10000000).toString()
  $("#input-name").val(name)
  $("#input-id").val(name)
  user = "User " + Math.floor(Math.random() * 10000000).toString()
  $("#input-fullname").val(user)

  # when the meeting name is changed, change the id also
  $("#input-id").on "keyup", -> $("#input-name").val $(this).val()

  # button to generate the links
  $("input, select, textarea", "#api-mate-config").on "change keyup", (e) ->
    generateUrls()

  # button to clear the inputs
  $(".api-mate-clearall").on "click", (e) ->
    clearAllFields()
    generateUrls()

  generateUrls()
