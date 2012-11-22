REDIS = (require 'redis-url')
node_env = process.env.NODE_ENV || 'development'

class RedisMessageCapsule
  @capsules: {} # class variable
  @configuration: # class variable
    redisURL: process.env.REDIS_URL || process.env.REDISTOGO_URL || 'redis://127.0.0.1:6379/'
    dbNumber:
      switch node_env
        when  'production' then 7
        when  'development' then 8
        when  'test' then 9
        else 9

  @makeCapsuleKey: (url, dbNum)-> "#{url}.#{dbNum}" # class method

  @materializeCapsule: (redisURL=nil, dbNumber=-1)-> # class method
    url = redisURL || RedisMessageCapsule.configuration.redisURL
    dbNum = dbNumber
    dbNum = RedisMessageCapsule.configuration.dbNumber if dbNum < 0
    key = (RedisMessageCapsule.makeCapsuleKey url, dbNum)
    # materialize the capsule:
    capsule = RedisMessageCapsule.capsules[key] || (new Capsule url, dbNum)
    RedisMessageCapsule.capsules[key] = capsule

###
# Capsule
#    binds to a redis database (to a selected dbNumber)
###
class Capsule
  constructor: (@redisURL, @dbNumber) ->
    @channelEmitters = {}
    @channelListeners = {} # sort of threads, for now they just poll ;)

    @redisClient = REDIS.connect(@redisURL)
    @redisClient.select @dbNumber if @redisClient?
    unless @redisClient?
      console.log "!!!\n!!! Can not connect to redis server at #{@redisURL}\n!!!"

  materializeChannel: (channelName) -> @channelEmitters[channelName] ||= new ChannelEmitter(channelName, @redisClient)
  channel: (channelName) -> materializeChannel(channelName)
  makeChannel: (channelName) -> materializeChannel(channelName)
  createChannel: (channelName) -> materializeChannel(channelName)

  listenFor: (channelName, handler) ->
    @channelListeners[channelName] ||= new ChannelListener(channelName, @redisClient)
    @channelListeners[channelName].startListening(handler)
  on: (channelName, handler) -> @listenFor(channelName, handler)
  listen: (channelName, handler) -> @listenFor(channelName, handler)
  listenTo: (channelName, handler) -> @listenFor(channelName, handler)

class ChannelEmitter
  constructor: (@channelName, @redisClient) ->

  emit: (message, callback=null)->
    try
      payload = 'data': message
      payloadJSON = (JSON.stringify payload)
      throw "Could not serialize to json: #{message}" unless payloadJSON?
      @redisClient.rpush @channelName, payloadJSON, (err, count)->
        callback(err, count) if callback?
    catch ex
      (callback ex) if callback?

class ChannelListener
  constructor: (@channelName, @redisClient) ->
    @listening = false

  startListening: (handler)->
    @channelMsgHandler ||= new ChannelMessageHandler @channelName, @redisClient
    @channelMsgHandler.register(handler)

class ChannelMessageHandler
  constructor: (@channelName, @redisClient) ->
    @handlers = []
    setInterval( ( (cmh)-> cmh.pollForMessage() ) , 100, @) 

  register: (handler) -> @handlers.push handler
  unregister: (handler) ->
    @handlers.splice(@handlers.indexOf(handler), 1) while -1 isnt @handlers.indexOf(handler)

  pollForMessage: ()->
    return unless @handlers.length?
    try
      @redisClient.lpop @channelName, (err, element) =>
        return unless element?
        err = message = null
        try 
          payload = (JSON.parse element)
        catch ex
          err = ex
        finally
          payload ||= {}
          message = payload.data
          (handler err, message) for handler in @handlers
    catch ex 
      (handler ex) for handler in @handlers

module.exports = RedisMessageCapsule
