#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_       = require './lodash'
fs      = require 'fs'
path    = require 'path'
Promise = require 'bluebird'

git = require './git-wrapper'
{Amend, Commit, Diff, File, Status, Tag, Treeish} = require './models'

# Public: Main class. Instances represent the whole git repository.
#
# You must provide a valid working directory to the constructor.
#
# ##Example
# ```coffee
# Git = require 'promised-git'
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
class PromisedGit
  # Public: Construct a new {PromisedGit} instance.
  #
  # cwd - The path of the git repository as {String}.
  constructor: (@cwd) ->
    if not fs.existsSync(cwd)
      throw new Error("'#{cwd}' does not exist!")

  # Public: Add file(s) to the index.
  #
  # ###Example
  # ```coffee
  #   Git = require 'promised-git'
  #   git = new Git('/tmp/exampleRepo')
  #
  #   git.add()                       # => Adds all unstaged changes to the index.
  #   git.add('a.coffee')             # => Adds 'a.coffee' to the index.
  #   git.add('a.coffee', 'b.coffee') # => Adds 'a.coffee' and 'b.coffee' to the index.
  # ```
  # You can use instances of {File} instead of the path:
  # ```coffee
  #   Git = require 'promised-git'
  #   git = new Git('/tmp/exampleRepo')
  #
  #   git.status().then (o) ->
  #     file = o.unstaged[0]
  #     git.add(file)                 # => Adds the first unstaged {File} to the index.
  # ```
  # file - The file(s) to add as {String}|{File}|{Array}.
  #
  # Returns: Promise.
  add: (file) ->
    if _.isArray(file)
      file = _.map file, (val) ->
        if _.isFile(val)
          val.path
        else
          val
    else if _.isFile(file)
      file = file.path
    else if not _.isString(file)
      file = '.'

    @cmd 'add', {A: true}, file

  # Public: Amend HEAD.
  #
  # Returns a Promise that resolves to an instance of {Amend}.
  amend: ->
    @cmd 'log', {'1': true, format: '%B'}
    .then (amendMessage) => new Amend(amendMessage, this)

  # Public: Checkout a oid.
  #
  # oid     - The oid to checkout as {String}|{Treeish}.
  # options - The options as plain {Object}.
  #
  # Returns: Promise.
  checkout: (oid='HEAD', options={}) ->
    if _.isPlainObject(oid)
      [options, oid] = [oid, 'HEAD']
    @cmd 'checkout', options, oid

  # Public: Checkout file.
  #
  # file - The file(s) to add to the index as {String}|{File}|{Array}.
  # oid  - The oid to check the file out to.
  #
  # Returns:  Promise.
  checkoutFile: (file, oid='HEAD') ->
    options =
      f: true
      treeish: oid

    if _.isArray(file)
      file = _.map file, (val) ->
        if _.isFile(val)
          val.path
        else
          val
    else if _.isFile(file)
      file = file.path
    else if not _.isString(file)
      return Promise.reject new Error("Invalid file: '#{file}'")

    @cmd 'checkout', options, file

  # Public: Access to the {GitWrapper}. Use it to execute custom git commands.
  #
  # command - The command to execute as {String}.
  # options - The options to pass as {Object}.
  #           :treeish - Set a treeish range, for example `HEAD..HEAD~5`.
  # args    - The args to pass as {String}|{Array}.
  #
  # Returns a Promise that resolves to the git cli output.
  cmd: (command, options, args) ->
    if _.isArray(options) or _.isString(options)
      [options, args] = [null, options]
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
    if not _.isString(message)
      return Promise.reject(new Error('No commit message!'))

    # Set '--cleanup=strip' unless '--cleanup' has already been set.
    if not _.has(options, 'cleanup')
      options.cleanup = 'strip'

    if fs.existsSync(message)
      options.file = message
    else
      options.m = message

    @cmd 'commit', options

  # Public: Get the diff for a file.
  #
  # file    - The file(s) to diff as {String}|{File}|{Array}.
  #           If you pass no file path(s), it will diff all modified files.
  # options - The {Object} with options for git-diff.
  #           :cached - {Boolean} Show the diff from index.
  #
  # Returns: Promise resolving to {Diff} if you passed a single path or to an
  #          {Array} of {Diff}s if you passed an {Array} or nothing for file.
  getDiff: (file, options={}) ->
    if _.isPlainObject(file)
      [options, file] = [file, null]

    if not (_.has(options, 'treeish') or file?)
      @status().then (o) =>
        paths = if 'cached' of options
          _.map(o.staged, 'path')
        else
          _.map(o.unstaged, 'path')
        @getDiff(paths, options)
    else if _.isArray(file)
      diffs = for filePath in file
        @getDiff(filePath, options)
        .then (diff) -> diff
        .catch -> null
      Promise.all(diffs).then(_.compact)
    else
      _.extend options, {'p': true, 'unified': 1, 'no-color': true}
      @cmd 'diff', options, file
      .then (raw) ->
        if not raw?.length > 0
          throw new Error("'#{file}' has no diffs! Forgot '--cached'?")
        new Diff(file, raw)


  # Public: Retrieve the maxCount newest tags.
  #
  # maxCount - The maximum amount of tags to return as {Number}.
  #
  # Returns a Promise that resolves to an {Array} of {Tag}s.
  getTags: (maxCount=15) ->
    options =
      format: '%(objectname) %(refname)'
      sort: 'authordate'
      count: maxCount

    @cmd 'for-each-ref', options, 'refs/tags/'
    .then (raw) =>
      if not raw?.length > 0
        throw new Error('No tags available')
      tags = raw.split('\n')[...-1]
      Promise.map tags, (tagRaw) => new Tag(tagRaw, this)

  # Public: Initialize the git repository.
  init: ->
    @cmd 'init'

  # Public: Get the log for the current repository.
  #
  # ref   - The ref to get the log for as {String}.
  # limit - The maximum amount of commits to show as {Number}.
  #
  # Returns:  Promise resolving to an {Array} of {Commit}s.
  log: (ref='HEAD', limit=15) ->
    [ref, limit] = ['HEAD', ref] if _.isNumber(ref)
    options =
      'header': true
      'max-count': limit

    @cmd 'rev-list', options, ref
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

  # Public: Reset repo to oid.
  #
  # oid     - The oid to reset to as {String}.
  # options - The {Object} with flags for git CLI.
  #           :soft  - {Boolean)
  #           :mixed - {Boolean) [Default]
  #           :hard  - {Boolean)
  #           :merge - {Boolean)
  #           :keep  - {Boolean)
  #
  # Returns: Promise.
  reset: (oid='HEAD', options={}) ->
    if _.isTreeish(oid)
      oid = oid.ref
    else if _.isPlainObject(oid)
      [options, oid] = [oid, 'HEAD']

    @cmd 'reset', options, oid

  # Public: git-rev-parse oid.
  #
  # oid - The oid to rev-parse as {String}|{Treeish}.
  #
  # Returns a Promise that resolves to the rev-parsed oid.
  revParse: (oid='HEAD', options={}) ->
    if _.isTreeish(oid)
      oid = oid.ref
    else if _.isPlainObject(oid)
      [options, oid] = [oid, 'HEAD']
    else if not _.isString(oid)
      return Promise.reject(new Error 'Invalid oid')

    @cmd 'rev-parse', options, oid

  # Public: Wrapper for git-show.
  #         If you pass oid and file you get the file at oid.
  #         If you only pass oid you get the head of oid.
  #         If you only pass file you get the changes made by HEAD to file.
  #
  # oid     - The treeish to show as {String}|{Treeish}.
  # file    - The file to show as {String}|{File}.
  # options - The options as plain {Object}.
  #
  # Returns: Promise.
  show: (oid, file, options) ->
    if _.isTreeish(file)
      [oid, file] = [file, oid]
    else if _.isFile(oid)
      [oid, file] = [file, oid]

    if _.isPlainObject(file)
      [options, file] = [file, null]
    else if _.isPlainObject(oid)
      [options, oid]  = [oid, null]

    if not file? and _.isString(oid)
      isTreeishAnExistingPath = fs.existsSync(path.join(@cwd, oid))
      if isTreeishAnExistingPath
        [oid, file] = [file, oid]

    if _.isTreeish(oid)
      oid = oid.ref
    else if not _.isString(oid)
      oid = ''

    if _.isFile(file)
      file = file.path
    else if not _.isString(file)
      file = ''

    if file.length isnt 0 and oid.length isnt 0
      file = ":#{file}"

    @cmd 'show', options, "#{oid}#{file}"

  # Public: Get the repo status.
  #
  # Returns a Promise resolving to an instance of {Status}.
  status: ->
    options =
      z: true
      b: true

    @cmd 'status', options
      .then (raw) => new Status(raw, this)

  # Public: Unstage file(s) from the index.
  #
  # file - The file(s) to unstage as {String}|{File}|{Array}.
  #        If you pass nothing or a '.' it will unstage all files from index.
  #
  # Returns: Promise.
  unstage: (file) ->
    if _.isArray(file)
      file = _.map file, (val) ->
        if _.isFile(val)
          val.path
        else
          val
    else if _.isFile(file)
      file = file.path
    else if not _.isString(file)
      file = '.'

    @cmd 'reset', {treeish: 'HEAD'}, file

module.exports = PromisedGit
