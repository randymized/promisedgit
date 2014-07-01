temp = require('temp')

Git = require '../src/git-promised'
prepareFixture = require './helper'

describe 'Git-Promised', ->

  #############################################################################
  # The test fixture we are using contains:                                   #
  #############################################################################
  #                                                                           #
  #   ## master                                                               #
  #   M  a.coffee     =>  1 Staged                                            #
  #    M b.coffee     =>  1 Unstaged                                          #
  #   ?? d.coffee     =>  1 Untracked                                         #
  #      c.coffee     =>  1 tracked & unmodified file                         #
  #                                                                           #
  #############################################################################
  #   Commits:                                                                #
  #############################################################################
  #                                                                           #
  #     commit 3393287f69716a01ffb922cd18b41d530d2d6795                       #
  #     tree 48b770804c8c8530b970ee11bce68c1ba6e798de                         #
  #     parent ac657698c7630e3b65f575912aff76bf581f335f                       #
  #     author Maximilian Schüßler <git@mschuessler.org> 1404161627 +0200     #
  #     committer Maximilian Schüßler <git@mschuessler.org> 1404161627 +0200  #
  #                                                                           #
  #         Second commit                                                     #
  #                                                                           #
  #---------------------------------------------------------------------------#
  #                                                                           #
  #     commit ac657698c7630e3b65f575912aff76bf581f335f                       #
  #     tree d7cf090a06f92f68f07a3b461595acb5468c73a9                         #
  #     author Maximilian Schüßler <git@mschuessler.org> 1404061376 +0200     #
  #     committer Maximilian Schüßler <git@mschuessler.org> 1404061376 +0200  #
  #                                                                           #
  #         Initial commit                                                    #
  #                                                                           #
  #############################################################################

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
          o.branch.should.eql 'master'
          # 1 Staged file
          o.staged.should.have.length(1)
          o.staged[0].path.should.eql 'a.coffee'
          o.staged[0].mode.should.eql 'M '
          # 1 Unstaged file
          o.unstaged.should.have.length(1)
          o.unstaged[0].path.should.eql 'b.coffee'
          o.unstaged[0].mode.should.eql ' M'
          # 1 Untracked file
          o.untracked.should.have.length(1)
          o.untracked[0].path.should.eql 'd.coffee'
          o.untracked[0].mode.should.eql '??'

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

  describe '#diff()', ->
    git = new Git(prepareFixture('testDir'))
    before ->
      git.init()

    describe 'when we pass a file', ->
      describe 'when it exists', ->

        describe 'when it contains staged diffs', ->
          it 'resolves with an empty raw diff', ->
            git.diff('a.coffee').then (o) ->
              o.raw.should.eql ''
          describe 'when we add the --cached flag', ->
            it 'resolves with a Diff object', ->
              git.diff('a.coffee', cached: true).then (o) ->
                o.raw.should.be.ok.and.not.equal ''

        describe 'when it contains unstaged diffs', ->
          it 'resolves with a Diff object', ->
            git.diff('b.coffee').then (o) ->
              diffRaw = """diff --git a/b.coffee b/b.coffee
                          index 3463c49..6232e25 100644
                          --- a/b.coffee
                          +++ b/b.coffee
                          @@ -6,3 +6,3 @@ grade = (student) ->
                             else
                          -    "C"
                          +    "F"\n \n#{ }"""
              o.raw.should.eql diffRaw

        describe 'when it contains no diffs', ->
          it 'resolves with an empty raw diff', ->
            git.diff('c.coffee').then (o) ->
              o.raw.should.eql ''

      describe 'when it is not existing', ->
        it 'rejects the promise', ->
          git.diff('e.coffee').should.be.rejected

    describe 'when we do not pass a file', ->
      it 'rejects the promise', ->
        git.diff().should.be.rejected

  describe '#add()', ->

    git = null
    beforeEach ->
      git = new Git(prepareFixture('testDir'))

    describe 'when we pass a file', ->

      describe 'when the file exists', ->
        it 'adds it to the index', ->
          git.add('d.coffee')
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(2)
            o.unstaged.should.have.length(1)
            o.untracked.should.have.length(0)

      describe 'when the file does not exist', ->
        it 'rejects the promise', ->
          git.add('e.coffee').should.be.rejected

    describe 'when we pass nothing', ->
      it 'adds all files', ->
        git.add()
        .then -> git.status()
        .then (o) ->
          o.staged.should.have.length(3)
          o.unstaged.should.have.length(0)
          o.untracked.should.have.length(0)

  describe '#checkoutFile()', ->

    git = null
    beforeEach ->
      git = new Git(prepareFixture('testDir'))

    describe 'when we pass a file', ->
      describe 'when it exists', ->
        it 'checks it out', ->
          git.checkoutFile('b.coffee')
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(1)
            o.unstaged.should.have.length(0)
            o.untracked.should.have.length(1)
      describe 'when it does not exist', ->
        it 'rejects the promise', ->
          git.checkoutFile('e.coffee').should.be.rejected
    describe 'when we pass nothing', ->
      it 'checks out all files', ->
        git.checkoutFile()
        .then -> git.status()
        .then (o) ->
          o.staged.should.have.length(0)
          o.unstaged.should.have.length(0)
          o.untracked.should.have.length(1)

  describe '#reset()', ->

    git = null
    beforeEach ->
      git = new Git(prepareFixture('testDir'))
      git.init()

    describe "when we reset without passing a treeish (defaults to HEAD)", ->
      describe "when we use no or the --mixed flag", ->
        it "removes the file from index, leaves it in working tree", ->
          git.reset()
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(0)
            o.unstaged.should.have.length(2)
            o.untracked.should.have.length(1)

      describe "when we use the --soft flag", ->
        it "leaves the added file in the index", ->
          git.reset({soft: true})
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(1)
            o.unstaged.should.have.length(1)
            o.untracked.should.have.length(1)

      describe "when we use the --hard flag", ->
        it "removes the file from index and working tree", ->
          git.reset({hard: true})
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(0)
            o.unstaged.should.have.length(0)
            o.untracked.should.have.length(1)

    describe "when we reset to a specific treeish", ->
      describe "when we use no or the --mixed flag", ->
        it "resets to HEAD~1, changes stay in the working tree", ->
          git.reset('HEAD~1')
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(0)
            o.unstaged.should.have.length(2)
            o.untracked.should.have.length(1)

      describe "when we use the --soft flag", ->
        it "resets to HEAD~1, changes stay in the index and working tree", ->
          git.reset('HEAD~1', {soft: true})
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(1)
            o.unstaged.should.have.length(1)
            o.untracked.should.have.length(1)

      describe "when we use the --hard flag", ->
        it "resets to HEAD~1, all changes get discarded completely", ->
          git.reset('HEAD~1', {hard: true})
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(0)
            o.unstaged.should.have.length(0)
            o.untracked.should.have.length(1)

    describe 'when we reset to an invalid treeish', ->
      it 'rejects the promise', ->
        git.reset('pusemuckel').should.be.rejected
