Actor = require './actor'
Diff = require './diff'
Treeish = require './treeish'

module.exports=
class Commit extends Treeish

  constructor: (
    ref
    repo
    @tree
    @parents
    @author
    @authoredDate
    @committer
    @committedDate
    @gpgsig
    @message
  ) -> super(ref, repo)

  @parse: (raw, repo) ->
    throw new Error('No raw data!') unless (typeof(raw) is 'string')

    ref = raw.match(/^commit (.*)$/gm)[0].split(' ')[1]
    tree = raw.match(/^tree (.*)$/gm)?[0].split(' ')[1] or ''
    [author, authoredDate] = @actor raw.match(/^author (.*)$/gm)?[0] or ''
    [committer, committedDate] = @actor raw.match(/^committer (.*)$/gm)?[0] or ''
    parents = (parent.split(' ')?[1] for parent in (raw.match(/^parent (.*)$/gm)) or [])
    gpgsig = raw.match(/^[^\-|VERSION|\n](.*)+$/gm)?[1].join?('\n') or ''
    message = raw.match(/[ ]{4}([^]*)/gm)?[0].replace(/^ {4}| +$/gm, '').trim() or ''

    [comitter, comittedDate] = [author, authoredDate] unless comitter?

    new Commit(
      ref
      repo
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
    [m, actor, epoch] = line.match(/^.+? (.*) (\d+) .*$/gm) or ['', '', '']
    return [Actor.from_string(actor), new Date(1000 * +epoch)]
