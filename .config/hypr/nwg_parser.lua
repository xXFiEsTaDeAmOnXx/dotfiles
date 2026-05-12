-- nwg_parser.lua
-- Reads nwg-displays .conf files dynamically and converts them on-the-fly to hl.* commands

local config_dir = os.getenv("HOME") .. "/.config/hypr/"

local function parse_nwg_file(filename)
	local filepath = config_dir .. filename
	local file = io.open(filepath, "r")

	if not file then
		print("Could not open file: " .. filepath)
		return
	end

	-- 'raw_line' is used to prevent the Lua 5.4 "constant value" assignment error
	for raw_line in file:lines() do
		-- Create a new local variable 'line' with the whitespace removed
		local line = raw_line:match("^%s*(.-)%s*$")

		-- Ignore empty lines and comments
		if line ~= "" and not line:match("^#") then
			------------------------------------------------
			-- PARSE MONITORS
			------------------------------------------------
			if line:match("^monitor=") then
				local val = line:sub(9) -- Strip "monitor="
				local parts = {}
				for p in val:gmatch("[^,]+") do
					table.insert(parts, p)
				end

				if parts[2] == "transform" then
					-- Output: hl.monitor({ output = "DP-1", transform = 3 })
					hl.monitor({
						output = parts[1],
						transform = tonumber(parts[3]),
					})
				elseif #parts >= 4 then
					-- Output: hl.monitor({ output = "DP-1", mode = "1920x1080@100.0", position = "0x0", scale = "1.0" })
					hl.monitor({
						output = parts[1],
						mode = parts[2],
						position = parts[3],
						scale = parts[4], -- kept as string ("1.0") to match your example
					})
				end
			end

			------------------------------------------------
			-- PARSE WORKSPACES
			------------------------------------------------
			if line:match("^workspace=") then
				local val = line:sub(11) -- Strip "workspace="
				local parts = {}
				for p in val:gmatch("[^,]+") do
					table.insert(parts, p)
				end

				-- The first part is always the workspace ID or name (Output: workspace = 1)
				local ws_id = tonumber(parts[1]) or parts[1]
				local rule = { workspace = ws_id }

				-- Parse remaining properties (e.g., monitor:DP-1, default:true)
				for i = 2, #parts do
					local key, value = parts[i]:match("([^:]+):(.*)")
					if key and value then
						-- Type conversion for Lua
						if value == "true" then
							value = true
						elseif value == "false" then
							value = false
						elseif tonumber(value) then
							-- Ensure strings like "DP-1" stay strings, but numbers convert
							value = tonumber(value)
						end

						rule[key] = value
					end
				end

				-- Output: hl.workspace_rule({ workspace = 1, monitor = "DP-1", default = true })
				hl.workspace_rule(rule)
			end
		end
	end

	file:close()
end

-- Load the files
parse_nwg_file("monitors.conf")
parse_nwg_file("workspaces.conf")
