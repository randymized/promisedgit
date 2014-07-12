#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

# Public: Represents the diffs of a file.
class Diff
  # Public: Constructs a new instance of {Diff}.
  #
  # path - The path to the fill that was diffed as {String}.
  # raw      - The raw diff data as {String}.
  constructor: (@path, @raw='') ->
    @chunks = [] = @raw.split(/^@@(?=[ \-\+\,0-9]*@@)/gm)
    @chunks = ('@@' + line for line in @chunks[1..])

module.exports = Diff
