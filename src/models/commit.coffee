#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

Actor   = require './actor'
Diff    = require './diff'
Treeish = require './treeish'

# Public: Represents a git commit object.
class Commit extends Treeish
  # Public: Constructs a new instance of {Commit}.
  #
  # raw  - The raw commit data as {String}.
  # repo - The repository as {GitPromised}.
  constructor: (@raw, @repo) ->
    throw new Error('No raw data!') unless (typeof(@raw) is 'string')
    @parseRaw()

  # Internal: Parse the @raw data.
  parseRaw: ->
    @ref = @parseRef(@raw)
    @tree = @parseTree(@raw)
    [@author, @authoredDate] = @actor @parseAuthor(@raw)
    [@committer, @committedDate] = @actor @parseCommitter(@raw)
    @parents = @parseParents(@raw)
    @gpgsig = @parseGpgSig(@raw)
    @message = @parseMessage(@raw)

  # Internal: Parses raw and returns the commit hash.
  #
  # raw - The raw data as {String}.
  #
  # Returns the commit hash as {String}.
  parseRef: (raw) ->
    regex = /^(?:commit )?([a-z0-9]{40})$/m
    raw.match(regex)[1]

  # Internal: Parses raw and returns the tree hash.
  #
  # raw - The raw data as {String}.
  #
  # Returns the tree hash as {String}.
  parseTree: (raw) ->
    regex = /^tree\s(.+)$/m
    raw.match(regex)?[1]

  # Internal: Parses raw and returns the raw author.
  #
  # raw - The raw data as {String}.
  #
  # Returns the raw author as {String}.
  parseAuthor: (raw) ->
    regex = /^author\s(.+)$/m
    raw.match(regex)?[1]

  # Internal: Parses raw and returns the raw committer.
  #
  # raw - The raw data as {String}.
  #
  # Returns the raw committer as {String}.
  parseCommitter: (raw) ->
    regex = /^committer\s(.+)$/m
    raw.match(regex)?[1]

  # Internal: Parses raw and returns the parents.
  #
  # raw - The raw data as {String}.
  #
  # Returns the parents as {Array}.
  parseParents: (raw) ->
    regex = /^parent\s(.+)$/gm
    parents = raw.match(regex) or []
    for parent in parents
      parent.split(' ')?[1]

  # Internal: Parses raw and returns the gpgsig.
  #
  # raw - The raw data as {String}.
  #
  # Returns the gpgsig as {String}.
  parseGpgSig: (raw) ->
    regex = /^[^\-|VERSION|\n](.*)+$/gm
    raw.match(regex)?[1].join?('\n')

  # Internal: Parses raw and returns the commit message.
  #
  # raw - The raw data as {String}.
  #
  # Returns the commit message as {String}.
  parseMessage: (raw) ->
    regex = /^[ ]{4}([^]*)$/gm
    message = raw.match(regex)?[0]
    message?.replace(/^ {4}| +$/m, '').trim()

  # Internal: Parses a raw actor line.
  #
  # line - The raw actor line as {String}.
  #
  # Returns an {Array} with:
  #   :0 - The {Actor}.
  #   :1 - The time as {Date}.
  actor: (line) ->
    [m, actor, epoch] = line?.match(/^(.*?) (\d+) .*$/m) or ['', '', '']
    return [new Actor(actor), new Date(1000 * +epoch)]

module.exports = Commit
