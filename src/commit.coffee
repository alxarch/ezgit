g = require "nodegit"

g.Commit::toJSON = ->
	id: "#{@id()}"
	type: "commit"
	tree: "#{@treeId()}"
	parents: @parents().map (p) -> "#{p}"
	date: @date()
	committer: @committer().toJSON()
	author: @author().toJSON()
	message: "#{@message()}"

module.exports = g.Commit
