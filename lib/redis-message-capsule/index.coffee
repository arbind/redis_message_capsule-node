REDIS = (require 'redis-url')
TAGG  = (require 'threads_a_gogo')
JASON = require("JASON")
node_env = process.env.NODE_ENV || 'development'

notifyOnMessages = (redisClient, channel, handler)=> # the worker method
  redisClient.lpop channel, (err, element) =>
    return unless element?
    # console.log element
    try 
      payload = (JSON.parse element)
    catch ignoredException
      # noop 
    finally
      payload ?= {}
    message = payload.data
    console.log "#{channel}:"
    console.log message
    handler(message)

class Channel
  constructor: (@name, @redisClient) ->

  send: (message)->
    payload = 'data': message
    console.log payload
    console.log (JSON.stringify payload)
    @redisClient.rpush @name, (JSON.stringify payload), (err, count)->
      console.log count

class RedisMessageCapsule
  config: {}

  constructor: ->
    console.log "node_env: " + node_env
    dbNumber = 7 if node_env is 'production'
    dbNumber = 8 if node_env is 'development'
    dbNumber = 9 if node_env is 'test'
    dbNumber ||= 9

    @redisClients = {}
    @capsuleChannels = {}
    @listenerThreads = {}

    @configuration =
      redisURL: process.env.REDIS_URL || process.env.REDISTOGO_URL || 'redis://127.0.0.1:6379/'
      redisDBNumber: dbNumber
    @config = @configuration

  makeClientKey: (url, dbNum)-> "#{url}.#{dbNum}"
  makeChannelKey: (name, url, dbNum)-> "#{name}.#{url}.#{dbNum}"
  makeListenerKey: (channels, url, dbNum)-> [ channels..., url, dbNum].join('.')

  channel: (name, redisURL=null, dbNumber=-1)->
    url = redisURL || @config.redisURL
    dbNum = dbNumber
    dbNum = @config.redisDBNumber if dbNum < 0

    channelKey = @makeChannelKey(name, url, dbNum)
    return @capsuleChannels[channelKey] if @capsuleChannels[channelKey]?

    clientKey = @makeClientKey(url, dbNum)
    redisClient = @redisClients[clientKey]

    unless redisClient?
      redisClient = REDIS.connect(url)
      unless redisClient?
        console.log "!!!\n!!! Can not connect to redis server at #{uri}\n!!!"
        return null
      console.log "selecting #{dbNum}"
      redisClient.select dbNum
      @redisClients[clientKey] = redisClient

    channel = new Channel(name, redisClient)
    @capsuleChannels[channelKey] = channel
    channel

  ###
  # functionAsString
  #   convert
  #     fnName = function (){...}
  #   into:
  #     function fnName(){...}
  ###
  functionAsString: (fnName, fn) ->
    fnToString = fn.toString()
    fnToString.replace("function", "function #{fnName}")

  listen: (channelsArray, cfg={}, handler)->
    unless handler?
      handler = cfg
      cfg = {redisUrl:null, dbNumber:-1}
    channels = channelsArray if channels instanceof Array
    channels ?= [ channelsArray ]
    dbNum = cfg.dbNumber || -1
    dbNum = @config.redisDBNumber if dbNum < 0
    url = cfg.redisUrl || @config.redisURL
    key = @makeListenerKey(channels, url, dbNum)
    console.log key

    redisClient = require('redis-url').connect(url) # assume a separate context.
    unless redisClient?
      console.log "!!!\n!!! Can not connect to redis server at #{uri}\n!!!"
      return null
    console.log "selecting #{dbNum}"
    redisClient.select dbNum, (err, val)->
      console.log val
      setInterval(notifyOnMessages, 100, redisClient, channelName, handler) for channelName in channels


module.exports = new RedisMessageCapsule

# r = require './index'; cat = r.listen 'cat'



# failed attempt to use threads a go go  
# listen: (channelsArray, cfg={}, handler)->
#   unless handler?
#     handler = cfg
#     cfg = {redisUrl:null, dbNumber:-1}
#   channels = channelsArray if channels instanceof Array
#   channels ?= [ channelsArray ]
#   dbNum = cfg.dbNumber || -1
#   dbNum = @config.redisDBNumber if dbNum < 0
#   url = cfg.redisUrl || @config.redisURL
#   key = @makeListenerKey(channels, url, dbNum)
#   console.log key

#   notifyOnMessages = (channelsArray)-> # the worker method
#     puts "1"
#     puts xyz
#     # Context is now inside of a TAGG thread
#     #   There are no shared resources: Can't rely on outside closures, everything must be passed in.
#     #   thread is available as a global variable
#     #   may need to require things as if being they were being used for 1st time
#     thread.name = "RedisMessageCapsuleListener"
#     while true # listen forever to redis messages
#       thread.redisClient.blpop channelsArray..., 0, (err, channel_element)=> # grab a message, or block thread to wait for the next one.
#         console.log err
#         console.log channel_element
#         channel = channel_element[0]
#         element = channel_element[1]
#         console.log channel
#         console.log element
#         try 
#           payload = (JSON.parse element)
#         catch ignoredException
#           # noop 
#         finally
#           payload ?= {}
#         message = payload.data
#         # fire event on channel
#         console.log "#{channel}: #{message}"
#         thread.emit('pop', message)


#   tagThread = @listenerThreads[key] = TAGG.create()
#   tagThread.eval("JASON= "+ JASON.stringify(JASON));

#   tagThread.on('pop', handler)
#   tagThread.eval "xyz = 'XXXXYYYYZZZZZZZZZZ'"
#   tagThread.eval "var redis = " + JSON.stringify(require('redis-url'))
#   console.log 'a'
#   console.log JSON.stringify(require('redis-url').connect(url) )
#   console.log 'b'

#   redisClient = require('redis-url').connect(url) # assume a separate context.
#   tagThread.description = "Listening for messages from #{url} on channel: #{channels.join(',')} "
#   unless redisClient?
#     console.log "!!!\n!!! Can not connect to redis server at #{uri}\n!!!"
#     return null
#   console.log "selecting #{dbNum}"
#   # represent the worker method as a string
#   notifyOnMessagesAsString = (@functionAsString 'notifyOnMessages', notifyOnMessages)
#   # declare the method in the thread's context
#   tagThread.eval notifyOnMessagesAsString, (err, val) ->
#     redisClient.select dbNum, (err, val)->

#       console.log "connected!"
#       console.log "Listening for messages on #{[channels...].join(', ')} [db: #{dbNum}]"
#       channelNames = '[ ' # represent the array of channels as a string (to pass as an argument to eval)
#       (channelNames += ', ' unless 0 is idx; channelNames += "'#{channel}'") for channel, idx in channels
#       channelNames += ' ]'
#       console.log  "notifyOnMessages(#{channelNames}, '#{url}', #{dbNum})"
#       #start listening
#       console.log 5
#       # console.log JASON.stringify(redisClient)
#       # tagThread.eval("var redisClient =" + JASON.stringify(redisClient))
#       console.log 6
#       tagThread.eval "notifyOnMessages(#{channelNames}, '#{url}', #{dbNum})", (err, val) -> console.log "launching!"; console.log err; console.log val
