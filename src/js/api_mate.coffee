# A class that does all the logic of the API Mate. It's integrated with the html markup
# via data attributes and a few classes. Can be used with other applications than the
# API Mate to provide similar functionality.
#
# Depends on:
# * jQuery
# * underscore/lodash
# * mustache
# * bigbluebutton-api-js
# * bootstrap (for the modal, especially)
#
window.ApiMate = class ApiMate

  # `placeholders` should be an object with the properties:
  # * `results`: a string with the jQuery selector for the element that will contain
  #   the URLs generated.
  # * `modal`: a string with the jQuery selector for an element that will be used as
  #   a modal window (should follow bootstrap's model for modals).
  #
  # `templates` should be an object with the properties:
  # * `results`: a string with a mustache template to show the list of links generated.
  # * `postSuccess`: a string with a mustache template with the internal content of the
  #   modal when showing a success message for a POST request.
  # * `postError`: a string with a mustache template with the internal content of the
  #   modal when showing an error message for a POST request.
  # * `preUpload`: a string with a mustache template to format the body of a the POST
  #   request to pre-upload files when creating a conference.
  constructor: (@placeholders, @templates) ->
    @updatedTimer = null
    @urls = [] # last set of urls generated
    @placeholders ?= {}
    @templates ?= {}
    @templates['results'] ?= resultsTemplate
    @templates['postSuccess'] ?= postSuccessTemplate
    @templates['postError'] ?= postErrorTemplate
    @templates['preUpload'] ?= preUploadUrl

  start: ->
    # set random values in some inputs
    @initializeMenu()

    # when the meeting name is changed, change the id also
    $("[data-api-mate-param*='meetingID']").on "keyup", ->
      $("[data-api-mate-param*='name']").val $(this).val()

    # triggers to generate the links
    $("[data-api-mate-param]").on "change keyup", (e) =>
      @generateUrls()
      @addUrlsToPage(@urls)
    $("[data-api-mate-server]").on "change keyup", (e) =>
      @generateUrls()
      @addUrlsToPage(@urls)

    # expand or collapse links
    $("[data-api-mate-expand]").on "click", =>
      selected = !$("[data-api-mate-expand]").hasClass("active")
      @expandLinks(selected)

    # button to clear the inputs
    $("[data-api-mate-clear]").on "click", (e) =>
      @clearAllFields()
      @generateUrls()
      @addUrlsToPage(@urls)

    # generate the links already on setup
    @generateUrls()
    @addUrlsToPage(@urls)

    # binding elements
    @bindPostRequests()

  initializeMenu: ->
    vbridge = "7" + pad(Math.floor(Math.random() * 10000 - 1).toString(), 4)
    $("[data-api-mate-param*='voiceBridge']").val(vbridge)
    name = "random-" + Math.floor(Math.random() * 10000000).toString()
    $("[data-api-mate-param*='name']").val(name)
    $("[data-api-mate-param*='meetingID']").val(name)
    user = "User " + Math.floor(Math.random() * 10000000).toString()
    $("[data-api-mate-param*='fullName']").val(user)

  # Add a div with all links and a close button to the global
  # results container
  addUrlsToPage: (urls) ->
    placeholder = $(@placeholders['results'])
    for item in urls
      desc = item.description
      if desc.match(/recordings/i)
        item.urlClass = "api-mate-url-recordings"
      else if desc.match(/from mobile/i)
        item.urlClass = "api-mate-url-from-mobile"
      else if desc.match(/mobile:/i)
        item.urlClass = "api-mate-url-mobile-api"
      else if desc.match(/custom call/i)
        item.urlClass = "api-mate-url-custom-call"
      else
        item.urlClass = "api-mate-url-standard"
    opts =
      title: new Date().toTimeString()
      urls: urls
    html = Mustache.to_html(@templates['results'], opts)
    $(placeholder).html(html)
    @expandLinks($("[data-api-mate-expand]").hasClass("active"))

    # mark the items as updated
    $('.api-mate-results', @placeholders['results']).addClass("updated")
    clearTimeout(@updatedTimer)
    @updatedTimer = setTimeout( =>
      $('.api-mate-results', @placeholders['results']).removeClass("updated")
    , 300)

    $(@placeholders['results']).trigger('api-mate-urls-added')

  # Returns a BigBlueButtonApi configured with the server set by the user in the inputs.
  getApi: ->
    server = {}
    server.url = $("[data-api-mate-server='url']").val()
    server.salt = $("[data-api-mate-server='salt']").val()
    server.mobileSalt = $("[data-api-mate-server='mobile-salt']").val()

    # Do some cleanups on the server URL to that pasted URLs in various formats work better
    # Remove trailing /, and add /api on the end if missing.
    server.url = server.url.replace(/(\/api)?\/?$/, '/api')
    server.name = server.url

    new BigBlueButtonApi(server.url, server.salt, server.mobileSalt)

  # Generate urls for all API calls and store them internally in `@urls`.
  generateUrls: () ->
    params = {}

    $('[data-api-mate-param]').each ->
      $elem = $(this)
      attrs = $elem.attr('data-api-mate-param').split(',')
      value = inputValue($elem)
      if attrs? and value?
        for attr in attrs
          params[attr] = value
      true # don't ever stop

    lines = inputValue("textarea[data-api-mate-param='meta']")
    if lines?
      lines = lines.replace(/\r\n/g, "\n").split("\n")
      for line in lines
        separator = line.indexOf("=")
        if separator >= 0
          paramName = line.substring(0, separator)
          paramValue = line.substring(separator+1, line.length)
          params["meta_" + paramName] = paramValue

    lines = inputValue("textarea[data-api-mate-param='custom-params']")
    if lines?
      lines = lines.replace(/\r\n/g, "\n").split("\n")
      for line in lines
        separator = line.indexOf("=")
        if separator >= 0
          paramName = line.substring(0, separator)
          paramValue = line.substring(separator+1, line.length)
          params["custom_" + paramName] = paramValue

    lines = inputValue("textarea[data-api-mate-param='custom-calls']")
    if lines?
      lines = lines.replace(/\r\n/g, "\n").split("\n")
      customCalls = lines
    else
      customCalls = null

    # get the list of links and add them to the page
    api = @getApi()
    @urls = api.getUrls(params, customCalls)

  # Empty all inputs in the configuration menu
  clearAllFields: ->
    $("[data-api-mate-param]").each ->
      $(this).val("")
      $(this).attr("checked", null)

  # Expand (if `selected` is true) or collapse the links.
  expandLinks: (selected) ->
    if selected
      $(".api-mate-link", @placeholders['results']).addClass('expanded')
    else
      $(".api-mate-link", @placeholders['results']).removeClass('expanded')

  # Logic for when a button to send a request via POST is clicked.
  bindPostRequests: ->
    _apiMate = this
    $(document).on 'click', 'a[data-api-mate-post]', (e) ->
      $target = $(this)
      href = $target.attr('data-url')

      # get the data to be posted for this method
      method = $target.attr('data-api-mate-post')
      data = _apiMate.getPostData(method)

      $('[data-api-mate-post]').addClass('disabled')
      $.ajax
        url: href
        type: "POST"
        crossDomain: true
        contentType:"application/xml; charset=utf-8"
        dataType: "xml"
        data: data
        complete: (jqxhr, status) ->
          # TODO: show the result properly formatted and highlighted in the modal
          modal = _apiMate.placeholders['modal']
          postSuccess = _apiMate.templates['postSuccess']
          postError = _apiMate.templates['postError']

          if jqxhr.status is 200
            $('.modal-header', modal).removeClass('alert-danger')
            $('.modal-header', modal).addClass('alert-success')
            html = Mustache.to_html(postSuccess, { response: jqxhr.responseText })
            $('.modal-body', modal).html(html)
          else
            $('.modal-header h4', modal).text('Ooops!')
            $('.modal-header', modal).addClass('alert-danger')
            $('.modal-header', modal).removeClass('alert-success')
            opts =
              status: jqxhr.status
              statusText: jqxhr.statusText
            opts['response'] = jqxhr.responseText unless _.isEmpty(jqxhr.responseText)
            html = Mustache.to_html(postError, opts)
            $('.modal-body', modal).html(html)

          $(modal).modal({ show: true })
          $('[data-api-mate-post]').removeClass('disabled')

      e.preventDefault()
      false

  getPostData: (method) ->
    if method is 'create'
      urls = inputValue("textarea[data-api-mate-param='pre-upload']")
      if urls?
        urls = urls.replace(/\r\n/g, "\n").split("\n")
        urls = _.map(urls, (u) -> { url: u })
        opts = { urls: urls }
        Mustache.to_html(@templates['preUpload'], opts)
    else if method is 'setConfigXML'
      # TODO: apparently BigBlueButton receives these parameters from the URL and not from
      #   the body of the POST request as stated in the docs, need to check it better
      null
      # if isFilled("textarea[data-api-mate-param='config-xml']")
      #   api = @getApi()
      #   query  = "meetingID=#{api.encodeForUrl($("#input-id").val())}"
      #   query += "&configXML=#{api.encodeForUrl($("#input-config-xml").val())}"
      #   checksum = api.checksum('setConfigXML', query)
      #   query + "&checksum=" + checksum

# Returns the value set in an input, if any. For checkboxes, returns the value
# as a boolean. For any other input, return as a string.
# `selector` can be a string with a selector or a jQuery object.
inputValue = (selector) ->
  if _.isString(selector)
    $elem = $(selector)
  else
    $elem = selector

  type = $elem.attr('type') or $elem.prop('tagName')?.toLowerCase()
  switch type
    when 'checkbox'
      $elem.is(":checked")
    else
      value = $elem.val()
      if value? and not _.isEmpty(value.trim())
        value
      else
        null

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
