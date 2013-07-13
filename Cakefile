fs = require('fs')
{print} = require('sys')
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
  console.log timeNow() + ' - running: ' + bin + ' ' + (if options? then options.join(' ') else "")
  cmd = spawn bin, options
  cmd.stdout.on 'data', (data) -> print data.toString()
  cmd.stderr.on 'data', (data) -> print data.toString()
  cmd.on 'exit', (code) ->
    console.log 'done.'
    onExit?(code, options)

compileView = (done) ->
  options = ['-o', 'lib', 'src/api_mate.jade']
  run 'jade', options, ->
    done?()

compileCss = (done) ->
  options = ['src/api_mate.scss', 'lib/api_mate.css']
  run 'node-sass', options, ->
    done?()

compileJs = (done) ->
  options = ['-c', '-o', 'lib', 'src/api_mate.coffee']
  run 'coffee', options, ->
    done?()

build = (done) ->
  compileView (err) ->
    unless err
      compileCss (err) ->
        unless err
          compileJs (err) ->
            done?()

task 'build', 'Build everything from src/ into lib/', ->
  build()
