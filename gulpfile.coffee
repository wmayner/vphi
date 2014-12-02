sh = require 'execSync'
path = require 'path'
gulp = require 'gulp'
gutil = require 'gulp-util'
stylus = require 'gulp-stylus'
coffee = require 'gulp-coffee'
watch = require 'gulp-watch'
rimraf = require 'gulp-rimraf'
mochaPhantomJS = require 'gulp-mocha-phantomjs'
Duo = require 'duo'

ONLINE = true

SRC_DIR = './src'
LIB_DIR = './lib'
BUILD_DIR = './build'
ENTRYPOINT = './index.js'
# TODO watch stylus
STYLUS = "#{SRC_DIR}/*.styl"
COFFEE_DIR = "#{SRC_DIR}"
COFFEE = "#{COFFEE_DIR}/**/*.coffee"
SRC_FILES = [STYLUS, COFFEE]

TEST_DIR = './test'
TEST_SRC_FILES = "#{TEST_DIR}/src/*.coffee"
TEST_JS_DIR = "#{TEST_DIR}/js"

###
Helpers
###

compileStylus = (outputDir, input) ->
  output = path.join outputDir, 'index.css'
  gulp.src(STYLUS)
    .pipe(stylus({linenos: true})).on('error', gutil.log)
    .pipe(gulp.dest(outputDir))
    .on 'finish', (err) ->
      gutil.log err if err
      gutil.log "  [stylus] Compiled #{STYLUS} to #{output}"

compileCoffee = (outputDir, input) ->
  cmd = sh.exec "coffee -co #{outputDir} #{input}"
  gutil.log cmd.stdout
  gutil.log "  [coffee] Compiled #{input} to #{outputDir}"

runDuo = (input, output, development = false) ->
  if ONLINE
    cmd = sh.exec "duo #{input} --no-cache > #{output}"
  else
    cmd = sh.exec "browserify -o build/build.js #{input} --no-cache > #{output}"
  gutil.log cmd.stdout

###
Build the app
###

# Compile stylus to the build directory
gulp.task 'stylus', -> compileStylus BUILD_DIR, STYLUS

# Compile Coffeescript to the build directory
gulp.task 'coffee', -> compileCoffee LIB_DIR, COFFEE_DIR

# Compile CoffeeScript and Stylus
gulp.task 'build', ['duo', 'stylus']

# Build source with Duo
gulp.task 'duo', ['coffee'], ->
  runDuo ENTRYPOINT, "#{BUILD_DIR}/build.js",

# Clean built files
gulp.task 'clean', ->
  gulp.src([
      "#{BUILD_DIR}/build.js"
      "#{BUILD_DIR}/index.css"
      "#{LIB_DIR}/*"
    ], {read: false}).pipe(rimraf())

# Watch source directory for changes and build to the test directory
gulp.task 'watch-stylus', ['stylus'], ->
  gulp.watch(STYLUS, ['stylus'])
    .on('error', gutil.log)

# Watch source directory for changes and build to the test directory
gulp.task 'watch-coffee', ['duo'], ->
  gulp.watch(COFFEE, ['duo'])
    .on('error', gutil.log)

# Watch source directory for changes and build to the test directory
gulp.task 'watch', ['watch-stylus', 'watch-coffee'], ->

# Watch by default
gulp.task 'default', ['watch']

###
Testing
###

# Compile test source
gulp.task 'coffee-test', ->
  compileCoffee TEST_JS_DIR, TEST_SRC_FILES

# Build tests with Duo
gulp.task 'duo-test', ['coffee-test'], ->
  runDuo "#{TEST_DIR}/js/tests.js", "#{TEST_DIR}/tests.js", false

# Run tests
gulp.task 'run-tests', ['duo-test'], ->
  gulp.src("#{TEST_DIR}/index.html")
    .pipe(mochaPhantomJS({reporter: 'min'}))
    .on 'error', (err) -> this.emit('end')

# Watch test directory for changes and run tests
gulp.task 'test', ['run-tests'], ->
  gulp.watch([SRC_FILES, TEST_SRC_FILES], ['run-tests'])
    .on('error', gutil.log)
