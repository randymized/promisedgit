#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

Diff = require './diff'
File = require './file'

class Treeish
  # Public: Constructs a new instance of {Treeish}.
  #
  # @ref  - The object ref as {String}.
  # @repo - The repository as {GitPromised}.
  #
  # Returns: A new instance of {Treeish}.
  constructor: (@ref, @repo) ->
    throw new Error('No valid git repo!') unless @repo?.isGitRepo
    throw new Error('No valid ref!') unless (typeof(@ref) is 'string')

  # Public: Checkout the {Treeish} in git.
  #
  # Returns: Promise.
  checkout: ->
    @repo.checkout(@ref)

  # Public: Get the {Diff} this {Treeish} introduced.
  #
  # Returns: Promise that resolves to a {Diff}.
  diff: ->
    @repo.show(@ref, pretty: 'raw').then (raw) ->
      new Diff(null, raw)

  # Public: Get the diff to another {Treeish}.
  #
  # treeish - The treeish to diff against as {String} or {Treeish}.
  #
  # Returns: Promise that resolves to a {Diff}.
  diffTo: (treeish='HEAD') ->
    options = {treeish: "#{@ref}..#{treeish}"}
    @repo.getDiff(options)

  # Public: Get the diff from another {Treeish}.
  #
  # treeish - The treeish to diff against as {String} or {Treeish}.
  #
  # Returns: Promise that resolves to a {Diff}.
  diffFrom: (treeish='HEAD') ->
    options = {treeish: "#{treeish}..#{@ref}"}
    @repo.getDiff(options)

  # Public: Get the content of a file at this {Treeish}.
  #
  # file - The file as {String}.
  #
  # Returns: Promise that resolves to a {String} with the content.
  getFile: (file) ->
    return throw new Error('No valid file!') unless file?
    return file.show(@ref) if file instanceof File
    @repo(@ref, file)

  # Public: Reset the current branch to this {Treeish}.
  #
  # mode - The git-reset mode to use as {String}.
  #
  # Returns: Promise.
  reset: (mode) ->
    options = {}
    options[mode] = true if mode?

    @repo.cmd 'reset', options, @ref

module.exports = Treeish
