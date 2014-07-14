#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

# Public: This class extends lodash with functionality we need for PromisedGit.
class LodashExtended
  # Public: Mixin our methods to lodash and return the extended instance.
  #
  # Returns the extended lodash instance as {Object}.
  @extend: ->
    return @lodash if @lodash?

    extension =
      'isActor'       : @::isActor
      'isAmend'       : @::isAmend
      'isCommit'      : @::isCommit
      'isDiff'        : @::isDiff
      'isFile'        : @::isFile
      'isStatus'      : @::isStatus
      'isTag'         : @::isTag
      'isTreeish'     : @::isTreeish
      'isPromisedGit' : @::isPromisedGit
    @lodash = require 'lodash'
    @lodash.mixin(extension, {'chain': false})
    return @lodash


  # Public: Check if obj is an instance of {Actor}.
  #
  # obj - The object to check as {Object}.
  #
  # Returns {Boolean}.
  isActor: (obj) ->
    Actor = require './models/actor'
    obj instanceof Actor

  # Public: Check if obj is an instance of {Amend}.
  #
  # obj - The object to check as {Object}.
  #
  # Returns {Boolean}.
  isAmend: (obj) ->
    Amend = require './models/amend'
    obj instanceof Amend

  # Public: Check if obj is an instance of {Commit}.
  #
  # obj - The object to check as {Object}.
  #
  # Returns {Boolean}.
  isCommit: (obj) ->
    Commit = require './models/commit'
    obj instanceof Commit

  # Public: Check if obj is an instance of {Diff}.
  #
  # obj - The object to check as {Object}.
  #
  # Returns {Boolean}.
  isDiff: (obj) ->
    Diff = require './models/diff'
    obj instanceof Diff

  # Public: Check if obj is an instance of {File}.
  #
  # obj - The object to check as {Object}.
  #
  # Returns {Boolean}.
  isFile: (obj) ->
    File = require './models/file'
    obj instanceof File

  # Public: Check if obj is an instance of {Status}.
  #
  # obj - The object to check as {Object}.
  #
  # Returns {Boolean}.
  isStatus: (obj) ->
    Status = require './models/status'
    obj instanceof Status

  # Public: Check if obj is an instance of {Tag}.
  #
  # obj - The object to check as {Object}.
  #
  # Returns {Boolean}.
  isTag: (obj) ->
    Tag = require './models/tag'
    obj instanceof Tag

  # Public: Check if obj is an instance of {Treeish}.
  #
  # obj - The object to check as {Object}.
  #
  # Returns {Boolean}.
  isTreeish: (obj) ->
    Treeish = require './models/treeish'
    obj instanceof Treeish

  # Public: Check if obj is an instance of {PromisedGit}.
  #
  # obj - The object to check as {Object}.
  #
  # Returns {Boolean}.
  isPromisedGit: (obj) ->
    PromisedGit = require './promised-git'
    obj instanceof PromisedGit

module.exports = LodashExtended.extend()
