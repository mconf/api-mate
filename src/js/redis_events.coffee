$ ->
  redisEvents = new RedisEvents()
  redisEvents.bind()

  $(".events-template").on "click", (e) ->
    redisEvents.selectTemplate($(".event-json", $(this)).text())

    # highlight the template selected
    $(this).addClass("updated")
    clearTimeout(@selectTemplateTimeout)
    @selectTemplateTimeout = setTimeout( =>
      $(this).removeClass("updated")
    , 300)

window.RedisEvents = class RedisEvents

  constructor: ->
    @serverUrl = @getServerUrlFromInput()
    @pushPath = '/push'
    @pullPath = '/pull'
    @publishChannel = null
    @source = null
    @lastContentSent = null
    @searchTimeout = null

  bind: ->
    @bindSearch()

    # Button to send and event to the server
    $("[data-events-out-submit]").on "click", (e) =>
      content = $("[data-events-out-content]").val()
      content = JSON.parse(content) # TODO: error in case is not valid
      channel = $("[data-events-out-channel]").val().trim()
      channel = 'to-bbb-apps' if not channel? or channel is ""
      @lastContentSent = content
      @sendEvent({ channel: channel, data: content })

    # Button to subscribe to the events from the server
    $("[data-events-server-connect]").on "click", (e) =>
      url = @getServerUrlFromInput()
      @connect(url)

    $("[data-events-out-pretty]").on "click", (e) =>
      @selectTemplate($("[data-events-out-content]").val())

  bindSearch: ->
    timeout = @searchTimeout
    $(document).on 'keyup', '[data-events-search-input]', (e) ->
      $searchInput = $(this)

      search = ->
        searchTerm = $searchInput.val()
        showOrHide = ->
          $elem = $(this)
          if searchTerm? and not _.isEmpty(searchTerm.trim())
            visible = false
            searchRe = makeSearchRegexp(searchTerm)
            eventText = $("[data-events-template-content]", $elem).text()
            visible = true if eventText.match(searchRe)
          else
            visible = true
          if visible
            $elem.show()
          else
            $elem.hide()
          true # don't ever stop
        $('[data-events-template]').each(showOrHide)

      clearTimeout(timeout)
      timeout = setTimeout( ->
        search()
      , 200)

  getServerUrlFromInput: ->
    $("[data-events-server='url']").val()

  onMessageReceived: (e) =>
    console.log(e)
    @setConnected(true)
    data = JSON.parse(e.data)
    if $("[data-events-out-pretty]").is(":checked")
      pretty = JSON.stringify(data, null, 4)
    else
      pretty = JSON.stringify(data, null, 0)

    return if @excludeEvent(pretty)

    if JSON.stringify(data) is JSON.stringify(@lastContentSent)
      @lastContentSent = null
      $message = $('<pre class="events-result sent">').html(pretty)
      $icon = $('<span class="glyphicon glyphicon-arrow-up tooltipped" title="sent by you">')
      $message.prepend($icon)
      # $label = $('<span class="label label-danger">').html('sent')
      # $message.prepend($label)
    else
      $message = $('<pre class="events-result received">').html(pretty)
      # $label = $('<span class="label label-success">').html('received')
      # $message.prepend($label)

    $('#events-results').prepend($message)
    Application.bindTooltips()

  onMessageError: (e) =>
    console.log "EventSource failed"
    @setConnected(false)

  excludeEvent: (str) ->
    patterns = $("[data-events-config='exclude']").val()
    for pattern in patterns.split('\n')
      if str? and pattern? and pattern.trim() != '' and str.match(pattern)
        return true
    false

  connect: (url) ->
    try
      @serverUrl = url
      @setConnected(true)
      @source.close() if @source?
      @source = new EventSource("#{@serverUrl}#{@pullPath}", { withCredentials: false })
      @source.onerror = @onMessageError
      @source.onmessage = @onMessageReceived
    catch
      @setConnected(false)

  setConnected: (connected) ->
    if connected
      $("#menu-server").removeClass("disconnected")
      $("#menu-server").addClass("connected")
    else
      $("#menu-server").removeClass("connected")
      $("#menu-server").addClass("disconnected")

  sendEvent: (content) ->
    url = "#{@serverUrl}#{@pushPath}"
    console.log "Sending the event", content, "to", url
    $.ajax
      url: url
      type: 'POST'
      cache: false
      data: JSON.stringify(content)
      crossdomain: true
      contentType: 'application/json'
      success: (data) ->
        console.log 'Sent the event successfully'
      error: (jqXHR, textStatus, err) ->
        console.log 'Error sending the event:', textStatus, ', err', err

  selectTemplate: (text) ->
    content = text
    if $("[data-events-out-pretty]").is(":checked")
      content = JSON.stringify(JSON.parse(content), null, 4)
    else
      content = JSON.stringify(JSON.parse(content), null, 0)
    $("[data-events-out-content]").val(content)

    # highlight the elements updated
    $('[data-events-out-content]').addClass("updated")
    clearTimeout(@selectTemplateTimeout2)
    @selectTemplateTimeout2 = setTimeout( =>
      $('[data-events-out-content]').removeClass("updated")
    , 300)

makeSearchRegexp = (term) ->
  terms = term.split(" ")
  terms = _.filter(terms, (t) -> not _.isEmpty(t.trim()))
  terms = _.map(terms, (t) -> ".*#{t}.*")
  terms = terms.join('|')
  new RegExp(terms, "i");
