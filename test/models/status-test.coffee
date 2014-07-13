Git = require '../../src/promised-git'
prepareFixture = require '../helper'
{Status, Commit, Treeish, File} = require '../../src/models'

describe 'Status', ->

  [git, statusParsed] = []

  statusPorcelainRaw = '''
    ## master
    M  a.coffee
     M b.coffee
    ?? d.coffee
  '''

  before ->
    git = new Git(prepareFixture('testDir'))

  describe 'when we pass a valid git porcelain status', ->

    before ->
      statusParsed = new Status(statusPorcelainRaw, git)

    it 'returns the correct branch name', ->
      statusParsed.branch.should.eql 'master'

    it 'returns the correct staged files', ->
      staged = statusParsed.staged
      staged.length.should.eql 1
      staged[0].path.should.eql 'a.coffee'

    it 'returns the correct unstaged files', ->
      unstaged = statusParsed.unstaged
      unstaged.length.should.eql 1
      unstaged[0].path.should.eql 'b.coffee'

    it 'returns the correct untracked files', ->
      untracked = statusParsed.untracked
      untracked.length.should.eql 1
      untracked[0].path.should.eql 'd.coffee'

  describe 'when we pass an invalid repository object', ->
    it 'throws an Error', ->

      (-> Status(statusPorcelainRaw, null)).should.throw(Error)
