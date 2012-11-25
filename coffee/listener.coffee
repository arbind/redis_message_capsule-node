Fiber = require 'fibers'

# Process to run in fiber
blpopProcess = (listener)=>
  listener.blpopForever()  # launch the first blpop and let it block the current fiber
  Fiber.yield(listener)    # let blpop block and yield back to main fiber

class Listener
  constructor: (@channelName, @redisURL, @dbNumber) ->
    @handlers = []
    @listening = false
    @listenerFiber = null
    @redisClient = null

  register: (handler) ->
    @handlers.push handler
    @launchListener() unless @listenerFiber?
    handler

  unregister: (handler) ->
    @handlers.splice(@handlers.indexOf(handler), 1) while -1 isnt @handlers.indexOf(handler)

  stopListening: ()-> @listening = false

  launchListener: ()->
    return @listenerFiber if @listenerFiber?
    @listenerFiber = (Fiber blpopProcess)
    @listenerFiber.run(@)

  ###
  #   blpop: blocking pop
  #     pop a message from a channel (a list in redis)
  #     pass the message to all registered handlers for processing
  #     recursively call itself to consume the next message
  #     block until a message is available if the list is empty
  #     
  #     to avoid blocking the main loop, only call this method from withn a fiber
  ###
  blpopForever: () => # Blocks, run this inside of a separate Fiber so main loop won't block
    @redisClient ||= (RedisMessageCapsule.materialize_redis_client @redisURL, @dbNumber)
    unless @redisClient?
      console.log "Could not connect to redis #{listener.redisURL} [#{listener.dbNumber}]"  
      return
    @redisClient.blpop @channelName, 0, (err, channel_element) =>
      err = message = null
      try 
        channel = channel_element[0]
        element = channel_element[1]
        payload = (JSON.parse element) if element?
      catch ex
        err = ex
      finally
        payload ||= {}
        message = payload.data
        for handler in @handlers
          do(handler) =>
            try
              (handler err, message)
            catch handlerEx
              console.log "handler Exception:"
              console.log handlerEx
        @blpopForever()

module.exports = Listener