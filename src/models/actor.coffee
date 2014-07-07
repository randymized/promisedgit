#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

module.exports = class Actor
  constructor: (@name, @email) ->

  # Public: Get a string representation of the Actor.
  toString: ->
    "#{@name} <#{@email}>"

  # Public: Parse an Actor from a "bla <bla@example.com>" string.
  #
  # Returns Actor.
  @from_string: (str) ->
    if /<.+>/.test str
      [m, name, email] = /(.*) <(.+?)>/.exec str
      return new Actor(name, email)
    else
      return new Actor(str, null)
