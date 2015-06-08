path = require "path"
g = require "nodegit"
assign = require "object-assign"
{Transform, PassThrough} = require "stream"
zlib = require "zlib"
fs = require "fs"
Promise = g.Promise = require "bluebird"

Promise.stream = (str) ->
	new Promise (resolve, reject) ->
		str.on "error", reject
		str.on "end", resolve

{INIT_FLAG, INIT_MODE} = g.Repository
g.RepositoryInitOptions.fromObject = (options) ->
	opt = assign {}, g.Repository.INIT_DEFAULTS, options
	result = new g.RepositoryInitOptions()
	result.flags = 0
	unless opt.reinit
		result.flags |= INIT_FLAG.NO_REINIT
	unless opt.dotgit
		result.flags |= INIT_FLAG.NO_DOTGIT_DIR
	if opt.description
		result.description = opt.description
	result.initialHead = if opt.head then "#{opt.head}" else "refs/heads/master"
	if opt.origin
		result.originUrl = "#{opt.origin}"
	if opt.workdir
		result.workdirPath = "#{opt.workdir}"
	if opt.relative_gitlink
		result.flags |= INIT_FLAG.RELATIVE_GITLINK
	if opt.bare
		result.flags |= INIT_FLAG.BARE
	if opt.template
		result.flags |= INIT_FLAG.EXTERNAL_TEMPLATE
		result.templatePath = opt.template
	if opt.mkdirp or opt.mkdir
		result.flags |= INIT_FLAG.MKDIR
	if opt.mkdirp
		result.flags |= INIT_FLAG.MKPATH
	result.mode = 0
	switch opt.shared
		# nodegit.Repository.INIT_MODE values are wrong
		when "umask"
			result.mode = 0
		when "group"
			result.mode = 0x2775
		when "all"
			result.mode = 0x2777
		else
			result.mode |= "#{result.mode}" | 0
	result

class GitObjectReadStream extends Transform

	_transform: (chunk, encoding, callback) ->
		unless @header
			for c, i in chunk when c is 0
				break
			@header = "#{chunk.slice 0, i}"
			[type, size] = @header.split /\s+/
			@emit "ready", type, size
			chunk = chunk.slice i + 1
		@push chunk
		callback()

g.Commit::_oidMethod = "id"
g.Blob::_oidMethod = "id"
g.Note::_oidMethod = "id"
g.OdbObject::_oidMethod = "id"
g.Object::_oidMethod = "id"
g.Tag::_oidMethod = "id"
g.Tree::_oidMethod = "id"
g.TreeEntry::_oidProperty = "oid"
g.Reference::_oidMethod = "target"
g.IndexEntry::_oidProperty = "id"
g.RebaseOperation::_oidProperty = "id"
g.DiffFile::_oidProperty = "id"

ZEROID = g.Oid.ZERO = g.Oid.fromString (new Array(40)).join "0"

g.Oid.fromAnything = (item) ->
	if item instanceof g.Oid
		item
	else if item._oidMethod
		item[item._oidMethod]()
	else if item._oidProperty
		item[item._oidProperty]
	else if item?
		g.Oid.fromString "#{item}"
	else
		g.Oid.ZERO

g.Repository.INIT_DEFAULTS = Object.freeze
	bare: yes
	reinit: yes
	template: null
	mkdir: yes
	mkdirp: no
	dotgit: yes
	head: null
	workdir: null
	origin: null
	relative_gitlink: no

g.Repository.OPEN_DEFAULTS = Object.freeze
	bare: no
	search: yes
	crossfs: no
g.Repository._open = g.Repository.open
g.Repository.open = (path, options={}) ->
	ceilings = ([].concat (options.ceilings or "")).join path.delimiter
	options = assign {}, g.Repository.OPEN_DEFAULTS, options
	flags = 0
	unless options.search
		flags |= @OPEN_FLAG.OPEN_NO_SEARCH
	if options.bare
		flags |= @OPEN_FLAG.OPEN_BARE
	if options.crossfs
		flags |= @OPEN_FLAG.OPEN_CROSS_FS

	@openExt path, flags, ceilings

g.Repository._init = g.Repository.init
g.Repository.init = (path, options={}) ->
	Promise.resolve @initExt path, g.RepositoryInitOptions.fromObject options

assign g.Repository::,
	findRef: (options="HEAD") ->
		p =
			if "string" is typeof options and g.Reference.isValidName options
				@findRef options
			else if options.ref and g.Reference.isValidName options.ref
				@findRef options.ref
			else if options.tag
				@findRef "refs/tags/#{options.tag}"
			else if options.branch
				@findRef "refs/heads/#{options.branch}"
			else
				@head()
		p.then (ref) =>
			if not ref.isSymbolic()
				ref
			else if options.symbolic
				ref
			else
				@findRef ref.symbolicTarget()

	findByPath: (path, options={}) ->
		@findRef options
		.then (ref) => g.Commit.lookup @, ref.target()
		.then (commit) -> commit.getEntry path
		.then (entry) => g.Object.lookup @_repo, g.Oid.fromString(entry.sha()), g.Object.TYPE.ANY

	createRef: (name, target, options={}) ->
		oid = g.Oid.fromAnything target
		force = if options.force then 1 else 0
		sig = options.signature or Signature.default @
		Promise.resolve g.Reference.create @, name, oid, force, sig, message or ""

	createReadStream: (item) ->
		oid = g.Oid.fromAnything item
		sha = "#{oid}"
		Promise.resolve path.join @path(), "objects", sha[0..1], sha[2..]
		.then (loose) ->
			stream = new GitObjectReadStream()
			zip = zlib.createUnzip()
			read = fs.createReadStream loose
			done = new Promise (resolve) ->
				stream.on "ready", (type, size) -> resolve {type, size, stream}
			read.pipe(zip).pipe(stream)
			Promise.map [read, zip, stream], Promise.stream
			.then -> done
		.catch (err) =>
			g.Blob.lookup @, oid
			.then (blob) ->
				type: "blob"
				size: blob.rawsize()
				stream: blob.toReadableStream()

assign g.Blob::,
	toReadableStream: ->
		stream = new PassThrough()
		stream.end @content()
		stream


module.exports = g
