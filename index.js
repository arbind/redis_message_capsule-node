nodeMessageCapsule = require('./lib/redis-message-capsule/index.js')

nodeMessageCapsule.listen('cat', {}, function(message){console.log('@', message, '!')}  ) 

module.exports = nodeMessageCapsule