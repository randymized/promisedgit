File = require './file'

module.exports=
class Status
  constructor: (@branch, @staged, @unstaged, @untracked) ->
    @branch    ?= 'HEAD'
    @staged    ?= []
    @unstaged  ?= []
    @untracked ?= []

  @parse: (raw, repo) ->
    lineSeparator = if raw.indexOf('\u0000') isnt -1 then '\u0000' else '\n'
    lines = raw.split(lineSeparator)

    branch = lines[0].substring(3)
    lines.shift()

    staged    = []
    unstaged  = []
    untracked = []

    for line in lines when line isnt ''
      mode = line.substring(0, 2)
      path = line.substring(3)
      file = new File(path, repo, mode)
      staged.push file if file.staged()
      unstaged.push file if file.unstaged()
      untracked.push file if file.untracked()

    new Status(branch, staged, unstaged, untracked)
