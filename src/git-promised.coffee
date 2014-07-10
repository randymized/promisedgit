#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_            = require 'underscore'
fs           = require 'fs'
path         = require 'path'
Promise      = require 'bluebird'

git = require './git-wrapper'
{Amend, Commit, Diff, File, Status, Tag, Treeish} = require './models'

# Public: Main class. Instances represent the whole git repository.
#
# You must provide a valid working directory to the constructor.
#
# ##Example
# ```coffee
# Git = require 'git-promised'
# git = new Git('/tmp/exampleRepo')
#
# # Add all unstaged files to the index.
# git.add().then ->
#   # Commit them.
#   git.commit('Much important changes, sir').then ->
#     # What did we commit?
#     git.show('HEAD', {stat: true}).then (o) ->
#       console.log(o)
#       # commit d4e73a81525749e0538ab91a8cf9dd2e4a85a682
#       # Author: Maximilian Schüßler <git@mschuessler.org>
#       # Date:   Tue Jul 8 10:01:21 2014 +0200
#       #
#       #     Much important changes, sir
#       #
#       #  a.coffee | 2 +-
#       #  b.coffee | 2 +-
#       #  d.coffee | 4 ++++
#       #  3 files changed, 6 insertions(+), 2 deletions(-)
# ```
class GitPromised
  # Public: Create an instance representing the git repository.
  #
  # cwd - The {String} representing the cwd.
  #
  # Returns: The {GitPromised} instance.
  constructor: (@cwd) ->
    throw new Error("'#{@cwd}' does not exist!") unless fs.existsSync(@cwd)
    @isGitRepo = true

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

  # Public: Amend HEAD.
  #
  # Returns: Promise that resolves to an {Amend} instance.
  amend: ->
    @cmd 'log', {'1': true, format: '%B'}
    .then (amendMessage) => new Amend(amendMessage, this)

  # Public: Checkout a treeish.
  #
  # treeish - The treeish to checkout as {String} or {Treeish}.
  # options - The options as {Object}.
  #
  # Returns: Promise.
  checkout: (treeish='HEAD', options={}) ->
    @cmd 'checkout', options, treeish

  # Public: Checkout file.
  #
  # file - The {String} with the file to checkout.
  #        Defaults to checking out all files with changes!
  #
  # Returns:  Promise.
  checkoutFile: (file) ->
    options = {f: true} unless file?
    @cmd 'checkout', options, file

  # Public: Access to the GitWrapper. Use it to execute custom git commands.
  #
  # command - The command to execute as {String}.
  # options - The options to pass as {Object}.
  #           :treeish - If you need to specifiy a git treeish range do it here.
  #                      Example: `HEAD..HEAD~5`.
  # args    - The args to pass as {String} or {Array}.
  #
  # Returns: Promise that resolves to the stdout/stderr.
  cmd: (command, options, args) ->
    if options instanceof Array or options instanceof String
      [options, args] = [args, options]
    options ?= {}
    args ?= []

    git(command, options, args, @cwd)

  # Public: Commit the staged changes.
  #
  # message - The message or the path to the commit message file as {String}.
  # options - The options as {Object}.
  #           :cleanup - Defaults to 'strip'.
  #
  # Returns: Promise
  commit: (message, options={}) ->

    # If nothing gets passed for message abort.
    error = new Error('No commit message!')
    return Promise.reject(error) unless typeof(message) is 'string'

    # Set '--cleanup=strip' unless '--cleanup' has already been set.
    options.cleanup = 'strip' unless 'cleanup' of options

    if fs.existsSync(message)
      options.file = message
    else
      options.m = message

    @cmd 'commit', options

  # Public: Get the diff for a file.
  #
  # file    - The {String} (or multiple in an {Array}) with the path of the file
  #           to diff.
  #           If you pass no file path(s), it will diff all modified files.
  # options - The {Object} with options git-diff.
  #           :cached - {Boolean} Show the diff from index.
  #
  # Returns: Promise resolving to {Diff} if you passed a single path or to an
  #          {Array} of {Diff}s if you passed an {Array} or nothing for file.
  getDiff: (file, options={}) ->
    if not (file instanceof File) and
    not (typeof(file) is 'string') and
    not Array.isArray(file)

      options = file if file?
      file = null
    if not ('treeish' of options) and not file?
      @status().then (o) =>
        paths = if 'cached' of options
          o.staged.map ({filePath}) -> filePath
        else
          o.unstaged.map ({filePath}) -> filePath
        @getDiff(paths, options)
    else if file instanceof Array
      diffs = for filePath in file
        @getDiff(filePath, options)
        .then (diff) -> diff
        .catch -> null
      Promise.all(diffs).then(_.compact)
    else
      _.extend options, {'p': true, 'unified': 1, 'no-color': true}
      @cmd 'diff', options, file
        .then (raw) ->
          return new Diff(file, raw) if raw?.length > 0
          return throw new Error("'#{file}' has no diffs! Forgot '--cached'?")

  # Public: Retrieve the maxCount newest tags.
  #
  # maxCount - The {Number} of tags to return. (Default: 15)
  #
  # Returns: Promise that resolves to an {Array} of {Tag}s.
  getTags: (maxCount=15) ->
    options =
      format: '%(objectname) %(refname)'
      sort: 'authordate'
      count: maxCount

    @cmd 'for-each-ref', options, 'refs/tags/'
      .then (raw) =>
        return throw new Error('No tags available') unless raw.length > 0
        tags = raw.split('\n')[...-1]
        Promise.map tags, (tagRaw) => new Tag(tagRaw, this)

  # Public: Initialize the git repo.
  init: ->
    @cmd 'init'

  # Public: Get an array of commits from the current repo.
  #
  # treeish - The {String} Treeish.
  # limit   - The {Number} amount of commits to show.
  #
  # Returns:  Promise resolving to an {Array} of {Commit}s.
  log: (treeish='HEAD', limit=15, skip=0) ->
    [treeish, limit] = ['HEAD', treeish] if typeof(treeish) is 'number'
    options =
      'header': true
      'skip': skip
      'max-count': limit

    @cmd 'rev-list', options, treeish
      .then (commitsRaw) =>
        commitsRaw = commitsRaw.split('\0')?[...-1] or []
        new Commit(raw, this) for raw in commitsRaw

  # Public: Refresh the git index.
  #
  # Returns: Promise.
  refreshIndex: ->
    options =
      refresh: true

    @cmd 'add', options, '.'

  # Public: Reset repo to treeish.
  #
  # treeish - The {String} to reset to. (Default: 'HEAD')
  # options - The {Object} with flags for git CLI.
  #           :soft  - {Boolean)
  #           :mixed - {Boolean) [Default]
  #           :hard  - {Boolean)
  #           :merge - {Boolean)
  #           :keep  - {Boolean)
  #
  # Returns: Promise.
  reset: (treeish='HEAD', options={}) ->
    treeish = treeish.ref if treeish instanceof Treeish
    [treeish, options] = ['HEAD', treeish] if typeof(treeish) is 'object'

    @cmd 'reset', options, treeish

  # Public: Wrapper for git-show.
  #         If you pass treeish and file you get the file@treeish.
  #         If you only pass treeish you get the head of treeish.
  #         If you only pass file you get the changes made by HEAD to file.
  #
  # treeish - The {String} or {Treeish} to show.
  # file    - The {String} or {File} to show.
  # options - The {Object} options.
  #
  # Returns: Promise.
  show: (treeish, file, options) ->
    [treeish, file] = [file, treeish] if file instanceof Treeish
    [treeish, file] = [file, treeish] if treeish instanceof File

    if treeish instanceof Object and
    typeof(treeish) isnt 'string' and
    not options?
      [treeish, options] = [options, treeish] unless treeish instanceof Treeish
    if file instanceof Object and typeof(file) isnt 'string' and not options?
      [file, options] = [options, file] unless file instanceof File

    if not file? and typeof(treeish) is 'string'
      isTreeishAnExistingPath = fs.existsSync(path.join(@cwd, treeish))
      [treeish, file] = [file, treeish] if isTreeishAnExistingPath

    treeish = treeish.ref if treeish instanceof Treeish
    treeish = '' unless typeof treeish is 'string'
    file = file.filePath if file instanceof File
    file = '' unless typeof file is 'string'
    file = ":#{file}" unless file.length is 0 or treeish.length is 0

    @cmd 'show', options, "#{treeish}#{file}"

  # Public: Get the repo status.
  #
  # Returns: Promise resolving to {Status}
  status: ->
    options =
      z: true
      b: true

    @cmd 'status', options
      .then (raw) => new Status(raw, this)

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

    @cmd 'reset', {}, file

module.exports = GitPromised
