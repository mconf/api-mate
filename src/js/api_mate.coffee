$ ->
  placeholders =
    results: '#api-mate-results'
    modal: '#post-response-modal'
  apiMate = new ApiMate(placeholders)
  apiMate.start()
  $('#api-mate-results').on 'api-mate-urls-added', ->
    Application.bindTooltips()

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
    @debug = false
    @urlsLast = null

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
    $("[data-api-mate-special-param]").on "change keyup", (e) =>
      @generateUrls()
      @addUrlsToPage(@urls)
    $("[data-api-mate-sha]").on "click", (e) =>
      $("[data-api-mate-sha]").removeClass('active')
      $(e.target).addClass('active')
      @generateUrls()
      @addUrlsToPage(@urls)

    # expand or collapse links
    $("[data-api-mate-expand]").on "click", =>
      selected = !$("[data-api-mate-expand]").hasClass("active")
      @expandLinks(selected)
      true

    # button to clear the inputs
    $("[data-api-mate-clear]").on "click", (e) =>
      @clearAllFields()
      @generateUrls()
      @addUrlsToPage(@urls)

    # button to re-randomize menu
    $("[data-api-mate-randomize]").on "click", (e) =>
      @initializeMenu()
      @generateUrls()
      @addUrlsToPage(@urls)

    # set our debug flag
    $("[data-api-mate-debug]").on "click", =>
      selected = !$("[data-api-mate-debug]").hasClass("active")
      @debug = selected
      true

    # generate the links already on setup
    @generateUrls()
    @addUrlsToPage(@urls)

    # binding elements
    @bindPostRequests()

    # search
    @bindSearch()

  initializeMenu: ->
    vbridge = "7" + pad(Math.floor(Math.random() * 10000 - 1).toString(), 4)
    $("[data-api-mate-param*='voiceBridge']").val(vbridge)
    name = "random-" + Math.floor(Math.random() * 10000000).toString()
    $("[data-api-mate-param*='name']").val(name)
    $("[data-api-mate-param*='meetingID']").val(name)
    $("[data-api-mate-param*='recordID']").val(name)
    user = "User " + Math.floor(Math.random() * 10000000).toString()
    $("[data-api-mate-param*='fullName']").val(user)

    @setMenuValuesFromURL()

  # Add a div with all links and a close button to the global
  # results container
  addUrlsToPage: (urls) ->
    # don't do it again unless something changed
    isEqual = urls? and @urlsLast? and (JSON.stringify(urls) == JSON.stringify(@urlsLast))
    return if isEqual
    @urlsLast = _.map(urls, _.clone)

    placeholder = $(@placeholders['results'])
    for item in urls
      desc = item.description
      if desc.match(/recording/i)
        item.urlClass = "api-mate-url-recordings"
      else if desc.match(/mobile/i)
        item.urlClass = "api-mate-url-from-mobile"
      else if desc.match(/custom call/i)
        item.urlClass = "api-mate-url-custom-call"
      else
        item.urlClass = "api-mate-url-standard"
    opts =
      title: new Date().toTimeString()
      urls: urls
    html = Mustache.to_html(@templates['results'], opts)
    $('.results-tooltip').remove()
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

    # Do some cleanups on the server URL to that pasted URLs in various formats work better
    # Remove trailing /, and add /api on the end if missing.
    server.url = server.url.replace(/(\/api)?\/?$/, '/api')
    server.name = server.url

    opts = {}
    if $("[data-api-mate-sha='sha256']").hasClass("active")
      opts.shaType = 'sha256'
    else
      opts.shaType = 'sha1'

    new BigBlueButtonApi(server.url, server.salt, @debug, opts)

  # Generate urls for all API calls and store them internally in `@urls`.
  generateUrls: () ->
    params = {}
    customParams = {}

    $('[data-api-mate-param]').each ->
      $elem = $(this)
      attrs = $elem.attr('data-api-mate-param').split(',')
      value = inputValue($elem)
      if attrs? and value?
        for attr in attrs
          params[attr] = value
      true # don't ever stop

    lines = inputValue("textarea[data-api-mate-special-param='meta']")
    if lines?
      lines = lines.replace(/\r\n/g, "\n").split("\n")
      for line in lines
        separator = line.indexOf("=")
        if separator >= 0
          paramName = line.substring(0, separator)
          paramValue = line.substring(separator+1, line.length)
          params["meta_" + paramName] = paramValue

    lines = inputValue("textarea[data-api-mate-special-param='custom-params']")
    if lines?
      lines = lines.replace(/\r\n/g, "\n").split("\n")
      for line in lines
        separator = line.indexOf("=")
        if separator >= 0
          paramName = line.substring(0, separator)
          paramValue = line.substring(separator+1, line.length)
          params["custom_" + paramName] = paramValue
          customParams["custom_" + paramName] = paramValue

    lines = inputValue("textarea[data-api-mate-special-param='custom-calls']")
    if lines?
      lines = lines.replace(/\r\n/g, "\n").split("\n")
      customCalls = lines
    else
      customCalls = null

    # generate the list of links
    api = @getApi()
    @urls = []

    # standard API calls
    _elem = (name, desc, url) ->
      { name: name, description: desc, url: url }
    for name in api.availableApiCalls()
      if name is 'join'
        params['password'] = params['moderatorPW']
        @urls.push _elem(name, "#{name} as moderator", api.urlFor(name, params))
        params['password'] = params['attendeePW']
        @urls.push _elem(name, "#{name} as attendee", api.urlFor(name, params))

        # so all other calls will use the moderator password
        params['password'] = params['moderatorPW']
      else
        @urls.push _elem(name, name, api.urlFor(name, params))

    # custom API calls set by the user
    if customCalls?
      for name in customCalls
        @urls.push _elem(name, "custom call: #{name}", api.urlFor(name, customParams, false))

    # for mobile
    params['password'] = params['moderatorPW']
    @urls.push _elem("join", "mobile call: join as moderator", api.setMobileProtocol(api.urlFor("join", params)))
    params['password'] = params['attendeePW']
    @urls.push _elem("join", "mobile call: join as attendee", api.setMobileProtocol(api.urlFor("join", params)))

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

      # get the data to be posted for this method and the content type
      method = $target.attr('data-api-mate-post')
      data = _apiMate.getPostData(method)
      contentType = _apiMate.getPostContentType(method)

      $('[data-api-mate-post]').addClass('disabled')
      $.ajax
        url: href
        type: "POST"
        crossDomain: true
        contentType: contentType
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
      if isFilled("textarea[data-api-mate-param='configXML']")
        api = @getApi()
        query  = "configXML=#{api.encodeForUrl($("#input-config-xml").val())}"
        query += "&meetingID=#{api.encodeForUrl($("#input-mid").val())}"
        checksum = api.checksum('setConfigXML', query)
        query += "&checksum=" + checksum
        query

  getPostContentType: (method) ->
    if method is 'create'
      'application/xml; charset=utf-8'
    else if method is 'setConfigXML'
      'application/x-www-form-urlencoded'

  bindSearch: ->
    _apiMate = this
    $(document).on 'keyup', '[data-api-mate-search-input]', (e) ->
      $target = $(this)
      searchTerm = inputValue($target)

      search = ->
        $elem = $(this)
        if searchTerm? and not _.isEmpty(searchTerm.trim())
          visible = false
          searchRe = makeSearchRegexp(searchTerm)
          attrs = $elem.attr('data-api-mate-param')?.split(',') or []
          attrs = attrs.concat($elem.attr('data-api-mate-search')?.split(',') or [])
          for attr in attrs
            visible = true if attr.match(searchRe)
        else
          visible = true

        if visible
          $elem.parents('.form-group').show()
        else
          $elem.parents('.form-group').hide()
        true # don't ever stop

      $('[data-api-mate-param]').each(search)
      $('[data-api-mate-special-param]').each(search)

  setMenuValuesFromURL: ->
    # set values based on parameters in the URL
    # gives priority to params in the hash (e.g. 'api_mate.html#sharedSecret=123')
    query = getHashParams()
    # but also accept params in the search string for backwards compatibility (e.g. 'api_mate.html?sharedSecret=123')
    query2 = parseQueryString(window.location.search.substring(1))
    query = _.extend(query2, query)
    if query.server?
      $("[data-api-mate-server='url']").val(query.server)
      delete query.server
    # accept several options for the secret
    if query.salt?
      $("[data-api-mate-server='salt']").val(query.salt)
      delete query.salt
    if query.sharedSecret?
      $("[data-api-mate-server='salt']").val(query.sharedSecret)
      delete query.sharedSecret
    if query.secret?
      $("[data-api-mate-server='salt']").val(query.secret)
      delete query.secret
    # all other properties
    for prop, value of query
      setInputValue($("[data-api-mate-param='#{prop}']"), value)
      setInputValue($("[data-api-mate-special-param='#{prop}']"), value)


