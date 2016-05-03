g = require "nodegit"

g.Object::toJSON = ->
	id: "#{@id()}"
	type: g.Object.type2string(@type())

module.exports = g.Object
