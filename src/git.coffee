#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_       = require 'underscore'
shell   = require 'shelljs'
Promise = require 'bluebird'


# Internal: Git CLI wrapper.
#
# command - The command to execute as {String}.
# options - The options to pass as {Object}.
#  :treeish - If you need to specifiy a git treeish range do it here.
#             Èxample: `HEAD..HEAD~5`.
# args    - The to pass as {String|Array}.
# cwd     - The current working directory as {String}.
#
# Returns: Promise that resolves to the stdout/stderr.
module.exports = (command, options, args, cwd) ->
  if options instanceof Array or typeof(options) is 'string'
    [options, args] = [args, options]
  command = 'git ' + command if command.substring(0, 4) isnt 'git '

  # Supress the default shell output to user console.
  shell.silent = true
  shell.cd cwd ? process.cwd()

  args = args_to_argv(args)
  options = options_to_argv(options)

  command = "#{command} #{options} #{args}"
  new Promise (resolve, reject) ->
    shell.exec command, {silent: true, async: true}, (code, output) ->
      if code isnt 0
        error = new Error("'#{command}' exited with error code #{code}")
        error.code = code
        error.stderr = output
        reject(error)
      resolve(output)

# Internal: Converts the options object into an array.
#
# options - The options as {Object}.
#
# Returns: The escaped and formatted options as {String}.
options_to_argv = (options={}) ->
  argv = []
  for key, val of options
    # If there is a key named 'treeish' the user specified a git treeish range.
    if key is 'treeish'
      argv.push val
      # argv.push escapeShellArg(val)
    else if key.length == 1
      if val == true
        argv.push "-#{key}"
      else if val == false
        # ignore
      else
        argv.push "-#{key}"
        argv.push escapeShellArg(val)
    else
      if val == true
        argv.push "--#{key}"
      else if val == false
        # ignore
      else
        argv.push "--#{key}=#{escapeShellArg(val)}"

  argv.join(' ')

# Internal: Escapes the argument(s) and formats them.
#
# args - The arguments as {String|Array}.
#
# Returns: The escaped and formatted arguments as {String}.
args_to_argv = (args=[]) ->
  if args instanceof Array
    argv = (escapeShellArg(arg) for arg in args)
    argv.join(' ')
  else if typeof(args) is 'string'
    escapeShellArg(args)
  else
    ''

# Internal: Helper method to escape shell arguments.
#
# cmd - The command to escape as {String}.
#
# Returns: The escaped command as {String}.
escapeShellArg = (cmd) ->
  cmd = cmd.trim() if typeof(cmd) is 'string'
  cmd = '\"' + cmd.replace(/\"/g, '"\\""') + '\"' if ' ' in cmd or '"' in cmd
  cmd
