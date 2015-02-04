'use strict'
###
# index.coffee
###

# TODO angularify graph editor, depend on control panel within
angular.module 'vphi', [
  require('./services/compute').name
  require('./services/format').name
  require('./services/graph').name
  require('./graph-editor/control-panel').name
  require('./concept-space').name
  require('./control-panel').name
  require('./output-summary').name
  require('./concept-list').name
]
  .constant 'version', require('../../package.json').version
