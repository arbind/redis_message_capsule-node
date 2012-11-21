REDIS = require('redis-url')
node_env = process.env.NODE_ENV || 'development'

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
    @listenerClients = {}

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

  _handleNextMessage: (redisClient, channelsArray, handler)=> # infinite recursion for getting next message
    redisClient.blpop channelsArray..., 0, (err, channel_element)=>
      console.log err
      console.log channel_element
      channel = channel_element[0]
      element = channel_element[1]
      try 
        payload = (JSON.parse element)
      catch ignoredException
        # noop 
      finally
        payload ?= {}
      message = payload.data
      # fire event on channel
      console.log "#{channel}: #{message}"
      handler(message) if handler?()
      @_handleNextMessage redisClient, channelsArray..., handler

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
    
    redisClient = @listenerClients[key] || REDIS.connect(url)
    unless redisClient?
      console.log "!!!\n!!! Can not connect to redis server at #{uri}\n!!!"
      return null
    console.log "selecting #{dbNum}"
    redisClient.select dbNum
    console.log "connected!"
    @listenerClients[key] = redisClient
    console.log "Listening for messages on #{[channels...].join(', ')} [db: #{dbNum}]"
    @_handleNextMessage redisClient, channels, handler

module.exports = new RedisMessageCapsule
