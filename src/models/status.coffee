#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

File = require './file'

# Public: Represents the git status for the whole repository.
class Status
  # Public: Constructs a new instance of {Status}.
  #
  # raw  - The raw porcelain status as {String}.
  # repo - The repository as {GitPromised}.
  constructor: (raw, @repo) ->
    throw new Error('Invalid repository') unless @repo?.isGitRepo
    @parseRaw(raw)

  # Internal: Parses the raw data.
  #
  # raw - The raw porcelain status as {String}.
  parseRaw: (raw) ->
    lines = splitLines(raw)
    @branch = parseBranch(lines)

    [@staged, @unstaged, @untracked] = parseFiles(lines, @repo)

  # Private: Split the raw data into lines.
  # raw - The raw porcelain status as {String}.
  #
  # Returns an {Array} of lines.
  splitLines = (raw) ->
    raw.split if '\u0000' in raw then '\u0000' else '\n'

  # Private: Retrieves the branch name.
  #
  # lines - The lines as {Array}.
  #
  # Returns the branch name as {String}.
  parseBranch = (lines) ->
    branch = lines[0].substring(3) ? 'HEAD'
    lines.shift()
    branch

  # Private: Parses the raw data and returns an array of {File}s.
  #
  # lines - The lines as {Array}.
  # repo  - The repository as {GitPromised}.
  #
  # Returns an {Array} with the indices
  #   :0 - The staged files as {Array}.
  #   :1 - The unstaged files as {Array}.
  #   :2 - The untacked files as {Array}.
  parseFiles = (lines, repo) ->
    staged    = []
    unstaged  = []
    untracked = []

    for line in lines when line isnt ''
      mode = line.substring(0, 2)
      path = line.substring(3)
      file = new File(path, repo, mode)

      staged.push file if file.isStaged()
      unstaged.push file if file.isUnstaged()
      untracked.push file if file.isUntracked()

    [staged, unstaged, untracked]


module.exports = Status
