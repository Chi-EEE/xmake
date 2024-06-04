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
-- @file        search_package.lua
--

import("core.base.json")
import("core.base.option")
import("lib.detect.find_tool")
import("package.manager.wally.configurations")

function main(name)
	import("net.http")
	local temp = os.tmpfile()
	http.download(configurations.default_registry() .. "/v1/package-search?query=" .. name, temp, { timeout = 10 })
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
