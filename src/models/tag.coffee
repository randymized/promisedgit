Promise = require 'bluebird'

Commit  = require './commit'
Treeish = require './treeish'

module.exports=
class Tag extends Treeish

  constructor: (
    ref
    repo
    @commit
  ) -> super(ref, repo)


  @parse: (raw, repo) ->
    return throw new Error('No tags available!') unless typeof(raw) is 'string'
    return throw new Error('No valid git repo!') unless repo?.isGitRepo

    tags = raw.split('\n')[...-1]
    Promise.map tags, (tagRaw) ->
      [hash, ref] = tagRaw.split(' ')
      ref = ref.split('refs/tags/')[1]
      repo.show(hash).then (commitRaw) ->
        new Tag(ref, repo, Commit.parse(commitRaw, repo))