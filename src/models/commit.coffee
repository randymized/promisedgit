Actor = require './actor'
Diff = require './diff'
Treeish = require './treeish'

module.exports=
class Commit extends Treeish

  constructor: (@raw, @repo) ->
    throw new Error('No raw data!') unless (typeof(@raw) is 'string')
    @parseRaw()

  parseRaw: ->
    @ref = @parseRef(@raw)
    @tree = @parseTree(@raw)
    [@author, @authoredDate] = @actor @parseAuthor(@raw)
    [@committer, @committedDate] = @actor @parseCommitter(@raw)
    @parents = @parseParents(@raw)
    @gpgsig = @parseGpgSig(@raw)
    @message = @parseMessage(@raw)

  parseRef: (line) ->
    regex = /^(?:commit )?([a-z0-9]{40})$/m
    line.match(regex)[1]

  parseTree: (line) ->
    regex = /^tree\s(.+)$/m
    line.match(regex)?[1]

  parseAuthor: (line) ->
    regex = /^author\s(.+)$/m
    line.match(regex)?[1]

  parseCommitter: (line) ->
    regex = /^committer\s(.+)$/m
    line.match(regex)?[1]

  parseParents: (line) ->
    regex = /^parent\s(.+)$/gm
    parents = line.match(regex) or []
    for parent in parents
      parent.split(' ')?[1]

  parseGpgSig: (line) ->
    regex = /^[^\-|VERSION|\n](.*)+$/gm
    line.match(regex)?[1].join?('\n')

  parseMessage: (line) ->
    regex = /^[ ]{4}([^]*)$/gm
    message = line.match(regex)?[0]
    message?.replace(/^ {4}| +$/m, '').trim()

  actor: (line) ->
    [m, actor, epoch] = line?.match(/^(.*?) (\d+) .*$/m) or ['', '', '']
    return [Actor.from_string(actor), new Date(1000 * +epoch)]
