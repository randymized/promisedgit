_       = require 'underscore'
fs      = require 'fs'
Promise = require 'bluebird'

git     = require './git'
Status  = require './models/status'
Commit  = require './models/commit'
Diff    = require './models/diff'

module.exports=
class Git

  # Public: Constructor
  #
  # cwd - The {String} representing the cwd.
  constructor: (cwd) ->
    @cwd = cwd if cwd?
    @cwd ?= process.cwd()
    throw new Error("'#{@cwd}' does not exist!") unless fs.existsSync(@cwd)

  # Public: Run git command.
  #
  # command - The {String} command to execute.
  # options - The {Object} containing options
  #
  # args    - The {Array} or {String} representing the arguments to pass.
  #
  # Returns: Promise resolving the stdout from CLI.
  cmd: (command, options, args) ->
    if options instanceof Array or options instanceof String
      [options, args] = [args, options]
    options ?= {}
    args ?= []

    git(command, options, args, @cwd)

  # Public: Initialize the cwd.
  init: ->
    @cmd 'init'

  # Public: Get the repo status.
  #
  # Returns: Promise resolving to {::Status}
  status: ->
    options =
      z: true
      b: true

    @cmd 'status', options
      .then (raw) -> Status.parse(raw)

  # Public: Get an array of commits from the current repo.
  #
  # treeish - The {String} Treeish.
  # limit   - The {Integer} amount of commits to show.
  #
  # Returns:  Promise resolving to an {Array} of {::Commit}s.
  commits: (treeish='HEAD', limit=15) ->
    options =
      pretty: 'raw'
      'max-count': limit
    args = treeish

    @cmd 'rev-list', options, args
      .then (raw) ->
        return Commit.parse(raw)

  # Public: Get the diff for path.
  #
  # file    - The {String} (or multiple in an {Array}) with the path of the file
  #           to diff.
  #           If you pass no file path(s), it will diff all modified files.
  # options - The {Object} with options git-diff.
  #   :cached - {Boolean} Show the diff from index.
  #
  # Returns: Promise resolving to {::Diff} if you passed a single path or to an
  #          {Array} of {::Diffs} if you passed an {Array} or nothing for file.

  diff: (file, options={}) ->
    if (typeof(file) isnt 'string') and not (file instanceof Array)
      options = file
      options ?= {}

      @status().bind(this).then (o) ->
        paths = if 'cached' of options
          o.staged.map ({path}) -> path
        else
          o.unstaged.map ({path}) -> path
        @diff(paths, options)
    else
      if file instanceof Array
        Promise.all (@diff(path, options) for path in file)
      else
        _.extend options, {'p': true, 'unified': 1, 'no-color': true}
        @cmd 'diff', options, file
          .then (raw) ->
            return throw new Error("'#{file}' has no diffs! Forgot '--cached'?") unless raw?
            return new Diff(file, raw)

  # Public: Refresh the git index.
  #
  # Returns: Promise.
  refreshIndex: ->
    options =
      refresh: true

    @cmd 'add', options, '.'

  # Public: Add file(s) to the index.
  #
  # file - The {String} or {Array} of files to add to index.
  #        Defaults to add all files!
  #
  # Returns: Promise.
  add: (file) ->
    file ?= '.'
    options =
      A: true
    @cmd 'add', options, file

  # Public: Checkout file.
  #
  # file - The {String} with the file to checkout.
  #        Defaults to checking out all files with changes!
  #
  # Returns:  Promise.
  checkoutFile: (file) ->
    options = {f: true} unless file?
    @cmd 'checkout', options, file

  # Public: Reset repo to treeish.
  #
  # treeish - The {String} to reset to. (Default: 'HEAD')
  # options - The {Object} with flags for git CLI.
  #   :soft  - {Boolean)
  #   :mixed - {Boolean) When no other option given git defaults to 'mixed'.
  #   :hard  - {Boolean)
  #   :merge - {Boolean)
  #   :keep  - {Boolean)
  #
  # Returns: Promise.
  reset: (treeish='HEAD', options={}) ->
    [treeish, options] = ['HEAD', treeish] if typeof(treeish) is 'object'
    @cmd 'reset', options, treeish

  # Public: Remove given file(s) from the index but leave it/them in the
  #         working tree.
  #
  # file - The {String} or {Array} of files to unstage.
  #
  # Returns: Promise.
  unstage: (file) ->
    return Promise.reject('No file given') unless file?
    file = [file] unless file instanceof Array
    file.unshift 'HEAD', '--'

    @cmd 'reset', file
