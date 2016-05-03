g = require "nodegit"
g.Revparse.toSpec = (value) ->
	switch typeof value
		when "string"
			value
		when "number"
			"HEAD@{#{value | 0}}"
		when "object"
			if not value
				"HEAD"
			else if value instanceof Date
				"HEAD@{#{value.toISOString()}}"
			else
				{id, rev, tag, ref, branch, date, path, offset, search, upstream, type} = value
				result = "#{id or rev or tag or ref or branch or 'HEAD'}"
				if upstream and "#{branch}" is result
					result = "#{branch}@{upstream}"

				if offset
					result = "#{result}@{#{offset | 0}}"

				if date
					result = "#{result}@{#{date}}"

				if path
					result = "#{result}:#{path.replace /^\/+/, ''}"
				else if search
					result= "#{result}:/#{search}"
				else if type
					result = "#{result}^{#{type}}"

				result

single = g.Revparse.single
g.Revparse.single = (repo, where) -> single repo, @toSpec where
module.exports = g.Revparse
