--!strict
local Types = require("./Types")
local Result = require("./Result")
local Common = require("./Common")

local MessageHandler = {}

function MessageHandler.result<T, E>(r: Result.Result<T, E>, runner: Types.BookstrapRunner<T, E>)
	if not runner.PipeResultErrors or r:isOk() then return end
	runner.Log:write(`\27[91mThread {coroutine.running()} raised Err result {r:unwrapErr()}.\27[39m\n`, "Panic", true)
end

function MessageHandler.panicInternal<T,E>(msg: string|Result.Result<T,E>?, runner: Types.BookstrapRunner<T,E>)
	if not msg then msg = "No output from Lua." end
	if typeof(msg) == "table" then msg = msg:unwrapErr() end

	local trace = Common.GenerateStackTrace("Allowlist", runner.StackAllowlist)
	local stackSize = #trace + 3
	local stack = table.create(stackSize)
	table.insert(stack, `\x07\27[91mThread {coroutine.running()} panicked with {msg}\27[39m`)
	table.insert(stack, "[\27[94mStack Begin\27[39m]")

	for i, stackInfo in trace do
		stack[i+2] = `   \27[92m{tostring(stackInfo)}\27[39m`
	end
	table.insert(stack, "[\27[94mStack End\27[39m]\n")
	runner.Log:write(table.concat(stack, "\n"), "Panic", true)
	
	Common.disposeRunningThread()
end

return MessageHandler