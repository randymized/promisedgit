shell   = require 'shelljs'
Promise = require 'bluebird'

module.exports = (command, options) ->
  command = 'git ' + command if command.substring(0, 4) isnt 'git '

  if options? and options?.cwd
    shell.config.silent = true
    shell.pushd options.cwd
    shell.config.silent = false
  else
    shell.config.silent = true
    shell.pushd process.cwd()
    shell.config.silent = false

  new Promise (resolve, reject) ->
    shell.exec command, silent: true, (code, output) ->
      if code isnt 0
        error = new Error("'#{command}' exited with error code #{code}")
        error.code = code
        error.stdout = output
        reject(error)
      resolve(output)
