#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

fs     = require 'fs'
path   = require 'path'
wrench = require 'wrench'
temp   = require('temp').track()

chai = require 'chai'
chai.should()
chai.use require('chai-as-promised')

module.exports = (fixtureName) ->
  throw new Error('No fixtureName given!') unless fixtureName?

  tempPath    = temp.mkdirSync('git-promised-test')
  fixturePath = path.join __dirname, 'fixtures', fixtureName

  wrench.copyDirSyncRecursive(fixturePath, tempPath, forceDelete: true)
  fs.renameSync(path.join(tempPath, 'git.git'), path.join(tempPath, '.git'))

  tempPath
