fs = require 'fs'

module.exports=
class File

  constructor: (@path, @mode) ->
    @parseMode()

  update: (@mode) ->
    @parseMode()

  parseMode: ->
    @modeIndex       = @mode.substring(0, 1)
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
