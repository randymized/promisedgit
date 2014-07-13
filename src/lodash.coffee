#
# Copyright (c) 2014 by Maximilian Schüßler. See LICENSE for details.
#

lodash = require 'lodash'

# Public: Similar `instanceof` operator, but checks for the `constructor.name`.
#
# ### Caution
# Uglifying scripts will __break__ this method, so be careful!
#
# obj   - The object to test as {Object}.
# klass - The klass name as {String}|{Function}.
#
# ### Example
# ```coffee
# testCommit = new Commit('e9e3ad6a71996fb83440df2ac36912e2ddb555e0', git)
# _.instanceOf(testCommit, 'Commit')  # => true
# _.instanceOf(testCommit, 'Treeish') # => true
# _.instanceOf(testCommit, 'Object')  # => true
# _.instanceOf(testCommit, 'File')    # => false
# _.instanceOf(testCommit, 'Array')   # => false
# ```
#
# Returns: {Boolean}.
instanceOf = (obj, klass) ->
  return obj instanceof klass if lodash.isFunction(klass)
  obj = Object.getPrototypeOf(obj)
  while obj?
    return true if obj.constructor.name is klass
    obj = Object.getPrototypeOf(obj)
  false
lodash.mixin({'instanceOf': instanceOf}, {'chain': false})

module.exports = lodash
