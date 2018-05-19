del = require 'del'
gulp = require 'gulp'
jade = require 'gulp-jade'
path = require 'path'
shell = require 'gulp-shell'
templateCache = require 'gulp-angular-templatecache'
watch = require 'gulp-watch'

SRC_DIR = './src'
LIB_DIR = './lib'
APP_DIR = './app'

# TODO watch stylus
STYLUS_DIR = "#{SRC_DIR}/css"
STYLUS_FILES = "#{STYLUS_DIR}/**/*.styl"

JADE_MAIN = "#{SRC_DIR}/index.jade"
JADE_PARTIALS = "#{SRC_DIR}/js/**/*.jade"

COFFEE_DIR = "#{SRC_DIR}/js"
COFFEE_FILES = "#{COFFEE_DIR}/**/*.coffee"
COFFEE_CMD = './node_modules/coffee-script/bin/coffee'

ENTRYPOINT = "#{COFFEE_DIR}/index.coffee"

gulp.task 'clean:html', -> del "#{APP_DIR}/*.html"

gulp.task 'clean:js', -> del "#{APP_DIR}/js/*.js"

gulp.task 'clean:css', -> del "#{APP_DIR}/css/*.css"

gulp.task 'clean', ['clean:html', 'clean:js', 'clean:css']

gulp.task 'compile:jade', ['clean:html'], ->
  gulp.src JADE_MAIN
    .pipe jade()
    .pipe gulp.dest APP_DIR

gulp.task 'compile:templates', ->
  gulp.src JADE_PARTIALS
    .pipe jade()
    .pipe templateCache({
      module: 'vphi'
      # Strip path.
      # Because of this templates must have unique names
      transformUrl: path.basename
    })
    .pipe gulp.dest "#{APP_DIR}/js"

gulp.task 'compile:stylus', ['clean:css'], shell.task(
  # Compile with line numbers and sourcemaps
  "./node_modules/stylus/bin/stylus -l -m #{STYLUS_DIR}/app.styl -o #{APP_DIR}/css"
)

gulp.task 'browserify', shell.task(
  "./node_modules/browserify/bin/cmd.js #{ENTRYPOINT} --transform coffeeify --extension='.coffee' --no-cache -o #{APP_DIR}/js/app.js",
)

gulp.task 'build', ['compile:jade', 'compile:templates', 'compile:stylus', 'browserify']

gulp.task 'watch:jade', ['compile:jade', 'compile:templates'], ->
  gulp.watch([JADE_MAIN, JADE_PARTIALS], ['compile:jade', 'compile:templates'])

gulp.task 'watch:stylus', ['compile:stylus'], ->
  gulp.watch(STYLUS_FILES, ['compile:stylus'])

gulp.task 'watch:coffee', ['browserify'], ->
  gulp.watch(COFFEE_FILES, ['browserify'])

gulp.task 'dev', ['build', 'watch:jade', 'watch:stylus', 'watch:coffee']

gulp.task 'default', ['dev']
