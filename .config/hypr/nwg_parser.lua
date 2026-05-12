-- nwg_parser.lua
-- Parses legacy Hyprlang .conf files and converts them to hl.* Lua calls.
-- Supports: monitor (all variants + extra args), workspace rules.
-- Handles merged lines (nwg-displays bug: missing newline between entries).
-- Handles transform-only lines by merging them into the preceding monitor rule.

local config_dir = os.getenv("HOME") .. "/.config/hypr/"

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

-- Trim leading/trailing whitespace
local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

-- Split a string by a single separator character
local function split(s, sep)
	local parts = {}
	for p in s:gmatch("([^" .. sep .. "]+)") do
		table.insert(parts, trim(p))
	end
	return parts
end

-- Convert a string value to the most appropriate Lua type
local function coerce(value)
	if value == "true" then
		return true
	elseif value == "false" then
		return false
	elseif tonumber(value) then
		return tonumber(value)
	else
		return value
	end
end

--------------------------------------------------------------------------------
-- MONITOR PARSER
-- Old syntax: monitor = NAME, RESOLUTION, POSITION, SCALE[, extra, ...]
-- Extra args consumed in pairs:
--   transform, N | mirror, NAME | bitdepth, N | cm, VALUE
--   sdrbrightness, N | sdrsaturation, N | sdr_eotf, VALUE | vrr, N
--   icc, PATH | supports_wide_color, N | supports_hdr, N
--   sdr_min_luminance, N | sdr_max_luminance, N
--   min_luminance, N | max_luminance, N | max_avg_luminance, N
-- Special variants:
--   monitor = NAME, disable
--   monitor = NAME, addreserved, TOP, BOTTOM, LEFT, RIGHT
--   monitor = NAME, transform, N   (nwg-displays rotation-only line)
--------------------------------------------------------------------------------

local MONITOR_EXTRA_KEYS = {
	transform = true,
	mirror = true,
	bitdepth = true,
	cm = true,
	sdrbrightness = true,
	sdrsaturation = true,
	sdr_eotf = true,
	vrr = true,
	icc = true,
	supports_wide_color = true,
	supports_hdr = true,
	sdr_min_luminance = true,
	sdr_max_luminance = true,
	min_luminance = true,
	max_luminance = true,
	max_avg_luminance = true,
}

-- Pending monitor rules keyed by output name.
-- nwg-displays emits a separate "monitor=NAME,transform,N" line after the main
-- monitor line, so we stage each rule here and merge transform into it before
-- flushing via hl.monitor().
local pending_monitors = {}
local pending_order = {}

local function flush_monitor(output)
	if pending_monitors[output] then
		hl.monitor(pending_monitors[output])
		pending_monitors[output] = nil
		for i, v in ipairs(pending_order) do
			if v == output then
				table.remove(pending_order, i)
				break
			end
		end
	end
end

local function flush_all_monitors()
	for _, output in ipairs(pending_order) do
		if pending_monitors[output] then
			hl.monitor(pending_monitors[output])
			pending_monitors[output] = nil
		end
	end
	pending_order = {}
end

local function stage_monitor(rule)
	local output = rule.output
	if not pending_monitors[output] then
		table.insert(pending_order, output)
	end
	pending_monitors[output] = rule
end

local function parse_monitor(val)
	local parts = split(val, ",")
	if #parts < 2 then
		return
	end

	local output = parts[1]
	local second = parts[2]

	-- Special: monitor = NAME, disable
	if second == "disable" then
		flush_monitor(output)
		hl.monitor({ output = output, disabled = true })
		return
	end

	-- Special: monitor = NAME, addreserved, TOP, BOTTOM, LEFT, RIGHT
	if second == "addreserved" then
		flush_monitor(output)
		hl.monitor({
			output = output,
			reserved_area = {
				top = tonumber(parts[3]) or 0,
				bottom = tonumber(parts[4]) or 0,
				left = tonumber(parts[5]) or 0,
				right = tonumber(parts[6]) or 0,
			},
		})
		return
	end

	-- Special: transform-only line emitted by nwg-displays
	-- e.g. monitor=DP-1,transform,3
	if second == "transform" and #parts == 3 then
		if pending_monitors[output] then
			-- Merge into the already-staged rule for this output
			pending_monitors[output].transform = tonumber(parts[3])
		else
			-- No prior rule — stage a minimal one
			stage_monitor({ output = output, transform = tonumber(parts[3]) })
		end
		return
	end

	-- Standard: monitor = NAME, MODE, POSITION, SCALE[, extra pairs...]
	-- Flush any previously staged rule for this output first.
	flush_monitor(output)

	local rule = {
		output = output,
		mode = second,
		position = parts[3],
		scale = coerce(parts[4] or "auto"),
	}

	-- Parse optional extra key/value pairs (e.g. transform, 1, mirror, DP-2)
	local i = 5
	while i <= #parts do
		local key = parts[i]
		if MONITOR_EXTRA_KEYS[key] and parts[i + 1] then
			rule[key] = coerce(parts[i + 1])
			i = i + 2
		else
			i = i + 1
		end
	end

	-- Stage it — a transform-only line for the same output may follow
	stage_monitor(rule)
