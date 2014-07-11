#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

Git = require '../../src/git-promised'
prepareFixture = require '../helper'
{Commit} = require '../../src/models'

describe 'Commit', ->
  describe 'Prototype functions', ->
    # Initialize empty comparison variables.
    [
      example
      ref
      tree
      parents
      authorLine
      authoredDate
      committerLine
      committedDate
      message
    ] = []

    beforeEach ->
      # Our test data.
      example = '''
        8a0d851367d123a6956c0e8a3735c671240f2b18
        tree 0a15f149a441fead2b82660489b4bba736f14d23
        parent 7dff0c6194daed203e8ab0f7ff7ab35df99fd5fb
        parent 9ff65a2cf3e1a4840166b7d9e93febddeed48662
        author Maximilian Schüßler <git@mschuessler.org> 1404686270 +0200
        committer Maximilian Schüßler <git@mschuessler.org> 1404686270 +0200

            Merge branch 'test'
      '''

      # Our comparison data.
      ref = '8a0d851367d123a6956c0e8a3735c671240f2b18'
      tree = '0a15f149a441fead2b82660489b4bba736f14d23'
      parents = [
        '7dff0c6194daed203e8ab0f7ff7ab35df99fd5fb'
        '9ff65a2cf3e1a4840166b7d9e93febddeed48662'
      ]
      authorLine = 'Maximilian Schüßler <git@mschuessler.org> 1404686270 +0200'
      authoredDate = new Date(1000 * +1404686270)
      committerLine = 'Maximilian Schüßler <git@mschuessler.org> 1404686270 +0200'
      committedDate = new Date(1000 * +1404686270)
      message = "Merge branch 'test'"

    describe '#parseRef()', ->
      it 'parses the raw input and returns the 40-digit identifier', ->
        Commit::parseRef(example).should.eql ref

    describe '#parseTree()', ->
      it 'parses the raw input and returns the tree hash', ->
        Commit::parseTree(example).should.eql tree

    describe '#parseAuthor()', ->
      it 'parses the raw input and returns author line', ->
        Commit::parseAuthor(example).should.eql authorLine

    describe '#parseComitter()', ->
      it 'parses the raw input and returns committer line', ->
        Commit::parseAuthor(example).should.eql committerLine

    describe '#parseParents()', ->
      it 'parses the raw input and returns an array of parent hashes', ->
        Commit::parseParents(example).should.eql parents

    describe '#parseGpgSig()', ->
      it 'parses the raw input and returns the gpg signature', ->

    describe '#parseMessage()', ->
      it 'parses the raw input and returns the trimed message', ->
        Commit::parseMessage(example).should.eql message

    describe '#parseRaw()', ->

      describe 'when we pass input', ->
        it 'invokes the helper methods and sets the object properties', ->

          class Dummy extends Commit
            constructor: (@raw) ->
              @parseRaw()

          test = new Dummy(example)

          test.ref.should.eql ref
          test.tree.should.eql tree
          test.parents.should.eql parents
          test.message.should.eql message

          test.author.name.should.eql 'Maximilian Schüßler'
          test.author.email.should.eql 'git@mschuessler.org'
          test.authoredDate.should.eql authoredDate
          test.committer.name.should.eql 'Maximilian Schüßler'
          test.committer.email.should.eql 'git@mschuessler.org'
          test.committedDate.should.eql committedDate
