#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

_ = require 'underscore'

# Public: Represents the diffs of a file.
class Diff
  constructor: (@filePath, @raw='') ->
    @chunks = [] = @raw.split(/^@@(?=[ \-\+\,0-9]*@@)/gm)
    @chunks = ('@@' + line for line in @chunks[1..])

module.exports = Diff
