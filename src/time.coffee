g = require "nodegit"
TIME = Symbol "time"
OFFSET = Symbol "offset"
g.Time.now = -> g.Time.fromDate new Date()
g.Time::toJSON = ->
	d = new Date Math.floor @time() * 1000
	d.toJSON()

class Time extends g.Time
	constructor: (time, offset) ->
		@[TIME] = time
		@[OFFSET] = offset
	time: -> @[TIME]
	offset: -> @[OFFSET]

g.Time.fromDate = (d) ->
	time = d.getTime() / 1000 | 0
	offset = d.getTimezoneOffset()
	new Time time, offset

module.exports = g.Time
