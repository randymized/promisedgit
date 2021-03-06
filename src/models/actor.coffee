#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

# Public: Represents a committer/author/tagger.
class Actor
  # Public: Construct a new Actor.
  #
  # raw - The raw actor as {String}.
  #
  # Returns an instance of Actor.
  constructor: (raw) ->
    if /<.+>/.test raw
      [m, name, email] = /(.*) <(.+?)>/.exec raw
      [@name, @email] = [name, email]
    else
      @name = raw


  # Public: Get a string representation of the actor.
  #
  # Returns the formatted representation as {String}.
  toString: ->
    if @email then "#{@name} <#{@email}>" else @name

module.exports = Actor
