#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

Actor = require './actor'
Diff = require './diff'
Treeish = require './treeish'

# Public: Handles commit amending.
class Amend

  alive: true
  destroyed: false

  # Public: Constructor
  #
  # message - The original commit message as {String}.
  # repo    - The repository as {GitPromised}.
  #
  # Returns: A new instance of {Amend}.
  constructor: (@origMessage='', @repo) ->
    [@origMessage, @repo] = ['', @origMessage] if @origMessage?.isGitRepo
    throw new Error('No valid git repo!') unless @repo?.isGitRepo

    @origMessage = "#{@origMessage?.trim()}\n"
    @repo.reset 'HEAD^', soft: true

  # Public: Abort amending.
  #
  # Returns: Promise.
  abort: ->
    @repo.reset('ORIG_HEAD').then (stdout) =>
      @destroy()
      stdout

  # Public: Commit changes with message or the file message points to.
  #
  # message - The commit message or the path of the file to commit with as
  #           {String}.
  #
  # Returns: Promise.
  commit: (message=@origMessage) ->
    @repo.commit(message).then (stdout) =>
      @destroy()
      stdout

  # Public: Get the original commit message.
  #
  # Returns the original commit message as {String}.
  getAmendMessage: ->
    @origMessage

  # Public: Destroy amend object.
  destroy: ->
    @repo = null
    @alive = false
    @destroyed = true

module.exports = Amend
