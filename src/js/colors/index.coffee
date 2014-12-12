###
# colors/index.coffee
###

solarized = require './solarized'


white = d3.rgb 255, 255, 255

module.exports =
  solarized: solarized
  node:
    on: solarized.cyan
    off: solarized.base1
    label: white
  link:
    line: white
    endpoint: white
