local Result = require("./Result")
local Types = require("./Types")
local MessageHandler = require("./MessageHandler")
local task = require("@lune/task")

-- A threading libraries that handles exit outs properly rather than
-- raising the error

-- You should use this instead of coroutine to create threads

local function IS_LIKELY_RESULT(r: any)
	return type(r) == "table" and r.is ~= nil
end

return function<T,E>(runner: Types.BookstrapRunner<T,E>)
	local threading = {}
	threading.owned = {} :: {[thread]: string?}

	function threading.createRunner<U,V,A...>(
		tIdentifier: string?,
		requireResultReturn: boolean,
		emitInitErr: boolean,
		fn: (A...) -> Result.Result<U, V>
	): (A...) -> Result.Result<U,V>

		local Result = runner.Exports.Result
		return function(...)
			local rA = Result.try(fn, ...)
			-- close thread from threading
			threading.owned[coroutine.running()] = nil

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
		threading.owned[t] = true
		return t
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