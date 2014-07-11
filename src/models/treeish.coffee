#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_ = require 'lodash'

Diff = require './diff'
File = require './file'

# Public: This class is the base class to allow easy access to relevant actions
# upon any kind of treeish object in git.
class Treeish
  # Public: Constructs a new instance of {Treeish}.
  #
  # ref  - The object ref as {String}.
  # repo - The repository as {GitPromised}.
  #
  # Returns: A new instance of {Treeish}.
  constructor: (@ref, @repo) ->
    throw new Error('No valid ref!') unless _.isString(@ref)
    throw new Error('No valid git repo!') unless @repo?.isGitRepo

  # Public: Checkout the {Treeish} in git.
  #
  # Returns: Promise.
  checkout: ->
    @repo.checkout(@ref)

  # Public: Get the {Diff} this {Treeish} introduced.
  #
  # Returns: Promise that resolves to a {Diff}.
  diff: ->
    @repo.cmd('diff', [@ref, "#{@ref}~"]).then (raw) ->
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
    throw new Error('No valid file!') unless file?
    return file.show(@ref) if file instanceof File
    @repo.show(@ref, file)

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
