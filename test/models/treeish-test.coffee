#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

Git = require '../../src/git-promised'
prepareFixture = require '../helper'
{File, Treeish} = require '../../src/models'

describe 'Treeish', ->
  [
    git
    file
    fileString
    treeish
    treeishOid
    treeishFirst
    treeishString
    treeishOidString
    treeishFirstString
  ] = []

  beforeEach ->
    git = new Git(prepareFixture('diffTest'))

    file = new File('test.coffee', git)
    fileString = 'test.coffee'

    treeishString = 'HEAD~1'
    treeishOidString = 'e9e3ad6a71996fb83440df2ac36912e2ddb555e0'
    treeishFirstString = '64e14332ba7a7a02a6f868f425b16d9658cce0b5'

    treeish = new Treeish(treeishString, git)
    treeishOid = new Treeish(treeishOidString, git)
    treeishFirst = new Treeish(treeishFirstString, git)

  describe '::constructor()', ->

    describe 'when we pass no valid ref', ->
      it 'throws', ->
        Treeish.should.throw(null)

  describe 'when the treeish points to any object except the very first', ->

    describe 'when we are using a symbolic reference (HEAD~1)', ->

      describe '#checkout()', ->
        it 'checks out that ref', ->
          treeish.checkout(f: true).then ->
            git.cmd('rev-parse HEAD').should.eventually.contain treeishOidString

      describe '#diff()', ->
        it 'returns the Diff the ref introduced', ->
          diffRaw = '''
            diff --git a/test.coffee b/test.coffee
            index 81bf396..e1fd401 100644
            --- a/test.coffee
            +++ b/test.coffee
            @@ -1 +1,2 @@
             ab
            +c
          '''

          treeish.diff().then ({raw, chunks}) ->
            raw.should.contain diffRaw
            chunks.length.should.equal 1

      describe '#diffTo()', ->

        diffRaw = '''
          diff --git a/test.coffee b/test.coffee
          index e1fd401..e69de29 100644
          --- a/test.coffee
          +++ b/test.coffee
          @@ -1,2 +0,0 @@
          -ab
          -c
        '''
        describe 'when we pass a valid treeish to compare against', ->

          describe 'when we pass a treeish as String', ->
            it 'returns the diff to it', ->
              treeish.diffTo(treeishFirstString).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

          describe 'when we pass a treeish as Treeish object', ->
            it 'returns the diff to it', ->
              treeish.diffTo(treeishFirst).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

        describe 'when the treeish we pass is not valid', ->
          it 'rejects the promise', ->
            treeish.diffTo({}).should.be.rejected
            treeish.diffTo('INVALID').should.be.rejected

      describe '#diffFrom()', ->

        diffRaw = '''
          diff --git a/test.coffee b/test.coffee
          index e69de29..e1fd401 100644
          --- a/test.coffee
          +++ b/test.coffee
          @@ -0,0 +1,2 @@
          +ab
          +c
        '''
        describe 'when we pass a valid treeish to compare against', ->

          describe 'when we pass a treeish as String', ->
            it 'returns the diff from it', ->
              treeish.diffFrom(treeishFirstString).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

          describe 'when we pass a treeish as Treeish object', ->
            it 'returns the diff from it', ->
              treeish.diffFrom(treeishFirst).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

        describe 'when the treeish we pass is not valid', ->
          it 'rejects the promise', ->
            treeish.diffFrom({}).should.be.rejected
            treeish.diffFrom('INVALID').should.be.rejected

      describe '#showFile()', ->

        fileContentAtTreeish = '''
          ab
          c
        '''

        describe 'when we pass a valid file as String', ->
          it 'returns the contents of that file at this commit', ->
            treeish.showFile(fileString).then (content) ->
              content.should.contain fileContentAtTreeish

        describe 'when we pass a valid file as File instance', ->
          it 'returns the contents of that file at this commit', ->
            treeish.showFile(file).then (content) ->
              content.should.contain fileContentAtTreeish

        describe 'when we pass an invalid file', ->
          it 'rejects the promise', ->
            treeish.showFile().should.be.rejected
            treeish.showFile({}).should.be.rejected
            treeish.showFile('WhyYouNoExist').should.be.rejected

      describe '#reset()', ->
        it 'resets the HEAD to this treeish', ->
          treeish.reset().then ->
            git.cmd('rev-parse HEAD').should.eventually.contain treeishOidString

    describe 'when we are using the unique hash', ->

      describe '#checkout()', ->
        it 'checks out that ref', ->
          treeishOid.checkout(f: true).then ->
            git.cmd('rev-parse HEAD').should.eventually.contain treeishOidString

      describe '#diff()', ->
        it 'returns the Diff the ref introduced', ->
          diffRaw = '''
            diff --git a/test.coffee b/test.coffee
            index 81bf396..e1fd401 100644
            --- a/test.coffee
            +++ b/test.coffee
            @@ -1 +1,2 @@
             ab
            +c
          '''

          treeishOid.diff().then ({raw, chunks}) ->
            raw.should.contain diffRaw
            chunks.length.should.equal 1

      describe '#diffTo()', ->

        diffRaw = '''
          diff --git a/test.coffee b/test.coffee
          index e1fd401..e69de29 100644
          --- a/test.coffee
          +++ b/test.coffee
          @@ -1,2 +0,0 @@
          -ab
          -c
        '''
        describe 'when we pass a valid treeish to compare against', ->

          describe 'when we pass a treeish as String', ->
            it 'returns the diff to it', ->
              treeishOid.diffTo(treeishFirstString).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

          describe 'when we pass a treeish as Treeish object', ->
            it 'returns the diff to it', ->
              treeishOid.diffTo(treeishFirst).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

        describe 'when the treeish we pass is not valid', ->
          it 'rejects the promise', ->
            treeishOid.diffTo({}).should.be.rejected
            treeishOid.diffTo('INVALID').should.be.rejected

      describe '#diffFrom()', ->

        diffRaw = '''
          diff --git a/test.coffee b/test.coffee
          index e69de29..e1fd401 100644
          --- a/test.coffee
          +++ b/test.coffee
          @@ -0,0 +1,2 @@
          +ab
          +c
        '''
        describe 'when we pass a valid treeish to compare against', ->

          describe 'when we pass a treeish as String', ->
            it 'returns the diff from it', ->
              treeishOid.diffFrom(treeishFirstString).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

          describe 'when we pass a treeish as Treeish object', ->
            it 'returns the diff from it', ->
              treeishOid.diffFrom(treeishFirst).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

        describe 'when the treeish we pass is not valid', ->
          it 'rejects the promise', ->
            treeishOid.diffFrom({}).should.be.rejected
            treeishOid.diffFrom('INVALID').should.be.rejected

      describe '#showFile()', ->

        fileContentAtTreeish = '''
          ab
          c
        '''

        describe 'when we pass a valid file as String', ->
          it 'returns the contents of that file at this commit', ->
            treeishOid.showFile(fileString).then (content) ->
              content.should.contain fileContentAtTreeish

        describe 'when we pass a valid file as File instance', ->
          it 'returns the contents of that file at this commit', ->
            treeishOid.showFile(file).then (content) ->
              content.should.contain fileContentAtTreeish

        describe 'when we pass an invalid file', ->
          it 'rejects the promise', ->
            treeishOid.showFile().should.be.rejected
            treeishOid.showFile({}).should.be.rejected
            treeishOid.showFile('WhyYouNoExist').should.be.rejected

      describe '#reset()', ->
        it 'resets the HEAD to this treeish', ->
          treeishOid.reset().then ->
            git.cmd('rev-parse HEAD').should.eventually.contain treeishOidString

  describe 'when the treeish points to the very first object in repo history', ->

    describe '#checkout()', ->
      it 'checks out that ref', ->
        treeishFirst.checkout(f: true).then ->
          git.cmd('rev-parse HEAD').should.eventually.contain treeishFirstString

    describe '#diff()', ->
      it 'returns the Diff the ref introduced', ->
        diffRaw = '''
          diff --git a/test.coffee b/test.coffee
          new file mode 100644
          index 0000000..e69de29
        '''

        treeishFirst.diff().then ({raw, chunks}) ->
          raw.should.contain diffRaw
          chunks.length.should.equal 0

    describe '#diffTo()', ->

      diffRaw = '''
        diff --git a/test.coffee b/test.coffee
        index e69de29..e1fd401 100644
        --- a/test.coffee
        +++ b/test.coffee
        @@ -0,0 +1,2 @@
        +ab
        +c
      '''
      describe 'when we pass a valid treeish to compare against', ->

        describe 'when we pass a treeish as String', ->
          it 'returns the diff to it', ->
            treeishFirst.diffTo(treeishOidString).then (diff) ->
              diff.raw.should.contain diffRaw
              diff.chunks.length.should.equal 1

        describe 'when we pass a treeish as Treeish object', ->
          it 'returns the diff to it', ->
            treeishFirst.diffTo(treeishOid).then (diff) ->
              diff.raw.should.contain diffRaw
              diff.chunks.length.should.equal 1

      describe 'when the treeish we pass is not valid', ->
        it 'rejects the promise', ->
          treeishFirst.diffTo({}).should.be.rejected
          treeishFirst.diffTo('INVALID').should.be.rejected

    describe '#diffFrom()', ->

      diffRaw = '''
        diff --git a/test.coffee b/test.coffee
        index e1fd401..e69de29 100644
        --- a/test.coffee
        +++ b/test.coffee
        @@ -1,2 +0,0 @@
        -ab
        -c
      '''
      describe 'when we pass a valid treeish to compare against', ->

        describe 'when we pass a treeish as String', ->
          it 'returns the diff from it', ->
            treeishFirst.diffFrom(treeishOidString).then (diff) ->
              diff.raw.should.contain diffRaw
              diff.chunks.length.should.equal 1

        describe 'when we pass a treeish as Treeish object', ->
          it 'returns the diff from it', ->
            treeishFirst.diffFrom(treeishOid).then (diff) ->
              diff.raw.should.contain diffRaw
              diff.chunks.length.should.equal 1

      describe 'when the treeish we pass is not valid', ->
        it 'rejects the promise', ->
          treeishFirst.diffFrom({}).should.be.rejected
          treeishFirst.diffFrom('INVALID').should.be.rejected

    describe '#showFile()', ->

      fileContentAtTreeish = ''

      describe 'when we pass a valid file as String', ->
        it 'returns the contents of that file at this commit', ->
          treeishFirst.showFile(fileString).then (content) ->
            content.should.equal fileContentAtTreeish

      describe 'when we pass a valid file as File instance', ->
        it 'returns the contents of that file at this commit', ->
          treeishFirst.showFile(file).then (content) ->
            content.should.equal fileContentAtTreeish

      describe 'when we pass an invalid file', ->
        it 'rejects the promise', ->
          treeishFirst.showFile().should.be.rejected
          treeishFirst.showFile({}).should.be.rejected
          treeishFirst.showFile('WhyYouNoExist').should.be.rejected

    describe '#reset()', ->
      it 'resets the HEAD to this treeish', ->
        treeishFirst.reset().then ->
          git.cmd('rev-parse HEAD').should.eventually.contain treeishFirstString
