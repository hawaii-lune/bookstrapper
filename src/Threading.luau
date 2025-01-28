local Result = require("./Result")
local Types = require("./Types")
local MessageHandler = require("./MessageHandler")
local Common = require("./Common")
local task = require("@lune/task")

-- A threading libraries that handles exit outs properly rather than
-- raising the error

-- You should use this instead of coroutine to create threads

local function IS_LIKELY_RESULT(r: any)
	return type(r) == "table" and r.is ~= nil
end

local function resultXpcallTry(resultImpl, runner, tID, fn, ...)
	local trace
	local ok, body = xpcall(fn, function(err)
		trace = Common.GenerateStackTrace(if MessageHandler.DebugMode then "All" else "Allowlist", runner.StackAllowlist)
		return err
	end)

	if not ok then 
		local errR = resultImpl.Err(body)
		MessageHandler.panicWithTrace(errR, trace, runner, tID, false)
		return errR
	end

	return resultImpl.Ok(body)
end

return function<T,E>(runner: Types.BookstrapRunner<T,E>)
	local threading = {}
	local ownershipSize = 0
	local closeForWaitThread
	threading.owned = {} :: {[thread]: string?}

	function threading.createRunner<U,V,A...>(
		tIdentifier: string?,
		requireResultReturn: boolean,
		emitInitErr: boolean,
		fn: (A...) -> Result.Result<U, V>
	): (A...) -> Result.Result<U,V>

		local Result = runner.Exports.Result
		return function(...)
			local rA = resultXpcallTry(Result, runner, tIdentifier, fn, ...)
			-- close thread from threading
			if threading.owned[coroutine.running()] then
				ownershipSize -= 1
				threading.owned[coroutine.running()] = nil

				if ownershipSize == 0 and closeForWaitThread then
					task.defer(closeForWaitThread)
				end
			end

			if rA:isErr() then
				if emitInitErr then MessageHandler.result(rA, tIdentifier, runner) end
				return rA
			end

			local okVal = rA:unwrap()
			local isResult = IS_LIKELY_RESULT(okVal)
			if not isResult and requireResultReturn then
				rA = Result.Err("thread did not return a Result as required.")
				if emitInitErr then MessageHandler.result(rA, tIdentifier, runner) end
				return rA
			end

			return okVal
		end
	end

	function threading.allocThreadForRunner<T, E, A...>(fnOrThread: (A...) -> Result.Result<T, E>|thread): thread
		if type(fnOrThread) == "thread" then
			-- check thread allocation
			if not threading.owned[fnOrThread] then runner.Exports.Panic(`thread {fnOrThread} is not allocated and cannot be used}`) end
			return fnOrThread
		end

		local t = coroutine.create(threading.createRunner(nil, false, true, fnOrThread::(A...) -> Result.Result<T,E>))
		ownershipSize += 1
		threading.owned[t] = true
		return t
	end

	function threading.WaitForClose()
		closeForWaitThread = coroutine.running()
		return coroutine.yield()
	end

	local exported = {}

	function exported.Spawn<T, E, A...>(fnOrThread: (A...) -> Result.Result<T, E>|thread, ...:A...): thread
		return task.spawn(threading.allocThreadForRunner(fnOrThread), ...)
	end

	function exported.Defer<T, E, A...>(fnOrThread: (A...) -> Result.Result<T, E>|thread, ...:A...): thread
		return task.defer(threading.allocThreadForRunner(fnOrThread), ...)
	end

	function exported.Delay<T, E, A...>(init: number, fnOrThread: (A...) -> Result.Result<T, E>|thread, ...:A...): thread
		return task.delay(init, threading.allocThreadForRunner(fnOrThread), ...)
	end

	function exported.Create<T, E, A...>(init: number, fnOrThread: (A...) -> Result.Result<T, E>, ...:A...): thread
		return threading.allocThreadForRunner(fnOrThread)
	end

	threading.Exports = exported
	return threading
end