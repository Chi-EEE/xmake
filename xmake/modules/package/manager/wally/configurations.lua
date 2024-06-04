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
-- @file        configurations.lua
--

function wally_version()
	return "0.3.2"
end

function default_registry()
    return "https://api.wally.run"
end

function main()
	return {
		package_alias = { description = "The package alias.", default = "", type = "string" },
		root_dir = { description = "Set the root directory.", default = path.join(os.projectdir(), "Packages") },
		registry = { description = "Set the registry server.", default = default_registry() },
	}
end
