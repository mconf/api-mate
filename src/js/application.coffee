$ ->
  Application.bindTooltips()

window.Application = class Application
  @bindTooltips: ->
    defaultOptions =
      container: 'body'
      placement: 'top'
      template: '<div class="tooltip results-tooltip" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
    $('.tooltipped').tooltip(defaultOptions)
