#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

Commit  = require './commit'
Treeish = require './treeish'

# Public: A tag is a special git oid.
class Tag extends Treeish
  # Public: Constructs a new Tag instance.
  #
  # raw  - The raw data as {String}.
  # repo - The repository as {PromisedGit}.
  constructor: (raw, repo) ->
    [hash, ref] = @parseRaw(raw)
    super(ref, repo)

    repo.show(hash, {pretty: 'raw'}).then (commitRaw) =>
      @commit = new Commit(commitRaw, @repo)

  # Internal: Helper method to parse the raw data.
  #
  # raw - The raw data as {String}.
  #
  # Returns the formatted data as {Array}.
  parseRaw: (raw) ->
    [hash, ref] = raw.split(' ')
    ref = ref.split('refs/tags/')[1]
    [hash, ref]

module.exports = Tag
