###
# colors/index.coffee
###

solarized = require './solarized'

black = d3.rgb 0, 0, 0
white = d3.rgb 255, 255, 255
yellow = d3.rgb 255, 255, 50

module.exports =
  solarized: solarized
  black: black
  white: white
  node:
    on: solarized.cyan
    off: solarized.base1
    label:
      on: white
      off: white
  link:
    line: white
    endpoint: white
  cause: solarized.blue
  effect: d3.rgb 42, 188, 72
  repertoire:
    partitioned: '#ccc'
