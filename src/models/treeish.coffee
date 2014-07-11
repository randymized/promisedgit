#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_       = require 'lodash'
Promise = require 'bluebird'

Diff = require './diff'
File = require './file'

# Public: This class is the base class to allow easy access to relevant actions
# upon any kind of treeish object in git.
class Treeish

  # Private: Git magic root commit hash.
  GIT_ROOT_COMMIT = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'

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
  checkout: (options={}) ->
    @repo.checkout(@ref, options)

  # Public: Get the {Diff} this {Treeish} introduced.
  #
  # Returns: Promise that resolves to a {Diff}.
  diff: (options={}) ->
    @repo.cmd('diff', options, "#{@ref}~..#{@ref}")
    .catch => @repo.cmd('diff', options, "#{GIT_ROOT_COMMIT}..#{@ref}")
    .then (raw) -> new Diff(null, raw)

  # Public: Get the diff to another {Treeish}.
  #
  # treeish - The treeish to diff against as {String} or {Treeish}.
  #
  # Returns: Promise that resolves to a {Diff}.
  diffTo: (treeish='HEAD') ->
    treeish = treeish.ref if treeish instanceof Treeish
    options = {treeish: "#{@ref}..#{treeish}"}
    return @repo.getDiff(options) if _.isString(treeish)
    return Promise.reject(new Error('Invalid treeish.'))

  # Public: Get the diff from another {Treeish}.
  #
  # treeish - The treeish to diff against as {String} or {Treeish}.
  #
  # Returns: Promise that resolves to a {Diff}.
  diffFrom: (treeish='HEAD') ->
    treeish = treeish.ref if treeish instanceof Treeish
    options = {treeish: "#{treeish}..#{@ref}"}
    return @repo.getDiff(options) if _.isString(treeish)
    return Promise.reject(new Error('Invalid treeish.'))

  # Public: Get the content of a file at this {Treeish}.
  #
  # file - The file as {String}.
  #
  # Returns: Promise that resolves to a {String} with the content.
  showFile: (file) ->
    return file.show(@ref) if file instanceof File
    return @repo.show(@ref, file) if _.isString(file)
    return Promise.reject(new Error('Invalid file.'))

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