# Returns the value set in an input, if any. For checkboxes, returns the value
# as a boolean. For any other input, return as a string.
# `selector` can be a string with a selector or a jQuery object.
inputValue = (selector) ->
  $elem = $(selector)

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

# Sets `value` as the value of the input. For checkboxes checks the input if the value
# is anything other than [null, undefined, 0].
# `selector` can be a string with a selector or a jQuery object.
setInputValue = (selector, value) ->
  $elem = $(selector)

  type = $elem.attr('type') or $elem.prop('tagName')?.toLowerCase()
  switch type
    when 'checkbox'
      val = value? && value != '0' && value != 0
      $elem.prop('checked', val)
    else
      $elem.val(value)

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

# Parse the query string into an object
# From http://www.joezimjs.com/javascript/3-ways-to-parse-a-query-string-in-a-url/
parseQueryString = (queryString) ->
  params = {}

  # Split into key/value pairs
  if queryString? and not _.isEmpty(queryString)
    queries = queryString.split("&")
  else
    queries = []

  # Convert the array of strings into an object
  i = 0
  l = queries.length
  while i < l
    temp = queries[i].split('=')
    params[temp[0]] = temp[1]
    i++

  params

makeSearchRegexp = (term) ->
  terms = term.split(" ")
  terms = _.filter(terms, (t) -> not _.isEmpty(t.trim()))
  terms = _.map(terms, (t) -> ".*#{t}.*")
  terms = terms.join('|')
  new RegExp(terms, "i");

# Get the parameters from the hash in the URL
# Adapted from: http://stackoverflow.com/questions/4197591/parsing-url-hash-fragment-identifier-with-javascript#answer-4198132
getHashParams = ->
  hashParams = {}
  a = /\+/g  # Regex for replacing addition symbol with a space
  r = /([^&;=]+)=?([^&;]*)/g
  d = (s) -> decodeURIComponent(s.replace(a, " "))
  q = window.location.hash.substring(1)
  hashParams[d(e[1])] = d(e[2]) while e = r.exec(q)
  hashParams
