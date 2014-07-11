prepareFixture = require '../helper'
{Diff} = require '../../src/models'

describe 'Diff', ->
  diffRaw = '''
    diff --git a/package.json b/package.json
    index 3a5e73d..840ce06 100644
    --- a/package.json
    +++ b/package.json
    @@ -22,8 +22,7 @@
       },
       "dependencies": {
         "bluebird": "~2.2.1",
    -    "lodash": "~2.4.1",
    -    "shelljs": "~0.3.0"
    +    "lodash": "~2.4.1"
       },
       "devDependencies": {
         "chai": "~1.9.1",
    @@ -38,7 +37,6 @@
       "keywords": [
         "git",
         "promise",
    -    "async",
    -    "shell"
    +    "async"
       ]
     }
  '''

  diffChunks = [
    '''
      @@ -22,8 +22,7 @@
         },
         "dependencies": {
           "bluebird": "~2.2.1",
      -    "lodash": "~2.4.1",
      -    "shelljs": "~0.3.0"
      +    "lodash": "~2.4.1"
         },
         "devDependencies": {
           "chai": "~1.9.1",\n
    ''',
    '''
      @@ -38,7 +37,6 @@
         "keywords": [
           "git",
           "promise",
      -    "async",
      -    "shell"
      +    "async"
         ]
       }
    '''
  ]

  describe '::constructor', ->
    it 'parses the raw data', ->

      diff = new Diff('package.json', diffRaw)

      diff.raw.should.contain diffRaw
      diff.chunks.should.eql diffChunks
