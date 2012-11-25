# environment (needed to select redis db)
global.node_env ||= process.env.NODE_ENV || 'development'

# module
module.exports = require './redis-message-capsule'
