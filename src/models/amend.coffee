#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_ = require '../lodash'

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
  # repo    - The repository as {PromisedGit}.
  constructor: (@origMessage='', @repo) ->
    if _.isPromisedGit(origMessage)
      [@origMessage, @repo] = ['', origMessage]
    else if not _.isPromisedGit(repo)
      throw new Error('Invalid repository object')

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
  commit: (message) ->
    message = @origMessage unless _.isString(message)
    @repo.commit(message).then (stdout) -> stdout

  # Public: Get the original commit message.
  #
  # Returns the original commit message as {String}.
  getAmendMessage: ->
    @origMessage

module.exports = Amend
