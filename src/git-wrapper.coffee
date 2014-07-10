#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_       = require 'lodash'
fs      = require 'fs'
shell   = require 'shelljs'
Promise = require 'bluebird'

# Internal: GitWrapper parses our commands to and the output from the CLI. You
#           can access it through the {GitPromised::cmd} method.
class GitWrapper

  # Public: Git CLI wrapper.
  #
  # command - The command to execute as {String}.
  # options - The options to pass as {Object}.
  #           :treeish - If you need to specifiy a git treeish range do it here.
  #                      Example: `HEAD..HEAD~5`.
  # args    - The args to pass as {String} or {Array}.
  # cwd     - The current working directory as {String}.
  #
  # Returns: Promise that resolves to the stdout/stderr.
  @cmd: (command, options, args, cwd) ->
    if _.isArray(options) or _.isString(options)
      [args, cwd] = [options, args]
    command = 'git ' + command if command.substring(0, 4) isnt 'git '

    # `options` and `args` are optional, `cwd` is not.
    if not fs.existsSync(cwd)
      [options, cwd] = [null, options] if fs.existsSync(options)
      [args, cwd] = [null, args] if fs.existsSync(options)

    if not fs.existsSync(cwd)
      return throw new Error("'#{cwd}' is no valid repository path!")

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

  # Private: Converts the options object into an array.
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

  # Private: Escapes the argument(s) and formats them.
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

  # Private: Helper method to escape shell arguments.
  #
  # cmd - The command to escape as {String}.
  #
  # Returns: The escaped command as {String}.
  escapeShellArg = (cmd) ->
    cmd = cmd.trim() if typeof(cmd) is 'string'
    cmd = '\"' + cmd.replace(/\"/g, '"\\""') + '\"' if ' ' in cmd or '"' in cmd
    cmd

module.exports = GitWrapper.cmd
