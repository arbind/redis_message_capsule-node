node_env = process.env.NODE_ENV || 'development'

class Channel
  constructor: (@name, @redis_client) ->

  send: (message)->
    payload = 'data': message
    @redis_client.rpush @name, payload.to_json


class RedisMessageCapsule
  config: {}

  constructor: ->
    dbNumber = 7 if node_env is 'production'
    dbNumber = 8 if node_env is 'development'
    dbNumber = 9 if node_env is 'test'
    dbNumber ||= 9

    @redis_clients = {}
    @capsule_channels = {}
    @listener_threads = {}

    @configuration =
      redisURL: process.env.REDIS_URL || process.env.REDISTOGO_URL || 'redis://127.0.0.1:6379/'
      redisDBNumber: dbNumber
    @config = @configuration


  make_client_key: (url, db_num)-> "#{url}.#{db_num}"
  make_channel_key: (name, url, db_num)-> "#{name}.#{url}.#{db_num}"
  make_listener_key: (channels..., url, db_num)-> [ channels..., url, db_num].join('.')

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
