temp = require('temp')

Git = require '../src/git-promised'
prepareFixture = require './helper'
{Commit, Diff, File, Status, Treeish} = require '../src/models'

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
          o.staged[0].filePath.should.eql 'a.coffee'
          o.staged[0].mode.should.eql 'M '
          # 1 Unstaged file
          o.unstaged.should.have.length(1)
          o.unstaged[0].filePath.should.eql 'b.coffee'
          o.unstaged[0].mode.should.eql ' M'
          # 1 Untracked file
          o.untracked.should.have.length(1)
          o.untracked[0].filePath.should.eql 'd.coffee'
          o.untracked[0].mode.should.eql '??'

  describe '#log()', ->
    git = new Git(prepareFixture('testDir'))
    it 'parses the rev-list and returns an array of "Commit" objects', ->
      git.init().then ->
        git.log().then (o) ->
          o.should.have.length(2)

          o[0].ref.should.eql '3393287f69716a01ffb922cd18b41d530d2d6795'
          o[0].message.should.eql 'Second commit'
          o[0].parents.should.eql ['ac657698c7630e3b65f575912aff76bf581f335f']

          o[1].ref.should.eql 'ac657698c7630e3b65f575912aff76bf581f335f'
          o[1].message.should.eql 'Initial commit'
          o[1].parents.should.eql []

  describe '#diff()', ->
    git = new Git(prepareFixture('testDir'))
    before ->
      git.init()

    describe 'when we pass a file', ->
      describe 'when it exists', ->

        describe 'when it contains staged diffs', ->
          it 'rejects the promise', ->
            git.diff('a.coffee').should.be.rejected

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
          it 'rejects the promise', ->
            git.diff('c.coffee').should.be.rejected

      describe 'when it is not existing', ->
        git.diff('e.coffee').should.be.rejected

    describe 'when we do not pass a file', ->
      it 'returns all diffs in workingTree', ->
        git.diff().then (o) ->
          o.should.have.length(1)
          o[0].filePath.should.eql 'b.coffee'
          o[0].chunks.should.have.length(1)

      describe 'when we set the --cached flag', ->
        it 'returns all diffs in index', ->
          git.diff({cached: true}).then (o) ->
            o.should.have.length(1)
            o[0].filePath.should.eql 'a.coffee'
            o[0].chunks.should.have.length(1)

    describe 'when we pass multiple files', ->
      describe 'when only some of them contain diffs', ->
        it 'returns Diff-Objects for the files that have diffs', ->
          git.diff(['a.coffee', 'b.coffee']).then (o) ->
            o.should.have.length(1)
            diffRaw = """diff --git a/b.coffee b/b.coffee
                          index 3463c49..6232e25 100644
                          --- a/b.coffee
                          +++ b/b.coffee
                          @@ -6,3 +6,3 @@ grade = (student) ->
                             else
                          -    "C"
                          +    "F"\n \n#{ }"""
            o[0].raw.should.eql diffRaw

      describe 'when none of them contain diffs', ->
        it 'returns an empty array', ->
          git.diff(['a.coffee', 'c.coffee']).then (o) ->
            o.should.have.length(0)

      describe 'when some of them do not exist', ->
        it 'returns an array with the diffs of the existing files', ->
          git.diff(['b.coffee', 'c.coffee', 'e.coffee']).then (o) ->
            o.should.have.length(1)

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

  describe '#unstage()', ->

    git = null
    beforeEach ->
      git = new Git(prepareFixture('testDir'))

    describe 'when we pass a file', ->

      describe 'when it exists', ->

        describe 'when it is staged', ->
          it 'unstages the file', ->
            git.unstage('a.coffee')
            .then -> git.status()
            .then (o) ->
              o.staged.should.have.length(0)
              o.unstaged.should.have.length(2)
              o.untracked.should.have.length(1)

        describe 'when it is not staged', ->
          it 'changes nothing', ->
            git.unstage('b.coffee')
            .then -> git.status()
            .then (o) ->
              o.staged.should.have.length(1)
              o.unstaged.should.have.length(1)
              o.untracked.should.have.length(1)

      describe 'when it does not exist', ->
        it 'changes nothing', ->
          git.unstage('e.coffee')
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(1)
            o.unstaged.should.have.length(1)
            o.untracked.should.have.length(1)

    describe 'when we pass an array of files', ->

      beforeEach ->
        git.add('b.coffee')

      describe 'when they all exist', ->
        it 'unstages the staged files', ->
          git.unstage ['a.coffee', 'b.coffee', 'c.coffee', 'd.coffee']
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(0)
            o.unstaged.should.have.length(2)
            o.untracked.should.have.length(1)

      describe 'when some or all of them do not exist', ->
        it 'unstages the staged files', ->
          git.unstage ['a.coffee', 'b.coffee', 'c.coffee', 'e.coffee']
          .then -> git.status()
          .then (o) ->
            o.staged.should.have.length(0)
            o.unstaged.should.have.length(2)
            o.untracked.should.have.length(1)

    describe 'when we pass nothing', ->
      it 'rejects the promise', ->
        git.unstage().should.be.rejected

  describe '#show()', ->
    git = new Git(prepareFixture('testDir'))
    fileString   = 'a.coffee'
    fileInstance = new File fileString, git
    fileNotExistingString = 'e.coffee'
    fileNotExistingInstance = new File fileNotExistingString, git

    treeishString   = 'ac657698c7630e3b65f575912aff76bf581f335f'
    treeishInstance = new Treeish treeishString, git
    treeishNotExistingString   = 'ac657698c7630e3b66g775912aff76bf581f335f'
    treeishNotExistingInstance = new Treeish treeishNotExistingString, git

    fileContent = '''
          # Assignment:
          number   = 42
          opposite = true

          # Conditions:
          number = -42 if opposite

          # Functions:
          square = (x) -> x * x

          # Arrays:
          list = [1, 2, 3, 4, 5]

          # Objects:
          math =
            root:   Math.sqrt
            square: square
            cube:   (x) -> x * square x

          # Splats:
          race = (winner, runners...) ->
            print winner, runners

          # Existence:
          alert "I knew it!" if elvis?

          # Array comprehensions:
          cubes = (math.cube num for num in list)\n'''

    changesToFileAtHead = currentHead = """
      commit 3393287f69716a01ffb922cd18b41d530d2d6795
      Author: Maximilian Schüßler <git@mschuessler.org>
      Date:   Mon Jun 30 22:53:47 2014 +0200

          Second commit

      diff --git a/a.coffee b/a.coffee
      index 0db65dd..1b78e9c 100644
      --- a/a.coffee
      +++ b/a.coffee
      @@ -9,7 +9,7 @@ number = -42 if opposite
       square = (x) -> x * x
       #{ }
       # Arrays:
      -list = [1, 2, 3, 4, 5]
      +list = [1, 2, 3, 4, 5, 6]
       #{ }
       # Objects:
       math =\n
    """

    treeishContent = '''
      commit ac657698c7630e3b65f575912aff76bf581f335f
      Author: Maximilian Schüßler <git@mschuessler.org>
      Date:   Sun Jun 29 19:02:56 2014 +0200
    '''

    describe 'when we pass an treeish and a file', ->

      describe 'when we pass a Treeish instance and a File instance', ->
        describe 'when both are existing in repo', ->
          it 'returns the file at treeish', ->
            git.show(treeishInstance, fileInstance).should.eventually.eql fileContent
        describe 'when either of them is not existing in repo', ->
          it 'rejects the promise', ->
            git.show(treeishNotExistingInstance, fileInstance)
            .should.eventually.be.rejected
            git.show(treeishInstance, fileNotExistingInstance)
            .should.eventually.be.rejected


      describe 'when we pass a Treeish instance and a file string', ->
        describe 'when both are existing in repo', ->
          it 'returns the file at treeish', ->
            git.show(treeishInstance, fileString).should.eventually.eql fileContent
        describe 'when either of them is not existing in repo', ->
          it 'rejects the promise', ->
            git.show(treeishNotExistingInstance, fileString)
            .should.eventually.be.rejected
            git.show(treeishInstance, fileNotExistingString)
            .should.eventually.be.rejected


      describe 'when we pass a treeish string and a File instance', ->
        describe 'when both are existing in repo', ->
          it 'returns the file at treeish', ->
            git.show(treeishString, fileInstance).should.eventually.eql fileContent
        describe 'when either of them is not existing in repo', ->
          it 'rejects the promise', ->
            git.show(treeishNotExistingString, fileInstance)
            .should.eventually.be.rejected
            git.show(treeishString, fileNotExistingInstance)
            .should.eventually.be.rejected


      describe 'when we pass a treeish string and a file string', ->
        describe 'when both are existing in repo', ->
          it 'returns the file at treeish', ->
            git.show(treeishString, fileString).should.eventually.eql fileContent
        describe 'when either of them is not existing in repo', ->
          it 'rejects the promise', ->
            git.show(treeishNotExistingString, fileString)
            .should.eventually.be.rejected
            git.show(treeishString, fileNotExistingString)
            .should.eventually.be.rejected

    describe 'when we only pass a treeish', ->
      describe 'when we pass a Treeish instance', ->
        describe 'when it is existing', ->
          it 'returns the treeish itself', ->
            git.show(treeishInstance).should.eventually.contain treeishContent
        describe 'when it is not existing', ->
          it 'rejects the promise', ->
            git.show(treeishNotExistingInstance).should.eventually.be.rejected

      describe 'when we pass a treeish string', ->
        describe 'when it is existing', ->
          it 'returns the treeish itself', ->
            git.show(treeishString).should.eventually.contain treeishContent
        describe 'when it is not existing', ->
          it 'rejects the promise', ->
            git.show(treeishNotExistingString).should.eventually.be.rejected

    describe 'when we only pass a file', ->
      describe 'when we pass a File instance', ->
        describe 'when it is existing', ->
          it 'returns the changes made to the file by HEAD', ->
            git.show(fileInstance).should.eventually.eql changesToFileAtHead
        describe 'when it is not existing', ->
          it 'rejects the promise', ->
            git.show(fileNotExistingInstance).should.eventually.be.rejected

      describe 'when we pass a file string', ->
        describe 'when it is existing', ->
          it 'returns the changes made to the file by HEAD', ->
            git.show(fileString).should.eventually.eql changesToFileAtHead
        describe 'when it is not existing', ->
          it 'rejects the promise', ->
            git.show(fileNotExistingString).should.eventually.be.rejected

    describe 'when we pass neither a file nor a treeish', ->
      it 'returns the head of the current branch', ->
        git.show().should.eventually.eql currentHead

  describe '#tags()', ->
    git = new Git(prepareFixture('tagsTest'))
    before ->
      git.init()
    describe 'when we pass no max number of tags to show', ->
      it 'shows the last 15 or less if there are less', ->
        git.tags().should.eventually.have.length(2)
    describe 'when we pass a max number of tags', ->
      it 'only shows the N newest tags sorted by authordate', ->
        git.tags(1).then (tags) ->
          tags.should.have.length(1)
          tags[0].ref.should.eql '4th'
    describe 'when the repo has no tags', ->
      it 'rejects the promise', ->
        git = new Git(prepareFixture('testDir'))
        git.init().then ->
          git.tags().should.eventually.be.rejected
