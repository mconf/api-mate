$ ->
  redisEvents = new RedisEvents()
  redisEvents.bind()

  $(".events-template").on "click", (e) ->
    redisEvents.selectTemplate($(this).text())

window.RedisEvents = class RedisEvents

  constructor: ->
    @serverUrl = @getServerUrlFromInput()
    @pushPath = '/push'
    @pullPath = '/pull'
    @publishChannel = 'any-channel'
    @source = null
    @lastContentSent = null

  bind: ->
    # Button to send and event to the server
    $("[data-events-out-submit]").on "click", (e) =>
      content = $("[data-events-out-content]").val()
      content = JSON.parse(content) # TODO: error in case is not valid
      @lastContentSent = content
      @sendEvent({ channel: @publishChannel, data: content })

    # Button to subscribe to the events from the server
    $("[data-events-server-connect]").on "click", (e) =>
      url = @getServerUrlFromInput()
      @connect(url)

    $("[data-events-out-pretty]").on "click", (e) =>
      @selectTemplate($("[data-events-out-content]").val())

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
    console.log "EventSource failed."
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
    $("#input-event-out-content").val(content)