end

--------------------------------------------------------------------------------
-- WORKSPACE RULE PARSER
-- Old syntax: workspace = ID_OR_NAME[, key:value, ...]
-- Keys: monitor, default, gaps_in, gaps_out, border_size, no_border,
--       no_shadow, no_rounding, decorate, persistent, on_created_empty,
--       default_name, layout, animation
--------------------------------------------------------------------------------

local function parse_workspace(val)
	local parts = split(val, ",")
	if #parts < 1 then
		return
	end

	local ws_id = coerce(parts[1])
	local rule = { workspace = ws_id }

	for i = 2, #parts do
		local key, value = parts[i]:match("^([^:]+):(.*)")
		if key and value then
			rule[trim(key)] = coerce(trim(value))
		end
	end

	hl.workspace_rule(rule)
end

--------------------------------------------------------------------------------
-- LINE SPLITTER
-- nwg-displays sometimes omits the newline between the last monitor= entry
-- and the first workspace= entry, producing merged lines like:
--   "monitor=DP-3,2560x1440@74.97,1080x0,1.0workspace=1,monitor:DP-1,default:true"
-- This splits any raw line into clean keyword-prefixed segments.
--------------------------------------------------------------------------------

local KEYWORDS = { "monitor", "workspace" }

local function split_into_segments(line)
	local segments = {}
	local pos = 1

	while pos <= #line do
		-- Find the nearest keyword= at or after pos
		local best_start, best_len = nil, nil
		for _, kw in ipairs(KEYWORDS) do
			local found = line:find(kw .. "=", pos, true)
			if found and (not best_start or found < best_start) then
				best_start = found
				best_len = #kw + 1
			end
		end

		if not best_start then
			break
		end

		-- Find where this segment ends (start of next keyword= or EOS)
		local seg_end = #line
		for _, kw in ipairs(KEYWORDS) do
			local found = line:find(kw .. "=", best_start + best_len, true)
			if found and found - 1 < seg_end then
				seg_end = found - 1
			end
		end

		local segment = trim(line:sub(best_start, seg_end))
		if segment ~= "" then
			table.insert(segments, segment)
		end
		pos = seg_end + 1
	end

	return segments
end

--------------------------------------------------------------------------------
-- DISPATCH
--------------------------------------------------------------------------------

local function process_segment(segment)
	if segment:match("^monitor=") then
		parse_monitor(segment:sub(9)) -- strip "monitor="
	elseif segment:match("^workspace=") then
		-- Flush all pending monitors before emitting workspace rules,
		-- since Hyprland needs monitors to exist first.
		flush_all_monitors()
		parse_workspace(segment:sub(11)) -- strip "workspace="
	end
end

--------------------------------------------------------------------------------
-- FILE PARSER
--------------------------------------------------------------------------------

local function parse_nwg_file(filename)
	local filepath = config_dir .. filename
	local file = io.open(filepath, "r")
	if not file then
		print("Could not open file: " .. filepath)
		return
	end

	for raw_line in file:lines() do
		local line = trim(raw_line)
		if line ~= "" and not line:match("^#") then
			local segments = split_into_segments(line)
			for _, seg in ipairs(segments) do
				process_segment(seg)
			end
		end
	end

	file:close()

	-- Flush any monitors that had no following transform line
	flush_all_monitors()
end

--------------------------------------------------------------------------------
-- ENTRY POINT
--------------------------------------------------------------------------------

parse_nwg_file("monitors.conf")
parse_nwg_file("workspaces.conf")
