-- C# Concurrency system through Task
-- Do NOT create threads through coroutine or task since these ignore bookstrapper
-- 's error collector

-- This works by creating a temporary worker for a thread, then pushing the
-- OK or EXCEPTION result to the top

-- This API closely mirrors that of task

local task = require("@lune/task")
local ThreadExceptionHandler = require("./ThreadExceptionHandler")
local Common = require("./Common")

local Threading = {}
local consumsable: {[thread]: true} = {}

local function createBKSThread<A...>(fn): thread
	local mainWorker = Common.getBookstrapperFromThread()

	local co = coroutine.create(function(...)
		local co = coroutine.running()
		Common.BookstrappedThreads[co] = mainWorker
		local tc = ThreadExceptionHandler(fn, mainWorker)
		mainWorker:ExecuteTryCatch(tc, ...)
		consumsable[co] = nil
		Common.BookstrappedThreads[co] = nil
	end)

	consumsable[co] = true
	return co
end

local function bksHandler<A...>(fn: (A...) -> ()|thread): thread
	if typeof(fn) == "function" then
		fn = createBKSThread(fn)
	else
		if not consumsable[fn] then Common.G_PANIC(`Thread is not usable in the given context.`) end
	end

	return fn::thread
end

function Threading.create(fn: (...any) -> ()): thread
	return createBKSThread(fn)
end

function Threading.spawn(thread, ...)
	return task.spawn(bksHandler(thread), ...)
end

function Threading.defer(thread, ...)
	return task.defer(bksHandler(thread), ...)
end

function Threading.delay(interval, thread, ...)
	return task.delay(interval, bksHandler(thread), ...)
end

function Threading.cancel(thread)
	if not consumsable[thread] then Common.G_PANIC("Thread is not usable in the given context") end
	task.cancel(thread)
end

function Threading.wrap(fn: (...any) -> ()): (...any) -> ()
	local t = Threading.create(fn)
	return function(...)
		Threading.spawn(t, ...)
	end
end

function Threading.malloc(thread)
	consumsable[thread]=true
end

function Threading.free(thread)
	consumsable[thread]=nil
end

Threading.Exported = {
	create = Threading.create,
	spawn = Threading.spawn,
	defer = Threading.defer,
	delay = Threading.delay,
	cancel = Threading.cancel,
	wrap = Threading.cancel
}

table.freeze(Threading.Exported)
return Threading