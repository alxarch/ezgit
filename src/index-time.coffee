g = require "nodegit"
g.IndexTime::toJSON = -> [@seconds, @nanoseconds]
module.exports = g.IndexTime
