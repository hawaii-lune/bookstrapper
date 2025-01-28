--!strict
local Types = require("./Types")
local Common = require("./Common")
local Result = require("./Result")

local MessageHandler = {}
local DEBUGMODE = false

local function threadTostring(tid: string?): string
	return if type(tid)=="string" then `thread: {tid}` else tostring(coroutine.running())
end

function MessageHandler.result<T, E>(r: Result.Result<T, E>, tID: string?, runner: Types.BookstrapRunner<T, E>)
	if not runner.PipeResultErrors or r:isOk() then return end
	runner.Log:write(`\27[91m{threadTostring(tID)} raised Err: {r:unwrapErr()}\27[39m\n`, "Panic", true)
	--runner.Log:write("[HINT]: To hide the outermost Result error, set PipeResultErrors to false on the Bookstrapper", "Info", true)
end

function MessageHandler.panicInternal<T,E>(msg: string|Result.Result<T,E>?, runner: Types.BookstrapRunner<T,E>, tID: string?, throw: boolean): Result.Result<T, string>?
	-- Throw is used to return a result instead of cutting the thread, its used to raise "Thread panicked while executing" outside of pcalls
	-- Export.panic will always throw.

	tID = threadTostring(tID)

	if not msg then msg = "No output from Lua." end
	if typeof(msg) == "table" then msg = msg:unwrapErr() end

	local trace = Common.GenerateStackTrace(if DEBUGMODE then "All" else "Allowlist", runner.StackAllowlist)
	local stackSize = #trace + 3
	local stack = table.create(stackSize)
	table.insert(stack, `\x07\27[91m{tID} panicked with {msg}\27[39m`)
	table.insert(stack, "[\27[94mStack Begin\27[39m]")

	for i, stackInfo in trace do
		stack[i+2] = `   \27[92m{tostring(stackInfo)}\27[39m`
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