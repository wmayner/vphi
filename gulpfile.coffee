exec = require("child_process").exec
path = require "path"
gulp = require "gulp"
gutil = require "gulp-util"
stylus = require "gulp-stylus"
coffee = require "gulp-coffee"
watch = require "gulp-watch"
rimraf = require "gulp-rimraf"
Duo = require "duo"

SRC_DIR = "src"
LIB_DIR = "lib"
BUILD_DIR = "build"
ENTRY = "./index.js"
STYLUS = "#{SRC_DIR}/*.styl"
COFFEE = "#{SRC_DIR}/*.coffee"
SRC_FILES = [STYLUS, COFFEE]
TEST_FILES = "test/*"

compileStylus = (outputDir, cb = ->) ->
  output = path.join outputDir, "index.css"
  gulp.src(STYLUS)
    .pipe(stylus({linenos: true})).on("error", gutil.log)
    .pipe(gulp.dest(outputDir))
    .on "finish", (err) ->
      gutil.log err if err
      gutil.log "  [stylus] Compiled #{STYLUS} to #{output}"
      cb()

compileCoffee = (outputDir, cb = ->) ->
  gulp.src(COFFEE)
    .pipe(coffee({bare: true})).on("error", gutil.log)
    .pipe(gulp.dest(outputDir))
    .on "finish", (err) ->
      gutil.log err if err
      gutil.log "  [coffee] Compiled #{COFFEE} to #{outputDir}/"
      cb()

runDuo = (buildDir, development = false, cb = ->) ->
  cmd = exec "duo #{ENTRY} --build #{BUILD_DIR} --no-cache > #{path.join(BUILD_DIR, "build.js")}", (err, stdout, stderr) ->
    gutil.log err if err
    gutil.log stdout if stdout
    gutil.log stderr if stderr

# Compile Coffeescript to the build directory
gulp.task "coffee", -> compileCoffee LIB_DIR

# Compile stylus to the build directory
gulp.task "stylus", -> compileStylus BUILD_DIR

# Build Javascript deps with Duo
gulp.task "duo", ["coffee"], -> runDuo BUILD_DIR, false

# Compile CoffeeScript and Stylus
gulp.task "build", ["duo", "stylus"]

# Clean built files
gulp.task "clean", ->
  gulp.src(["#{BUILD_DIR}/build.js", "#{BUILD_DIR}/index.css"], {read: false})
    .pipe(rimraf())

# Run tests
gulp.task "run-tests", ->
  cmd = exec "mocha", (err, stdout, stderr) ->
    gutil.log err if err
    gutil.log stdout if stdout
    gutil.log stderr if stderr

# Watch test directory for changes and run tests
gulp.task "test", ["run-tests"], ->
  gulp.watch([SRC_FILES, TEST_FILES], ["run-tests"])
    .on("error", gutil.log)

# Watch source directory for changes and build to the test directory
gulp.task "watch-stylus", ["stylus"], ->
  gulp.watch(STYLUS, ["stylus"])
    .on("error", gutil.log)

# Watch source directory for changes and build to the test directory
gulp.task "watch-coffee", ["duo"], ->
  gulp.watch(COFFEE, ["duo"])
    .on("error", gutil.log)

# Watch source directory for changes and build to the test directory
gulp.task "watch", ["watch-stylus", "watch-coffee"], ->

# Watch by default
gulp.task "default", ["watch"]
