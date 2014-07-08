#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

Diff = require './diff'
File = require './file'

module.exports =
class Treeish

  constructor: (@ref, @repo) ->
    throw new Error('No valid git repo!') unless @repo?.isGitRepo
    throw new Error('No valid ref!') unless (typeof(@ref) is 'string')

  checkout: ->
    @repo.checkout(@ref)

  diff: (treeish='HEAD') ->
    options = {treeish: "#{@ref}..#{treeish}"}
    @repo.getDiff(options)

  diffFrom: (treeish='HEAD') ->
    options = {treeish: "#{treeish}..#{@ref}"}
    @repo.getDiff(options)

  getFile: (file) ->
    return throw new Error('No valid file!') unless file?
    return file.show(@ref) if file instanceof File
    @repo(@ref, file)

  reset: (mode) ->
    options = {}
    options[mode] = true if mode?

    @repo.cmd 'reset', options, @ref
