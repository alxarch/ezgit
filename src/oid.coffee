g = require "nodegit"

TYPES = new Map()
TYPES.set g.AnnotatedCommit, (commit) -> commit.id()
TYPES.set g.Blob, (blob) -> blob.id()
TYPES.set g.Commit, (commit) -> commit.id()
TYPES.set g.DiffFile, (diff) -> diff.id()
TYPES.set g.IndexEntry, (entry) -> entry.id
TYPES.set g.Note, (node) -> node.id()
TYPES.set g.Object, (o) -> o.id()
TYPES.set g.OdbObject, (o) -> o.id()
TYPES.set g.Oid, (o) -> o
TYPES.set g.RebaseOperation, (op) -> op.id
TYPES.set g.Reference, (ref) -> ref.target()
TYPES.set g.Tag, (tag) -> tag.id()
TYPES.set g.Tree, (tree) -> tree.id()
TYPES.set g.TreeEntry, (entry) -> entry.oid

# Hold a special reference for deep comparison
ZEROID = g.Oid.ZERO = g.Oid.fromString "0"
NONZERO = g.Oid.fromString "1"

g.Oid.isZero = (oid) ->
	switch typeof oid
		when "string" then ZEROID.strcmp(oid) is 0
		when "object" then ZEROID.equal g.Oid.fromObject(oid) or NONZERO
		else false

g.Oid.fromObject = (obj) ->
	if obj instanceof g.Oid
		obj
	else if obj? and TYPES.has obj.constructor
		TYPES.get(obj.constructor)(obj)
	else
		null

fromString = g.Oid.fromString

g.Oid.fromString = (str) -> if ZEROID.strcmp(str) is 0 then ZEROID else fromString str
g.Oid.cast = (obj) ->
	switch typeof obj
		when "string" then g.Oid.fromString obj
		when "object" then g.Oid.fromObject obj
		else null

g.Oid::toJSON = -> @toString()

module.exports = g.Oid
