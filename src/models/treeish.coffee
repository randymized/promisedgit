{Model} = require 'backbone'
{File}  = require './'

module.exports =
class Treeish extends Model

  constructor: (@repo, @ref) ->
    throw new Error('No valid git repo!!!') unless @repo?.isGitRepo
    throw new Error('No valid ref!!!') unless (typeof(@ref) is 'string')

  checkout: ->
    @repo.checkout(@ref)

  diff: (treeish='HEAD') ->
    @repo.diff(null, "#{@ref}..#{treeish}")

  diffTo: (treeish) ->
    @diff(treeish)

  diffFrom: (treeish='HEAD') ->
    @repo.diff(null, "#{treeish}..#{@ref}")

  getFile: (file) ->
    return throw new Error('No valid file!') unless file?
    return file.show(@ref) if file instanceof File
    @repo(@ref, file)

  reset: (mode) ->
    options = if mode? then {"#{mode}": true} else {}
    @cmd 'reset', options, @ref
