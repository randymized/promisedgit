_       = require 'underscore'
fs      = require 'fs'
Promise = require 'bluebird'

git     = require './git'
Status  = require './models/status'
Commit  = require './models/commit'
Diff    = require './models/diff'

module.exports=
class Git

  constructor: (cwd) ->
    @cwd = cwd if cwd?
    @cwd ?= process.cwd()
    throw new Error("'#{@cwd}' does not exist!") unless fs.existsSync(@cwd)

  cmd: (command, options, args) ->
    if options instanceof Array or options instanceof String
      [options, args] = [args, options]
    options ?= {}
    args ?= []

    git(command, options, args, @cwd)

  init: ->
    @cmd 'init'

  status: ->
    options =
      z: true
      b: true

    @cmd 'status', options
      .then (raw) -> Status.parse(raw)

  commits: (treeish='HEAD', limit=15, skip=0) ->
    options =
      pretty: 'raw'
      'max-count': limit
    args = treeish

    @cmd 'rev-list', options, args
      .then (raw) ->
        return Commit.parse(raw)

  diff: (path, options={}) ->
    return Promise.reject('No path given') unless path?
    _.extend options, {'p': true, 'unified': 1, 'no-color': true}

    @cmd 'diff', options, path
      .then (raw) ->
        return new Diff(path, raw)

  refreshIndex: ->
    options =
      refresh: true

    @cmd 'add', options, '.'

  add: (file) ->
    file ?= '.'
    options =
      A: true
    @cmd 'add', options, file

  checkoutFile: (file) ->
    options = {f: true} unless file?
    @cmd 'checkout', options, file

#  checkout: ->
#  cherryPick: ->
#  fetch: ->
#  pull: ->
#  push: ->
#  init: ->
#  log: ->
#  show: ->
#  stageFile: ->
#  unstageFile: ->
#  tags: ->
