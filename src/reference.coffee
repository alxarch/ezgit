g = require "nodegit"

g.Reference.find = (repo, refname="HEAD") ->
	ref =
		if @isValidName refname
		then @lookup(repo, refname).catch -> null
		else @dwim repo, refname
	ref.then (r) =>
		if r?.isSymbolic()
			refname = r.symbolicTarget()
			@find repo, refname
			.catch -> r
		else
			ref

{TYPE} = g.Reference
lookup = new Map
for key, value of TYPE
	lookup.set value, key.toLowerCase()

g.Reference.type2string ?= (type) ->
	if lookup.has type
	then lookup.get type
	else lookup.get 0
g.Reference::toJSON = ->
	name: @toString()
	short: @shothand()
	symbolic: @isSymbolic()
	type: g.Reference.type2string @type()
	target: if @isSymbolic() then @symbolicTarget() else @target()?.toString()

module.exports = g.Reference
