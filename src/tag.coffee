g = require "nodegit"
g.Tag::toJSON = ->
	id: "#{@id()}"
	name: "#{@name()}"
	target: "#{@targetId()}"
	message: "#{@message()}"
	tagger: "#{@tagger()?.toJSON()}"
	type: "#{@targetType()}"
module.exports = g.Tag
