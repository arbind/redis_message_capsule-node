// Generated by CoffeeScript 1.4.0
(function() {
  var Capsule, Channel;

  Channel = require('./channel');

  /*
  # Capsule
  #    binds to a redis database (to a selected dbNumber)
  */


  Capsule = (function() {

    function Capsule(redisURL, dbNumber) {
      this.redisURL = redisURL;
      this.dbNumber = dbNumber;
      this.channels = {};
      this.redisClient = RedisMessageCapsule.materialize_redis_client(this.redisURL, this.dbNumber);
      if (this.redisClient == null) {
        console.log("!!!\n!!! Can not connect to redis server at " + this.redisURL + "\n!!!");
      }
    }

    Capsule.prototype.materializeChannel = function(channelName) {
      var _base;
      return (_base = this.channels)[channelName] || (_base[channelName] = new Channel(channelName, this.redisClient, this.redisURL, this.dbNumber));
    };

    Capsule.prototype.channel = function(channelName) {
      return this.materializeChannel(channelName);
    };

    Capsule.prototype.makeChannel = function(channelName) {
      return this.materializeChannel(channelName);
    };

    Capsule.prototype.createChannel = function(channelName) {
      return this.smaterializeChannel(channelName);
    };

    return Capsule;

  })();

  module.exports = Capsule;

}).call(this);