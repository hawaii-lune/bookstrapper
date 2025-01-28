--!strict
local Types = require("./Types")
local Result = require("./Result")
local MessageHandler = require("./MessageHandler")

local function flattenArgs(...)
	local buffer = {}
	for _, key in {...} do
		table.insert(buffer, tostring(key))
	end
	return table.concat(buffer, "  ")
end


return function<T,E>(runner: Types.BookstrapRunner<T,E>)
	local exports = {}

	function exports.Write(...: any)
		runner.Log:write(`{flattenArgs(...)}`, "Log", true)
	end

	function exports.WriteLine(...: any)
		runner.Log:write(`{flattenArgs(...)}\n`, "Log", true)
	end

	function exports.Warn(...: any)
		runner.Log:write(`{flattenArgs(...)}\n`, "Warning", true)
	end

	function exports.Panic(msg: string|Result.Result<T, E>?)
		local tID = runner.Threading.owned[coroutine.running()]
		MessageHandler.panicInternal(msg, runner, tID, true)
	end

	exports.Result = Result(exports.Panic)
	exports.Threading = runner.Threading.Exports

	table.freeze(exports)
	return exports
end