_ = require 'underscore'

Actor = require './actor'

module.exports=
class Commit

  constructor: (@id, @parents, @author, @authoredDate, @committer, @committedDate, @gpgsig, @message) ->

  @parse: (raw) ->
    return throw new Error("Unsufficient data:\n'#{raw}'") unless raw?

    commits = []
    lines = raw.split '\n'
    while lines.length
      id = _.last lines.shift().split(' ')
      break if !id
      tree = _.last lines.shift().split(' ')

      parents = []
      while /^parent/.test lines[0]
        parents.push _.last lines.shift().split(' ')

      author_line = lines.shift()
      [author, authoredDate] = @actor author_line

      committer_line = lines.shift()
      [committer, committedDate] = @actor committer_line

      gpgsig = []
      if /^gpgsig/.test lines[0]
        gpgsig.push lines.shift().replace /^gpgsig /, ''
        while !/^ -----END PGP SIGNATURE-----$/.test lines[0]
          gpgsig.push lines.shift()
        gpgsig.push lines.shift()

      # not doing anything with this yet, but it's sometimes there
      if /^encoding/.test lines[0]
        encoding = _.last lines.shift().split(' ')

      lines.shift()

      messageLines = []
      while /^ {4}/.test lines[0]
        messageLines.push lines.shift()[4..-1]

      while lines[0]? && !lines[0].length
        lines.shift()

      commits.push new Commit(
        id
        parents
        author
        authoredDate
        committer
        committedDate
        gpgsig.join('\n')
        messageLines.join('\n')
      )

    commits

  @actor: (line) ->
    [m, actor, epoch] = /^.+? (.*) (\d+) .*$/.exec line
    return [Actor.from_string(actor), new Date(1000 * +epoch)]
