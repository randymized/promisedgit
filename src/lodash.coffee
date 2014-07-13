#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

lodash = require 'lodash'

# Public: _.isInstanceOf()
#
# obj   - The object to check as {Object}.
# klass - The klass name as {String}.
#
# Returns: {Boolean}.
instanceOf = (obj, klass) ->
  obj = Object.getPrototypeOf(obj)
  while obj?
    return true if obj.constructor.name is klass
    obj = Object.getPrototypeOf(obj)
  false

lodash.mixin({'instanceOf': instanceOf}, {'chain': false})

module.exports = lodash
