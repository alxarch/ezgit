g = require "nodegit"
path = require "path"
co = require "co"

g.Repository.OPEN_DEFAULTS = OPEN_DEFAULTS = Object.freeze
	bare: no
	search: yes
	crossfs: no

openRepository = g.Repository.open

joinPaths = (paths) ->
	if typeof paths is "string"
		paths = paths.split path.delimiter
	else if not Array.isArray paths
		paths = [paths]
	paths.join path.delimiter

{OPEN_FLAG} = g.Repository
g.Repository.open = (path, options={}) ->
	ceilings = joinPaths options.ceilings
	options = Object.assign {}, OPEN_DEFAULTS, options
	flags = 0
	unless options.search
		flags |= OPEN_FLAG.OPEN_NO_SEARCH
	if options.bare
		flags |= OPEN_FLAG.OPEN_BARE
	if options.crossfs
		flags |= OPEN_FLAG.OPEN_CROSS_FS

	g.Repository.openExt path, flags, ceilings

initRepository = g.Repository.init
g.Repository.init = (path, options={}) ->
	if typeof options in ["boolean", "number"]
		options = bare: options
	unless options instanceof g.RepositoryInitOptions
		options = g.RepositoryInitOptions.fromObject options
	return g.Repository.initExt path, options

Object.assign g.Repository::,
	headRefName: ->
		if @isEmpty()
			@head().catch (err) -> err.message.replace /.*'([^']+)'.*/, '$1'
		else
			@head().then (head) ->
				name = head.name()
				head.free()
				name

	commit: (options) ->
		co ->
			{ref, tree} = options
			if ref instanceof g.Reference
				ref = ref.name()
			else if ref
				ref = "#{ref}"
			else
				ref = null

			unless tree instanceof g.Tree
				tree = yield g.Tree.lookup @, g.Oid.cast tree

			author = g.Signature.create options.author
			committer = g.Signature.create options.committer

			parents = (p for p in (options.parents or []) when p)
			parents = yield parents.map (parent) =>
				if parent instanceof g.Commit
					Promise.resolve parent
				else
					@getCommit g.Oid.cast parent

			message = options.message or "Commit #{new Date()}"

			author ?= @defaultSignature()
			committer ?= @defaultSignature()
			parent_count = parents.length
			oid = yield g.Commit.create @, ref, author, committer, null, message, tree, parent_count, parents
			commit = yield g.Commit.lookup @, oid

	find: (where) -> g.Revparse.single @, where

	createRef: (name, target, options={}) ->
		oid = g.Oid.cast target
		force = if options.force then 1 else 0
		sig = options.signature or Signature.default @
		message = options.message or ""
		g.Reference.create @, name, oid, force, sig, message
