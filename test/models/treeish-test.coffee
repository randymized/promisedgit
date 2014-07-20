#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

Git = require '../../src/promised-git'
prepareFixture = require '../helper'
{File, Treeish} = require '../../src/models'

describe 'Treeish', ->
  [
    git
    file
    fileString
    oid
    oidOid
    oidFirst
    oidString
    oidOidString
    oidFirstString
  ] = []

  beforeEach ->
    git = new Git(prepareFixture('diffTest'))

    file = new File('test.coffee', git)
    fileString = 'test.coffee'

    oidString = 'HEAD~1'
    oidOidString = 'e9e3ad6a71996fb83440df2ac36912e2ddb555e0'
    oidFirstString = '64e14332ba7a7a02a6f868f425b16d9658cce0b5'

    oid = new Treeish(oidString, git)
    oidOid = new Treeish(oidOidString, git)
    oidFirst = new Treeish(oidFirstString, git)

  describe '::constructor()', ->

    describe 'when we pass no valid ref', ->
      it 'throws', ->
        (-> new Treeish null, git).should.throw(Error)

    describe 'when we pass an invalid repository object', ->
      it 'throws', ->
        (-> new Treeish 'HEAD', null).should.throw(Error)

    describe 'when ref and repository object are valid', ->
      it 'does not throw', ->
        (-> new Treeish 'HEAD', git).should.not.throw(Error)

  describe 'when the oid points to any object except the very first', ->

    describe 'when we are using a symbolic reference (HEAD~1)', ->

      describe '#checkout()', ->
        it 'checks out that ref', ->
          oid.checkout(f: true).then ->
            git.cmd('rev-parse HEAD').should.eventually.contain oidOidString

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

          oid.diff().then ({raw, chunks}) ->
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
        describe 'when we pass a valid oid to compare against', ->

          describe 'when we pass a oid as String', ->
            it 'returns the diff to it', ->
              oid.diffTo(oidFirstString).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

          describe 'when we pass a oid as Treeish object', ->
            it 'returns the diff to it', ->
              oid.diffTo(oidFirst).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

        describe 'when the oid we pass is not valid', ->
          it 'rejects the promise', ->
            oid.diffTo('INVALID').should.be.rejected

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
        describe 'when we pass a valid oid to compare against', ->

          describe 'when we pass a oid as String', ->
            it 'returns the diff from it', ->
              oid.diffFrom(oidFirstString).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

          describe 'when we pass a oid as Treeish object', ->
            it 'returns the diff from it', ->
              oid.diffFrom(oidFirst).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

        describe 'when the oid we pass is not valid', ->
          it 'rejects the promise', ->
            oid.diffFrom('INVALID').should.be.rejected

      describe '#showFile()', ->

        fileContentAtTreeish = '''
          ab
          c
        '''

        describe 'when we pass a valid file as String', ->
          it 'returns the contents of that file at this commit', ->
            oid.showFile(fileString).then (content) ->
              content.should.contain fileContentAtTreeish

        describe 'when we pass a valid file as File instance', ->
          it 'returns the contents of that file at this commit', ->
            oid.showFile(file).then (content) ->
              content.should.contain fileContentAtTreeish

        describe 'when we pass an invalid file', ->
          it 'rejects the promise', ->
            oid.showFile().should.be.rejected
            oid.showFile('WhyYouNoExist').should.be.rejected

      describe '#reset()', ->
        it 'resets the HEAD to this oid', ->
          oid.reset().then ->
            git.cmd('rev-parse HEAD').should.eventually.contain oidOidString

    describe 'when we are using the unique hash', ->

      describe '#checkout()', ->
        it 'checks out that ref', ->
          oidOid.checkout(f: true).then ->
            git.cmd('rev-parse HEAD').should.eventually.contain oidOidString

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

          oidOid.diff().then ({raw, chunks}) ->
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
        describe 'when we pass a valid oid to compare against', ->

          describe 'when we pass a oid as String', ->
            it 'returns the diff to it', ->
              oidOid.diffTo(oidFirstString).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

          describe 'when we pass a oid as Treeish object', ->
            it 'returns the diff to it', ->
              oidOid.diffTo(oidFirst).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

        describe 'when the oid we pass is not valid', ->
          it 'rejects the promise', ->
            oidOid.diffTo('INVALID').should.be.rejected

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
        describe 'when we pass a valid oid to compare against', ->

          describe 'when we pass a oid as String', ->
            it 'returns the diff from it', ->
              oidOid.diffFrom(oidFirstString).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

          describe 'when we pass a oid as Treeish object', ->
            it 'returns the diff from it', ->
              oidOid.diffFrom(oidFirst).then (diff) ->
                diff.raw.should.contain diffRaw
                diff.chunks.length.should.equal 1

        describe 'when the oid we pass is not valid', ->
          it 'rejects the promise', ->
            oidOid.diffFrom('INVALID').should.be.rejected

      describe '#showFile()', ->

        fileContentAtTreeish = '''
          ab
          c
        '''

        describe 'when we pass a valid file as String', ->
          it 'returns the contents of that file at this commit', ->
            oidOid.showFile(fileString).then (content) ->
              content.should.contain fileContentAtTreeish

        describe 'when we pass a valid file as File instance', ->
          it 'returns the contents of that file at this commit', ->
            oidOid.showFile(file).then (content) ->
              content.should.contain fileContentAtTreeish

        describe 'when we pass an invalid file', ->
          it 'rejects the promise', ->
            oidOid.showFile().should.be.rejected
            oidOid.showFile('WhyYouNoExist').should.be.rejected

      describe '#reset()', ->
        it 'resets the HEAD to this oid', ->
          oidOid.reset().then ->
            git.cmd('rev-parse HEAD').should.eventually.contain oidOidString

  describe 'when the oid points to the very first object in repo history', ->

    describe '#checkout()', ->
      it 'checks out that ref', ->
        oidFirst.checkout(f: true).then ->
          git.cmd('rev-parse HEAD').should.eventually.contain oidFirstString

    describe '#diff()', ->
      it 'returns the Diff the ref introduced', ->
        diffRaw = '''
          diff --git a/test.coffee b/test.coffee
          new file mode 100644
          index 0000000..e69de29
        '''

        oidFirst.diff().then ({raw, chunks}) ->
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
      describe 'when we pass a valid oid to compare against', ->

        describe 'when we pass a oid as String', ->
          it 'returns the diff to it', ->
            oidFirst.diffTo(oidOidString).then (diff) ->
              diff.raw.should.contain diffRaw
              diff.chunks.length.should.equal 1

        describe 'when we pass a oid as Treeish object', ->
          it 'returns the diff to it', ->
            oidFirst.diffTo(oidOid).then (diff) ->
              diff.raw.should.contain diffRaw
              diff.chunks.length.should.equal 1

      describe 'when the oid we pass is not valid', ->
        it 'rejects the promise', ->
          oidFirst.diffTo('INVALID').should.be.rejected

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
      describe 'when we pass a valid oid to compare against', ->

        describe 'when we pass a oid as String', ->
          it 'returns the diff from it', ->
            oidFirst.diffFrom(oidOidString).then (diff) ->
              diff.raw.should.contain diffRaw
              diff.chunks.length.should.equal 1

        describe 'when we pass a oid as Treeish object', ->
          it 'returns the diff from it', ->
            oidFirst.diffFrom(oidOid).then (diff) ->
              diff.raw.should.contain diffRaw
              diff.chunks.length.should.equal 1

      describe 'when the oid we pass is not valid', ->
        it 'rejects the promise', ->
          oidFirst.diffFrom('INVALID').should.be.rejected

    describe '#showFile()', ->

      fileContentAtTreeish = ''

      describe 'when we pass a valid file as String', ->
        it 'returns the contents of that file at this commit', ->
          oidFirst.showFile(fileString).then (content) ->
            content.should.equal fileContentAtTreeish

      describe 'when we pass a valid file as File instance', ->
        it 'returns the contents of that file at this commit', ->
          oidFirst.showFile(file).then (content) ->
            content.should.equal fileContentAtTreeish

      describe 'when we pass an invalid file', ->
        it 'rejects the promise', ->
          oidFirst.showFile().should.be.rejected
          oidFirst.showFile({}).should.be.rejected
          oidFirst.showFile('WhyYouNoExist').should.be.rejected

    describe '#reset()', ->
      it 'resets the HEAD to this oid', ->
        oidFirst.reset().then ->
          git.cmd('rev-parse HEAD').should.eventually.contain oidFirstString
