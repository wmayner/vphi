'use strict'
###
# index.coffee
###

angular.module 'vphi', [
  require('./services/compute').name
  require('./services/compute/pyphi').name
  require('./services/formatter').name
  require('./services/network').name
  require('./network-editor').name
  require('./concept-space').name
  require('./control-panel').name
  require('./output-summary').name
  require('./concept-list').name
]
  .constant 'VERSION', require('../../package.json').version
  .constant 'PYPHI_VERSION', '1.0.0'
  .constant 'PHISERVER_URL', 'http://127.0.0.1:5000'  # Development
  # .constant 'PHISERVER_URL', 'http://144.92.177.185'  # Production
  .constant 'NETWORK_SIZE_LIMIT', 8
  .constant 'CANVAS_HEIGHT', 500
