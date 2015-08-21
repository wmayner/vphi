'use strict'
###
# index.coffee
###

angular.module 'vphi', [
  require('./services/compute').name
  require('./services/formatter').name
  require('./services/network').name
  require('./network-editor').name
  require('./concept-space').name
  require('./control-panel').name
  require('./output-summary').name
  require('./concept-list').name
]
  .constant 'VERSION', require('../../package.json').version
  .constant 'NETWORK_SIZE_LIMIT', 9
  .constant 'CANVAS_HEIGHT', 500
