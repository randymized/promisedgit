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
  # repo - The repository as {GitPromised}.
  #
  # Returns: An instance of {Tag}.
  constructor: (raw, repo) ->
    [hash, ref] = @parseRaw(raw)
    super(ref, repo)

    repo.show(hash, {pretty: 'raw'}).then (commitRaw) =>
      @commit = new Commit(commitRaw, @repo)

  # Internal: Helper method to parse the raw data.
  #
  # raw - The raw dat as {String}.
  #
  # Returns: The formatted raw data as {Array}.
  parseRaw: (raw) ->
    [hash, ref] = raw.split(' ')
    ref = ref.split('refs/tags/')[1]
    [hash, ref]

module.exports = Tag
