module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-exec'
  grunt.loadNpmTasks 'grunt-release'
  grunt.loadNpmTasks 'grunt-gh-pages'
  grunt.loadNpmTasks 'grunt-coffee-coverage'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.initConfig

    'coffee':
      compile:
        expand: true
        cwd: "#{__dirname}/src/"
        src: '**/*.coffee'
        dest: 'lib/'
        ext: '.js'
      compileForCoverage:
        expand: true
        cwd: "#{__dirname}"
        src: ['test/*.coffee', 'test/models/*.coffee']
        dest: '.grunt'
        ext: '.js'

    'copy':
      copyFixturesCoverage:
        files: [
          {expand: true, cwd: 'test/fixtures/', src: ['**'], dest: '.grunt/test/fixtures'},
        ]

    'coffeelint':
      app: ['src/**/*.coffee', 'test/*.coffee', 'test/models/*.coffee']
      options:
        arrow_spacing:
          level: 'warn'
        indentation:
          value: 2
          level: 'warn'
        line_endings:
          level: 'warn'
          value: 'unix'
        max_line_length:
          value: 80
          level: 'ignore'
          limitComments: true
        no_empty_functions:
          level: 'warn'
        no_empty_param_list:
          level: 'warn'
        no_interpolation_in_single_quotes:
          level: 'error'
        no_stand_alone_at:
          level: 'warn'
        no_trailing_whitespace:
          level: 'ignore'
          allowed_in_comments: false
          allowed_in_empty_lines: true
        no_unnecessary_double_quotes:
          level: 'warn'

    'mochaTest':
      test:
        options:
          reporter: 'spec'
          require: 'coffee-script/register'
        src: ['test/*.coffee', 'test/models/*.coffee']
      coverage:
        options:
          reporter: 'html-cov'
          quiet: true
          captureFile: 'coverage.html'
          # require: '.grunt/src/init.js'
        src: '.grunt/test/**/*.js'

    'coffeeCoverage':
      options:
        path: 'relative'
        initfile: '.grunt/src/init.js'
      cov:
        options:
          initfile: '.grunt/src/init.js'
        src: 'src'
        dest: '.grunt/src'

    'exec':
      build_docs:
        # I am using a patched version of biscotto to hotfix
        # https://github.com/atom/biscotto/pull/59 for now.
        command: 'biscotto'

    'gh-pages':
      options:
        base: 'doc'
      src: ['**']

    'release':
      options:
        bump: true
        add: true
        commit: true
        tag: true
        push: true
        pushTags: true
        tagName: 'v<%= version %>'
        commitMessage: 'Prepare v<%= version %> release'

  grunt.registerTask('build', 'coffee:compile')
  grunt.registerTask('docs', ['exec:build_docs', 'gh-pages'])
  grunt.registerTask('lint', 'coffeelint')
  grunt.registerTask('test', 'mochaTest:test')

  grunt.registerTask('default', 'prepublish')
  grunt.registerTask 'coverage', [
    'coffeeCoverage'
    'coffee:compileForCoverage'
    'copy:copyFixturesCoverage'
    'mochaTest:coverage'
  ]
  grunt.registerTask('prepublish', ['lint', 'test', 'build'])
