Channel = require './channel'

###
# Capsule
#    binds to a redis database (to a selected dbNumber)
###
class Capsule
  constructor: (@redisURL, @dbNumber) ->
    @channels = {}
    @redisClient = (RedisMessageCapsule.materialize_redis_client @redisURL, @dbNumber)
    unless @redisClient?
      console.log "!!!\n!!! Can not connect to redis server at #{@redisURL}\n!!!"

  materializeChannel: (channelName) -> @channels[channelName] ||= new Channel(channelName, @redisClient, @redisURL, @dbNumber)
  channel: (channelName) -> @materializeChannel(channelName)
  makeChannel: (channelName) -> @materializeChannel(channelName)
  createChannel: (channelName) -> @smaterializeChannel(channelName)

module.exports = Capsule