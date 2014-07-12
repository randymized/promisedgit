#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_  = require 'lodash'
fs = require 'fs'

Treeish = require './treeish'

# Public: Represents a file and its status.
class File
  # Public: Constructs a new instance of {File}.
  #
  # path - The file path as {String}.
  # repo     - The repository as {GitPromised}.
  # mode     - The porcelain status as {String}.
  constructor: (@path, @repo, @mode='  ') ->
    throw new Error('Invalid git repo.') unless @repo?.isGitRepo
    throw new Error('Invalid file path.') unless _.isString(@path)
    @parseMode()

  # Public: Update the porcelain status.
  #
  # mode - The porcelain status as {String}.
  update: (@mode) ->
    @parseMode()

  # Internal: Parses the porcelain status.
  parseMode: ->
    @modeIndex = @mode.substring(0, 1)
    @modeWorkingTree = @mode.substring(1, 2)

  # Public: Test if the file is added.
  #
  # Returns: {Boolean}
  isAdded: ->
    @mode.contains('A')

  # Public: Test if the file is copied.
  #
  # Returns: {Boolean}
  isCopied: ->
    @mode.contains('C')

  # Public: Test if the file is deleted.
  #
  # Returns: {Boolean}
  isDeleted: ->
    @mode.contains('D')

  # Public: Test if the file is modified.
  #
  # Returns: {Boolean}
  isModified: ->
    @mode.contains('M')

  # Public: Test if the file is renamed.
  #
  # Returns: {Boolean}
  isRenamed: ->
    @mode.contains('R')

  # Public: Test if the file is staged.
  #
  # Returns: {Boolean}
  isStaged: ->
    /[ACDMR]/g.test @modeIndex

  # Public: Test if the file is unstaged.
  #
  # Returns: {Boolean}
  isUnstaged: ->
    /[ACDMR]/g.test @modeWorkingTree

  # Public: Test if the file is untracked.
  #
  # Returns: {Boolean}
  isUntracked: ->
    @mode is '??'

  # Public: Get the content of a file at this {Treeish}.
  #
  # file - The file as {String}.
  #
  # Returns: Promise that resolves to a {String} with the content.
  show: (oid='HEAD') ->
    oid = oid.ref if _.isString(oid.ref)
    return @repo.show(oid, @path) if _.isString(oid)
    Promise.reject(new Error('Invalid oid.'))

module.exports = File
