temp = require('temp')
chai = require 'chai'
chai.should()
expect = chai.expect

Git = require '../src/git-promised'
prepareFixture = require './helper'

describe 'Git', ->
  git = null
  beforeEach ->
    gitPath = prepareFixture('testDir')
    git = new Git(gitPath)

  describe '#init()', ->
    it 'initializes a new git repo', ->
      git = new Git(temp.mkdirSync('git-promised-test'))
      git.init().then (o) ->
        o.should.contain 'Initialized empty Git repository in'

  describe '#status()', ->
    it 'parses the status and returns an object to use', ->
      git.init().then ->
        git.status().then (o) ->
          o.should.have.deep.property('branch', 'master')
          # 1 Staged file
          o.staged.should.have.length(1)
          o.should.have.deep.property('staged[0].path', 'a.coffee')
          o.should.have.deep.property('staged[0].mode', 'M ')
          # 1 Unstaged file
          o.unstaged.should.have.length(1)
          o.should.have.deep.property('unstaged[0].path', 'b.coffee')
          o.should.have.deep.property('unstaged[0].mode', ' M')
          # 1 Untracked file
          o.untracked.should.have.length(1)
          o.should.have.deep.property('untracked[0].path', 'd.coffee')
          o.should.have.deep.property('untracked[0].mode', '??')
