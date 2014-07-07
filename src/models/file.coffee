#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

{Model} = require 'backbone'
fs = require 'fs'

module.exports=
class File extends Model

  constructor: (@filePath, @repo, @mode='  ') ->
    throw new Error('No valid git repo!!!') unless @repo?.isGitRepo
    throw new Error('No valid filePath!!!') unless (typeof(@filePath) is 'string')
    @parseMode()

  update: (@mode) ->
    @parseMode()

  parseMode: ->
    @modeIndex = @mode.substring(0, 1)
    @modeWorkingTree = @mode.substring(1, 2)

  added: ->
    @mode.contains('A')

  copied: ->
    @mode.contains('C')

  deleted: ->
    @mode.contains('D')

  modified: ->
    @mode.contains('M')

  renamed: ->
    @mode.contains('R')

  staged: ->
    /[ACDMR]/g.test @modeIndex

  unstaged: ->
    /[ACDMR]/g.test @modeWorkingTree

  untracked: ->
    @mode is '??'
