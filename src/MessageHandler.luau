--!strict
local Types = require("./Types")
local Common = require("./Common")
local Result = require("./Result")

local MessageHandler = {}
MessageHandler.DebugMode = false

local function threadTostring(tid: string?): string
	return if type(tid)=="string" then `thread: {tid}` else tostring(coroutine.running())
end

function MessageHandler.result<T, E>(r: Result.Result<T, E>, tID: string?, runner: Types.BookstrapRunner<T, E>)
	if not runner.PipeResultErrors or r:isOk() then return end
	runner.Log:write(`\27[91m{threadTostring(tID)} raised Err: {r:unwrapErr()}\27[39m\n`, "Panic", true)
	--runner.Log:write("[HINT]: To hide the outermost Result error, set PipeResultErrors to false on the Bookstrapper", "Info", true)
end

function MessageHandler.panicWithTrace<T, E>(msg: string|Result.Result<T, E>?, trace: {Types.StackInfo}?, runner: Types.BookstrapRunner<T, E>, tID: string?, throw: boolean)
	tID = threadTostring(tID)

	if not msg then msg = "No output from Lua." end
	if typeof(msg) == "table" then msg = msg:unwrapErr() end

	if not trace then
		trace = Common.GenerateStackTrace(if MessageHandler.DebugMode then "All" else "Allowlist", runner.StackAllowlist)
	end

	local stackSize = #trace + 3
	local stack = table.create(stackSize)
	table.insert(stack, `\x07\27[91m{tID} panicked with {msg}\27[39m`)
	table.insert(stack, "[\27[94mStack Begin\27[39m]")

	for i, stackInfo in trace do
		if stackInfo.TruncationMarker then
			stack[i+2] = `   \27[90m<TRUNCATED>\27[39m`
		else
			if stackInfo.RepeatCount > 1 then
				stack[i+2] = `   \27[92m{tostring(stackInfo)} \27[90m({stackInfo.RepeatCount}x)\27[39m`
			else
				stack[i+2] = `   \27[92m{tostring(stackInfo)}\27[39m`
			end
		end
	end
	table.insert(stack, "[\27[94mStack End\27[39m]\n")
	runner.Log:write(table.concat(stack, "\n"), "Panic", true)
	
	if throw then
		error("Thread panicked while executing", -1)
	else
		return runner.Exports.Result.Err("Thread panicked while executing")
	end
end

return MessageHandler