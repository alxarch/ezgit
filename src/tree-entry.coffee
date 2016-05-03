g = require "nodegit"

g.TreeEntry::toJSON = ->
	id: @oid()
	path: @path()
	type: if @isBlob() then "blob" else "tree"
	filename: @filename()
	attr: @attr().toString 8

module.exports = g.TreeEntry
