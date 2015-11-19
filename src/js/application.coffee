$ ->
  Application.bindTooltips()

window.Application = class Application
  @bindTooltips: ->
    defaultOptions =
      container: 'body'
      placement: 'top'
    $('.tooltipped').tooltip(defaultOptions)
