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

function _download_zip(registry, scope, name, version, package_alias, outdir, packagedir, headers)
	import("utils.archive")
	local temp = os.tmpfile() .. ".zip"
	local zip_url = registry .. "/v1/package-contents/" .. scope .. "/" .. name .. "/" .. version

	try { function() return http.download(zip_url, temp, { headers = headers, timeout = 2 }) end}

	os.mkdir(outdir)

	local ok = try { function() archive.extract(temp, packagedir); return true end }
	if not ok then
		raise("Failed to extract package %s", name)
		return
	end

	io.writefile(path.join(outdir, package_alias .. ".lua"), string.format([[return require(script.Parent._Index["%s_%s@%s"]["%s"])]], scope, name, version, name))
end

function _install_dependencies(registry, dependencies, outdir, packagedir, headers)
	for dep_package_alias, dep in pairs(dependencies) do
		local dep_scope, dep_name, dep_range = string.match(dep, [[(%w+)/(%w+)@(.+)]])
		dep_range = dep_range:replace(",", "")
		local temp = os.tmpfile() .. ".json"
		local metadata_url = registry .. "/v1/package-metadata/" .. dep_scope .. "/" .. dep_name

		try { function() return http.download(metadata_url, temp, { headers = headers, timeout = 2 }) end}

		local data = try { function() return json.decode(io.readfile(temp)) end }
		if not data then
			raise("Failed to fetch dependency package %s", dep_package_alias)
			return
		end
		local packages = {}
		for _, dep_package in ipairs(data.versions) do
			if semver.satisfies(dep_package.package.version, dep_range) then
				table.insert(packages, dep_package)
			end
		end
		table.sort(packages, function(a, b)
			local a_version = semver.new(a.package.version)
			local b_version = semver.new(b.package.version)
			return a_version:gt(b_version)
		end)
		local latest_package = packages[1]
		local dep_dependencies = latest_package.dependencies
		local dep_version = latest_package.package.version
		local dep_packagedir = path.join(outdir, "_Index", dep_scope .. "_" .. dep_name .. "@" .. dep_version, dep_name)

		_install_dependencies(registry, dep_dependencies, outdir, dep_packagedir, headers)

		_download_zip(registry, dep_scope, dep_name, dep_version, dep_package_alias, outdir, dep_packagedir, headers)

		io.writefile(path.join(path.directory(packagedir), dep_package_alias .. ".lua"), string.format([[return require(script.Parent.Parent._Index["%s_%s@%s"]["%s"])]], dep_scope, dep_name, dep_version, dep_name))
	end
end

function _download_package_metadata(registry, scope, name, version, outdir, headers)
	import("net.http")
	local temp = os.tmpfile() .. ".json"
	local metadata_url = registry .. "/v1/package-metadata/" .. scope .. "/" .. name
	try { function() return http.download(metadata_url, temp, { headers = headers, timeout = 2 }) end}
	
	local data = try { function() return json.decode(io.readfile(temp)) end }
	if not data then
		raise("Failed to fetch package %s", name)
		return
	end

	local latest_package = data.versions[1]
	local dependencies = latest_package.dependencies
	local packagedir = path.join(outdir, "_Index", scope .. "_" .. name .. "@" .. version, name)

	_install_dependencies(registry, dependencies, outdir, packagedir, headers)

	if version == "latest" then
		version = latest_package.package.version
	else
		version = string.trim(version)
	end

	return version
end

function main(name, opt)
	opt = opt or {}
	local configs = opt.configs or {}
	local wally = find_tool("wally")
	if not wally then
		raise("wally not found!")
	end

	local package_alias = configs.package_alias
	if package_alias == "" then
		raise("package_alias not found!")
	end

	if not name:find("/") then
		raise("package name(%s) not found!", name)
	end
	
	local wally_version, _ = os.iorunv(wally.program, { "--version" })
	wally_version = string.match(wally_version, "wally (.*)")

	local headers = {
		"Wally-Version: " .. wally_version,
	}

	local registry = configs.registry

	local split = name:split("/", { plain = true })
	local scope = split[1]
	local name = split[2]
	local version = opt.require_version
	local package_type = configs.type

	local outdir = os.projectdir()
	if package_type == "default" then
		outdir = path.join(outdir, "Packages")
	elseif package_type == "server" then
		outdir = path.join(outdir, "ServerPackages")
	elseif package_type == "dev" then
		outdir = path.join(outdir, "DevPackages")
	end

	version = _download_package_metadata(registry, scope, name, version, outdir, headers)

	if not semver.is_valid(version) then
		raise("Invalid version: %s", version)
	end

	local packagedir = path.join(outdir, "_Index", scope .. "_" .. name .. "@" .. version, name)
	_download_zip(registry, scope, name, version, package_alias, outdir, packagedir, headers)
end
