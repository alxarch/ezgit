g = require "nodegit"

g.Blob::toJSON = ->
	id: "#{@id()}"
	size: "#{@rawsize()}"
	binary: if @isBinary() then yes else no
	filemode: "#{@filemode().toString 8}"

module.exports = g.Blob
