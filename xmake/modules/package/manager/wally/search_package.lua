import("core.base.json")
import("core.base.option")
import("lib.detect.find_tool")

function main(name, opt)
	opt = opt or {}
	local configs = opt.configs or {}
	local wally = find_tool("wally")
	if not wally then
		raise("wally not found!")
	end
	import("net.http")
	local temp = os.tmpfile()
	http.download(configs.registry .. "/v1/package-search?query=" .. name, temp, { timeout = 10 })
	local data = json.decode(io.readfile(temp))
	local results = {}
	for _, package in ipairs(data) do
		local scope = package.scope
		local name = package.name
		local version = package.versions[1]
		local description = package.description
		table.insert(
			results,
			{ name = "wally::" .. scope .. "/" .. name, version = version, description = description }
		)
	end
	return results
end
