Listener = require './listener'

class Channel
  constructor: (@channelName, @redisClient, @redisURL, @dbNumber) ->
    @listener = null

  send: (message, callback=null)->
    try
      payload = 'data': message
      payloadJSON = (JSON.stringify payload)
      throw "Could not serialize to json: #{message}" unless payloadJSON?
      @redisClient.rpush @channelName, payloadJSON, (err, count)->
        callback(err, count) if callback?
    catch ex
      (callback ex) if callback?
  emit: (message, callback=null)-> @send(message, callback=null)
  message: (message, callback=null)-> @send(message, callback=null)

  register: (handler) ->
    @listener ||= new Listener @channelName, @redisURL, @dbNumber
    @listener.register(handler)
    @
  on: (handler) -> (@register handler)

  uneregister:   ()->  # +++
  stopListening: ()->  # +++

module.exports = Channel