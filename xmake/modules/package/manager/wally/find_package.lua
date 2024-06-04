--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      Chi-EEE
-- @file        find_package.lua
--

import("core.base.json")
import("core.base.semver")
import("lib.detect.find_tool")

function main(name, opt)
	opt = opt or {}
	local configs = opt.configs or {}
	local wally = find_tool("wally")
	if not wally then
		raise("wally not found!")
	end

	if not name:find("/") then
		raise("package name(%s) not found!", name)
	end

	local require_version = opt.require_version
	local split = name:split("/", { plain = true })
	local scope = split[1]
	local name = split[2]

	import("net.http")
	local version = ""

	if require_version == "latest" then
		local temp = os.tmpfile()
		http.download(configs.registry .. "/v1/package-metadata/" .. scope .. "/" .. name, temp, { timeout = 10 })
		local data = json.decode(io.readfile(temp))
		local latest_package = data.versions[1]
		version = latest_package.package.version
	else
		version = require_version
	end

	if not semver.is_valid(version) then
		raise("Invalid version: %s", version)
	end

	local package_type = configs.type
	local outdir = os.projectdir()
	if package_type == "default" then
		outdir = path.join(outdir, "Packages")
	elseif package_type == "server" then
		outdir = path.join(outdir, "ServerPackages")
	elseif package_type == "dev" then
		outdir = path.join(outdir, "DevPackages")
	end
	local packagedir = path.join(outdir, "_Index", scope .. "_" .. name .. "@" .. version, name)

	local result = nil
	if os.exists(packagedir) then
		print("Found: " .. packagedir)
		result = { includedirs = {}, linkdirs = {}, links = {} }
		table.insert(result.includedirs, packagedir)
		table.insert(result.linkdirs, packagedir)
		table.insert(result.links, packagedir)
	end
	return result
end
