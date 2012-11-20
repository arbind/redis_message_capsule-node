sys = require 'sys'
{exec} = require 'child_process'

task 'spec:server', 'Test server-side specs', ->
  exec 'NODE_ENV=test ./node_modules/.bin/mocha --compilers cofee:coffee-script spec/server/test.coffee', (err, stdout, stderr) ->
    throw err if err
    sys.print "Test server-side specs\n" + stdout + stderr + "\n----------------------------------------\n"

task 'spec:client', 'Test client-side specs', ->
  exec 'NODE_ENV=test ./node_modules/.bin/mocha --compilers cofee:coffee-script spec/client/test.coffee', (err, stdout, stderr) ->
    throw err if err
    sys.print "Test client-side specs\n" + stdout + stderr + "\n----------------------------------------\n"

task 'spec:user', 'Test user-interaction specs (headless-browser)', ->
  exec 'NODE_ENV=test ./node_modules/.bin/mocha --compilers cofee:coffee-script spec/user/test.coffee', (err, stdout, stderr) ->
    throw err if err
    sys.print "Test user-interaction specs (headless-browser)\n" + stdout + stderr + "\n----------------------------------------\n"


task 'spec', 'Run all client and server specs', ->
  invoke 'spec:server'
  invoke 'spec:client'
  invoke 'spec:user'
