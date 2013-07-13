fs = require('fs')
{print} = require('sys')
{spawn} = require('child_process')
jade = require('jade')
sass = require('node-sass')

binPath = './node_modules/.bin/'
viewSrc = 'src/api_mate.jade'
stylesheetSrc = 'src/api_mate.scss'
stylesheetOutput = 'lib/api_mate.css'
javascriptSrc = 'src/api_mate.coffee'

# Returns a string with the current time to print out.
timeNow = ->
  today = new Date()
  today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds()

# Spawns an application with `options` and calls `onExit`
# when it finishes.
run = (bin, options, onExit) ->
  bin = binPath + bin
  console.log timeNow() + ' - running: ' + bin + ' ' + (if options? then options.join(' ') else "")
  cmd = spawn bin, options
  cmd.stdout.on 'data', (data) -> #print data.toString()
  cmd.stderr.on 'data', (data) -> print data.toString()
  cmd.on 'exit', (code) ->
    console.log timeNow() + ' - done.'
    onExit?(code, options)

compileView = (done) ->
  options = ['-o', 'lib', viewSrc]
  run 'jade', options, ->
    done?()

compileCss = (done) ->
  options = [stylesheetSrc, stylesheetOutput]
  run 'node-sass', options, ->
    done?()

compileJs = (done) ->
  options = ['-c', '-o', 'lib', javascriptSrc]
  run 'coffee', options, ->
    done?()

build = (done) ->
  compileView (err) ->
    unless err
      compileCss (err) ->
        unless err
          compileJs (err) ->
            done?()

watch = () ->
  fs.watchFile viewSrc, (curr, prev) ->
    compileView()
  fs.watchFile stylesheetSrc, (curr, prev) ->
    compileCss()
  fs.watchFile javascriptSrc, (curr, prev) ->
    compileJs()

task 'build', 'Build everything from src/ into lib/', ->
  build()

task 'watch', 'Watch for changes to compile the sources', ->
  watch()
