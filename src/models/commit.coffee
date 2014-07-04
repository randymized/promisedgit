Actor = require './actor'
Diff = require './diff'
Treeish = require './treeish'

module.exports=
class Commit extends Treeish

  initialize: (@repo, @ref, @tree, @parents, @author, @authoredDate, @committer, @committedDate, @gpgsig, @message) ->

  @parse: (raw, repo) ->
    throw new Error('No valid git repo!!!') unless repo?.isGitRepo
    throw new Error('No raw data!!!') unless (typeof(raw) is 'string')

    ref = raw.match(/^commit (.*)$/gm)[0].split(' ')[1]
    tree = raw.match(/^tree (.*)$/gm)[0].split(' ')[1]
    [author, authoredDate] = @actor raw.match(/^author (.*)$/gm)[0]
    [committer, committedDate] = @actor raw.match(/^committer (.*)$/gm)[0]
    parents = (parent.split(' ')[1] for parent in (raw.match(/^parent (.*)$/gm)) or [])
    gpgsig = raw.match(/^[^\-|VERSION|\n](.*)+$/gm)?[1].join?('\n') or ''
    message = raw.match(/[ ]{4}([^]*)/gm)?[0].replace(/^ {4}| +$/gm, '').trim() or ''

    new Commit(
      repo
      ref
      tree
      parents
      author
      authoredDate
      committer
      committedDate
      gpgsig
      message
    )

  @actor: (line) ->
    [m, actor, epoch] = /^.+? (.*) (\d+) .*$/.exec line
    return [Actor.from_string(actor), new Date(1000 * +epoch)]
