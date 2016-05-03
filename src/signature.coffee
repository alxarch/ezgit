g = require "nodegit"
trim = (value) -> if typeof value is "string" then value.replace /(^[<\s]+|[\s>]+$)/g, "" else value

createSignature = g.Signature.create
g.Signature.create = (args...) ->
	switch args.length
		when 4
			[name, email, time, offset] = args
		when 3
			[name, email, date] = args
			{time, offset} = g.Time.parse date
		when 2
			[signature, date] = args
			{time, offset} = g.Time.parse date
			if typeof signature is "string"
				{name, email} = g.Signature.parse signature
			else if signature instanceof g.Signature
				name = signature.name()
				email = signature.email()
			else if typeof signature is "object"
				{name, email} = signature
		when 1
			[signature] = args
			if signature instanceof g.Signature
				return signature
			else if typeof signature is "string"
				{name, email} = g.Signature.parse signature
				{time, offset} = g.Time.parse null
			else if typeof signature is "object"
				{name, email, date} = signature
				{time, offset} = g.Time.parse date
	time = parseInt time
	offset = parseInt offset
	name = trim name
	email = trim email
	unless name and time and offset
		return Promise.resolve null
	createSignature name, email, time, offset

g.Signature.parse = (signature) ->
	m = "#{signature}".match /^([^<]+)(?:<([^>]+)>)?$/
	unless m?
		throw new TypeError "Cannot parse signature"
	[name, email] = m[1..]
	{name, email}

g.Signature.fromString = (signature, date) ->
	{name, email} = @parse signature
	{time, offset} = g.Time.parse date
	email = trim email
	name = trim name
	@create name, email, time, offset

g.Signature::getDate = ->
	d = new Date()
	d.setTime @when().time() * 1000
	d

g.Signature::toJSON = ->
	name: @name()
	email: @email()
	date: @getDate()

module.exports = g.Signature
