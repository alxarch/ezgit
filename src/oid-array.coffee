g = require "nodegit"
g.Oidarray::toJSON = -> ("#{id}" for id in @ids())
module.exports = g.Oidarray
