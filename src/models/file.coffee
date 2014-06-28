fs = require 'fs'

module.exports=
class File

  constructor: (@path, @mode) ->
    @parseMode()

  update: (@mode) ->
    parseMode()

  parseMode: ->
    @resetStatus()
    @modeIndex       = @mode.substring(0, 1)
    @modeWorkingTree = @mode.substring(1, 2)

    switch @modeIndex
      when 'A' then @indexAdded    = true
      when 'C' then @indexCopied   = true
      when 'D' then @indexDeleted  = true
      when 'M' then @indexModified = true
      when 'R' then @indexRenamed  = true
      when '?' then @sUntracked    = true
    switch @modeWorkingTree
      when 'A' then @workingTreeAdded    = true
      when 'C' then @workingTreeCopied   = true
      when 'D' then @workingTreeDeleted  = true
      when 'M' then @workingTreeModified = true
      when 'R' then @workingTreeRenamed  = true
      when '?' then @sUntracked          = true

  resetStatus: ->
    @indexAdded          = false
    @indexCopied         = false
    @indexDeleted        = false
    @indexModified       = false
    @indexRenamed        = false
    @workingTreeAdded    = false
    @workingTreeCopied   = false
    @workingTreeDeleted  = false
    @workingTreeModified = false
    @workingTreeRenamed  = false
    @sUntracked          = false

  added: ->
    @indexAdded or @workingTreeAdded
  copied: ->
    @indexCopied or @workingTreeCopied
  deleted: ->
    @indexDeleted or @workingTreeDeleted
  modified: ->
    @indexModified or @workingTreeModified
  renamed: ->
    @indexRenamed or @workingTreeRenamed

  staged: ->
    @indexAdded or @indexCopied or @indexDeleted or @indexModified or @indexRenamed
  unstaged: ->
    @workingTreeAdded or @workingTreeCopied or @workingTreeDeleted or @workingTreeModified or @workingTreeRenamed
  untracked: ->
    @sUntracked
