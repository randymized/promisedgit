_      = require 'underscore'
fs     = require 'fs'
path   = require 'path'
shell  = require 'shelljs'
wrench = require 'wrench'
temp   = require('temp').track()

module.exports = (fixtureName) ->
  return throw new Error 'No fixtureName given!' unless fixtureName?

  tempPath    = temp.mkdirSync('git-promised-test')
  fixturePath = path.join __dirname, 'fixtures', fixtureName

  wrench.copyDirSyncRecursive(fixturePath, tempPath, forceDelete: true)
  fs.renameSync(path.join(tempPath, 'git.git'), path.join(tempPath, '.git'))

  return tempPath
