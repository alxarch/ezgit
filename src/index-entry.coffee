g = require "nodegit"
IndexTime = require "./index-time"


# Fix auto enum conversion
g.Enums.EXTENDED_FLAGS.EXTENDED_FLAGS = g.Enums.IDXENTRY_EXTENDED_FLAG.S

g.IndexEntry.FLAGS = g.Enums.IDXENTRY_FLAG
g.IndexEntry.EXTENDED_FLAGS = g.Enums.IDXENTRY_EXTENDED_FLAG

g.IndexEntry::toJSON = ->
	path: @path
	size: @fileSize
	flags: @flags
	id: @id.toString()
	dev: @dev
	gid: @gid
	uid: @uid
	ino: @ino
	mode: @mode.toString(8)
	mtime: IndexTime::toJSON.apply @mtime
	ctime: IndexTime::toJSON.apply @ctime

module.exports = g.IndexEntry
