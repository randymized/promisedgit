_            = require 'underscore'
fs           = require 'fs'
path         = require 'path'
Promise      = require 'bluebird'
{Collection} = require 'backbone'

git = require './git'
{Commit, Diff, File, Status, Tag, Treeish} = require './models'

module.exports=
class Git

  files: new Collection()
  refs:  new Collection()

  # Public: Constructor
  #
  # cwd - The {String} representing the cwd.
  constructor: (cwd) ->
    @cwd = cwd if cwd?
    @cwd ?= process.cwd()
    return throw new Error("'#{@cwd}' does not exist!") unless fs.existsSync(@cwd)
    @isGitRepo = true

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

  # Public: constructor the cwd.
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
      .bind(this).then (raw) -> Status.parse(raw, this)

  # Public: Get an array of commits from the current repo.
  #
  # treeish - The {String} Treeish.
  # limit   - The {Integer} amount of commits to show.
  #
  # Returns:  Promise resolving to an {Array} of {::Commit}s.
  log: (treeish='HEAD', limit=15, skip=0) ->
    options =
      'skip': skip
      'max-count': limit

    @cmd 'rev-list', options, treeish
      .bind(this)
      .then (hashes) ->
        hashes = hashes.split('\n')[...-1]
        commits = for hash in hashes
          @show(hash, {pretty: 'raw', q: true})
          .bind(this)
          .then (raw) -> Commit.parse(raw, this)
        Promise.all(commits)

  # Public: Get the diff for a file.
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
    if not (file instanceof File) and not (typeof(file) is 'string') and not Array.isArray(file)
      options = file if file?
      file = null
    if not ('treeish' of options) and not file?
      @status().bind(this).then (o) ->
        paths = if 'cached' of options
          o.staged.map ({filePath}) -> filePath
        else
          o.unstaged.map ({filePath}) -> filePath
        @diff(paths, options)
    else if file instanceof Array
      diffs = for filePath in file
        @diff(filePath, options)
        .then (diff) -> diff
        .catch -> null
      Promise.all(diffs).then(_.compact)
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
    treeish = treeish.ref if treeish instanceof Treeish
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

    @cmd 'reset', {}, file

  # Public: Wrapper for git-show.
  #         If you pass treeish and file you get the file@treeish.
  #         If you only pass treeish you get the head of treeish.
  #         If you only pass file you get the changes made by HEAD to file.
  #
  # treeish - The {String} or {::Treeish} to show.
  # file    - The {String} or {::File} to show.
  # options - The {Object} options.
  #
  # Returns: Promise.
  show: (treeish, file, options) ->
    [treeish, file] = [file, treeish] if file instanceof Treeish
    [treeish, file] = [file, treeish] if treeish instanceof File
    if treeish instanceof Object and not (typeof(treeish) is 'string') and not options?
      [treeish, options] = [options, treeish] unless treeish instanceof Treeish
    if file instanceof Object and not (typeof(file) is 'string') and not options?
      [file, options] = [options, file] unless file instanceof File

    if not file? and (typeof(treeish) is 'string')
      [treeish, file] = [file, treeish] if fs.existsSync(path.join(@cwd, treeish))

    treeish = treeish.ref if treeish instanceof Treeish
    treeish = '' unless typeof treeish is 'string'
    file = file.filePath if file instanceof File
    file = '' unless typeof file is 'string'
    file = ":#{file}" unless file.length is 0 or treeish.length is 0

    @cmd 'show', options, "#{treeish}#{file}"

  # Public: Retrieve the maxCount newest tags.
  #
  # maxCount - The {Number} of tags to return. (Default: 15)
  #
  # Returns: Promise that resolves to an array of {::Tag}s.
  tags: (maxCount=15) ->
    options =
      format: '"%(objectname) %(refname)"'
      sort: 'authordate'
      count: maxCount

    @cmd 'for-each-ref', options, 'refs/tags/'
      .bind(this)
      .then (raw) -> Tag.parse(raw, this)
