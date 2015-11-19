$ ->
  redisEvents = new RedisEvents()
  redisEvents.bind()

  $(".events-template").on "click", (e) ->
    content = $(this).text()
    $("#input-event-out-content").val(content)

window.RedisEvents = class RedisEvents

  constructor: ->
    @serverUrl = @getServerUrlFromInput()
    @pushPath = '/push'
    @pullPath = '/pull'
    @publishChannel = 'any-channel'
    @source = null

  bind: ->
    # Button to send and event to the server
    $("[data-events-out-submit]").on "click", (e) =>
      content = $("[data-events-out-content]").val()
      content = JSON.parse(content) # TODO: error in case is not valid
      @sendEvent({ channel: @publishChannel, data: content })

    # Button to subscribe to the events from the server
    $("[data-events-server-connect]").on "click", (e) =>
      url = @getServerUrlFromInput()
      @connect(url)

  getServerUrlFromInput: ->
    $("[data-events-server='url']").val()

  connect: (url) ->
    @serverUrl = url
    @setConnected(true)
    @source.close() if @source?
    @source = new EventSource("#{@serverUrl}#{@pullPath}", { withCredentials: false })
    @source.onerror = (e) =>
      console.log "EventSource failed."
      @setConnected(false)
    @source.onmessage = (e) =>
      console.log(e)
      @setConnected(true)
      data = JSON.parse(e.data)
      pretty = JSON.stringify(data, null, 0)
      $message = $('<pre class="events-result">').html(pretty)
      $('#events-results').prepend($message)

  setConnected: (connected) ->
    if connected
      $("#menu-server").removeClass("not-connected")
      $("#menu-server").addClass("connected")
    else
      $("#menu-server").removeClass("connected")
      $("#menu-server").addClass("not-connected")

  sendEvent: (content) ->
    url = "#{@serverUrl}#{@pushPath}"
    console.log "Sending the event", content, "to", url
    $.ajax
      url: url
      type: 'POST'
      cache: false
      data: content
      crossdomain: true
      success: (data) ->
        console.log 'Sent the event successfully'
      error: (jqXHR, textStatus, err) ->
        console.log 'Error sending the event:', textStatus, ', err', err
