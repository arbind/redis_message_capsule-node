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
    @listenerThreads = {}

    @configuration =
      redisURL: process.env.REDIS_URL || process.env.REDISTOGO_URL || 'redis://127.0.0.1:6379/'
      redisDBNumber: dbNumber
    @config = @configuration


  makeClientKey: (url, dbNum)-> "#{url}.#{dbNum}"
  makeChannelKey: (name, url, dbNum)-> "#{name}.#{url}.#{dbNum}"
  makeListenerKey: (channels..., url, dbNum)-> [ channels..., url, dbNum].join('.')


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
        puts "!!!\n!!! Can not connect to redis server at #{uri}\n!!!"
        return null
      console.log "selecting #{dbNum}"
      redisClient.select dbNum
      @redisClients[clientKey] = redisClient

    channel = new Channel(name, redisClient)
    @capsuleChannels[channelKey] = channel
    channel

  # connect to redis
  # if redisURL
  #   global.redis = require('redis-url').connect(redisURL)
  #   redis.on 'connect', =>
  #     redis.send_anyways = true
  #     console.log "redis: connection established"
  #     redis.select redisDBNumber, (err, val) => 
  #       redis.send_anyways = false
  #       redis.selectedDB = redisDBNumber
  #       console.log "redis: selected DB ##{redisDBNumber} for #{env}"
  #       redis.emit 'db-select', redisDBNumber
  #       unless debug
  #         redis.keys '*', (err, keys)->
  #           console.log "redis: #{keys.length} keys present in DB ##{redisDBNumber} "


module.exports = new RedisMessageCapsule
