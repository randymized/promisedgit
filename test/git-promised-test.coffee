temp = require('temp')
chai = require 'chai'
chai.should()
expect = chai.expect

Git = require '../src/git-promised'
prepareFixture = require './helper'

describe 'Git', ->

  describe '#init()', ->
    git = new Git(temp.mkdirSync('git-promised-test'))
    it 'initializes a new git repo', ->
      git.init().then (o) ->
        o.should.contain 'Initialized empty Git repository in'

  describe '#status()', ->
    git = new Git(prepareFixture('testDir'))
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

  describe '#commits()', ->
    git = new Git(prepareFixture('testDir'))
    it 'parses the rev-list and returns an array of "Commit" objects', ->
      git.init().then ->
        git.commits().then (o) ->
          o.should.have.length(2)

          o[0].id.should.eql '3393287f69716a01ffb922cd18b41d530d2d6795'
          o[0].message.should.eql 'Second commit'
          o[0].parents.should.eql ['ac657698c7630e3b65f575912aff76bf581f335f']

          o[1].id.should.eql 'ac657698c7630e3b65f575912aff76bf581f335f'
          o[1].message.should.eql 'Initial commit'
          o[1].parents.should.eql []
