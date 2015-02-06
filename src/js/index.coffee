'use strict'
###
# index.coffee
###

# TODO angularify graph editor, depend on control panel within
angular.module 'vphi', [
  require('./services/compute').name
  require('./services/format').name
  require('./services/graph').name
  require('./graph-editor').name
  require('./concept-space').name
  require('./control-panel').name
  require('./output-summary').name
  require('./concept-list').name
]
  .constant 'version', require('../../package.json').version
  .constant 'NETWORK_SIZE_LIMIT', 10
  .constant 'CANVAS_HEIGHT', 500
