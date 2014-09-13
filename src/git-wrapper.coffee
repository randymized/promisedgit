#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_       = require './lodash'
fs      = require 'fs'
Promise = require 'bluebird'
{exec}  = require 'child_process'

# Internal: GitWrapper parses our commands to and the output from the CLI. You
#           can access it through the {PromisedGit::cmd} method.
class GitWrapper

  # Public: Git CLI wrapper.
  #
  # command - The command to execute as {String}.
  # options - The options to pass as {Object}.
  #           :treeish - Set a treeish range, for example `HEAD..HEAD~5`.
  # args    - The args to pass as {String}|{Array}.
  # cwd     - The current working directory as {String}.
  #
  # Returns: Promise that resolves to the git cli output.
  @cmd: (command, options, args, cwd) ->
    if _.isArray(options) or _.isString(options)
      [args, cwd] = [options, args]

    # `options` and `args` are optional, `cwd` is not.
    if not fs.existsSync(cwd) and fs.existsSync(args)
      [cwd, args] = [args, null]
    else if not fs.existsSync(cwd)
      throw new Error("'#{cwd}' is no valid repository path!")

    args = args_to_argv(args)
    options = options_to_argv(options)
    command = "#{command} #{options} #{args}"
    command = 'git ' + command if command.substring(0, 4) isnt 'git '

    new Promise (resolve, reject) ->
      exec command,                         # Command
      {cwd: cwd, maxBuffer: 100*1024*1024}, # Options
      (error, stdout, stderr) ->            # Callback
        if error
          error.message = stderr
          reject(error)
        else
          resolve stdout

  # Private: Converts the options object into an array.
  #
  # options - The options as {Object}.
  #
  # Returns the escaped and formatted options as {String}.
  options_to_argv = (options={}) ->
    argv = []
    treeish = null

    for key, val of options
      if key is 'treeish'
        treeish = val
      else if key.length == 1
        argv.push "-#{key} #{escapeShellArg(val)}" unless _.isBoolean(val)
        argv.push "-#{key}" if val is true
      else
        argv.push "--#{key}=#{escapeShellArg(val)}" unless _.isBoolean(val)
        argv.push "--#{key}" if val is true
    argv.push(treeish, '--') if treeish

    argv.join(' ')

  # Private: Escapes the argument(s) and formats them.
  #
  # args - The arguments as {String}|{Array}.
  #
  # Returns the escaped and formatted arguments as {String}.
  args_to_argv = (args=[]) ->
    if _.isArray(args)
      argv = (escapeShellArg(arg) for arg in args)
      argv.join(' ')
    else if _.isString(args)
      escapeShellArg(args)
    else
      ''

  # Private: Helper method to escape shell arguments.
  #
  # cmd - The command to escape as {String}.
  #
  # Returns the escaped command as {String}.
  escapeShellArg = (cmd) ->
    if _.isString(cmd)
      cmd = cmd.trim()
      if ' ' in cmd or '"' in cmd
        '\"' + cmd.replace(/\"/g, '"\\""') + '\"'
      else
        cmd
    else if _.isNumber(cmd)
      cmd
    else
      ''

module.exports = GitWrapper.cmd
