#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

Promise = require 'bluebird'

Commit  = require './commit'
Treeish = require './treeish'

# Public: A tag is a special git treeish.
class Tag extends Treeish
  constructor: (
    ref
    repo
    @commit
  ) -> super(ref, repo)


  @parse: (raw, repo) ->
    return throw new Error('No tags available!') unless raw?.length > 0
    return throw new Error('No valid git repo!') unless repo?.isGitRepo

    tags = raw.split('\n')[...-1]
    Promise.map tags, (tagRaw) ->
      [hash, ref] = tagRaw.split(' ')
      ref = ref.split('refs/tags/')[1]
      repo.show(hash, {pretty: 'raw'}).then (commitRaw) ->
        new Tag(ref, repo, new Commit(commitRaw, repo))

module.exports = Tag
