#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_       = require 'lodash'
Promise = require 'bluebird'

Diff = require './diff'
File = require './file'

# Public: This class is the base class to allow easy access to relevant actions
# upon any kind of oid object in git.
class Treeish

  # Private: Git empty tree hash.
  GIT_ROOT_COMMIT = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'

  # Public: Constructs a new instance of {Treeish}.
  #
  # ref  - The object ref as {String}.
  # repo - The repository as {GitPromised}.
  #
  # Returns: A new instance of {Treeish}.
  constructor: (@ref, @repo) ->
    throw new Error('Invalid ref') unless _.isString(@ref)
    throw new Error('Invalid repository instance') unless @repo?.isGitRepo

  # Public: Checkout the {Treeish} in git.
  #
  # options - The options as plain {Object}.
  #
  # Returns: Promise.
  checkout: (options={}) ->
    @repo.checkout(@ref, options)

  # Public: Get the {Diff} this {Treeish} introduced.
  #
  # options - The options as plain {Object}.
  #
  # Returns a Promise that resolves to an instance of {Diff}.
  diff: (options={}) ->
    @repo.cmd('diff', options, "#{@ref}~..#{@ref}")
    .catch => @repo.cmd('diff', options, "#{GIT_ROOT_COMMIT}..#{@ref}")
    .then (raw) -> new Diff(null, raw)

  # Public: Get the diff to another {Treeish}.
  #
  # oid     - The oid to diff against as {String}|{Treeish}.
  # options - The options as plain {Object}.
  #
  # Returns a Promise that resolves to an instance of {Diff}.
  diffTo: (oid='HEAD', options={}) ->
    oid = oid.ref if oid instanceof Treeish
    options = _.extend options, {treeish: "#{@ref}..#{oid}"}
    return @repo.getDiff(options) if _.isString(oid)
    return Promise.reject(new Error('Invalid oid'))

  # Public: Get the diff from another {Treeish}.
  #
  # oid     - The oid to diff against as {String}|{Treeish}.
  # options - The options as plain {Object}.
  #
  # Returns a Promise that resolves to an instance of {Diff}.
  diffFrom: (oid='HEAD', options={}) ->
    oid = oid.ref if oid instanceof Treeish
    options = _.extend options,{treeish: "#{oid}..#{@ref}"}
    return @repo.getDiff(options) if _.isString(oid)
    return Promise.reject(new Error('Invalid oid'))

  # Public: Get the content of a file at this {Treeish}.
  #
  # file - The file as {String}.
  #
  # Returns a Promise that resolves to a {String} with the content of file at
  #   this treeish.
  showFile: (file) ->
    return file.show(@ref) if file instanceof File
    return @repo.show(@ref, file) if _.isString(file)
    return Promise.reject(new Error('Invalid file'))

  # Public: Reset the current branch to this {Treeish}.
  #
  # mode - The git-reset mode to use as {String}.
  #
  # Returns: Promise.
  reset: (mode) ->
    options = {}
    options[mode] = true if _.isString(mode)

    @repo.cmd 'reset', options, @ref

module.exports = Treeish
