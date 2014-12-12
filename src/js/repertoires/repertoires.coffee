distribution = require './repertoires/distribution'

CONTAINER_SELECTOR = '#repertoire-container'
PAST_SELECTOR = '#past-repertoires'
FUTURE_SELECTOR = '#future-repertoires'

$container = $(CONTAINER_SELECTOR)
height = 500
width = $container.width()

$container.append(distribution('hi'))
