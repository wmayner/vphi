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
  .constant 'PYPHI_VERSION', '0.8.1'
  .constant 'NETWORK_SIZE_LIMIT', 8
  .constant 'CANVAS_HEIGHT', 500
