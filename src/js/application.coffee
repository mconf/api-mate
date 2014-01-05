$ ->
  placeholders =
    results: '#api-mate-results'
    modal: '#post-response-modal'
  apiMate = new ApiMate(placeholders)
  apiMate.start()

  bindTooltips()
  $('#api-mate-results').on 'api-mate-urls-added', ->
    bindTooltips()

bindTooltips = ->
  defaultOptions =
    container: 'body'
    placement: 'top'
  $('.tooltipped').tooltip(defaultOptions)
