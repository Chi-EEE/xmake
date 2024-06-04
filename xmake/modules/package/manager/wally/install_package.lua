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
-- @file        install_package.lua
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

	local package_name = configs.package_name
	if package_name == "" then
		raise("package_name not found!")
	end

	if not name:find("/") then
		raise("package name(%s) not found!", name)
	end

	local split = name:split("/", { plain = true })
	local scope = split[1]
	local name = split[2]

	import("net.http")
	local version = opt.require_version
	local temp = os.tmpfile()
	http.download(configs.registry .. "/v1/package-metadata/" .. scope .. "/" .. name, temp, { timeout = 10 })
	local data = json.decode(io.readfile(temp))
	local latest_package = data.versions[1]
	local dependencies = latest_package.dependencies
	print(dependencies)
	if version == "latest" then
		version = latest_package.package.version
	else
		version = string.trim(version)
	end

	if not semver.is_valid(version) then
		raise("Invalid version: %s", version)
	end

	import("utils.archive")
	local temp = os.tmpfile() .. ".zip"
	local zip_url = configs.registry .. "/v1/package-contents/" .. scope .. "/" .. name .. "/" .. version
	local wally_version, _ = os.iorunv(wally.program, { "--version" })
	wally_version = string.match(wally_version, "wally (.*)")

	local headers = {
		"Wally-Version: " .. wally_version,
	}

	try({
		function()
			return http.download(zip_url, temp, { headers = headers, timeout = 10 })
		end,
	})

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

	os.mkdir(outdir)

	local ok = try({
		function()
			archive.extract(temp, packagedir)
			return true
		end,
	})
	if not ok then
		return
	end
	io.writefile(path.join(outdir, package_name .. ".lua"), [[
return require(script.Parent._Index["]] .. scope .. [[_]] .. name .. [[@]] .. version .. [["]["]] .. name .. [["])
]])
end
