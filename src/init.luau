local Types = require("./Types")
local Common = require("./Common")
local Exports = require("./Exports")
local Logger = require("./Logger")
local ThreadExceptionHandler = require("./ThreadExceptionHandler")
local Threading = require("./Threading")

-- we need to set the root log here as its how we can tell if we're working with
-- the init file or a shorthand
-- if its a shorthand then all log info is pointless

local LuaException = Exports.Exception.Extend("LuaException")

return function(name: string, tryFn: () -> ()): Types.BookstrapRunner
	local runner = {}::Types.BookstrapRunner
	runner.Name = name
	runner.TryCatchStack = {}
	runner.Log = Logger(name)
	runner.StackAllowList = {}

	function runner.ExecuteTryCatch(
		self: Types.BookstrapRunner,
		catch: Types.TryCatch<string>,
		...: any
	)
		local co = coroutine.running()
		local catchStack = self.TryCatchStack[co]

		if not catchStack then
			catchStack = {}
			self.TryCatchStack[co] = catchStack
		end
		local size = #catchStack

		table.insert(catchStack, {TryCatch = catch, FinallyExec = nil})
		local ok, err = pcall(catch._try, ...)
		table.remove(catchStack, size + 1)

		if size <= 0 then
			self.TryCatchStack[co] = nil
		end

		local ex = catch._ex
		if not ok and not ex then
			ex = LuaException(err)
		end
		
		if ex then
			if size > 0 then
				catchStack[size].FinallyExec = catch._finally
			end

			local handler = catch._catches[ex.Kind] or catch._defaultcatch
			if handler then handler(ex) end
		end

		if catch._finally then catch._finally() end
		return ok
	end

	function runner.Run(self: Types.BookstrapRunner)
		local co = coroutine.running()
		Common.BookstrappedThreads[co] = self
		Threading.malloc(co)
		
		local ok = self:ExecuteTryCatch(self.RootHandle)

		Threading.free(co)
		Common.BookstrappedThreads[coroutine.running()] = nil
		return ok
	end

	function runner.CreateStackTrace(self: Types.BookstrapRunner, filtermode: "Allowlist"|"All"|"C"?): {Types.StackInfo}
		return Common.GenerateStackTrace(filtermode or "Allowlist", runner.StackAllowList)
	end
	
	function runner.Exception<A>(self: Types.BookstrapRunner, kind: A, msg: string?): Types.Exception<A>
		local ex = {
			Kind = kind,
			Message = msg,
			Stack = self:CreateStackTrace("Allowlist"),
		}

		table.freeze(ex.Stack)
		table.freeze(ex)
		return ex
	end

	runner.Exports = Exports
	runner.RootHandle = ThreadExceptionHandler(tryFn, runner)

	return runner
end