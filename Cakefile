chokidar = require('chokidar')
fs = require('fs')
{spawn} = require('child_process')
jade = require('jade')
sass = require('node-sass')

binPath = './node_modules/.bin/'

# Returns a string with the current time to print out.
timeNow = ->
  today = new Date()
  today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds()

# Spawns an application with `options` and calls `onExit`
# when it finishes.
run = (bin, options, onExit) ->
  bin = binPath + bin
  console.log timeNow() + ' - running: ' + bin + ' ' + (if options? then options.join(' ') else '')
  cmd = spawn bin, options
  cmd.stdout.on 'data', (data) -> #console.log data.toString()
  cmd.stderr.on 'data', (data) -> console.log data.toString()
  cmd.on 'exit', (code) ->
    console.log timeNow() + ' - done.'
    onExit?(code, options)

compileView = (done) ->
  options = ['--pretty', 'src/views/api_mate.jade', '--out', 'lib', '--obj', 'src/jade_options.json']
  run 'jade', options, ->
    options = ['--pretty', 'src/views/redis_events.jade', '--out', 'lib', '--obj', 'src/jade_options.json']
    run 'jade', options, ->
      done?()

compileCss = (done) ->
  options = ['src/css/api_mate.scss', 'lib/api_mate.css']
  run 'node-sass', options, ->
    options = ['src/css/redis_events.scss', 'lib/redis_events.css']
    run 'node-sass', options, ->
      done?()

compileJs = (done) ->
  options = [
    '-o', 'lib',
    '--join', 'api_mate.js',
    '--compile', 'src/js/application.coffee', 'src/js/templates.coffee', 'src/js/api_mate.coffee'
  ]
  run 'coffee', options, ->
    options = [
      '-o', 'lib',
      '--join', 'redis_events.js',
      '--compile', 'src/js/application.coffee', 'src/js/redis_events.coffee'
    ]
    run 'coffee', options, ->
      done?()

build = (done) ->
  compileView (err) ->
    compileCss (err) ->
      compileJs (err) ->
        done?()

watch = () ->
  watcher = chokidar.watch('src', { ignored: /[\/\\]\./, persistent: true })
  watcher.on 'all', (event, path) ->
    console.log timeNow() + ' = detected', event, 'on', path
    if path.match(/\.coffee$/)
      compileJs()
    else if path.match(/\.scss/)
      compileCss()
    else if path.match(/\.jade/)
      compileView()

task 'build', 'Build everything from src/ into lib/', ->
  build()

task 'watch', 'Watch for changes to compile the sources', ->
  watch()
