g = require "nodegit"

g.OdbObject::toJSON = ->
	id: "#{@id()}"
	type: g.Object.type2string(@type())
	size: @size()

module.exports = g.OdbObject
