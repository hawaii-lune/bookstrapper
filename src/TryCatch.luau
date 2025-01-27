local Common = require("./Common")
local Types = require("./Types")

return function<ErrUnion>(
	tryFn: (...any) -> ()
): Types.TryCatch<ErrUnion>
	local tryCatch = {}
	tryCatch._try = tryFn
	tryCatch._catches = {}

	function tryCatch.Catch(self: Types.TryCatch<ErrUnion>, ex: ErrUnion?, fn: (Types.Exception<ErrUnion>) -> ())
		if ex then
			if self._catches[ex] then Common.G_PANIC(`Exception {ex} is already handled in TryCatch block`) end
			self._catches[ex] = fn
		else
			if self._defaultcatch then Common.G_PANIC("Default catch is already defined in TryCatch block") end
			self._defaultcatch = fn
		end

		return self
	end

	function tryCatch.Finally(self: Types.TryCatch<ErrUnion>, fn: () -> ())
		if self._finally then Common.G_PANIC("Finally is already defined in TryCatch block") end
		self._finally = fn
		return self
	end

	return setmetatable(tryCatch, {
		__call = function(self: Types.TryCatch<ErrUnion>)
			-- we need to push the thread into the panic handler
			local bookstrapper = Common.BookstrappedThreads[coroutine.running()]
			if not bookstrapper then
				Common.G_PANIC("Attempt to use TryCatch outside bookstrapped thread")
			end

			-- push the trycatch into the stack then defer to the bookstrapper
			bookstrapper:ExecuteTryCatch(self)
		end
	})
end