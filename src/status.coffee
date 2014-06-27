pushUniq = (array, value) ->
  array.push value unless value in array

createStatus = ->
  modified: []
  added: []
  deleted: []
  renamed: []
  copied: []

process = (host, status, code, file) ->
  keys =
    M: 'modified'
    A: 'added'
    D: 'deleted'
    R: 'renamed'
    C: 'copied'

  pushUniq host[status][keys[code]], file if code of keys
  pushUniq host[status].added, file if code is '?' and status is 'workingTree'

module.exports = (output) ->
  lineSeparator = if output.indexOf('\u0000') isnt -1 then '\u0000' else '\n'
  summary =
    branch: ''
    index: createStatus()
    workingTree: createStatus()

  lines = output.split(lineSeparator)
  for line in lines when line
    index = line.substring(0, 1)
    workingTree = line.substring(1, 2)
    file = line.substring(3)
    if index is '#' and workingTree is '#'
      summary.branch = file
    else
      process summary, 'index', index, file
      process summary, 'workingTree', workingTree, file
  summary
