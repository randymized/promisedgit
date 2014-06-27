fs      = require 'fs'
Promise = require 'bluebird'

git     = require './git'
status  = require './status'

module.exports=
class Git
  constructor: (@cwd=process.cwd()) ->
    throw new Error("'#{@cwd}' does not exist!") unless fs.existsSync(@cwd)

  cmd: (command) ->
    git(command, {cwd:@cwd})

  status: (raw=false) ->
    new Promise (resolve, reject) =>
      @cmd('status --porcelain -z')
      .then (o) ->
        resolve o if raw
        resolve status(o)
