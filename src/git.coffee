_       = require 'underscore'
shell   = require 'shelljs'
Promise = require 'bluebird'

module.exports = (command, options, args, cwd) ->
  if options instanceof Array or options instanceof String
    [options, args] = [args, options]
  command = 'git ' + command if command.substring(0, 4) isnt 'git '
  pushDir(cwd)

  options ?= {}
  options = options_to_argv options

  # Escape if necessary
  for val, i in options
    options[i] = val = val.trim()
    options[i] = escapeShellArg(val) if ' ' in val or '"' in val

  options = options.join ' '

  args ?= []

  # Escape if necessary
  for arg, i in args
    args[i] = arg = arg.trim()
    args[i] = escapeShellArg(arg) if ' ' in arg or '"' in arg

  args = args.join ' ' if args instanceof Array

  command = "#{command} #{options} #{args}"
  new Promise (resolve, reject) ->
    shell.exec command, silent: true, (code, output) ->
      if code isnt 0
        error = new Error("'#{command}' exited with error code #{code}")
        error.code = code
        error.stdout = output
        reject(error)
      resolve if output?.length > 0 then output else null

pushDir = (cwd) ->
  cwd ?= process.cwd()
  shell.config.silent = true
  shell.pushd cwd
  shell.config.silent = false

options_to_argv = (options) ->
  argv = []
  for key, val of options
    if key is 'treeish'
      argv.push val
    else if key.length == 1
      if val == true
        argv.push "-#{key}"
      else if val == false
        # ignore
      else
        argv.push "-#{key}"
        argv.push val
    else
      if val == true
        argv.push "--#{key}"
      else if val == false
        # ignore
      else
        argv.push "--#{key}=#{val}"
  return argv

escapeShellArg = (cmd) ->
  '\"' + cmd.replace(/\"/g, '"\\""') + '\"'
