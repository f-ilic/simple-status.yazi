-- Cache for username lookups to avoid repeated system calls
local username_cache = {}

-- Function to resolve UID to username
local function get_username(uid)
	if not uid then return nil end
	
	-- Check cache first
	if username_cache[uid] then
		return username_cache[uid]
	end
	
	-- Try to get username via system call
	local handle = io.popen("id -un " .. uid .. " 2>/dev/null")
	if handle then
		local username = handle:read("*a"):gsub("%s+", "") -- trim whitespace
		handle:close()
		
		-- Cache the result (fallback to UID if lookup failed)
		username_cache[uid] = (username ~= "" and username) or tostring(uid)
		return username_cache[uid]
	end
	
	-- Fallback to numeric UID
	return tostring(uid)
end

local function setup()
	-- Clear all existing status items to remove default content
	Status._left = {}
	Status._right = {}
	
	-- Add simple status bar (left side)
	Status:children_add(function()
		local h = cx.active.current.hovered
		if not h then
			return ui.Span("")
		end
		
		local parts = {}

		-- File owner (resolve UID to username)
		local uid = h.cha.uid
		if uid then
			local username = get_username(uid)
			table.insert(parts, ui.Span(username .. " "):fg("yellow"))
		end
		
		-- File permissions
		local perm = h.cha:perm()
		if perm then
			table.insert(parts, ui.Span(perm):fg("cyan"))
			table.insert(parts, ui.Span("  "):fg("white"))
		end
		
		
		-- Modified date
		if h.cha.mtime then
			local mtime = os.date("%Y-%m-%d %H:%M", math.floor(h.cha.mtime))
			table.insert(parts, ui.Span(mtime .. " "):fg("green"))
		end
		
		-- File size
		local size = h:size() or h.cha.len or 0
		table.insert(parts, ui.Span(ya.readable_size(size)):fg("white"))
		
		return ui.Line(parts)
	end, 100, Status.LEFT)
	
	-- Add position and selection info (right side)
	Status:children_add(function()
		local current = cx.active.current
		local cursor = current.cursor
		local length = #current.files
		
		local parts = {}
				
		-- Position info
		table.insert(parts, ui.Span(string.format("%d/%d  ", math.min(cursor + 1, length), length)):fg("white"))
		
		-- Percentage
		local percent = length == 0 and 0 or math.floor((cursor + 1) * 100 / length)
		if percent == 0 then
			table.insert(parts, ui.Span("All"):fg("green"))
		elseif percent == 100 then
			table.insert(parts, ui.Span("Bot"):fg("green"))
		else
			table.insert(parts, ui.Span(string.format("%d%%", percent)):fg("green"))
		end
		
		return ui.Line(parts)
	end, 100, Status.RIGHT)
end

return { setup = setup }

