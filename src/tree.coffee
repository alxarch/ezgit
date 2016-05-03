g = require "nodegit"
TreeEntry = require "./tree-entry"

g.Tree::toJSON = ->
	id: "#{@id()}"
	type: "tree"
	path: if typeof @path is "string" then @path else null
	entries: @entries().map (entry) -> TreeEntry::toJSON.apply entry

module.exports = g.Tree
