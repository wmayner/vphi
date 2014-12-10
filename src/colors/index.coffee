###
# colors/index.coffee
###

solarized = require './solarized'

module.exports =
  solarized: solarized
  node:
    on: solarized.cyan
    off: solarized.base1
    label: solarized.base03
