g = require "nodegit"
{INIT_FLAG, INIT_MODE} = g.Repository

g.RepositoryInitOptions.DEFAULTS = DEFAULTS = Object.freeze
	bare: yes
	dotgit: yes
	head: "master"
	mkdir: yes
	mkpath: no
	origin: null
	reinit: yes
	relative_gitlink: no
	template: null
	workdir: null

g.RepositoryInitOptions.toJSON = ->
	bare: @flags & INIT_FLAG.BARE
	dotgit: not @flags & INIT_FLAG.NO_DOTGIT_DIR
	flags: @flags
	head: @initialHead
	mkdir: @flags & INIT_FLAG.MKDIR
	mkpath: @flags & INIT_FLAG.MKPATH
	origin: @originUrl
	reinit: not @flags & INIT_FLAG.NO_REINIT
	relative_gitlink: @flags & INIT_FLAG.RELATIVE_GITLINK
	template: @templatePath
	workdir: @workdirPath
	mode: switch @mode
		when MODE_UMASK then "umask"
		when MODE_GROUP then "group"
		when MODE_ALL then "all"
		else mode?.toString(8)

g.RepositoryInitOptions.fromObject = (options) ->
	if options instanceof g.RepositoryInitOptions
		return options
	options = Object.assign {}, g.Repository.INIT_DEFAULTS, options
	result = new g.RepositoryInitOptions()
	result.flags = 0
	unless options.reinit
		result.flags |= INIT_FLAG.NO_REINIT
	unless options.dotgit
		result.flags |= INIT_FLAG.NO_DOTGIT_DIR
	if options.description
		result.description = options.description
	result.initialHead = if options.head then "#{options.head}" else "master"
	if options.origin
		result.originUrl = "#{options.origin}"
	if options.workdir
		result.workdirPath = "#{options.workdir}"
	if options.relative_gitlink
		result.flags |= INIT_FLAG.RELATIVE_GITLINK
	if options.bare
		result.flags |= INIT_FLAG.BARE
	if options.template
		result.flags |= INIT_FLAG.EXTERNAL_TEMPLATE
		result.templatePath = options.template
	if options.mkpath or options.mkdir
		result.flags |= INIT_FLAG.MKDIR
	if options.mkpath
		result.flags |= INIT_FLAG.MKPATH

	result.mode = 0
	switch typeof options.mode
		when "string"
			switch options.mode
				when "umask"
					result.mode = INIT_MODE.INIT_SHARED_UMASK
				when "group"
					result.mode = INIT_MODE.INIT_SHARED_GROUP
				when "all"
					result.mode = INIT_MODE.INIT_SHARED_ALL
				else
					result.mode = parseInt options.mode, 8
		when "number"
			result.mode = options.mode | 0
		else
			result.mode = 0
	result


module.exports = g.RepositoryInitOptions
