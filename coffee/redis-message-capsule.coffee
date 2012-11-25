REDIS = require 'redis-url'

Capsule = require './capsule'

class RedisMessageCapsule
  @capsules: {} 
  @configuration:
    redisURL: process.env.REDIS_URL || process.env.REDISTOGO_URL || 'redis://127.0.0.1:6379/'
    dbNumber:
      switch node_env
        when  'production' then 7
        when  'development' then 8
        when  'test' then 9
        else 9

  @makeCapsuleKey: (url, dbNum)-> "#{url}.#{dbNum}" # class method

  @capsule:  (redisURL=null, dbNumber=-1)-> (RedisMessageCapsule.materializeCapsule redisURL, dbNumber)

  @materializeCapsule: (redisURL=null, dbNumber=-1)-> # class method
    url = redisURL || RedisMessageCapsule.configuration.redisURL
    dbNum = dbNumber
    dbNum = RedisMessageCapsule.configuration.dbNumber if dbNum < 0
    key = (RedisMessageCapsule.makeCapsuleKey url, dbNum)
    # materialize the capsule:
    capsule = RedisMessageCapsule.capsules[key] || (new Capsule url, dbNum)
    RedisMessageCapsule.capsules[key] = capsule

  @materialize_redis_client: (redisURL, dbNumber)->
    redisClient = REDIS.connect(@redisURL)
    redisClient.select dbNumber if redisClient?
    redisClient

# module needs to be global other classses can reference its class methods
module.exports = global.RedisMessageCapsule = RedisMessageCapsule