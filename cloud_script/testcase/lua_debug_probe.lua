local M = {}

local started = false

local function validate_address(address)
	if type(address) ~= "string" then
		error("LuaDebug address must be a string", 3)
	end

	local port = string.match(address, "^127%.0%.0%.1:(%d+)$")
		or string.match(address, "^localhost:(%d+)$")
	port = tonumber(port)
	if not port or port < 1 or port > 65535 then
		error("LuaDebug address must use 127.0.0.1 or localhost with a valid port", 3)
	end
end

function M.start(options)
	options = options or {}
	local address = options.address or "127.0.0.1:12306"
	validate_address(address)

	if started then
		return true
	end

	local loaded, debugger_or_error = pcall(require, "debugger")
	if not loaded then
		error("LuaDebug module is unavailable: " .. tostring(debugger_or_error), 2)
	end

	local LDBG = debugger_or_error
	if type(LDBG) ~= "table" and type(LDBG) ~= "userdata" then
		error("LuaDebug module returned an unsupported value", 2)
	end
	if type(LDBG.start) ~= "function" then
		error("LuaDebug module does not provide start()", 2)
	end

	local start_ok, start_error = pcall(function()
		LDBG:start(address)
		if options.wait then
			if type(LDBG.event) ~= "function" then
				error("LuaDebug module does not provide event()")
			end
			LDBG:event("wait")
		end
	end)
	if not start_ok then
		error("LuaDebug failed to start: " .. tostring(start_error), 2)
	end

	started = true
	return true
end

function M.run_probe()
	local probe_value = 41
	-- LUA_DEBUG_BREAKPOINT: set a breakpoint on the next line.
	probe_value = probe_value + 1
	assert(probe_value == 42, "LuaDebug probe produced an unexpected value")
	return probe_value
end

return M
